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

import terminology_service.snomed_to_fhir as snomed;
import terminology_service.store_h2;

import ballerina/http;
import ballerina/log;
import ballerina/persist;
import ballerina/sql;
import ballerinax/health.fhir.r4;
import ballerinax/persist.sql as psql;

const int SNOMED_INSERT_BATCH_SIZE = 1000;

const int SNOMED_CLOSURE_PROGRESS_INTERVAL = 100000;

// Guards against two SNOMED imports running concurrently. Only one SNOMED import may be in flight at a
// time; the upload endpoint checks this before starting a background worker
// and rejects a second concurrent upload instead of racing it.
isolated boolean snomedImportInProgress = false;

# Attempts to acquire the single-flight SNOMED import guard.
#
# + return - `true` if the caller may proceed with an import (the guard is now held); `false` if another import is already in progress
public isolated function tryAcquireSnomedImportLock() returns boolean {
    lock {
        if snomedImportInProgress {
            return false;
        }
        snomedImportInProgress = true;
        return true;
    }
}

# Releases the single-flight SNOMED import guard acquired via `tryAcquireSnomedImportLock`. Must be called exactly once per successful acquisition, regardless of whether the import succeeded or failed.
public isolated function releaseSnomedImportLock() {
    lock {
        snomedImportInProgress = false;
    }
}

type ClosureRow record {|
    int ancestor;
    int descendant;
    int depth;
|};

type RelationshipRow record {|
    int sourceConceptId;
    string typeId;
    int destinationConceptId;
|};

