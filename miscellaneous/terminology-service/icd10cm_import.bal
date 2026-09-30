// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import terminology_service.icd10cm_to_fhir as icd10cm;
import terminology_service.store_h2;

import ballerina/http;
import ballerina/log;
import ballerina/persist;
import ballerina/sql;
import ballerina/uuid;
import ballerinax/health.fhir.r4;

const int ICD10CM_INSERT_BATCH_SIZE = 1000;

// The concepts.display column is VARCHAR(191). Some chapter/section titles
// and long descriptions exceed that (e.g. chapter 2's full malignant
// neoplasms section title), so the value stored in this column is truncated
// - the full, untruncated text is still what's returned by $lookup, since
// that's read from the serialized `concept` blob, not this column.
const int DISPLAY_COLUMN_LIMIT = 191;

isolated function truncateDisplayColumn(string display) returns string {
    if display.length() <= DISPLAY_COLUMN_LIMIT {
        return display;
    }
    return display.substring(0, DISPLAY_COLUMN_LIMIT);
}

// Guards against two ICD-10-CM imports running concurrently. Independent
// from the SNOMED guard (`snomedImportInProgress`) so an ICD-10-CM upload
// never blocks, or is blocked by, an unrelated SNOMED upload.
isolated boolean icd10cmImportInProgress = false;

# Attempts to acquire the single-flight ICD-10-CM import guard.
#
# + return - `true` if the caller may proceed with an import (the guard is now held); `false` if another import is already in progress
public isolated function tryAcquireIcd10cmImportLock() returns boolean {
    lock {
        if icd10cmImportInProgress {
            return false;
        }
        icd10cmImportInProgress = true;
        return true;
    }
}

# Releases the single-flight ICD-10-CM import guard acquired via `tryAcquireIcd10cmImportLock`. Must be called exactly once per successful acquisition, regardless of whether the import succeeded or failed.
public isolated function releaseIcd10cmImportLock() {
    lock {
        icd10cmImportInProgress = false;
    }
}

# Parses an ICD-10-CM release directory and loads it into the database. Any earlier load of the same url and version is replaced, and a partial load is rolled back if the import fails partway.
#
# + dirPath - The path of the extracted ICD-10-CM release directory
# + version - The version to record for the imported CodeSystem, if given
# + return - A summary of the import counts, or a `FHIRError` if the import fails
public isolated function importIcd10cmToDb(string dirPath, string? version) returns icd10cm:Icd10cmImportSummary|r4:FHIRError {
    icd10cm:Icd10cmImportBundle|error bundle = icd10cm:buildIcd10cmImport(dirPath, version);
    if bundle is error {
        return r4:createFHIRError(
                "Failed to build ICD-10-CM import bundle: " + bundle.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = bundle,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }

    byte[]|r4:FHIRError metadataBytes = codeSystemToByte(bundle.codeSystemMetadata);
    if metadataBytes is r4:FHIRError {
        return metadataBytes;
    }

    r4:CodeSystem meta = bundle.codeSystemMetadata;
    string csUrl = meta.url ?: icd10cm:ICD10CM_SYSTEM_URL;
    string csVersion = meta.version ?: "";

    // Staged under a placeholder url that can never match a real
    // url/version lookup, so the new row stays invisible to $lookup/
    // $validate-code/etc. for as long as it's being populated - only the
    // publish step below (after concepts+closure fully succeed) makes it
    // resolvable under the real csUrl, and only once it's actually complete.
    // This avoids a window where a concurrent request could resolve to a
    // same-url/version row whose concepts aren't loaded yet, without needing
    // a schema change to track completion.
    string stagingUrl = "urn:staging:icd10cm-import:" + uuid:createType1AsString();

    store_h2:CodeSystemInsert codeSystemInsert = {
        id: meta.id ?: icd10cm:ICD10CM_CODE_SYSTEM_ID,
        url: stagingUrl,
        version: csVersion,
        name: meta.name ?: icd10cm:ICD10CM_CODE_SYSTEM_NAME,
        title: meta.title ?: icd10cm:ICD10CM_CODE_SYSTEM_TITLE,
        status: meta.status,
        date: meta.date ?: "",
        publisher: meta.publisher ?: icd10cm:ICD10CM_PUBLISHER,
        codeSystem: metadataBytes
    };

    // The new load is inserted (staged, and fully populated below) BEFORE
    // any prior load of the same url/version is removed at the end of this
    // function - so a failure partway through this import leaves the
    // previous, still-usable load untouched instead of deleting it first and
    // only then discovering the replacement failed.
    int[]|persist:Error codeSystemResult = sClient->/codesystems.post([codeSystemInsert]);
    if codeSystemResult is persist:Error {
        return r4:createFHIRError(
                "Error while inserting ICD-10-CM CodeSystem row: " + codeSystemResult.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = codeSystemResult,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
    int codeSystemId = codeSystemResult[0];

    [int, map<int>, map<int>]|r4:FHIRError loadResult = loadIcd10cmConcepts(bundle, codeSystemId);
    if loadResult is r4:FHIRError {
        error? cleanup = deleteSnomedCodeSystemCascade(codeSystemId);
        if cleanup is error {
            log:printError(string `ICD-10-CM cleanup-on-failure failed for codeSystemId=${codeSystemId}: ${cleanup.message()}`);
        }
        return loadResult;
    }
    int conceptsImported = loadResult[0];
    map<int> dbIdByCode = loadResult[1];
    map<int> parentDbIdByConceptId = loadResult[2];

    int|r4:FHIRError closureRowsWritten = writeIcd10cmClosure(dbIdByCode, parentDbIdByConceptId, codeSystemId);
    if closureRowsWritten is r4:FHIRError {
        error? cleanup = deleteSnomedCodeSystemCascade(codeSystemId);
        if cleanup is error {
            log:printError(string `ICD-10-CM cleanup-on-failure failed for codeSystemId=${codeSystemId}: ${cleanup.message()}`);
        }
        return closureRowsWritten;
    }

    // Publish: the new load is fully populated now, so switch it from the
    // staging url to the real one in a single statement - this is the
    // instant it becomes resolvable by callers, and it's already complete
    // when it does.
    sql:ParameterizedQuery publishQuery = sql:queryConcat(
            `UPDATE `, escapeToQuery("codesystems"), ` SET `, escapeToQuery("url"), ` = ${csUrl}`,
            ` WHERE `, escapeToQuery("codeSystemId"), ` = ${codeSystemId}`);
    sql:ExecutionResult|persist:Error publishResult = sClient->executeNativeSQL(publishQuery);
    if publishResult is persist:Error {
        error? cleanup = deleteSnomedCodeSystemCascade(codeSystemId);
        if cleanup is error {
            log:printError(string `ICD-10-CM cleanup-on-failure failed for codeSystemId=${codeSystemId}: ${cleanup.message()}`);
        }
        return r4:createFHIRError(
                "Error while publishing ICD-10-CM CodeSystem row: " + publishResult.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = publishResult,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // Only now is any prior load of the same url/version removed - the new
    // load is both published and complete at this point.
    int|r4:FHIRError replaced = replacePriorLoads(csUrl, csVersion, excludeCodeSystemId = codeSystemId);
    if replaced is r4:FHIRError {
        log:printError(string `ICD-10-CM: failed to remove prior load(s) for ${csUrl}|${csVersion} after successful replacement: ${replaced.message()}`);
    } else if replaced > 0 {
        log:printInfo(string `ICD-10-CM replace: removed ${replaced} prior load(s) for ${csUrl}|${csVersion}`);
    }

    return {
        codeSystemId: codeSystemId.toString(),
        system: csUrl,
        'version: csVersion,
        chaptersRead: bundle.chaptersRead,
        sectionsRead: bundle.sectionsRead,
        orderFileRowsRead: bundle.orderFileRowsRead,
        conceptsImported: conceptsImported,
        closureRowsWritten: closureRowsWritten
    };
}

# Inserts every concept in topological order (chapters, then sections, then order-file codes grouped by raw length ascending), resolving each row's `parentConceptId` from the database ids assigned to the previously-flushed groups. A pending batch is flushed early whenever the next concept belongs to a later topological group than the batch currently holds, so a group is always fully flushed - and its database ids fully known - before any concept from the next group is built. Within a group, batches are still capped at `ICD10CM_INSERT_BATCH_SIZE` for efficiency.
#
# + bundle - The parsed ICD-10-CM import bundle, with concepts pre-sorted topologically
# + codeSystemId - The database id of the CodeSystem row the concepts belong to
# + return - A tuple of the number of concepts imported, the code -> database id map, and the child database id -> parent database id map, or a `FHIRError` if any insert fails
isolated function loadIcd10cmConcepts(icd10cm:Icd10cmImportBundle bundle, int codeSystemId) returns [int, map<int>, map<int>]|r4:FHIRError {
    int imported = 0;
    map<int> dbIdByCode = {};

    store_h2:ConceptInsert[] batch = [];
    string[] codesInBatch = [];
    int currentSortGroup = 0;
    boolean haveSortGroup = false;

    foreach icd10cm:IcdConceptImport item in bundle.concepts {
        if haveSortGroup && item.sortGroup != currentSortGroup && batch.length() > 0 {
            // Crossing into a new topological group - flush now so every
            // concept already queued (all from the group about to close) gets
            // its database id recorded before the next group's concepts,
            // which may depend on it as a parent, are built.
            int[]|r4:FHIRError flushedIds = flushConceptBatch(batch);
            if flushedIds is r4:FHIRError {
                return flushedIds;
            }
            recordInsertedIds(dbIdByCode, codesInBatch, flushedIds);
            imported += flushedIds.length();
            batch = [];
            codesInBatch = [];
        }
        currentSortGroup = item.sortGroup;
        haveSortGroup = true;

        int? parentDbId = ();
        string? parentCode = item.parentCode;
        if parentCode is string {
            int? resolved = dbIdByCode[parentCode];
            if resolved is int {
                parentDbId = resolved;
            } else {
                log:printError(string `ICD-10-CM concept '${item.code}' references unresolved parent '${parentCode}' - importing as a root-level orphan`);
            }
        }

        r4:CodeSystemConcept concept = icd10cm:icdConceptImportToR4(item);
        byte[]|r4:FHIRError conceptBytes = conceptToByte(concept);
        if conceptBytes is r4:FHIRError {
            log:printError("Skipping ICD-10-CM concept, serialization failed: code=" + item.code + ", " + conceptBytes.message());
            continue;
        }

        store_h2:ConceptInsert conceptInsert = {
            code: item.code,
            display: truncateDisplayColumn(item.display),
            definition: (),
            concept: conceptBytes,
            parentConceptId: parentDbId,
            codesystemCodeSystemId: codeSystemId
        };
        batch.push(conceptInsert);
        codesInBatch.push(item.code);

        if batch.length() >= ICD10CM_INSERT_BATCH_SIZE {
            int[]|r4:FHIRError flushedIds = flushConceptBatch(batch);
            if flushedIds is r4:FHIRError {
                return flushedIds;
            }
            recordInsertedIds(dbIdByCode, codesInBatch, flushedIds);
            imported += flushedIds.length();
            batch = [];
            codesInBatch = [];
        }
    }

    if batch.length() > 0 {
        int[]|r4:FHIRError flushedIds = flushConceptBatch(batch);
        if flushedIds is r4:FHIRError {
            return flushedIds;
        }
        recordInsertedIds(dbIdByCode, codesInBatch, flushedIds);
        imported += flushedIds.length();
    }

    // A clean second pass over the now-fully-populated dbIdByCode builds the
    // child -> parent database id map writeIcd10cmClosure walks. Simpler than
    // tracking it inline above, since a concept's own database id isn't known
    // until its batch is flushed - which may happen after later concepts in
    // the same group have already been built.
    map<int> parentDbIdByConceptId = {};
    foreach icd10cm:IcdConceptImport item in bundle.concepts {
        int? childDbId = dbIdByCode[item.code];
        string? parentCode = item.parentCode;
        if childDbId is int && parentCode is string {
            int? parentDbId = dbIdByCode[parentCode];
            if parentDbId is int {
                // map<int> keys are always strings in Ballerina - the
                // concept's database id is stringified to use as the key.
                parentDbIdByConceptId[childDbId.toString()] = parentDbId;
            }
        }
    }

    return [imported, dbIdByCode, parentDbIdByConceptId];
}

# Writes one closure row per concept-ancestor pair, plus a depth-0 self row for each concept. Since ICD-10-CM is a single-parent tree, each concept's ancestors are found with a straight walk up the `parentDbIdByConceptId` chain to its chapter root - no multi-parent BFS/deduplication is needed, unlike SNOMED's `writeClosure`. Rows are inserted in batches.
#
# + dbIdByCode - The database id assigned to every imported concept, keyed by code
# + parentDbIdByConceptId - The immediate parent's database id for every concept that has one (absent for chapter roots)
# + codeSystemId - The database id of the CodeSystem the closure rows belong to
# + return - The number of closure rows written, or a `FHIRError` if a batch insert fails
isolated function writeIcd10cmClosure(map<int> dbIdByCode, map<int> parentDbIdByConceptId, int codeSystemId) returns int|r4:FHIRError {
    int written = 0;
    ClosureRow[] batch = [];

    foreach int conceptId in dbIdByCode {
        batch.push({ancestor: conceptId, descendant: conceptId, depth: 0});

        int depth = 1;
        int? current = parentDbIdByConceptId[conceptId.toString()];
        while current is int {
            batch.push({ancestor: current, descendant: conceptId, depth: depth});
            depth += 1;
            current = parentDbIdByConceptId[current.toString()];
        }

        if batch.length() >= ICD10CM_INSERT_BATCH_SIZE {
            int|r4:FHIRError flushed = flushClosureBatch(batch, codeSystemId);
            if flushed is r4:FHIRError {
                return flushed;
            }
            written += flushed;
            batch = [];
        }
    }

    if batch.length() > 0 {
        int|r4:FHIRError flushed = flushClosureBatch(batch, codeSystemId);
        if flushed is r4:FHIRError {
            return flushed;
        }
        written += flushed;
    }

    return written;
}

# Runs the import in the background so the upload request can return right away, and removes the temp directory once the worker is done with it.
#
# + extractedPath - The path of the extracted ICD-10-CM release directory to import
# + version - The version to record for the imported CodeSystem, if given
# + tempDir - The temporary directory to remove once the import finishes
public isolated function runIcd10cmImportAsync(string extractedPath, string? version, string tempDir) returns () {
    log:printInfo("ICD-10-CM import worker started: extractedPath=" + extractedPath);
    icd10cm:Icd10cmImportSummary|r4:FHIRError result = importIcd10cmToDb(extractedPath, version);
    // Release the single-flight guard as soon as the DB work is done -
    // success or failure - so a queued upload isn't blocked by unrelated
    // temp-dir cleanup.
    releaseIcd10cmImportLock();
    if result is r4:FHIRError {
        log:printError("ICD-10-CM import failed: " + result.message());
    } else {
        log:printInfo(string `ICD-10-CM import complete: chaptersRead=${result.chaptersRead}, sectionsRead=${result.sectionsRead}, orderFileRowsRead=${result.orderFileRowsRead}, conceptsImported=${result.conceptsImported}, closureRowsWritten=${result.closureRowsWritten}, codeSystemId=${result.codeSystemId}`);
    }
    error? cleanup = removeDirectory(tempDir);
    if cleanup is error {
        log:printError("ICD-10-CM cleanup failed for " + tempDir + ": " + cleanup.message());
    }
}