# Parses an RF2 release directory and loads it into the database. Any earlier load of the same url and version is replaced, and a partial load is rolled back if the import fails partway.
#
# + dirPath - The path of the extracted RF2 release directory
# + version - The version to record for the imported CodeSystem, if given
# + return - A summary of the import counts, or a `FHIRError` if the import fails
public isolated function importSnomedToDb(string dirPath, string? version) returns snomed:SnomedImportSummary|r4:FHIRError {
    snomed:SnomedImportBundle|error bundle = snomed:buildSnomedImport(dirPath, version);
    if bundle is error {
        return r4:createFHIRError(
                "Failed to build SNOMED import bundle: " + bundle.message(),
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
    string csUrl = meta.url ?: snomed:SNOMED_SYSTEM_URL;
    string csVersion = meta.version ?: "";

    int replaced = check replacePriorLoads(csUrl, csVersion);
    if replaced > 0 {
        log:printInfo(string `SNOMED replace: removed ${replaced} prior load(s) for ${csUrl}|${csVersion}`);
    }

    store_h2:CodeSystemInsert codeSystemInsert = {
        id: meta.id ?: snomed:SNOMED_CODE_SYSTEM_ID,
        url: csUrl,
        version: csVersion,
        name: meta.name ?: snomed:SNOMED_CODE_SYSTEM_NAME,
        title: meta.title ?: snomed:SNOMED_CODE_SYSTEM_TITLE,
        status: meta.status,
        date: meta.date ?: "",
        publisher: meta.publisher ?: snomed:SNOMED_PUBLISHER,
        codeSystem: metadataBytes
    };

    int[]|persist:Error codeSystemResult = sClient->/codesystems.post([codeSystemInsert]);
    if codeSystemResult is persist:Error {
        return r4:createFHIRError(
                "Error while inserting SNOMED CodeSystem row: " + codeSystemResult.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = codeSystemResult,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
    int codeSystemId = codeSystemResult[0];

    [int, int, int]|r4:FHIRError loadResult = loadConceptsAndClosure(bundle, codeSystemId);
    if loadResult is r4:FHIRError {
        error? cleanup = deleteSnomedCodeSystemCascade(codeSystemId);
        if cleanup is error {
            log:printError(string `SNOMED cleanup-on-failure failed for codeSystemId=${codeSystemId}: ${cleanup.message()}`);
        }
        return loadResult;
    }

    return {
        codeSystemId: codeSystemId.toString(),
        system: snomed:SNOMED_SYSTEM_URL,
        version: version ?: "",
        conceptsRead: bundle.conceptsRead,
        conceptsImported: loadResult[0],
        descriptionsRead: bundle.descriptionsRead,
        textDefinitionsRead: bundle.textDefinitionsRead,
        relationshipsRead: bundle.relationshipsRead,
        closureRowsWritten: loadResult[1],
        relationshipRowsWritten: loadResult[2]
    };
}

# Inserts the concepts first to obtain their database ids, then uses those ids to build the closure and attribute-relationship rows.
#
# + bundle - The parsed SNOMED import bundle
# + codeSystemId - The database id of the CodeSystem row the concepts belong to
# + return - A tuple of the number of concepts imported, closure rows written, and relationship rows written, or a `FHIRError` if any insert fails
isolated function loadConceptsAndClosure(snomed:SnomedImportBundle bundle, int codeSystemId) returns [int, int, int]|r4:FHIRError {
    int imported = 0;
    map<int> dbIdByCode = {};
    store_h2:ConceptInsert[] batch = [];
    string[] codesInBatch = [];
    foreach snomed:SnomedConceptImport item in bundle.concepts {
        r4:CodeSystemConcept concept = snomed:snomedConceptImportToR4(item);
        byte[]|r4:FHIRError conceptBytes = conceptToByte(concept);
        if conceptBytes is r4:FHIRError {
            log:printError("Skipping SNOMED concept, serialization failed: code=" + item.code + ", " + conceptBytes.message());
            continue;
        }

        store_h2:ConceptInsert conceptInsert = {
            code: item.code,
            display: snomed:truncate191(item.display),
            definition: snomed:truncate191(item.definition),
            concept: conceptBytes,
            parentConceptId: (),
            codesystemCodeSystemId: codeSystemId
        };
        batch.push(conceptInsert);
        codesInBatch.push(item.code);

        if batch.length() >= SNOMED_INSERT_BATCH_SIZE {
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

    // Transitive is-a closure: a depth-0 self row per concept plus one row per
    // transitive ancestor that is also in the imported set.
    int closureRowsWritten = check writeClosure(bundle.isaParentsByChild, dbIdByCode, codeSystemId);

    // Non-is-a clinical attribute relationships (Finding site, Associated
    // morphology, etc), for $lookup property projection.
    int relationshipRowsWritten = check writeRelationships(bundle.attributeRelationships, dbIdByCode, codeSystemId);

    return [imported, closureRowsWritten, relationshipRowsWritten];
}

# Removes any earlier load of the same url and version, so re-uploading a release replaces it instead of duplicating it.
#
# + url - The CodeSystem canonical URL to check for prior loads
# + 'version - The CodeSystem version to check for prior loads
# + excludeCodeSystemId - A codeSystemId to never delete even if it matches url/version - used to protect a just-inserted replacement load when this is called after the new load succeeds rather than before it starts
# + return - The number of prior loads removed, or a `FHIRError` if lookup fails or any deletion fails (in which case every deletable prior load has still been removed - only the ones reported in the error remain)
isolated function replacePriorLoads(string url, string 'version, int? excludeCodeSystemId = ()) returns int|r4:FHIRError {
    sql:ParameterizedQuery q = excludeCodeSystemId is int
        ? sql:queryConcat(
                `SELECT `, escapeToQuery("codeSystemId"), ` FROM `, escapeToQuery("codesystems"),
                ` WHERE `, escapeToQuery("url"), ` = ${url} AND `, escapeToQuery("version"), ` = ${'version}`,
                ` AND `, escapeToQuery("codeSystemId"), ` != ${excludeCodeSystemId}`)
        : sql:queryConcat(
                `SELECT `, escapeToQuery("codeSystemId"), ` FROM `, escapeToQuery("codesystems"),
                ` WHERE `, escapeToQuery("url"), ` = ${url} AND `, escapeToQuery("version"), ` = ${'version}`);
    stream<record {|int codeSystemId;|}, persist:Error?> resultStream = sClient->queryNativeSQL(q);
    int[]|error ids = from var row in resultStream
        select row.codeSystemId;
    if ids is error {
        return r4:createFHIRError(
                "Error while finding existing SNOMED loads: " + ids.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = ids,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // Every matching id is attempted even if an earlier one fails, so a single
    // stuck deletion doesn't strand other stale duplicates that could still be
    // removed - each surviving duplicate is a row `getStoreCodeSystemByURL` could
    // later pick over the new load, since it has no other way to break the tie.
    int deletedCount = 0;
    string failureDetail = "";
    foreach int id in ids {
        error? del = deleteSnomedCodeSystemCascade(id);
        if del is error {
            failureDetail += string ` codeSystemId=${id}: ${del.message()};`;
        } else {
            deletedCount += 1;
        }
    }
    if failureDetail != "" {
        return r4:createFHIRError(
                string `Error while deleting ${ids.length() - deletedCount} of ${ids.length()} existing load(s):${failureDetail}`,
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return deletedCount;
}

# Deletes a CodeSystem and everything under it, in dependency order: closure rows, relationship rows, then any valueset_compose_include_concepts rows pointing at this CodeSystem's concepts (write-only bookkeeping table - $expand/$validate-code/etc. all resolve concepts via the stored ValueSet JSON, not this table, so dropping these rows has no functional effect on existing ValueSets), then concepts, then the CodeSystem itself.
#
# + codeSystemId - The database id of the CodeSystem to delete along with its dependents
# + return - An `error` if the deletion transaction fails, `()` otherwise
isolated function deleteSnomedCodeSystemCascade(int codeSystemId) returns error? {
    transaction {
        sql:ParameterizedQuery delClosure = sql:queryConcat(
                `DELETE FROM `, escapeToQuery("concept_closure"), ` WHERE `, escapeToQuery("codeSystemId"), ` = ${codeSystemId}`);
        _ = check sClient->executeNativeSQL(delClosure);

        sql:ParameterizedQuery delRelationships = sql:queryConcat(
                `DELETE FROM `, escapeToQuery("concept_relationships"), ` WHERE `, escapeToQuery("codeSystemId"), ` = ${codeSystemId}`);
        _ = check sClient->executeNativeSQL(delRelationships);

        sql:ParameterizedQuery delComposeIncludeConcepts = sql:queryConcat(
                `DELETE FROM `, escapeToQuery("valueset_compose_include_concepts"),
                ` WHERE `, escapeToQuery("conceptConceptId"), ` IN (SELECT `, escapeToQuery("conceptId"),
                ` FROM `, escapeToQuery("concepts"), ` WHERE `, escapeToQuery("codesystemCodeSystemId"), ` = ${codeSystemId})`);
        _ = check sClient->executeNativeSQL(delComposeIncludeConcepts);

        sql:ParameterizedQuery delConcepts = sql:queryConcat(
                `DELETE FROM `, escapeToQuery("concepts"), ` WHERE `, escapeToQuery("codesystemCodeSystemId"), ` = ${codeSystemId}`);
        _ = check sClient->executeNativeSQL(delConcepts);

        sql:ParameterizedQuery delCodeSystem = sql:queryConcat(
                `DELETE FROM `, escapeToQuery("codesystems"), ` WHERE `, escapeToQuery("codeSystemId"), ` = ${codeSystemId}`);
        _ = check sClient->executeNativeSQL(delCodeSystem);

        check commit;
    }
}

# Writes one closure row per concept-ancestor pair, plus a depth-0 self row for each concept. Rows are inserted in batches.
#
# + isaParentsByChild - The direct is-a parent SCTIDs for each concept code
# + dbIdByCode - The database id assigned to each already-inserted concept code
# + codeSystemId - The database id of the CodeSystem the closure rows belong to
# + return - The number of closure rows written, or a `FHIRError` if a batch insert fails
isolated function writeClosure(map<string[]> isaParentsByChild, map<int> dbIdByCode, int codeSystemId) returns int|r4:FHIRError {
    int written = 0;
    ClosureRow[] batch = [];

    foreach [string, int] [code, childDbId] in dbIdByCode.entries() {
        // Depth-0 self row: a concept is its own ancestor at depth 0.
        batch.push({ancestor: childDbId, descendant: childDbId, depth: 0});

        map<int> ancestorDepths = snomed:computeAncestorDepths(code, isaParentsByChild);
        foreach [string, int] [ancestorSctid, depth] in ancestorDepths.entries() {
            int? ancestorDbId = dbIdByCode[ancestorSctid];
            if ancestorDbId is int {
                batch.push({ancestor: ancestorDbId, descendant: childDbId, depth: depth});
            }
        }

        if batch.length() >= SNOMED_INSERT_BATCH_SIZE {
            int|r4:FHIRError flushed = flushClosureBatch(batch, codeSystemId);
            if flushed is r4:FHIRError {
                return flushed;
            }
            written += flushed;
            batch = [];
            if written % SNOMED_CLOSURE_PROGRESS_INTERVAL < SNOMED_INSERT_BATCH_SIZE {
                log:printInfo(string `SNOMED closure progress: ${written} rows written`);
            }
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

# Inserts a batch of closure rows as one multi-row statement. The fragments are collected in an array and joined once, rather than concatenated inside the loop.
#
# + rows - The closure rows to insert
# + codeSystemId - The database id of the CodeSystem the closure rows belong to
# + return - The number of rows inserted, or a `FHIRError` if the insert fails
isolated function flushClosureBatch(ClosureRow[] rows, int codeSystemId) returns int|r4:FHIRError {
    if rows.length() == 0 {
        return 0;
    }

    string head = string `INSERT INTO ${escape("concept_closure")} (${escape("ancestorConceptId")}, ${escape("descendantConceptId")}, ${escape("depth")}, ${escape("codeSystemId")}) VALUES `;

    sql:ParameterizedQuery[] fragments = [stringToParameterizedQuery(head)];
    boolean first = true;
    foreach ClosureRow row in rows {
        if !first {
            fragments.push(`, `);
        }
        fragments.push(`(${row.ancestor}, ${row.descendant}, ${row.depth}, ${codeSystemId})`);
        first = false;
    }

    sql:ParameterizedQuery query = sql:queryConcat(...fragments);
    psql:ExecutionResult|persist:Error result = sClient->executeNativeSQL(query);
    if result is persist:Error {
        return r4:createFHIRError(
                "Error while inserting closure batch: " + result.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = result,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return rows.length();
}

# Writes one row per active non-is-a Relationship (clinical attributes like Finding site, Associated morphology). Rows whose source or destination isn't in the imported concept set (e.g. destination outside a partial import) are skipped, same as writeClosure skips ancestors outside the imported set.
#
# + attributeRelationships - The non-is-a attribute relationships parsed from the release
# + dbIdByCode - The database id assigned to each already-inserted concept code
# + codeSystemId - The database id of the CodeSystem the relationship rows belong to
# + return - The number of relationship rows written, or a `FHIRError` if a batch insert fails
isolated function writeRelationships(snomed:SnomedAttributeRelationship[] attributeRelationships, map<int> dbIdByCode, int codeSystemId) returns int|r4:FHIRError {
    int written = 0;
    RelationshipRow[] batch = [];

    foreach snomed:SnomedAttributeRelationship rel in attributeRelationships {
        int? sourceDbId = dbIdByCode[rel.sourceId];
        int? destinationDbId = dbIdByCode[rel.destinationId];
        if sourceDbId is int && destinationDbId is int {
            batch.push({sourceConceptId: sourceDbId, typeId: rel.typeId, destinationConceptId: destinationDbId});
        }

        if batch.length() >= SNOMED_INSERT_BATCH_SIZE {
            int|r4:FHIRError flushed = flushRelationshipBatch(batch, codeSystemId);
            if flushed is r4:FHIRError {
                return flushed;
            }
            written += flushed;
            batch = [];
        }
    }

    if batch.length() > 0 {
        int|r4:FHIRError flushed = flushRelationshipBatch(batch, codeSystemId);
        if flushed is r4:FHIRError {
            return flushed;
        }
        written += flushed;
    }

    return written;
}

# Inserts a batch of attribute relationship rows as one multi-row statement.
#
# + rows - The relationship rows to insert
# + codeSystemId - The database id of the CodeSystem the relationship rows belong to
# + return - The number of rows inserted, or a `FHIRError` if the insert fails
isolated function flushRelationshipBatch(RelationshipRow[] rows, int codeSystemId) returns int|r4:FHIRError {
    if rows.length() == 0 {
        return 0;
    }

    string head = string `INSERT INTO ${escape("concept_relationships")} (${escape("sourceConceptId")}, ${escape("typeId")}, ${escape("destinationConceptId")}, ${escape("codeSystemId")}) VALUES `;

    sql:ParameterizedQuery[] fragments = [stringToParameterizedQuery(head)];
    boolean first = true;
    foreach RelationshipRow row in rows {
        if !first {
            fragments.push(`, `);
        }
        fragments.push(`(${row.sourceConceptId}, ${row.typeId}, ${row.destinationConceptId}, ${codeSystemId})`);
        first = false;
    }

    sql:ParameterizedQuery query = sql:queryConcat(...fragments);
    psql:ExecutionResult|persist:Error result = sClient->executeNativeSQL(query);
    if result is persist:Error {
        return r4:createFHIRError(
                "Error while inserting SNOMED relationship batch: " + result.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = result,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return rows.length();
}

# Runs the import in the background so the upload request can return right away, and removes the temp directory once the worker is done with it.
#
# + extractedPath - The path of the extracted RF2 release directory to import
# + version - The version to record for the imported CodeSystem, if given
# + tempDir - The temporary directory to remove once the import finishes
public isolated function runSnomedImportAsync(string extractedPath, string? version, string tempDir) returns () {
    log:printInfo("SNOMED import worker started: extractedPath=" + extractedPath);
    snomed:SnomedImportSummary|r4:FHIRError result = importSnomedToDb(extractedPath, version);
    // Release the single-flight guard as soon as the DB work is done - success
    // or failure - so a queued upload isn't blocked by unrelated temp-dir cleanup.
    releaseSnomedImportLock();
    if result is r4:FHIRError {
        log:printError("SNOMED import failed: " + result.message());
    } else {
        log:printInfo(string `SNOMED import complete: conceptsRead=${result.conceptsRead}, conceptsImported=${result.conceptsImported}, descriptionsRead=${result.descriptionsRead}, textDefinitionsRead=${result.textDefinitionsRead}, relationshipsRead=${result.relationshipsRead}, closureRowsWritten=${result.closureRowsWritten}, codeSystemId=${result.codeSystemId}`);
    }
    error? cleanup = removeDirectory(tempDir);
    if cleanup is error {
        log:printError("SNOMED cleanup failed for " + tempDir + ": " + cleanup.message());
    }
}

# Inserts a batch of concepts and returns their generated database ids.
#
# + batch - The concept rows to insert
# + return - The generated database ids, in the same order as `batch`, or a `FHIRError` if the insert fails
isolated function flushConceptBatch(store_h2:ConceptInsert[] batch) returns int[]|r4:FHIRError {
    int[]|persist:Error result = sClient->/concepts.post(batch);
    if result is persist:Error {
        return r4:createFHIRError(
                "Error while inserting concept batch: " + result.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = result,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return result;
}

# Maps each concept code to its generated database id. Relies on the insert returning ids in the same order as the records that were sent.
#
# + dbIdByCode - The map to populate with code -> database id entries
# + codes - The concept codes sent in the batch, in insert order
# + ids - The database ids returned by the insert, in the same order as `codes`
isolated function recordInsertedIds(map<int> dbIdByCode, string[] codes, int[] ids) {
    int count = codes.length() < ids.length() ? codes.length() : ids.length();
    if codes.length() != ids.length() {
        log:printError(string `SNOMED batch length mismatch: codes=${codes.length()}, ids=${ids.length()}. Some concepts will be unlinkable to parents.`);
    }
    foreach int i in 0 ..< count {
        dbIdByCode[codes[i]] = ids[i];
    }
}

