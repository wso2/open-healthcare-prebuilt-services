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

import terminology_service.store_h2;
import terminology_service.store_pg;

import ballerina/http;
import ballerina/lang.regexp;
import ballerina/log;
import ballerina/persist;
import ballerina/regex;
import ballerina/sql;
import ballerina/uuid;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.terminology;
import ballerinax/persist.sql as psql;

// import ballerina/io;

// Improve after the issue https://github.com/wso2/open-healthcare-prebuilt-services/issues/151 is fixed
final store_pg:Client sClient = check initializeClient();

# Creates and initializes the database client for the configured backend.
#
# + return - The initialized `store_pg:Client` or `store_h2:Client`, or an `error` if `db_type` is unsupported
function initializeClient() returns store_pg:Client|store_h2:Client|error {
    if db_type == "postgresql" {
        log:printInfo("Initializing PostgreSQL client for terminology service");
        return check new store_pg:Client();
    } else if db_type == "h2" {
        log:printInfo("Initializing H2 client for terminology service");
        return check new store_h2:Client();
    } else {
        log:printError("Unsupported database type provided: " + db_type);
        return error("Unsupported database type: " + db_type);
    }
}

# Result of resolving an inline (not persisted) ValueSet's `compose` directly - see `TerminologySource.expandInlineValueSetCompose`.
type InlineComposeResult record {|
    # The matching concepts (not yet paginated)
    r4:ValueSetExpansionContains[] concepts;
    # `url|version` (or bare `url` if unversioned) of every externally-referenced ValueSet that actually contributed at least one concept to `concepts`
    map<boolean> usedValueSetKeys;
|};

# Pages a fully-resolved concept list into a `ValueSetExpansion` and attaches it to `valueSet`. Shared by `expandValueSet`'s DB-backed path and its inline-compose fallback, so both end up with identical pagination/total behavior.
#
# + valueSet - The `ValueSet` the expansion is being built for
# + allConcepts - The complete (unpaged, already de-duplicated) set of matching concepts
# + offset - The number of matching concepts to skip
# + count - The maximum number of concepts to return
# + return - `valueSet` with its `expansion` populated
isolated function buildPagedValueSetExpansion(r4:ValueSet valueSet, r4:ValueSetExpansionContains[] allConcepts, int offset, int count) returns r4:ValueSet {
    int totalCount = allConcepts.length();
    r4:ValueSetExpansionContains[] pagedConcepts;
    if totalCount > offset + count {
        pagedConcepts = allConcepts.slice(offset, offset + count);
    } else if totalCount >= offset {
        pagedConcepts = allConcepts.slice(offset);
    } else {
        pagedConcepts = [];
    }

    return assembleValueSetExpansion(valueSet, pagedConcepts, totalCount, offset);
}

# Attaches an already-paged concept list to `valueSet` as its expansion. Split out of `buildPagedValueSetExpansion` so that a path which never holds the full member list - one that lets the database do the windowing and gets `total` from a separate `COUNT(*)` - still produces an identically-shaped expansion.
#
# + valueSet - The `ValueSet` the expansion is being built for
# + pagedConcepts - The concepts for this page only
# + total - Total number of matching concepts across all pages
# + offset - The number of matching concepts skipped before this page
# + return - `valueSet` with its `expansion` populated
isolated function assembleValueSetExpansion(r4:ValueSet valueSet, r4:ValueSetExpansionContains[] pagedConcepts, int total, int offset) returns r4:ValueSet {
    r4:ValueSetExpansion expansion = createExpandedValueSet(valueSet, pagedConcepts);
    expansion.total = total;
    expansion.offset = offset;
    valueSet.expansion = expansion.clone();
    return valueSet;
}

public isolated class TerminologySource {
    *terminology:Terminology;

    # Persists a `CodeSystem` resource and its concepts to the database.
    #
    # + codeSystem - The `CodeSystem` to add
    # + return - An `r4:FHIRError` if the insert fails, `()` otherwise
    public isolated function addCodeSystem(r4:CodeSystem codeSystem) returns r4:FHIRError? {
        // add the code system to the database
        store_h2:CodeSystemInsert dbCodeSystemInsert = {
            id: codeSystem.id ?: "",
            url: codeSystem.url ?: "",
            version: codeSystem.version ?: "",
            name: codeSystem.name ?: "",
            title: codeSystem.title ?: "",
            status: codeSystem.status,
            date: codeSystem.date ?: "",
            publisher: codeSystem.publisher ?: "",
            codeSystem: check codeSystemToByte(codeSystem)
        };

        int[]|persist:Error response = sClient->/codesystems.post([dbCodeSystemInsert]);
        if (response is persist:Error) {
            // error while adding code system to the database
            return r4:createFHIRError(
                    "Error while adding CodeSystem, " + response.message(),
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    cause = error("Error while adding CodeSystem"),
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
        // extract the concepts from the codesystem and add them to the database
        extractConceptsFromCodeSystem(codeSystem, response[0]);
    }

    # Persists a `ValueSet` resource and its concepts to the database.
    #
    # + valueSet - The `ValueSet` to add
    # + return - An `r4:FHIRError` if the insert fails, `()` otherwise
    public isolated function addValueSet(r4:ValueSet valueSet) returns r4:FHIRError? {
        // add the value set to the database
        store_h2:ValueSetInsert dbValueSetInsert = {
            id: valueSet.id ?: "",
            url: valueSet.url ?: "",
            version: valueSet.version ?: "",
            name: valueSet.name ?: "",
            title: valueSet.title ?: "",
            status: valueSet.status,
            date: valueSet.date ?: "",
            publisher: valueSet.publisher ?: "",
            valueSet: check valueSetToByte(valueSet)
        };

        int[]|persist:Error response = sClient->/valuesets.post([dbValueSetInsert]);
        if (response is persist:Error) {
            // error while adding value set to the database
            return r4:createFHIRError(
                    "Error while adding ValueSet, " + response.message(),
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    cause = error("Error while adding ValueSet"),
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
        // extract the concepts from the valueset and add them to the database
        extractConceptsFromValueSet(valueSet, response[0]);
    }

    # Looks up a stored `CodeSystem` by its id or canonical url.
    #
    # + system - The canonical url of the `CodeSystem` to find, used when `id` is not given
    # + id - The internal id of the `CodeSystem` to find, preferred over `system` when given
    # + version - The `CodeSystem` version to match
    # + return - The matching `r4:CodeSystem`, or an `r4:FHIRError` if neither `id` nor `system` is given or no match is found
    public isolated function findCodeSystem(r4:uri? system, string? id, string? version = ()) returns r4:CodeSystem|r4:FHIRError {
        r4:CodeSystem|r4:FHIRError|error? dbCodeSystem = ();
        if id != () {
            dbCodeSystem = getCodeSystemByID(id, version);
        } else if system != () {
            dbCodeSystem = getCodeSystemByURL(system, version);
        }

        if dbCodeSystem is r4:FHIRError {
            return dbCodeSystem;
        }

        if dbCodeSystem is error || dbCodeSystem is () {
            return r4:createFHIRError(
                        dbCodeSystem is error ? dbCodeSystem.message() : "Id or URL for the codesystem is required to find CodeSystem",
                    r4:ERROR,
                    r4:PROCESSING_NOT_FOUND,
                    cause = dbCodeSystem,
                    httpStatusCode = http:STATUS_NOT_FOUND
                );
        }

        return dbCodeSystem;
    }

    # Finds a concept by system and code, checking stored ValueSets first and falling back to stored CodeSystems.
    #
    # + system - The canonical url of the system the concept belongs to
    # + code - The code of the concept to find
    # + version - The system version to match
    # + return - The matching concept's details, or an `r4:FHIRError` if it isn't found in either a ValueSet or a CodeSystem
    public isolated function findConcept(r4:uri system, r4:code code, string? version) returns terminology:CodeConceptDetails|r4:FHIRError {
        // find the concept in the valueset table
        terminology:CodeConceptDetails|r4:FHIRError valuesetConceptDetails = findConceptInValueSet(system, code, version);
        if valuesetConceptDetails !is r4:FHIRError {
            return valuesetConceptDetails;
        }

        // find the concept in the codesystem table
        terminology:CodeConceptDetails|r4:FHIRError conceptDetails = findConceptInCodeSystem(system, code, version);
        if conceptDetails !is r4:FHIRError {
            return conceptDetails;
        }

        // concept not found in both tables
        return r4:createFHIRError(
                "Concept not found",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = error("No matching Concept found"),
                httpStatusCode = http:STATUS_NOT_FOUND);
    }

    # Looks up a stored `ValueSet` by its id or canonical url.
    #
    # + system - The canonical url of the `ValueSet` to find, used when `id` is not given
    # + id - The internal id of the `ValueSet` to find, preferred over `system` when given
    # + version - The `ValueSet` version to match
    # + return - The matching `r4:ValueSet`, or an `r4:FHIRError` if neither `id` nor `system` is given or no match is found
    public isolated function findValueSet(r4:uri? system, string? id, string? version) returns r4:ValueSet|r4:FHIRError {
        r4:ValueSet|r4:FHIRError|error dbValueSet;

        if id != () {
            dbValueSet = getValueSetByID(id, version);
        } else if system != () {
            dbValueSet = getValueSetByURL(system, version);
        } else {
            return r4:createFHIRError(
                    "Id or URL for the valueset is required to find ValueSet",
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    cause = error("No matching ValueSet found"),
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }

        if dbValueSet is r4:FHIRError {
            return dbValueSet;
        }

        if dbValueSet is error {
            return r4:createFHIRError(
                    "Cannot find ValueSet, " + dbValueSet.message(),
                    r4:ERROR,
                    r4:PROCESSING_NOT_FOUND,
                    cause = dbValueSet,
                    httpStatusCode = http:STATUS_NOT_FOUND
                );
        }

        return dbValueSet;
    }

    # Checks whether a `CodeSystem` with the given url and version is stored.
    #
    # + system - The canonical url of the `CodeSystem` to check
    # + version - The version of the `CodeSystem` to check
    # + return - `true` if a matching `CodeSystem` exists, `false` otherwise
    public isolated function isCodeSystemExist(r4:uri system, string version) returns boolean {
        // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
        // https://github.com/ballerina-platform/ballerina-library/issues/7920
        //
        // The recommended approach is:
        // store_h2:CodeSystem[] codeSystems = check from store_h2:CodeSystem codesystem in sClient->/codesystems(store_h2:CodeSystem)
        //     where codesystem.url == system && codesystem.version == version
        //     select codesystem;
        // return codeSystems.length() > 0;

        sql:ParameterizedQuery sqlQuery = sql:queryConcat(`SELECT 1 FROM `, escapeToQuery("codesystems"), ` WHERE `, escapeToQuery("url"), ` = ${system} AND `, escapeToQuery("version"), ` = ${version} LIMIT 1`);

        stream<record {}, persist:Error?> resultStream = sClient->queryNativeSQL(sqlQuery);
        record {}[]|error results = from record {} result in resultStream
            select result;

        return results is error ? false : results.length() > 0;
    }

    # Checks whether a `ValueSet` with the given url and version is stored.
    #
    # + system - The canonical url of the `ValueSet` to check
    # + version - The version of the `ValueSet` to check
    # + return - `true` if a matching `ValueSet` exists, `false` otherwise
    public isolated function isValueSetExist(r4:uri system, string version) returns boolean {
        // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
        // https://github.com/ballerina-platform/ballerina-library/issues/7920
        //
        // store_h2:ValueSet[] valueSets = check from store_h2:ValueSet valueSet in sClient->/valuesets(store_h2:ValueSet)
        //     where valueSet.url == system && valueSet.version == version
        //     select valueSet;
        // return valueSets.length() > 0;

        sql:ParameterizedQuery sqlQuery = sql:queryConcat(`SELECT 1 FROM `, escapeToQuery("valuesets"), ` WHERE `, escapeToQuery("url"), ` = ${system} AND `, escapeToQuery("version"), ` = ${version} LIMIT 1`);

        stream<record {}, persist:Error?> resultStream = sClient->queryNativeSQL(sqlQuery);
        record {}[]|error results = from record {} result in resultStream
            select result;

        return results is error ? false : results.length() > 0;
    }

    # Searches stored `CodeSystem`s matching the given FHIR search parameters, with optional pagination.
    #
    # + params - The search parameters to filter by, keyed by recognized parameter name
    # + offset - The number of matching records to skip, applied only when `count` is also given
    # + count - The maximum number of records to return, applied only when `offset` is also given
    # + return - The matching `r4:CodeSystem`s, or an `r4:FHIRError` if the query or result parsing fails
    public isolated function searchCodeSystem(map<r4:RequestSearchParameter[]> params, int? offset, int? count) returns r4:CodeSystem[]|r4:FHIRError {
        sql:ParameterizedQuery whereClause = ``;
        boolean isFirst = true;

        foreach var [paramName, paramList] in params.entries() {
            if terminology:CODESYSTEMS_SEARCH_PARAMS.hasKey(paramName) {
                foreach var param in paramList {
                    sql:ParameterizedQuery fragment = sql:queryConcat(escapeToQuery(paramName == "system" ? "url" : paramName), ` = ${param.value}`);
                    if fragment.strings.length() > 0 {
                        if isFirst {
                            whereClause = fragment;
                            isFirst = false;
                        } else {
                            whereClause = sql:queryConcat(whereClause, ` AND `, fragment);
                        }
                    }
                }
            }
        }

        if offset is int && count is int {
            whereClause = sql:queryConcat(whereClause, ` `, getLimitClause(count, offset));
        }

        stream<store_h2:CodeSystem, persist:Error?> codeSystemStream = sClient->/codesystems(store_h2:CodeSystem, whereClause);
        store_h2:CodeSystem[]|error dbCodeSystems = streamToStoreCodeSystem(codeSystemStream);

        if dbCodeSystems is error {
            return r4:createFHIRError(
                    dbCodeSystems.message(),
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    cause = dbCodeSystems,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }

        r4:CodeSystem[] codeSystemArray = [];
        foreach store_h2:CodeSystem dbCodeSystem in dbCodeSystems {
            r4:CodeSystem|error parsedCodeSystem = byteToCodeSystem(dbCodeSystem.codeSystem);
            if parsedCodeSystem is error {
                log:printError("Error while parsing CodeSystem: " + parsedCodeSystem.message());
                // Skip this CodeSystem if parsing fails
                continue;
            }
            codeSystemArray.push(parsedCodeSystem);
        }

        return codeSystemArray;
    }

    # Searches stored `ValueSet`s matching the given FHIR search parameters, with optional pagination. Returns every stored `ValueSet` when no search parameters are given.
    #
    # + params - The search parameters to filter by, keyed by recognized parameter name
    # + offset - The number of matching records to skip, applied only when `count` is also given
    # + count - The maximum number of records to return, applied only when `offset` is also given
    # + return - The matching `r4:ValueSet`s, or an `r4:FHIRError` if the query or result parsing fails
    public isolated function searchValueSet(map<r4:RequestSearchParameter[]> params, int? offset, int? count) returns r4:ValueSet[]|r4:FHIRError {

        stream<store_h2:ValueSet, persist:Error?> valueSetStream;

        if params.length() == 0 {
            valueSetStream = sClient->/valuesets(store_h2:ValueSet);
        } else {
            sql:ParameterizedQuery whereClause = ``;
            foreach var [paramName, paramList] in params.entries() {
                if terminology:CODESYSTEMS_SEARCH_PARAMS.hasKey(paramName) {
                    foreach var param in paramList {
                        sql:ParameterizedQuery fragment = sql:queryConcat(escapeToQuery(paramName == "system" ? "url" : paramName), ` = ${param.value}`);
                        if fragment.strings.length() > 0 {
                            whereClause = sql:queryConcat(fragment);
                        }
                    }
                }
            }

            if offset is int && count is int {
                whereClause = sql:queryConcat(whereClause, ` `, getLimitClause(count, offset));
            }
            valueSetStream = sClient->/valuesets(store_h2:ValueSet, whereClause);
        }

        store_h2:ValueSet[]|error dbValueSets = streamToStoreValueSet(valueSetStream);

        if dbValueSets is error {
            log:printError("Error while streaming ValueSets: " + dbValueSets.message());
            return r4:createFHIRError(
                    dbValueSets.message(),
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    cause = dbValueSets,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }

        r4:ValueSet[] valueSetArray = [];
        foreach store_h2:ValueSet dbValueSet in dbValueSets {
            r4:ValueSet|error parsedValueSet = byteToValueSet(dbValueSet.valueSet);
            if parsedValueSet is error {
                // Skip this ValueSet if parsing fails
                continue;
            }
            valueSetArray.push(parsedValueSet);
        }

        return valueSetArray;
    }

    # Implements FHIR `$expand`, resolving a stored `ValueSet`'s `compose.include` rules into its member concepts. Handles explicit concept lists, whole-system includes, nested ValueSet includes (recursively expanded), and intensional filters (`concept is-a`/`descendent-of` via the closure table or, absent one, a parent-link walk; `=` and `regex` property filters), ANDing multiple filters on the same include and unioning across includes. Applies an optional text filter and paginates the combined result.
    #
    # + searchParameters - The request's search parameters; a `filter` parameter narrows results by display text
    # + valueSet - The stored `ValueSet` to expand
    # + offset - The number of matching concepts to skip
    # + count - The maximum number of concepts to return
    # + return - The `valueSet` with its `expansion` populated, or an `r4:FHIRError` if the `ValueSet` or its includes cannot be resolved
    public isolated function expandValueSet(map<r4:RequestSearchParameter[]> searchParameters, r4:ValueSet valueSet, int offset, int count) returns r4:ValueSet|r4:FHIRError {
        store_h2:ValueSet|error dbValueSet = getStoreValueSetByURL(valueSet.url.toString(), valueSet.version);
        if dbValueSet is error {
            // Not every ValueSet handed to $expand was ever POSTed to us - an
            // inline "valueSet" parameter can be a throwaway resource built
            // entirely for one request Expand its own
            // compose directly instead, the same way the DB-backed path
            // below would if it had been persisted.
            string? filter = searchParameters.hasKey(terminology:FILTER) ? searchParameters.get(terminology:FILTER)[0].value : ();
            InlineComposeResult|r4:FHIRError inlineComposeResult = self.expandInlineValueSetCompose(searchParameters, valueSet, valueSet, filter);
            if inlineComposeResult is r4:FHIRError {
                return inlineComposeResult;
            }
            // compose is optional on the response (per the conformance suite's
            // own fixtures) - and here it would just be the throwaway wrapper's
            // own compose.include, not a single coherent rule a client could use the way a real
            // stored ValueSet's compose is used elsewhere. Omit it rather than
            // echo something that doesn't represent the expansion performed.
            r4:ValueSet inlineResult = valueSet.clone();
            inlineResult.compose = ();
            r4:ValueSet pagedInlineResult = buildPagedValueSetExpansion(inlineResult, inlineComposeResult.concepts, offset, count);
            // postProcessExpansion (terminology_connect.bal) derives
            // used-codesystem/abstract/inactive from a uniform system on
            // compose.include, which this throwaway wrapper doesn't have - but
            // it preserves and builds on whatever expansion.parameter already
            // holds, so seed used-valueset here; used-codesystem and the
            // abstract/inactive backfill still happen there, since it can
            // derive a uniform system from the
            // contains array instead of compose.include when that's empty.
            if inlineComposeResult.usedValueSetKeys.length() > 0 {
                r4:ValueSetExpansionParameter[] usedValueSetParams = [];
                foreach string usedValueSetKey in inlineComposeResult.usedValueSetKeys.keys() {
                    usedValueSetParams.push({name: "used-valueset", valueUri: usedValueSetKey});
                }
                r4:ValueSetExpansion? pagedExpansion = pagedInlineResult.expansion;
                if pagedExpansion is r4:ValueSetExpansion {
                    pagedExpansion.'parameter = usedValueSetParams;
                }
            }
            return pagedInlineResult;
        }
        int valueSetId = dbValueSet.valueSetId;

        // Get all includes for this ValueSet
        sql:ParameterizedQuery includeQuery = sql:queryConcat(escapeToQuery("valuesetValueSetId"), ` = ${valueSetId}`);
        stream<store_h2:ValueSetComposeInclude, persist:Error?> includeStream = sClient->/valuesetcomposeincludes(store_h2:ValueSetComposeInclude, whereClause = includeQuery);
        store_h2:ValueSetComposeInclude[]|error includes = from store_h2:ValueSetComposeInclude inc in includeStream
            select inc;
        if includes is error {
            return r4:createFHIRError(
                    "Error fetching ValueSet includes: " + includes.message(),
                    r4:ERROR,
                    r4:PROCESSING_NOT_FOUND,
                    cause = includes,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }

        r4:ValueSetExpansionContains[] allConcepts = [];
        string? filter = searchParameters.hasKey(terminology:FILTER) ? searchParameters.get(terminology:FILTER)[0].value : ();

        // The compose *rules* live in the stored resource itself - the
        // valueset_compose_includes rows fetched above only cover extensional
        // includes (a concept list, a whole CodeSystem, nested ValueSets).
        r4:ValueSet|error storedVs = byteToValueSet(dbValueSet.valueSet);

        // Fast path: a compose the database can satisfy end to end, so the
        // matching rows are ordered, counted and windowed in SQL rather than
        // materialized in full and sliced afterwards. Anything else - and any
        // failure here - falls through to the general path below unchanged.
        if storedVs is r4:ValueSet {
            WindowedInclude? window = windowedIncludeFastPath(storedVs, includes, filter);
            if window is WindowedInclude {
                [r4:ValueSetExpansionContains[], int]|error windowed = expandWindowedInclude(window, filter, offset, count);
                if windowed is [r4:ValueSetExpansionContains[], int] {
                    return assembleValueSetExpansion(valueSet, windowed[0], windowed[1], offset);
                }
                log:printError("Windowed include expansion failed; falling back to in-memory expansion",
                        windowed, valueSetUrl = valueSet.url ?: "");
            }
        }

        // De-dupes concepts contributed by multiple includes/filters on the same
        // CodeSystem (e.g. an unfiltered include plus a filtered include on the
        // same system). Keyed by internal codeSystemId rather than
        // ValueSetExpansionContains.system, since entries pushed below don't
        // carry a system - two different CodeSystems that happen to share a
        // code string must NOT collapse into one.
        map<boolean> seenConceptKeys = {};

        foreach store_h2:ValueSetComposeInclude include in includes {
            // If conceptFlag, get concepts from valueset_compose_include_concepts
            if include.conceptFlag {
                sql:ParameterizedQuery q = sql:queryConcat(
                        `SELECT c.* FROM `, escapeToQuery("concepts"), ` c JOIN `, escapeToQuery("valueset_compose_include_concepts"), ` vcic ON c.`, escapeToQuery("conceptId"), ` = vcic.`, escapeToQuery("conceptConceptId"),
                        ` WHERE vcic.`, escapeToQuery("valuesetcomposeValueSetComposeIncludeId"), ` = ${include.valueSetComposeIncludeId}`
                );
                stream<store_h2:Concept, persist:Error?> conceptStream = sClient->queryNativeSQL(q);
                store_h2:Concept[]|error dbConcepts = from store_h2:Concept c in conceptStream
                    select c;
                if dbConcepts is error {
                    continue;
                }
                string? includeSystemUrl = include.codeSystemId is int ? getCodeSystemUrlById(<int>include.codeSystemId) : ();
                foreach store_h2:Concept c in dbConcepts {
                    r4:CodeSystemConcept|error concept = byteToConcept(c.concept);
                    if concept is r4:CodeSystemConcept {
                        if filter is string && !displayMatchesTextFilter(concept.display, filter) {
                            continue;
                        }
                        string dedupeKey = (includeSystemUrl ?: "") + "|" + concept.code;
                        if seenConceptKeys.hasKey(dedupeKey) {
                            continue;
                        }
                        seenConceptKeys[dedupeKey] = true;
                        r4:ValueSetExpansionContains exp = {code: concept.code, display: concept.display, id: concept.id, system: includeSystemUrl};
                        allConcepts.push(exp);
                    }
                }
            }
            // If systemFlag, get all concepts for the code system
            else if include.systemFlag && include.codeSystemId is int {
                sql:ParameterizedQuery query = sql:queryConcat(escapeToQuery("codesystemCodeSystemId"), ` = ${include.codeSystemId}`);
                string? inMemoryFilter = filter;
                if filter is string && isPlainTextFilter(filter) {
                    query = sql:queryConcat(query, displayContainsFragment(escapeToQuery("display"), filter));
                    inMemoryFilter = ();
                }
                string? includeSystemUrl = getCodeSystemUrlById(<int>include.codeSystemId);
                // Streamed rather than collected first: a whole-system include
                // covers every concept in the CodeSystem.
                stream<store_h2:Concept, persist:Error?> conceptStream = sClient->/concepts(store_h2:Concept, query);
                error? iterationError = from store_h2:Concept c in conceptStream
                    do {
                        r4:CodeSystemConcept|error concept = byteToConcept(c.concept);
                        if concept is r4:CodeSystemConcept
                                && (inMemoryFilter is () || displayMatchesTextFilter(concept.display, inMemoryFilter)) {
                            string dedupeKey = (includeSystemUrl ?: "") + "|" + concept.code;
                            if !seenConceptKeys.hasKey(dedupeKey) {
                                seenConceptKeys[dedupeKey] = true;
                                allConcepts.push({code: concept.code, display: concept.display, id: concept.id, system: includeSystemUrl});
                            }
                        }
                    };
                if iterationError is error {
                    continue;
                }
            }
            // If valueSetFlag, get nested value sets and expand recursively
            else if include.valueSetFlag {
                sql:ParameterizedQuery q = sql:queryConcat(
                        `SELECT vs.* FROM `, escapeToQuery("valuesets"), ` vs JOIN `, escapeToQuery("valueset_compose_include_value_sets"), ` vcivs ON vs.`, escapeToQuery("valueSetId"), ` = vcivs.`, escapeToQuery("valuesetValueSetId"),
                        ` WHERE vcivs.`, escapeToQuery("valuesetcomposeValueSetComposeIncludeId"), ` = ${include.valueSetComposeIncludeId}`
                );
                stream<store_h2:ValueSet, persist:Error?> vsStream = sClient->queryNativeSQL(q);
                store_h2:ValueSet[]|error nestedVS = from store_h2:ValueSet v in vsStream
                    select v;
                if nestedVS is error {
                    continue;
                }
                foreach store_h2:ValueSet v in nestedVS {
                    r4:ValueSet|error parsedVS = byteToValueSet(v.valueSet);
                    if parsedVS is r4:ValueSet {
                        r4:ValueSet|r4:FHIRError expanded = self.expandValueSet(searchParameters, parsedVS, 0, 1000); // Recursively expand, no offset/count for nested
                        if expanded is r4:ValueSet {
                            if expanded.expansion is r4:ValueSetExpansion {
                                r4:ValueSetExpansion expansionVal = <r4:ValueSetExpansion>expanded.expansion;
                                if expansionVal.contains is r4:ValueSetExpansionContains[] {
                                    r4:ValueSetExpansionContains[] containsArr = <r4:ValueSetExpansionContains[]>expansionVal.contains;
                                    foreach r4:ValueSetExpansionContains c in containsArr {
                                        // Keyed by system+code, same as every other push site below -
                                        // not by the nested ValueSet's own id - so a direct include and
                                        // a nested include of the same CodeSystem/code correctly
                                        // de-duplicate against each other instead of being treated as
                                        // unrelated.
                                        string dedupeKey = (c.system ?: "") + "|" + (c.code ?: "");
                                        if seenConceptKeys.hasKey(dedupeKey) {
                                            continue;
                                        }
                                        seenConceptKeys[dedupeKey] = true;
                                        allConcepts.push(c);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Intensional includes: resolve `concept is-a` / `descendent-of`
        // filters against the closure table, from the compose rules decoded
        // above.
        if storedVs is r4:ValueSet {
            r4:ValueSetCompose? composeRules = storedVs.compose;
            if composeRules is r4:ValueSetCompose {
                foreach r4:ValueSetComposeInclude inc in composeRules.include {
                    r4:ValueSetComposeIncludeFilter[]? incFilters = inc.filter;
                    r4:uri? incSystem = inc.system;
                    if incFilters is r4:ValueSetComposeIncludeFilter[] && incFilters.length() > 0 && incSystem is r4:uri {
                        store_h2:CodeSystem|error filterCs = getStoreCodeSystemByURL(incSystem, inc.'version);
                        if filterCs is store_h2:CodeSystem {
                            // Per the FHIR compose.include model, multiple filters on the
                            // same include are ANDed together (each narrows the same
                            // member set further) - unlike multiple includes, which are
                            // unioned. Intersect each filter's matches by code instead of
                            // pushing every filter's matches independently. A no-op when
                            // there's only one filter.
                            r4:ValueSetExpansionContains[]? intersected = ();
                            foreach r4:ValueSetComposeIncludeFilter f in incFilters {
                                r4:ValueSetExpansionContains[] members = [];
                                match f.op {
                                    "is-a"|"descendent-of" if f.property == "concept" => {
                                        members = hasClosureRows(filterCs.codeSystemId)
                                            ? closureMembers(filterCs.codeSystemId, f.value, f.op == "is-a", filter)
                                            : parentWalkDescendants(filterCs.codeSystemId, f.value, f.op == "is-a", filter);
                                    }
                                    "=" => {
                                        members = filterConceptsByProperty(
                                                filterCs.codeSystemId, f.property, f.value, filter, stringEquals, exactMatch = true);
                                    }
                                    "regex" => {
                                        members = filterConceptsByProperty(
                                                filterCs.codeSystemId, f.property, f.value, filter, regexMatches);
                                    }
                                    _ => {
                                        // An unrecognized op, or is-a/descendent-of on a
                                        // property other than "concept", would otherwise
                                        // silently leave members empty - intersecting that in
                                        // produces an under-inclusive expansion returned as a
                                        // normal 200 instead of surfacing the unsupported filter.
                                        return r4:createFHIRError(
                                                string `Unsupported ValueSet compose filter: op=${f.op}, property=${f.property}`,
                                                r4:ERROR,
                                                r4:PROCESSING_NOT_SUPPORTED,
                                                diagnostic = "Supported filters: is-a/descendent-of on property 'concept', '=' and 'regex' on any property.",
                                                httpStatusCode = http:STATUS_BAD_REQUEST);
                                    }
                                }
                                intersected = intersected is r4:ValueSetExpansionContains[]
                                    ? intersectByCode(intersected, members)
                                    : members;
                            }
                            foreach r4:ValueSetExpansionContains m in (intersected ?: []) {
                                string dedupeKey = filterCs.url + "|" + (m.code ?: "");
                                if seenConceptKeys.hasKey(dedupeKey) {
                                    continue;
                                }
                                seenConceptKeys[dedupeKey] = true;
                                m.system = filterCs.url;
                                allConcepts.push(m);
                            }
                        }
                    }
                }
            }
        }

        return buildPagedValueSetExpansion(valueSet, allConcepts, offset, count);
    }

    # Resolves a ValueSet's `compose.include` directly from the in-memory resource, for a ValueSet that isn't (and was never meant to be) persisted - e.g. a throwaway `valueSet` parameter built for a single `$expand` request. Mirrors `expandValueSet`'s DB-backed handling (explicit concept lists, whole-system includes, nested ValueSet includes, intensional filters), but reads `compose`/`contained` off `rootValueSet` instead of querying `valuesetcomposeincludes`/`valuesets`. CodeSystems referenced by `include.system` still have to be real, persisted CodeSystems - only the ValueSet's own composition is inline.
    #
    # + searchParameters - The request's search parameters, forwarded to any externally-referenced nested ValueSet via `expandValueSet`
    # + rootValueSet - The ValueSet whose `contained` array local (`#...`) references in `compose` resolve against
    # + composeSource - The ValueSet whose `compose.include` is being processed (`rootValueSet` itself, or one of its contained ValueSets when recursing into a local reference)
    # + filter - Optional case-insensitive substring filter applied to concept display text
    # + return - The matching concepts (not yet paginated) plus the `url|version` of every externally-referenced ValueSet that actually contributed to the result, or an `r4:FHIRError` if a filter is unsupported
    isolated function expandInlineValueSetCompose(map<r4:RequestSearchParameter[]> searchParameters, r4:ValueSet rootValueSet, r4:ValueSet composeSource, string? filter) returns InlineComposeResult|r4:FHIRError {
        r4:ValueSetExpansionContains[] allConcepts = [];
        map<boolean> seenConceptKeys = {};
        map<boolean> usedValueSetKeys = {};

        r4:ValueSetCompose? compose = composeSource.compose;
        if compose is () {
            return {concepts: allConcepts, usedValueSetKeys};
        }

        foreach r4:ValueSetComposeInclude include in compose.include {
            r4:uri? includeSystem = include.system;
            r4:ValueSetComposeIncludeConcept[]? includeConcepts = include.concept;
            r4:ValueSetComposeIncludeFilter[]? includeFilters = include.filter;

            if includeSystem is r4:uri && includeConcepts is r4:ValueSetComposeIncludeConcept[] && includeConcepts.length() > 0 {
                store_h2:CodeSystem|error cs = getStoreCodeSystemByURL(includeSystem, include.'version);
                if cs is store_h2:CodeSystem {
                    foreach r4:ValueSetComposeIncludeConcept ic in includeConcepts {
                        store_h2:Concept|r4:FHIRError storeConcept = getStoreConceptByCode(cs.codeSystemId, ic.code);
                        if storeConcept is store_h2:Concept {
                            r4:CodeSystemConcept|error decoded = byteToConcept(storeConcept.concept);
                            if decoded is r4:CodeSystemConcept {
                                if filter is string && !displayMatchesTextFilter(decoded.display, filter) {
                                    continue;
                                }
                                string dedupeKey = includeSystem + "|" + decoded.code;
                                if !seenConceptKeys.hasKey(dedupeKey) {
                                    seenConceptKeys[dedupeKey] = true;
                                    allConcepts.push({code: decoded.code, display: decoded.display, id: decoded.id, system: includeSystem});
                                }
                            }
                        }
                    }
                }
            } else if includeSystem is r4:uri && includeFilters is r4:ValueSetComposeIncludeFilter[] && includeFilters.length() > 0 {
                store_h2:CodeSystem|error filterCs = getStoreCodeSystemByURL(includeSystem, include.'version);
                if filterCs is store_h2:CodeSystem {
                    r4:ValueSetExpansionContains[]? intersected = ();
                    foreach r4:ValueSetComposeIncludeFilter f in includeFilters {
                        r4:ValueSetExpansionContains[] members = [];
                        match f.op {
                            "is-a"|"descendent-of" if f.property == "concept" => {
                                members = hasClosureRows(filterCs.codeSystemId)
                                    ? closureMembers(filterCs.codeSystemId, f.value, f.op == "is-a", filter)
                                    : parentWalkDescendants(filterCs.codeSystemId, f.value, f.op == "is-a", filter);
                            }
                            "=" => {
                                members = filterConceptsByProperty(
                                        filterCs.codeSystemId, f.property, f.value, filter, stringEquals, exactMatch = true);
                            }
                            "regex" => {
                                members = filterConceptsByProperty(
                                        filterCs.codeSystemId, f.property, f.value, filter, regexMatches);
                            }
                            _ => {
                                return r4:createFHIRError(
                                        string `Unsupported ValueSet compose filter: op=${f.op}, property=${f.property}`,
                                        r4:ERROR,
                                        r4:PROCESSING_NOT_SUPPORTED,
                                        diagnostic = "Supported filters: is-a/descendent-of on property 'concept', '=' and 'regex' on any property.",
                                        httpStatusCode = http:STATUS_BAD_REQUEST);
                            }
                        }
                        intersected = intersected is r4:ValueSetExpansionContains[]
                            ? intersectByCode(intersected, members)
                            : members;
                    }
                    foreach r4:ValueSetExpansionContains m in (intersected ?: []) {
                        string dedupeKey = filterCs.url + "|" + (m.code ?: "");
                        if !seenConceptKeys.hasKey(dedupeKey) {
                            seenConceptKeys[dedupeKey] = true;
                            m.system = filterCs.url;
                            allConcepts.push(m);
                        }
                    }
                }
            } else if includeSystem is r4:uri {
                // Whole-system include, no explicit concept list and no filter.
                store_h2:CodeSystem|error cs = getStoreCodeSystemByURL(includeSystem, include.'version);
                if cs is store_h2:CodeSystem {
                    sql:ParameterizedQuery query = sql:queryConcat(escapeToQuery("codesystemCodeSystemId"), ` = ${cs.codeSystemId}`);
                    string? inMemoryFilter = filter;
                    if filter is string && isPlainTextFilter(filter) {
                        query = sql:queryConcat(query, displayContainsFragment(escapeToQuery("display"), filter));
                        inMemoryFilter = ();
                    }
                    // Streamed rather than collected first: a whole-system
                    // include covers every concept in the CodeSystem.
                    stream<store_h2:Concept, persist:Error?> conceptStream = sClient->/concepts(store_h2:Concept, query);
                    error? iterationError = from store_h2:Concept c in conceptStream
                        do {
                            r4:CodeSystemConcept|error concept = byteToConcept(c.concept);
                            if concept is r4:CodeSystemConcept
                                    && (inMemoryFilter is () || displayMatchesTextFilter(concept.display, inMemoryFilter)) {
                                string dedupeKey = includeSystem + "|" + concept.code;
                                if !seenConceptKeys.hasKey(dedupeKey) {
                                    seenConceptKeys[dedupeKey] = true;
                                    allConcepts.push({code: concept.code, display: concept.display, id: concept.id, system: includeSystem});
                                }
                            }
                        };
                    if iterationError is error {
                        log:printDebug("Whole-system include expansion failed", iterationError);
                    }
                }
            }

            r4:canonical[]? includeValueSets = include.valueSet;
            if includeValueSets is r4:canonical[] && includeValueSets.length() > 0 {
                // Per the FHIR spec, multiple valueSet references on the SAME
                // include are intersected - unlike multiple `include` entries
                // (which are unioned), or multiple `filter` entries on one
                // include (already intersected below, the same way). Resolve
                // each reference's own member list first, then intersect them.
                r4:ValueSetExpansionContains[]? intersectedNested = ();
                // Keys of every externally-referenced ValueSet resolved while
                // processing this include - merged into usedValueSetKeys only
                // if this include actually contributes to the final result
                // below.
                map<boolean> candidateUsedValueSetKeys = {};
                foreach r4:canonical ref in includeValueSets {
                    r4:ValueSetExpansionContains[] nestedResult;
                    if ref.startsWith("#") {
                        // Local reference: resolve within rootValueSet's own
                        // contained array rather than the store - a contained
                        // resource, by definition, was never persisted on its own.
                        string localId = ref.substring(1);
                        r4:ValueSet? containedVs = ();
                        r4:Resource[]? contained = rootValueSet.contained;
                        if contained is r4:Resource[] {
                            foreach r4:Resource res in contained {
                                json resJson = res.toJson();
                                if resJson is map<json> && resJson["resourceType"] == "ValueSet" && resJson["id"] == localId {
                                    r4:ValueSet|error parsed = resJson.cloneWithType(r4:ValueSet);
                                    if parsed is r4:ValueSet {
                                        containedVs = parsed;
                                    }
                                }
                            }
                        }
                        // A local reference that can't be resolved contributes no
                        // members - under intersection, that correctly zeroes out
                        // the whole include rather than silently ignoring it.
                        if containedVs is r4:ValueSet {
                            InlineComposeResult|r4:FHIRError nestedComposeResult =
                                self.expandInlineValueSetCompose(searchParameters, rootValueSet, containedVs, filter);
                            if nestedComposeResult is r4:FHIRError {
                                return nestedComposeResult;
                            }
                            nestedResult = nestedComposeResult.concepts;
                            foreach string key in nestedComposeResult.usedValueSetKeys.keys() {
                                candidateUsedValueSetKeys[key] = true;
                            }
                        } else {
                            nestedResult = [];
                        }
                    } else {
                        // External reference: resolve the normal way (a stored
                        // ValueSet, or - recursively - another inline fallback).
                        r4:ValueSet|r4:FHIRError expanded = self.expandValueSet(searchParameters, {resourceType: "ValueSet", status: "active", url: ref}, 0, 1000);
                        if expanded is r4:FHIRError {
                            nestedResult = [];
                        } else {
                            r4:ValueSetExpansion? nestedExpansion = expanded.expansion;
                            nestedResult = nestedExpansion is r4:ValueSetExpansion
                                ? (nestedExpansion.contains ?: [])
                                : [];
                            string? expandedUrl = expanded.url;
                            if expandedUrl is string {
                                // expandValueSet returns the request object it was
                                // given, not the resolved DB row - so when we call it above with a bare url
                                // and no version, expanded.version stays unset even
                                // though the stored ValueSet actually has one.
                                string? resolvedVersion = expanded.version;
                                if resolvedVersion is () {
                                    store_h2:ValueSet|error storedRef = getStoreValueSetByURL(expandedUrl);
                                    if storedRef is store_h2:ValueSet {
                                        resolvedVersion = storedRef.version;
                                    }
                                }
                                string usedKey = resolvedVersion is string && resolvedVersion != ""
                                    ? expandedUrl + "|" + resolvedVersion
                                    : expandedUrl;
                                candidateUsedValueSetKeys[usedKey] = true;
                            }
                        }
                    }
                    intersectedNested = intersectedNested is r4:ValueSetExpansionContains[]
                        ? intersectByCode(intersectedNested, nestedResult)
                        : nestedResult;
                }
                r4:ValueSetExpansionContains[] includeContribution = intersectedNested ?: [];
                if includeContribution.length() > 0 {
                    foreach string key in candidateUsedValueSetKeys.keys() {
                        usedValueSetKeys[key] = true;
                    }
                }
                foreach r4:ValueSetExpansionContains c in includeContribution {
                    string dedupeKey = (c.system ?: "") + "|" + (c.code ?: "");
                    if !seenConceptKeys.hasKey(dedupeKey) {
                        seenConceptKeys[dedupeKey] = true;
                        allConcepts.push(c);
                    }
                }
            }
        }

        return {concepts: allConcepts, usedValueSetKeys};
    }

    # Implements FHIR `$subsumes`, determining the subsumption relationship between two codes in the same `CodeSystem` via the closure table (falling back to a parent-chain walk).
    #
    # + system - The canonical url of the `CodeSystem` both codes belong to
    # + codeA - The first code to compare
    # + codeB - The second code to compare
    # + version - The `CodeSystem` version to match
    # + return - A `Parameters` resource with the subsumption outcome (`equivalent`, `subsumes`, `subsumed-by`, or `not-subsumed`), or an `r4:FHIRError` if the `CodeSystem` or either code is not found
    public isolated function subsumes(r4:uri system, r4:code codeA, r4:code codeB, string? version) returns r4:Parameters|r4:FHIRError {
        var codeSystem = getStoreCodeSystemByURL(system, version);

        if codeSystem !is store_h2:CodeSystem {
            return r4:createFHIRError(
                    "CodeSystem not found",
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    cause = error("No matching CodeSystem found"),
                    httpStatusCode = http:STATUS_NOT_FOUND);
        }

        if codeA == codeB {
            return {'parameter: [{name: terminology:OUTCOME, valueCode: terminology:EQUIVALENT}]};
        }

        // getConceptNode validates each code exists in this CodeSystem and
        // yields its DB conceptId.
        ConceptNode conceptA = check getConceptNode(codeA, codeSystem.codeSystemId);
        ConceptNode conceptB = check getConceptNode(codeB, codeSystem.codeSystemId);

        boolean aSubsumesB = closureContainsPair(conceptA.conceptId, conceptB.conceptId, codeSystem.codeSystemId)
            || isInParentChain(conceptA.conceptId, conceptB);
        if aSubsumesB {
            // terminology:SUBSUMED is a library constant, but its value ("subsumed")
            // is wrong per https://hl7.org/fhir/R4/valueset-concept-subsumption-outcome.html -
            // the correct code for "codeA subsumes codeB" is "subsumes". Using the
            // literal here instead of the mis-valued library constant.
            return {'parameter: [{name: terminology:OUTCOME, valueCode: "subsumes"}]};
        }

        boolean bSubsumesA = closureContainsPair(conceptB.conceptId, conceptA.conceptId, codeSystem.codeSystemId)
            || isInParentChain(conceptB.conceptId, conceptA);
        if bSubsumesA {
            return {'parameter: [{name: terminology:OUTCOME, valueCode: terminology:SUBSUMED_BY}]};
        }

        return {'parameter: [{name: terminology:OUTCOME, valueCode: terminology:NOT_SUBSUMED}]};
    }

    # Searches stored concepts whose display or definition text matches a regex filter, optionally restricted to a system, with pagination.
    #
    # + property - Whether to match against the concept's display or definition text
    # + filter - The regex fragment to match the property text against
    # + system - The canonical url to restrict the search to, or `()` to search across all systems
    # + offset - The number of matching concepts to skip
    # + count - The maximum number of concepts to return
    # + return - The matching concepts' details, or an `r4:FHIRError` if the query fails
    public isolated function searchConcept(DISPLAY|DEFINITION property, string filter, string? system, int offset, int count) returns terminology:CodeConceptDetails[]|r4:FHIRError {
        // Filtered via a subquery on the concept's own FK column rather than a
        // "c."-qualified join column: this whereClause is handed to the
        // generated persist resource method, whose own join aliases aren't
        // part of this function's contract (and "c." never matched any alias
        // it actually generates, silently breaking system-filtered searches
        // with a 500).
        sql:ParameterizedQuery whereClause = sql:queryConcat(
                escapeToQuery(property), getRegexOperator(), stringToParameterizedQuery("'.*" + filter + ".*'"),
                    system is () ? `` : sql:queryConcat(
                        ` AND `, escapeToQuery("codesystemCodeSystemId"),
                        ` IN (SELECT `, escapeToQuery("codeSystemId"), ` FROM `, escapeToQuery("codesystems"),
                        ` WHERE `, escapeToQuery("url"), ` = ${system})`),
                getLimitClause(count, offset)
        );

        stream<store_h2:ConceptWithRelations, persist:Error?> conceptStream = sClient->/concepts(store_h2:ConceptWithRelations, whereClause);
        store_h2:ConceptWithRelations[]|error dbConcepts = from store_h2:ConceptWithRelations concept in conceptStream
            select concept;

        if dbConcepts is error {
            return r4:createFHIRError(
                    dbConcepts.message(),
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    cause = dbConcepts,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }

        terminology:CodeConceptDetails[] concepts = [];
        foreach store_h2:ConceptWithRelations dbConcept in dbConcepts {
            r4:CodeSystemConcept|error codeSystemConcept = byteToConcept(<byte[]>dbConcept.concept);
            if codeSystemConcept is error {
                // Skip this Concept if parsing fails
                continue;
            }
            terminology:CodeConceptDetails details = {
                url: dbConcept.codeSystem?.url ?: "",
                concept: codeSystemConcept
            };
            concepts.push(details);
        }

        return concepts;
    }

    # Persists a `ConceptMap` resource to the database.
    #
    # + conceptMap - The `ConceptMap` to add
    # + return - An `r4:FHIRError` if the insert fails, `()` otherwise
    public isolated function addConceptMap(r4:ConceptMap conceptMap) returns r4:FHIRError? {
        return storeConceptMap(conceptMap);
    }

    # Finds stored `ConceptMap`s that map from the given source ValueSet, optionally restricted to a target ValueSet.
    #
    # + sourceValueSetUri - The canonical url of the source `ValueSet` to match
    # + targetValueSetUri - The canonical url of the target `ValueSet` to match, or `()` to match any target
    # + return - The matching `r4:ConceptMap`s, or an `r4:FHIRError` if the query fails
    public isolated function findConceptMaps(r4:uri sourceValueSetUri, r4:uri? targetValueSetUri) returns r4:ConceptMap[]|r4:FHIRError {
        return findStoredConceptMaps(sourceValueSetUri, targetValueSetUri);
    }

    # Looks up a stored `ConceptMap` by its canonical url.
    #
    # + conceptMapUrl - The canonical url of the `ConceptMap` to find
    # + version - The `ConceptMap` version to match
    # + return - The matching `r4:ConceptMap`, or an `r4:FHIRError` if no match is found
    public isolated function getConceptMap(r4:uri conceptMapUrl, string? version) returns r4:ConceptMap|r4:FHIRError {
        return getStoredConceptMapByUrl(conceptMapUrl, version);
    }

    # Checks whether a `ConceptMap` with the given url and version is stored.
    #
    # + system - The canonical url of the `ConceptMap` to check
    # + version - The version of the `ConceptMap` to check
    # + return - `true` if a matching `ConceptMap` exists, `false` otherwise
    public isolated function isConceptMapExist(r4:uri system, string version) returns boolean {
        return storedConceptMapExists(system, version);
    }

    # Searches stored `ConceptMap`s matching the given FHIR search parameters, with optional pagination.
    #
    # + params - The search parameters to filter by, keyed by recognized parameter name
    # + offset - The number of matching records to skip
    # + count - The maximum number of records to return
    # + return - The matching `r4:ConceptMap`s, or an `r4:FHIRError` if the query fails
    public isolated function searchConceptMap(map<r4:RequestSearchParameter[]> params, int? offset, int? count) returns r4:ConceptMap[]|r4:FHIRError {
        return searchStoredConceptMaps(params, offset, count);
    }
}

# Checks whether a closure row exists for the given ancestor/descendant pair in this CodeSystem.
#
# + ancestorId - Internal concept id of the potential ancestor
# + descendantId - Internal concept id of the potential descendant
# + codeSystemId - Internal id of the CodeSystem the pair belongs to
# + return - `true` if the pair exists in the closure table, `false` otherwise
isolated function closureContainsPair(int ancestorId, int descendantId, int codeSystemId) returns boolean {
    sql:ParameterizedQuery sqlQuery = sql:queryConcat(
            `SELECT 1 FROM `, escapeToQuery("concept_closure"),
            ` WHERE `, escapeToQuery("ancestorConceptId"), ` = ${ancestorId}`,
            ` AND `, escapeToQuery("descendantConceptId"), ` = ${descendantId}`,
            ` AND `, escapeToQuery("codeSystemId"), ` = ${codeSystemId} LIMIT 1`);

    stream<record {}, persist:Error?> resultStream = sClient->queryNativeSQL(sqlQuery);
    record {}[]|error results = from record {} result in resultStream
        select result;

    return results is error ? false : results.length() > 0;
}

# The in-memory form of the `$expand` display filter, kept for `filter` values that hold regex syntax - a literal-text value is pushed into SQL as a LIKE predicate by `displayContainsFragment` instead, so non-matching rows are never read.
#
# Written as a search rather than as `isFullMatch` against a `.*<filter>.*` pattern, because the two are not equivalent when a display contains a line terminator: `.` does not match one, so the wrapping `.*` cannot reach a match that sits on a later line, while SQL's `%` crosses them freely. Filtering on "active" would then find it in "Prefix Active" but not in "Prefix\nActive", and the same concept would be kept or dropped depending on whether its expansion happened to take the pushed-down path. `find` matches what LIKE does, and what a text filter is meant to mean.
#
# A concept with no display passes. See `displayContainsFragment` for why that quirk is preserved rather than fixed here.
#
# + display - The concept's display, if it has one
# + textFilter - The request's `filter` value
# + return - `true` if the concept survives the filter
isolated function displayMatchesTextFilter(string? display, string textFilter) returns boolean {
    if display is () {
        return true;
    }
    return regexp:find(re `${textFilter.toUpperAscii()}`, display.toUpperAscii()) !is ();
}

# A `compose` shape that `$expand` can satisfy entirely in the database: exactly one `include`, naming one CodeSystem, with no explicit concept list and no nested `valueSet` references - either narrowed by exactly one `is-a`/`descendent-of` filter (the ordinary SNOMED "all descendants of X" ValueSet) or not narrowed at all (a whole-CodeSystem include). These are the only shapes needing neither cross-include de-duplication nor filter intersection, so the row set can be ordered, counted and windowed in SQL instead of being materialized in full and sliced afterwards.
type WindowedInclude record {|
    # Internal id of the CodeSystem the include selects from
    int codeSystemId;
    # Canonical URL of that CodeSystem, stamped onto every returned entry
    string codeSystemUrl;
    # Code the `is-a`/`descendent-of` filter is anchored on, or `()` for a whole-CodeSystem include
    string? anchorCode;
    # For an anchored include, whether the anchor itself is a member (`is-a`) or only its descendants (`descendent-of`). Meaningless when `anchorCode` is `()`.
    boolean includeSelf;
|};

# Recognizes the `WindowedInclude` shapes, returning `()` for anything else so the caller falls through to the general in-memory path. Deliberately strict: it is only ever an optimization, so a shape it doesn't recognize costs nothing but the checks.
#
# + storedVs - The stored `ValueSet` resource, whose `compose` holds the include rules
# + includes - The ValueSet's persisted compose-include rows
# + textFilter - The request's `filter` value, if any
# + return - The recognized fast-path parameters, or `()` if this compose isn't one
isolated function windowedIncludeFastPath(r4:ValueSet storedVs, store_h2:ValueSetComposeInclude[] includes, string? textFilter)
        returns WindowedInclude? {
    // A regex-bearing `filter` has no LIKE equivalent, so the windowed page
    // query has no way to apply it - and applying it to the page afterwards
    // would return a short page under an already-computed total.
    if textFilter is string && !isPlainTextFilter(textFilter) {
        return ();
    }

    r4:ValueSetCompose? compose = storedVs.compose;
    if compose is () || compose.include.length() != 1 {
        return ();
    }

    r4:ValueSetComposeInclude include = compose.include[0];
    r4:uri? system = include.system;
    if system is () || include.concept is r4:ValueSetComposeIncludeConcept[] || include.valueSet is r4:canonical[] {
        return ();
    }

    store_h2:CodeSystem|error codeSystem = getStoreCodeSystemByURL(system, include.'version);
    if codeSystem is error {
        return ();
    }

    r4:ValueSetComposeIncludeFilter[]? filters = include.filter;
    if filters is () || filters.length() == 0 {
        // Whole-CodeSystem include. It is persisted as exactly one systemFlag
        // row (`saveValueSetCodeSystem`), and that row is what the general
        // path would have expanded - so anything else here (no row written
        // yet, an extra row, a row naming a different CodeSystem) is not this
        // shape and must not be claimed.
        if includes.length() != 1 || !includes[0].systemFlag || includes[0].codeSystemId != codeSystem.codeSystemId {
            return ();
        }
        return {
            codeSystemId: codeSystem.codeSystemId,
            codeSystemUrl: codeSystem.url,
            anchorCode: (),
            includeSelf: false
        };
    }

    // A filtered include is never persisted as a compose-include row
    // (`saveValueSetComposeInclude` returns before writing one), so this shape
    // has no rows at all. Any row present means some other include also
    // contributes members, which would need de-duplication against this one.
    if includes.length() > 0 {
        return ();
    }

    // More than one filter would have to be intersected, which needs both
    // sides resolved in full.
    if filters.length() != 1 {
        return ();
    }
    r4:ValueSetComposeIncludeFilter singleFilter = filters[0];
    if singleFilter.property != "concept" || (singleFilter.op != "is-a" && singleFilter.op != "descendent-of") {
        return ();
    }
    // Without closure rows, membership has to be found by walking parent links
    // level by level (`parentWalkDescendants`), which is not a single query.
    if !hasClosureRows(codeSystem.codeSystemId) {
        return ();
    }

    return {
        codeSystemId: codeSystem.codeSystemId,
        codeSystemUrl: codeSystem.url,
        anchorCode: singleFilter.value,
        includeSelf: singleFilter.op == "is-a"
    };
}

# Resolves a `WindowedInclude` with two queries - a `COUNT(*)` for `expansion.total` and an ordered, windowed `SELECT` for the requested page - so only the page's concept blobs are ever read or de-serialized, whatever the size of the closure or CodeSystem.
#
# The explicit `ORDER BY conceptId` also makes paging stable: the in-memory paths issue their queries without an ORDER BY, so the row order backing `offset`/`count` is whatever the database happens to return.
#
# `total` comes from `COUNT(*)`, which counts every matching row. The in-memory paths instead skip a row whose concept blob fails to de-serialize, so a corrupt blob would make the two disagree by one - the windowed count being the truthful one.
#
# + window - The recognized fast-path parameters
# + textFilter - The request's `filter` value, if any
# + offset - Number of matching concepts to skip
# + count - Maximum number of concepts to return
# + return - The page's concepts and the total match count, or an `error` if either query fails
isolated function expandWindowedInclude(WindowedInclude window, string? textFilter, int offset, int count)
        returns [r4:ValueSetExpansionContains[], int]|error {
    sql:ParameterizedQuery fromAndWhere;
    string? anchorCode = window.anchorCode;
    if anchorCode is string {
        store_h2:Concept|r4:FHIRError anchor = getStoreConceptByCode(window.codeSystemId, anchorCode);
        if anchor is r4:FHIRError {
            // An unresolvable anchor selects nothing - the same result the
            // in-memory path returns for it.
            return [[], 0];
        }
        fromAndWhere = sql:queryConcat(
                ` FROM `, escapeToQuery("concepts"), ` c JOIN `, escapeToQuery("concept_closure"), ` cc`,
                ` ON c.`, escapeToQuery("conceptId"), ` = cc.`, escapeToQuery("descendantConceptId"),
                ` WHERE cc.`, escapeToQuery("ancestorConceptId"), ` = ${anchor.conceptId}`,
                ` AND cc.`, escapeToQuery("codeSystemId"), ` = ${window.codeSystemId}`,
                window.includeSelf ? `` : sql:queryConcat(` AND cc.`, escapeToQuery("depth"), ` >= 1`));
    } else {
        fromAndWhere = sql:queryConcat(
                ` FROM `, escapeToQuery("concepts"), ` c`,
                ` WHERE c.`, escapeToQuery("codesystemCodeSystemId"), ` = ${window.codeSystemId}`);
    }

    // Only a filter that means literal text can become a LIKE predicate; a
    // regex-bearing one isn't recognized as a fast path candidate at all,
    // since the page query has no way to apply it.
    if textFilter is string {
        fromAndWhere = sql:queryConcat(fromAndWhere,
                displayContainsFragment(sql:queryConcat(`c.`, escapeToQuery("display")), textFilter));
    }

    sql:ParameterizedQuery countQuery = sql:queryConcat(`SELECT COUNT(*) AS `, escapeToQuery("total"), fromAndWhere);
    stream<record {|int total;|}, persist:Error?> countStream = sClient->queryNativeSQL(countQuery);
    record {|int total;|}[]|error countRows = from record {|int total;|} row in countStream
        select row;
    if countRows is error {
        return countRows;
    }
    int total = countRows.length() > 0 ? countRows[0].total : 0;
    if total == 0 || offset >= total {
        return [[], total];
    }

    sql:ParameterizedQuery pageQuery = sql:queryConcat(
            `SELECT c.* `, fromAndWhere,
            ` ORDER BY c.`, escapeToQuery("conceptId"), ` `, getLimitClause(count, offset));

    r4:ValueSetExpansionContains[] page = [];
    stream<store_h2:Concept, persist:Error?> pageStream = sClient->queryNativeSQL(pageQuery);
    while true {
        record {|store_h2:Concept value;|}|persist:Error? nextRow = pageStream.next();
        if nextRow is () {
            break;
        }
        if nextRow is persist:Error {
            check pageStream.close();
            return nextRow;
        }
        r4:CodeSystemConcept|error concept = byteToConcept(nextRow.value.concept);
        if concept is r4:CodeSystemConcept {
            page.push({
                code: concept.code,
                display: concept.display,
                id: concept.id,
                system: window.codeSystemUrl
            });
        }
    }
    check pageStream.close();

    return [page, total];
}

# Resolves an intensional `concept is-a` / `descendent-of` filter to its members via the closure table. Used when the surrounding compose is too complex for `expandWindowedInclude` to satisfy in SQL - it returns every member, so the caller can de-duplicate and intersect before paging.
#
# + codeSystemId - Internal id of the CodeSystem to search within
# + anchorCode - Code of the anchor concept whose descendants are collected
# + includeSelf - Whether to include the anchor concept itself in the result
# + textFilter - Optional case-insensitive substring filter applied to concept display text
# + return - Matching concepts as `r4:ValueSetExpansionContains` entries
isolated function closureMembers(int codeSystemId, string anchorCode, boolean includeSelf, string? textFilter) returns r4:ValueSetExpansionContains[] {
    r4:ValueSetExpansionContains[] members = [];

    store_h2:Concept|r4:FHIRError anchor = getStoreConceptByCode(codeSystemId, anchorCode);
    if anchor is r4:FHIRError {
        return members;
    }

    // A literal-text filter becomes a LIKE predicate, so non-matching rows are
    // never read or de-serialized. One carrying regex syntax has no LIKE
    // equivalent and still has to be matched in memory.
    sql:ParameterizedQuery displayFragment = ``;
    string? inMemoryFilter = textFilter;
    if textFilter is string && isPlainTextFilter(textFilter) {
        displayFragment = displayContainsFragment(sql:queryConcat(`c.`, escapeToQuery("display")), textFilter);
        inMemoryFilter = ();
    }

    sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT c.* FROM `, escapeToQuery("concepts"), ` c JOIN `, escapeToQuery("concept_closure"), ` cc ON c.`, escapeToQuery("conceptId"), ` = cc.`, escapeToQuery("descendantConceptId"),
            ` WHERE cc.`, escapeToQuery("ancestorConceptId"), ` = ${anchor.conceptId}`,
            ` AND cc.`, escapeToQuery("codeSystemId"), ` = ${codeSystemId}`,
                includeSelf ? `` : sql:queryConcat(` AND cc.`, escapeToQuery("depth"), ` >= 1`),
            displayFragment
    );

    // Streamed rather than collected into a `store_h2:Concept[]` first: only the
    // projected entries are held, not every matching row together with its blob.
    stream<store_h2:Concept, persist:Error?> conceptStream = sClient->queryNativeSQL(query);
    error? iterationError = from store_h2:Concept dbConcept in conceptStream
        do {
            r4:CodeSystemConcept|error concept = byteToConcept(dbConcept.concept);
            if concept is r4:CodeSystemConcept
                    && (inMemoryFilter is () || displayMatchesTextFilter(concept.display, inMemoryFilter)) {
                members.push({code: concept.code, display: concept.display, id: concept.id});
            }
        };
    if iterationError is error {
        return members;
    }

    return members;
}

// ---------------------------------------------------------------------------
// ConceptMap/$closure operation storage (https://hl7.org/fhir/R4/conceptmap-operation-closure.html).
// Maintains a client-named, incrementally-growing subsumption closure table:
// each call adds concepts to a named table and returns only the subsumption
// pairs not yet reported for that name. Handler: closurePost in
// terminology_connect.bal.
// ---------------------------------------------------------------------------

type ClosureTableRow record {|
    int closureTableId;
    string name;
    int currentVersion;
|};

type ClosureTablePairRow record {|
    int closureTablePairId;
    int closureTableId;
    int ancestorConceptId;
    int descendantConceptId;
    int reportedAtVersion;
|};

// A concept the client tried to add that couldn't be resolved to a stored
// concept (unknown system, or code not found under that system).
type UnmatchedClosureConcept record {|
    string? system;
    string code;
|};

# Looks up a named closure table, creating it with version 0 if it doesn't exist yet.
#
# + name - Client-supplied name identifying the closure table
# + return - The existing or newly-created `ClosureTableRow`, or an `r4:FHIRError` if creation fails
isolated function getOrCreateClosureTable(string name) returns ClosureTableRow|r4:FHIRError {
    sql:ParameterizedQuery selectQuery = sql:queryConcat(
            `SELECT * FROM `, escapeToQuery("closure_tables"),
            ` WHERE `, escapeToQuery("name"), ` = ${name}`);
    stream<ClosureTableRow, persist:Error?> existingStream = sClient->queryNativeSQL(selectQuery);
    ClosureTableRow[]|error existing = from ClosureTableRow row in existingStream
        select row;
    if existing is ClosureTableRow[] && existing.length() > 0 {
        return existing[0];
    }

    sql:ParameterizedQuery insertQuery = sql:queryConcat(
            `INSERT INTO `, escapeToQuery("closure_tables"),
            ` (`, escapeToQuery("name"), `, `, escapeToQuery("currentVersion"), `) VALUES (${name}, 0)`);
    psql:ExecutionResult|persist:Error result = sClient->executeNativeSQL(insertQuery);
    if result is persist:Error {
        // name is unique (idx_closure_tables_name), so a concurrent create can make
        // this INSERT fail on the constraint. Re-check for the row a concurrent
        // caller may have just created before treating this as a real failure.
        stream<ClosureTableRow, persist:Error?> concurrentStream = sClient->queryNativeSQL(selectQuery);
        ClosureTableRow[]|error concurrentlyCreated = from ClosureTableRow row in concurrentStream
            select row;
        if concurrentlyCreated is ClosureTableRow[] && concurrentlyCreated.length() > 0 {
            return concurrentlyCreated[0];
        }
        return r4:createFHIRError(
                "Error while creating closure table: " + result.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = result,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // Re-select by name rather than trusting lastInsertId's shape, which varies
    // by driver (int vs numeric string).
    stream<ClosureTableRow, persist:Error?> insertedStream = sClient->queryNativeSQL(selectQuery);
    ClosureTableRow[]|error inserted = from ClosureTableRow row in insertedStream
        select row;
    if inserted is ClosureTableRow[] && inserted.length() > 0 {
        return inserted[0];
    }

    int? closureTableId = ();
    string|int? lastInsertId = result.lastInsertId;
    if lastInsertId is int {
        closureTableId = lastInsertId;
    } else if lastInsertId is string {
        int|error parsedId = int:fromString(lastInsertId);
        if parsedId is int {
            closureTableId = parsedId;
        }
    }
    if closureTableId is () {
        return r4:createFHIRError(
                "Could not resolve the generated closure table id",
                r4:ERROR,
                r4:PROCESSING,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return {closureTableId, name, currentVersion: 0};
}

# Retrieves the internal concept ids already registered in a closure table.
#
# + closureTableId - Internal id of the closure table
# + return - Array of concept ids known to the table, or an empty array on query failure
isolated function getKnownConceptIds(int closureTableId) returns int[] {
    sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT `, escapeToQuery("conceptId"), ` FROM `, escapeToQuery("closure_table_concepts"),
            ` WHERE `, escapeToQuery("closureTableId"), ` = ${closureTableId}`);
    stream<record {|int conceptId;|}, persist:Error?> resultStream = sClient->queryNativeSQL(query);
    record {|int conceptId;|}[]|error rows = from record {|int conceptId;|} r in resultStream
        select r;
    if rows is error {
        return [];
    }
    return rows.map(r => r.conceptId);
}

# Registers a concept as known to a closure table.
#
# + closureTableId - Internal id of the closure table
# + conceptId - Internal id of the concept to register
# + return - An `r4:FHIRError` if the insert fails, `()` otherwise
isolated function addClosureTableConcept(int closureTableId, int conceptId) returns r4:FHIRError? {
    sql:ParameterizedQuery query = sql:queryConcat(
            `INSERT INTO `, escapeToQuery("closure_table_concepts"),
            ` (`, escapeToQuery("closureTableId"), `, `, escapeToQuery("conceptId"), `) VALUES (${closureTableId}, ${conceptId})`);
    psql:ExecutionResult|persist:Error result = sClient->executeNativeSQL(query);
    if result is persist:Error {
        return r4:createFHIRError(
                "Error while recording closure table concept: " + result.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = result,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
}

# Retrieves the internal ids of every ancestor of a concept within a CodeSystem.
#
# + conceptId - Internal id of the concept whose ancestors are looked up
# + codeSystemId - Internal id of the CodeSystem the concept belongs to
# + return - Array of ancestor concept ids, or an empty array on query failure
isolated function getAncestorConceptIds(int conceptId, int codeSystemId) returns int[] {
    sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT `, escapeToQuery("ancestorConceptId"), ` FROM `, escapeToQuery("concept_closure"),
            ` WHERE `, escapeToQuery("descendantConceptId"), ` = ${conceptId}`,
            ` AND `, escapeToQuery("codeSystemId"), ` = ${codeSystemId}`,
            ` AND `, escapeToQuery("depth"), ` >= 1`);
    stream<record {|int ancestorConceptId;|}, persist:Error?> resultStream = sClient->queryNativeSQL(query);
    record {|int ancestorConceptId;|}[]|error rows = from record {|int ancestorConceptId;|} r in resultStream
        select r;
    if rows is error {
        return [];
    }
    return rows.map(r => r.ancestorConceptId);
}

# Restricts descendant lookup to the concepts already known to a closure table, rather than returning every descendant, since `$closure` only needs to report pairs involving concepts the client has actually added. Joins against `closure_table_concepts` instead of binding the candidate set as an `IN (...)` list, since that list can otherwise grow past a driver's bound-parameter limit (e.g. PostgreSQL's 65535) once enough concepts are registered to a closure table.
#
# + conceptId - Internal id of the concept whose descendants are looked up
# + codeSystemId - Internal id of the CodeSystem the concept belongs to
# + closureTableId - Internal id of the closure table whose known concepts restrict the result
# + return - The descendants of `conceptId` that are known to `closureTableId`, or an `r4:FHIRError` if the query fails
isolated function getDescendantConceptIdsAmong(int conceptId, int codeSystemId, int closureTableId) returns int[]|r4:FHIRError {
    sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT cc.`, escapeToQuery("descendantConceptId"),
            ` FROM `, escapeToQuery("concept_closure"), ` cc`,
            ` JOIN `, escapeToQuery("closure_table_concepts"), ` ctc`,
            ` ON ctc.`, escapeToQuery("conceptId"), ` = cc.`, escapeToQuery("descendantConceptId"),
            ` WHERE cc.`, escapeToQuery("ancestorConceptId"), ` = ${conceptId}`,
            ` AND cc.`, escapeToQuery("codeSystemId"), ` = ${codeSystemId}`,
            ` AND cc.`, escapeToQuery("depth"), ` >= 1`,
            ` AND ctc.`, escapeToQuery("closureTableId"), ` = ${closureTableId}`);
    stream<record {|int descendantConceptId;|}, persist:Error?> resultStream = sClient->queryNativeSQL(query);
    record {|int descendantConceptId;|}[]|error rows = from record {|int descendantConceptId;|} r in resultStream
        select r;
    if rows is error {
        return r4:createFHIRError(
                "Error while resolving closure table descendants: " + rows.message(),
                r4:ERROR,
                r4:PROCESSING,
                cause = rows,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return rows.map(r => r.descendantConceptId);
}

# Checks whether an ancestor/descendant pair has already been reported for a closure table.
#
# + closureTableId - Internal id of the closure table
# + ancestorId - Internal concept id of the ancestor
# + descendantId - Internal concept id of the descendant
# + return - `true` if the pair was already reported, `false` otherwise
isolated function isPairReported(int closureTableId, int ancestorId, int descendantId) returns boolean {
    sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT 1 FROM `, escapeToQuery("closure_table_pairs"),
            ` WHERE `, escapeToQuery("closureTableId"), ` = ${closureTableId}`,
            ` AND `, escapeToQuery("ancestorConceptId"), ` = ${ancestorId}`,
            ` AND `, escapeToQuery("descendantConceptId"), ` = ${descendantId} LIMIT 1`);
    stream<record {}, persist:Error?> resultStream = sClient->queryNativeSQL(query);
    record {}[]|error rows = from record {} r in resultStream
        select r;
    return rows is error ? false : rows.length() > 0;
}

# Records a subsumption pair as reported for a closure table at a given version.
#
# + closureTableId - Internal id of the closure table
# + ancestorId - Internal concept id of the ancestor
# + descendantId - Internal concept id of the descendant
# + version - Version number the pair is being reported at
# + return - An `r4:FHIRError` if the insert fails, `()` otherwise
isolated function recordClosurePair(int closureTableId, int ancestorId, int descendantId, int version) returns r4:FHIRError? {
    sql:ParameterizedQuery query = sql:queryConcat(
            `INSERT INTO `, escapeToQuery("closure_table_pairs"),
            ` (`, escapeToQuery("closureTableId"), `, `, escapeToQuery("ancestorConceptId"), `, `,
            escapeToQuery("descendantConceptId"), `, `, escapeToQuery("reportedAtVersion"), `)`,
            ` VALUES (${closureTableId}, ${ancestorId}, ${descendantId}, ${version})`);
    psql:ExecutionResult|persist:Error result = sClient->executeNativeSQL(query);
    if result is persist:Error {
        return r4:createFHIRError(
                "Error while recording closure table pair: " + result.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = result,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
}

# Retrieves closure table pairs reported after a given version, to support a client resync.
#
# + closureTableId - Internal id of the closure table
# + sinceVersion - Only pairs reported after this version are returned
# + excludeVersion - Version to exclude from the results; typically the version this same call just produced, since that's already returned separately via the caller's own newly-discovered pairs
# + return - Matching `ClosureTablePairRow` entries, or an empty array on query failure
isolated function getPairsSinceVersion(int closureTableId, int sinceVersion, int excludeVersion) returns ClosureTablePairRow[] {
    sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT * FROM `, escapeToQuery("closure_table_pairs"),
            ` WHERE `, escapeToQuery("closureTableId"), ` = ${closureTableId}`,
            ` AND `, escapeToQuery("reportedAtVersion"), ` > ${sinceVersion}`,
            ` AND `, escapeToQuery("reportedAtVersion"), ` != ${excludeVersion}`);
    stream<ClosureTablePairRow, persist:Error?> resultStream = sClient->queryNativeSQL(query);
    ClosureTablePairRow[]|error rows = from ClosureTablePairRow r in resultStream
        select r;
    if rows is error {
        return [];
    }
    return rows;
}

# Updates a closure table's current version number.
#
# + closureTableId - Internal id of the closure table
# + newVersion - New version number to set
# + return - An `r4:FHIRError` if the update fails, `()` otherwise
isolated function bumpClosureTableVersion(int closureTableId, int newVersion) returns r4:FHIRError? {
    sql:ParameterizedQuery query = sql:queryConcat(
            `UPDATE `, escapeToQuery("closure_tables"), ` SET `, escapeToQuery("currentVersion"), ` = ${newVersion}`,
            ` WHERE `, escapeToQuery("closureTableId"), ` = ${closureTableId}`);
    psql:ExecutionResult|persist:Error result = sClient->executeNativeSQL(query);
    if result is persist:Error {
        return r4:createFHIRError(
                "Error while updating closure table version: " + result.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = result,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
}

# Maximum number of values bound into a single `IN (...)` clause across the bulk
# lookup helpers below. PostgreSQL caps a statement at 65535 bound parameters
# total; chunking well under that (and under whatever a given driver/pool
# tolerates) keeps a large $closure resync or bulk lookup from either failing
# outright or - worse - silently resolving to nothing once a chunk's query
# fails (see getConceptRefsByIds/getConceptDisplaysByCode/
# getConceptCodeAndDisplayByIds).
const int BULK_LOOKUP_CHUNK_SIZE = 1000;

# Resolves a batch of stored conceptIds back to their code, display, and CodeSystem url, chunking the `IN (...)` clause so a large batch can't exceed a driver's bound-parameter limit. Needed to build the `$closure` response, since `closure_table_pairs` only stores internal conceptIds.
#
# + conceptIds - Internal ids of the concepts to resolve
# + return - A map from conceptId (as string) to its `[code, display, systemUrl]` tuple (ids that couldn't be resolved are simply absent), or an `r4:FHIRError` if any chunk's query fails
isolated function getConceptRefsByIds(int[] conceptIds) returns map<[string, string?, string]>|r4:FHIRError {
    map<[string, string?, string]> refsByConceptId = {};
    int offset = 0;
    while offset < conceptIds.length() {
        int chunkEnd = offset + BULK_LOOKUP_CHUNK_SIZE > conceptIds.length() ? conceptIds.length() : offset + BULK_LOOKUP_CHUNK_SIZE;
        int[] chunk = conceptIds.slice(offset, chunkEnd);
        offset = chunkEnd;

        sql:ParameterizedQuery[] idFragments = [];
        boolean first = true;
        foreach int id in chunk {
            if !first {
                idFragments.push(`, `);
            }
            idFragments.push(`${id}`);
            first = false;
        }
        sql:ParameterizedQuery query = sql:queryConcat(
                `SELECT c.`, escapeToQuery("conceptId"), `, c.`, escapeToQuery("code"), `, c.`, escapeToQuery("display"), `, cs.`, escapeToQuery("url"),
                ` FROM `, escapeToQuery("concepts"), ` c`,
                ` JOIN `, escapeToQuery("codesystems"), ` cs ON c.`, escapeToQuery("codesystemCodeSystemId"), ` = cs.`, escapeToQuery("codeSystemId"),
                ` WHERE c.`, escapeToQuery("conceptId"), ` IN (`, sql:queryConcat(...idFragments), `)`);
        stream<record {|int conceptId; string code; string? display; string url;|}, persist:Error?> resultStream = sClient->queryNativeSQL(query);
        record {|int conceptId; string code; string? display; string url;|}[]|error rows = from var r in resultStream
            select r;
        if rows is error {
            return r4:createFHIRError(
                    "Error while resolving concept references: " + rows.message(),
                    r4:ERROR,
                    r4:PROCESSING,
                    cause = rows,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
        foreach var row in rows {
            refsByConceptId[row.conceptId.toString()] = [row.code, row.display, row.url];
        }
    }
    return refsByConceptId;
}

# Turns newly-discovered (and any resynced) subsumption pairs into a ConceptMap, one group per (descendant-system, ancestor-system) pair, with each element mapping a descendant code to its ancestor via a "subsumes" equivalence. Unmatched input concepts get their own element with an "unmatched" target, per the `$closure` spec.
#
# + name - Name of the closure table the pairs belong to
# + 'version - Version number to stamp on the resulting ConceptMap
# + pairs - Subsumption pairs to convert into map elements
# + unmatched - Client-supplied concepts that couldn't be resolved to stored concepts
# + return - The built `r4:ConceptMap`, or an `r4:FHIRError` on failure
isolated function buildClosureConceptMap(string name, int 'version, ClosureTablePairRow[] pairs, UnmatchedClosureConcept[] unmatched)
        returns r4:ConceptMap|r4:FHIRError {
    // Group pairs by (sourceSystem, targetSystem) - always the same system for
    // a within-CodeSystem is-a closure, but kept general in case cross-system
    // relationships are ever added to concept_closure.
    map<r4:ConceptMapGroupElement[]> elementsBySystemPair = {};

    map<boolean> seenConceptIds = {};
    int[] distinctConceptIds = [];
    foreach ClosureTablePairRow pair in pairs {
        foreach int id in [pair.descendantConceptId, pair.ancestorConceptId] {
            string idKey = id.toString();
            if seenConceptIds.hasKey(idKey) {
                continue;
            }
            seenConceptIds[idKey] = true;
            distinctConceptIds.push(id);
        }
    }
    map<[string, string?, string]> conceptRefsById = check getConceptRefsByIds(distinctConceptIds);

    foreach ClosureTablePairRow pair in pairs {
        [string, string?, string]? descendantRef = conceptRefsById[pair.descendantConceptId.toString()];
        [string, string?, string]? ancestorRef = conceptRefsById[pair.ancestorConceptId.toString()];
        if descendantRef is () || ancestorRef is () {
            continue;
        }
        [string, string?, string] [descCode, descDisplay, descSystem] = descendantRef;
        [string, string?, string] [ancCode, ancDisplay, ancSystem] = ancestorRef;

        string groupKey = descSystem + "|" + ancSystem;
        r4:ConceptMapGroupElement[] groupElements = elementsBySystemPair[groupKey] ?: [];
        groupElements.push({
            code: descCode,
            display: descDisplay,
            target: [
                {code: ancCode, display: ancDisplay, equivalence: "subsumes"}
            ]
        });
        elementsBySystemPair[groupKey] = groupElements;
    }

    foreach UnmatchedClosureConcept u in unmatched {
        string groupKey = (u.system ?: "") + "|" + (u.system ?: "");
        r4:ConceptMapGroupElement[] groupElements = elementsBySystemPair[groupKey] ?: [];
        groupElements.push({
            code: u.code,
            target: [
                {equivalence: "unmatched"}
            ]
        });
        elementsBySystemPair[groupKey] = groupElements;
    }

    r4:ConceptMapGroup[] groups = [];
    foreach [string, r4:ConceptMapGroupElement[]] [groupKey, elements] in elementsBySystemPair.entries() {
        string[] parts = re `\|`.split(groupKey);
        groups.push({
            'source: parts.length() > 0 ? parts[0] : (),
            target: parts.length() > 1 ? parts[1] : (),
            element: elements
        });
    }

    r4:ConceptMap conceptMap = {
        resourceType: "ConceptMap",
        id: uuid:createType4AsString(),
        status: "active",
        'version: 'version.toString()
    };
    if groups.length() > 0 {
        conceptMap.group = groups;
    }
    return conceptMap;
}

# Checks whether a CodeSystem's hierarchy is stored in the closure table (e.g. SNOMED).
#
# + codeSystemId - Internal id of the CodeSystem to check
# + return - `true` if closure rows exist for the CodeSystem, `false` otherwise
isolated function hasClosureRows(int codeSystemId) returns boolean {
    sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT 1 FROM `, escapeToQuery("concept_closure"),
            ` WHERE `, escapeToQuery("codeSystemId"), ` = ${codeSystemId} LIMIT 1`);
    stream<record {}, persist:Error?> resultStream = sClient->queryNativeSQL(query);
    record {}[]|error results = from record {} r in resultStream
        select r;
    return results is error ? false : results.length() > 0;
}

# Finds every descendant of a concept by walking parent links, for CodeSystems that don't have a closure table (e.g. LOINC).
#
# + codeSystemId - Internal id of the CodeSystem to search within
# + anchorCode - Code of the anchor concept whose descendants are collected
# + includeSelf - Whether to include the anchor concept itself in the result
# + textFilter - Optional case-insensitive substring filter applied to concept display text
# + return - Matching concepts as `r4:ValueSetExpansionContains` entries
isolated function parentWalkDescendants(int codeSystemId, string anchorCode, boolean includeSelf, string? textFilter) returns r4:ValueSetExpansionContains[] {
    r4:ValueSetExpansionContains[] members = [];

    store_h2:Concept|r4:FHIRError anchor = getStoreConceptByCode(codeSystemId, anchorCode);
    if anchor is r4:FHIRError {
        return members;
    }

    if includeSelf {
        r4:CodeSystemConcept|error anchorConcept = byteToConcept(anchor.concept);
        if anchorConcept is r4:CodeSystemConcept {
            boolean passesFilter = true;
            if textFilter is string {
                // Unlike every other filter site, a display-less anchor is
                // dropped rather than kept - preserved here as-is, since it
                // predates this and is a separate question.
                passesFilter = anchorConcept.display is string
                    && displayMatchesTextFilter(anchorConcept.display, textFilter);
            }
            if passesFilter {
                members.push({code: anchorConcept.code, display: anchorConcept.display, id: anchorConcept.id});
            }
        }
    }

    int[] frontier = [anchor.conceptId];
    while frontier.length() > 0 {
        // One query per level (parentConceptId IN (...frontier)) instead of
        // one per node in the frontier - a wide hierarchy (many siblings at
        // the same level) would otherwise add one DB round trip per node.
        sql:ParameterizedQuery[] parentIdFragments = [];
        boolean first = true;
        foreach int parentId in frontier {
            if !first {
                parentIdFragments.push(`, `);
            }
            parentIdFragments.push(`${parentId}`);
            first = false;
        }
        sql:ParameterizedQuery query = sql:queryConcat(
                `SELECT * FROM `, escapeToQuery("concepts"),
                ` WHERE `, escapeToQuery("parentConceptId"), ` IN (`, sql:queryConcat(...parentIdFragments), `)`,
                ` AND `, escapeToQuery("codesystemCodeSystemId"), ` = ${codeSystemId}`);
        stream<store_h2:Concept, persist:Error?> childStream = sClient->queryNativeSQL(query);
        store_h2:Concept[]|error children = from store_h2:Concept c in childStream
            select c;
        if children is error {
            break;
        }

        int[] nextFrontier = [];
        foreach store_h2:Concept child in children {
            nextFrontier.push(child.conceptId);

            r4:CodeSystemConcept|error childConcept = byteToConcept(child.concept);
            if childConcept is error {
                continue;
            }
            if textFilter is string && !displayMatchesTextFilter(childConcept.display, textFilter) {
                continue;
            }
            members.push({code: childConcept.code, display: childConcept.display, id: childConcept.id});
        }
        frontier = nextFrontier;
    }

    return members;
}

# Keeps entries of `a` whose code also appears in `b`, used to AND together multiple filters on the same compose.include.
#
# + a - Entries to filter
# + b - Entries whose codes are used as the allow-list
# + return - The subset of `a` whose code is present in `b`
isolated function intersectByCode(r4:ValueSetExpansionContains[] a, r4:ValueSetExpansionContains[] b) returns r4:ValueSetExpansionContains[] {
    map<boolean> codesInB = {};
    foreach var entry in b {
        if entry.code is string {
            codesInB[<string>entry.code] = true;
        }
    }
    r4:ValueSetExpansionContains[] result = [];
    foreach var entry in a {
        if entry.code is string && codesInB.hasKey(<string>entry.code) {
            result.push(entry);
        }
    }
    return result;
}

# Compares two strings for exact equality; used as the comparator for the `=` filter operator.
#
# + actual - Value to test
# + target - Value to compare against
# + return - `true` if `actual` equals `target`, `false` otherwise
isolated function stringEquals(string actual, string target) returns boolean => actual == target;

# Full-string regex match (Java Pattern semantics), used as the comparator for the `regex` filter operator. Client-supplied patterns that look catastrophically-backtracking are rejected (treated as a non-match) rather than evaluated - see `isPathologicalRegex`.
#
# + actual - Value to test
# + pattern - Regex pattern to match against
# + return - `true` if `actual` fully matches `pattern` and `pattern` isn't flagged as pathological, `false` otherwise
isolated function regexMatches(string actual, string pattern) returns boolean {
    if isPathologicalRegex(pattern) {
        return false;
    }
    return regex:matches(actual, pattern);
}

# Heuristically flags "obviously pathological" regex patterns before they ever reach the (backtracking) regex engine - specifically, a quantifier (+, *, {n,m}) applied directly around a group whose own content already contains a quantifier, e.g. ((a+)+)+. That shape is the textbook trigger for catastrophic backtracking: on a long input that almost-but-doesn't match, a backtracking engine (Java's java.util.regex, which `regex:matches` is backed by) can take exponential time working through every way to split the input among the nested repetitions, so even a few dozen characters can mean an effectively infinite hang. This is a heuristic, not a full static analysis of the pattern: it catches the common, well-known nested-quantifier family (including the exact shape the HL7 tx-ecosystem "regex-bad" conformance tests probe for), but not every possible ReDoS shape - e.g. ambiguous alternation like (a|ab)*c isn't structurally a nested quantifier, so it passes through unflagged.
#
# + pattern - Regex pattern to inspect
# + return - `true` if the pattern matches the known nested-quantifier ReDoS shape, `false` otherwise
isolated function isPathologicalRegex(string pattern) returns boolean {
    boolean[] groupHasQuantifier = [];
    boolean inCharClass = false;
    int i = 0;
    int len = pattern.length();
    while i < len {
        string c = pattern.substring(i, i + 1);

        if c == "\\" {
            // Escaped character - skip it and whatever it's escaping without
            // interpreting either as special.
            i += 2;
            continue;
        }

        if inCharClass {
            if c == "]" {
                inCharClass = false;
            }
            i += 1;
            continue;
        }
        if c == "[" {
            inCharClass = true;
            i += 1;
            continue;
        }

        if c == "(" {
            groupHasQuantifier.push(false);
            i += 1;
            continue;
        }

        if c == ")" {
            boolean hadQuantifier = groupHasQuantifier.length() > 0 ? groupHasQuantifier.remove(groupHasQuantifier.length() - 1) : false;
            // A quantifier nested inside this group also taints whichever
            // group encloses it, in case of deeper nesting like (((a+))+)+.
            if hadQuantifier && groupHasQuantifier.length() > 0 {
                groupHasQuantifier[groupHasQuantifier.length() - 1] = true;
            }
            i += 1;
            if hadQuantifier && i < len {
                string next = pattern.substring(i, i + 1);
                if next == "+" || next == "*" || next == "{" {
                    return true;
                }
            }
            continue;
        }

        if c == "+" || c == "*" || c == "{" {
            foreach int idx in 0 ..< groupHasQuantifier.length() {
                groupHasQuantifier[idx] = true;
            }
        }
        i += 1;
    }
    return false;
}

# Scans a CodeSystem's concepts and keeps the ones matching a filter, using the given comparator (exact match or regex) on a code or property.
#
# + codeSystemId - Internal id of the CodeSystem to search within
# + property - Property code to match against, or `"code"` to match the concept's own code
# + value - Value to compare the property (or code) against, via `matcher`
# + textFilter - Optional case-insensitive substring filter applied to concept display text
# + matcher - Comparator function used to test the property/code value against `value`
# + exactMatch - Whether `matcher` tests exact equality; lets a filter on `code` be resolved as a SQL predicate rather than by scanning every concept
# + return - Matching concepts as `r4:ValueSetExpansionContains` entries
isolated function filterConceptsByProperty(int codeSystemId, string property, string value, string? textFilter,
        isolated function (string actual, string target) returns boolean matcher, boolean exactMatch = false)
    returns r4:ValueSetExpansionContains[] {
    r4:ValueSetExpansionContains[] members = [];

    sql:ParameterizedQuery query = sql:queryConcat(escapeToQuery("codesystemCodeSystemId"), ` = ${codeSystemId}`);

    // `code` is a column, so an exact filter on it is a predicate rather than a
    // scan. Every other property lives inside the serialized concept blob,
    // which SQL can't reach - those still have to be read and tested here.
    boolean codeMatchedInSql = property == "code" && exactMatch;
    if codeMatchedInSql {
        query = sql:queryConcat(query, ` AND `, escapeToQuery("code"), ` = ${value}`);
    }

    string? inMemoryFilter = textFilter;
    if textFilter is string && isPlainTextFilter(textFilter) {
        query = sql:queryConcat(query, displayContainsFragment(escapeToQuery("display"), textFilter));
        inMemoryFilter = ();
    }

    // Streamed rather than collected into a `store_h2:Concept[]` first: only the
    // matching entries are held, not every concept in the CodeSystem.
    stream<store_h2:Concept, persist:Error?> conceptStream = sClient->/concepts(store_h2:Concept, query);
    error? iterationError = from store_h2:Concept dbConcept in conceptStream
        do {
            r4:CodeSystemConcept|error concept = byteToConcept(dbConcept.concept);
            if concept is r4:CodeSystemConcept {
                boolean matches = codeMatchedInSql;
                if !matches && property == "code" {
                    matches = matcher(concept.code, value);
                } else if !matches && concept.property is r4:CodeSystemConceptProperty[] {
                    foreach var prop in <r4:CodeSystemConceptProperty[]>concept.property {
                        if prop.code == property {
                            string? propValue = propertyValueAsString(prop);
                            if propValue is string && matcher(propValue, value) {
                                matches = true;
                                break;
                            }
                        }
                    }
                }
                if matches && (inMemoryFilter is () || displayMatchesTextFilter(concept.display, inMemoryFilter)) {
                    members.push({code: concept.code, display: concept.display, id: concept.id});
                }
            }
        };
    if iterationError is error {
        return members;
    }

    return members;
}

# Returns a concept property's value as plain text, whatever type it's stored as.
#
# + prop - Concept property to read the value from
# + return - The property's value as a string, or `()` if none of the supported value types is set
isolated function propertyValueAsString(r4:CodeSystemConceptProperty prop) returns string? {
    if prop.valueString is string {
        return <string>prop.valueString;
    }
    if prop.valueCode is r4:code {
        return <string>prop.valueCode;
    }
    if prop.valueBoolean is boolean {
        return prop.valueBoolean.toString();
    }
    if prop.valueInteger is int {
        return prop.valueInteger.toString();
    }
    return ();
}

# Walks up the parent chain from a concept node to check whether a target ancestor id is reached.
#
# + targetAncestorId - Internal concept id to search for among the ancestors
# + currentNode - Node to start walking up from
# + return - `true` if `targetAncestorId` is found while walking up, `false` otherwise
isolated function isInParentChain(int targetAncestorId, ConceptNode currentNode) returns boolean {
    int? parentId = currentNode.parentConceptId;

    while parentId is int {
        if parentId == targetAncestorId {
            return true;
        }

        ConceptNode|error nextNode = sClient->/concepts/[parentId](ConceptNode);
        if nextNode is error {
            return false;
        }
        parentId = nextNode.parentConceptId;
    }

    return false;
}

# Checks whether `code` is admitted by every filter on a `compose.include` (AND semantics, matching `expandValueSet`'s intensional-include handling). Unlike `expandValueSet`'s own filter evaluation - which needs the full member list to paginate/dedup across includes - this checks only the one code asked about, via a targeted lookup per filter instead of materializing and scanning every match. That matters at SNOMED scale: a broad `is-a` filter can match hundreds of thousands of concepts, and `$validate-code` only ever needs a yes/no answer for a single code.
#
# + codeSystemId - Internal id of the CodeSystem the filters apply against
# + filters - The include's filters; `code` must pass all of them
# + code - Code to test for membership
# + return - `true` if `code` passes every filter, `false` otherwise (including on an unsupported op/property)
isolated function isCodeAdmittedByComposeFilters(int codeSystemId, r4:ValueSetComposeIncludeFilter[] filters, string code) returns boolean {
    foreach r4:ValueSetComposeIncludeFilter f in filters {
        if !codeSatisfiesComposeFilter(codeSystemId, f, code) {
            return false;
        }
    }
    return true;
}

# Checks whether `code` alone satisfies a single `compose.include.filter`, via a targeted lookup rather than the full-list-then-scan approach `closureMembers`/`parentWalkDescendants`/`filterConceptsByProperty` use (those exist to build `$expand`'s member lists, where the full list is genuinely needed).
#
# + codeSystemId - Internal id of the CodeSystem the filter applies against
# + f - The filter to evaluate
# + code - Code to test
# + return - `true` if `code` satisfies the filter, `false` otherwise (including on an unsupported op/property)
isolated function codeSatisfiesComposeFilter(int codeSystemId, r4:ValueSetComposeIncludeFilter f, string code) returns boolean {
    match f.op {
        "is-a"|"descendent-of" if f.property == "concept" => {
            return isConceptRelatedByClosure(codeSystemId, f.value, code, f.op == "is-a");
        }
        "=" => {
            return conceptCodeMatchesProperty(codeSystemId, code, f.property, f.value, stringEquals);
        }
        "regex" => {
            return conceptCodeMatchesProperty(codeSystemId, code, f.property, f.value, regexMatches);
        }
        _ => {
            return false;
        }
    }
}

# Checks whether `code`'s concept is `anchorCode` itself (when `includeSelf`) or a descendant of it, via a targeted closure-table lookup where a closure exists, or a parent-link walk that stops as soon as `code` is found otherwise (unlike `parentWalkDescendants`, which collects every descendant before the caller can check membership).
#
# + codeSystemId - Internal id of the CodeSystem both codes belong to
# + anchorCode - Code of the ancestor concept
# + code - Code to test
# + includeSelf - Whether `code == anchorCode` itself counts as a match (`is-a` semantics) or not (`descendent-of` semantics)
# + return - `true` if `code` is related to `anchorCode` as described, `false` otherwise (including if either code can't be resolved)
isolated function isConceptRelatedByClosure(int codeSystemId, string anchorCode, string code, boolean includeSelf) returns boolean {
    store_h2:Concept|r4:FHIRError anchor = getStoreConceptByCode(codeSystemId, anchorCode);
    if anchor is r4:FHIRError {
        return false;
    }
    store_h2:Concept|r4:FHIRError target = getStoreConceptByCode(codeSystemId, code);
    if target is r4:FHIRError {
        return false;
    }
    if includeSelf && anchor.conceptId == target.conceptId {
        return true;
    }

    if hasClosureRows(codeSystemId) {
        sql:ParameterizedQuery query = sql:queryConcat(
                `SELECT 1 FROM `, escapeToQuery("concept_closure"),
                ` WHERE `, escapeToQuery("ancestorConceptId"), ` = ${anchor.conceptId}`,
                ` AND `, escapeToQuery("descendantConceptId"), ` = ${target.conceptId}`,
                ` AND `, escapeToQuery("codeSystemId"), ` = ${codeSystemId}`,
                ` AND `, escapeToQuery("depth"), ` >= 1 LIMIT 1`);
        stream<record {}, persist:Error?> resultStream = sClient->queryNativeSQL(query);
        record {}[]|error rows = from record {} r in resultStream
            select r;
        return rows is record {}[] && rows.length() > 0;
    }

    // No closure table for this CodeSystem (e.g. LOINC) - walk down from the
    // anchor via parentConceptId, level by level, stopping as soon as the
    // target concept is found instead of collecting every descendant first.
    int[] frontier = [anchor.conceptId];
    map<boolean> visited = {};
    while frontier.length() > 0 {
        int[] nextFrontier = [];
        foreach int parentId in frontier {
            sql:ParameterizedQuery query = sql:queryConcat(
                    `SELECT `, escapeToQuery("conceptId"), ` FROM `, escapeToQuery("concepts"),
                    ` WHERE `, escapeToQuery("parentConceptId"), ` = ${parentId}`,
                    ` AND `, escapeToQuery("codesystemCodeSystemId"), ` = ${codeSystemId}`);
            stream<record {|int conceptId;|}, persist:Error?> childStream = sClient->queryNativeSQL(query);
            record {|int conceptId;|}[]|error children = from record {|int conceptId;|} r in childStream
                select r;
            if children is error {
                continue;
            }
            foreach var child in children {
                if child.conceptId == target.conceptId {
                    return true;
                }
                string visitedKey = child.conceptId.toString();
                if visited.hasKey(visitedKey) {
                    continue;
                }
                visited[visitedKey] = true;
                nextFrontier.push(child.conceptId);
            }
        }
        frontier = nextFrontier;
    }
    return false;
}

# Checks whether `code`'s concept alone satisfies a `=`/`regex` property filter, by looking up just that one concept instead of loading and testing every concept in the CodeSystem (as `filterConceptsByProperty` does to build `$expand`'s member list).
#
# + codeSystemId - Internal id of the CodeSystem the concept belongs to
# + code - Code to test
# + property - The property code to match (or `"code"` to match the concept's own code)
# + value - The value to compare the property against
# + matcher - Comparator applied between the property's (or code's) value and `value`
# + return - `true` if the concept's `property` value matches, `false` otherwise (including if `code` can't be resolved)
isolated function conceptCodeMatchesProperty(int codeSystemId, string code, string property, string value,
        isolated function (string actual, string target) returns boolean matcher) returns boolean {
    store_h2:Concept|r4:FHIRError storeConcept = getStoreConceptByCode(codeSystemId, code);
    if storeConcept is r4:FHIRError {
        return false;
    }
    r4:CodeSystemConcept|error concept = byteToConcept(storeConcept.concept);
    if concept is error {
        return false;
    }

    if property == "code" {
        return matcher(concept.code, value);
    }
    if concept.property is r4:CodeSystemConceptProperty[] {
        foreach var prop in <r4:CodeSystemConceptProperty[]>concept.property {
            if prop.code != property {
                continue;
            }
            string? propValue = propertyValueAsString(prop);
            if propValue is string && matcher(propValue, value) {
                return true;
            }
        }
    }
    return false;
}

# Finds a concept by code within a ValueSet, searching its included concepts, included CodeSystems, filtered whole-CodeSystem includes, and any nested ValueSets recursively.
#
# + system - Canonical URL of the ValueSet to search
# + code - Code to look up
# + version - Optional version of the ValueSet
# + return - The matching concept's details, or an `r4:FHIRError` if not found
isolated function findConceptInValueSet(r4:uri system, r4:code code, string? version) returns terminology:CodeConceptDetails|r4:FHIRError {
    // check whether the value set exists
    var valueset = getStoreValueSetByURL(system, version);

    if valueset !is store_h2:ValueSet {
        return r4:createFHIRError(
                "CodeSystem not found",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = error("No matching CodeSystem found"),
                httpStatusCode = http:STATUS_NOT_FOUND);
    }

    // checks for valueset concepts
    sql:ParameterizedQuery sqlQuery = sql:queryConcat(
            `SELECT c.* FROM `, escapeToQuery("concepts"),
            ` c JOIN `, escapeToQuery("valueset_compose_include_concepts"), ` vcic ON c.`, escapeToQuery("conceptId"), ` = vcic.`, escapeToQuery("conceptConceptId"),
            `JOIN `, escapeToQuery("valueset_compose_includes"), ` vci ON vcic.`, escapeToQuery("valuesetcomposeValueSetComposeIncludeId"), ` = vci.`, escapeToQuery("valueSetComposeIncludeId"),
            `JOIN "valuesets" vs ON vci.`, escapeToQuery("valuesetValueSetId"), ` = vs.`, escapeToQuery("valueSetId"),
            `WHERE vs.`, escapeToQuery("valueSetId"), ` = ${valueset.valueSetId} AND c.`, escapeToQuery("code"), ` = ${code};`
        );

    store_h2:Concept|r4:FHIRError dbConcept = getStoreConcept(sqlQuery);
    if dbConcept !is r4:FHIRError {
        r4:CodeSystemConcept|error valueSetConcept = byteToConcept(dbConcept.concept);

        if valueSetConcept !is error {
            return {
                url: system,
                concept: valueSetConcept
            };
        }
    }

    // checks for code systems
    sqlQuery = sql:queryConcat(
            `SELECT c.* FROM `, escapeToQuery("concepts"), ` c JOIN `, escapeToQuery("codesystems"), ` cs ON c.`, escapeToQuery("codesystemCodeSystemId"), ` = cs.`, escapeToQuery("codeSystemId"),
            ` JOIN `, escapeToQuery("valueset_compose_includes"), ` vci ON cs.`, escapeToQuery("codeSystemId"), ` = vci.`, escapeToQuery("codeSystemId"),
            ` JOIN `, escapeToQuery("valuesets"), ` vs ON vci.`, escapeToQuery("valuesetValueSetId"), ` = vs.`, escapeToQuery("valueSetId"),
            ` WHERE vs.`, escapeToQuery("valueSetId"), ` = ${valueset.valueSetId} AND c.`, escapeToQuery("code"), ` = ${code};`
    );

    dbConcept = getStoreConcept(sqlQuery);
    if dbConcept !is r4:FHIRError {
        r4:CodeSystemConcept|error valueSetConcept = byteToConcept(dbConcept.concept);

        if valueSetConcept !is error {
            return {
                url: system,
                concept: valueSetConcept
            };
        }
    }

    // checks filtered whole-CodeSystem includes: saveValueSetComposeInclude
    // deliberately skips writing a valueset_compose_includes row for these
    // (membership depends on evaluating the filter, not a static join), so the
    // two checks above never match a code from one. Evaluate the filter
    // directly here instead, using the same per-operator logic $expand's
    // intensional-include handling uses - otherwise a code the filter
    // legitimately admits is reported as "not found".
    r4:ValueSet|error storedVs = byteToValueSet(valueset.valueSet);
    if storedVs is r4:ValueSet {
        r4:ValueSetCompose? composeRules = storedVs.compose;
        if composeRules is r4:ValueSetCompose {
            foreach r4:ValueSetComposeInclude inc in composeRules.include {
                r4:ValueSetComposeIncludeFilter[]? incFilters = inc.filter;
                r4:uri? incSystem = inc.system;
                if incFilters is r4:ValueSetComposeIncludeFilter[] && incFilters.length() > 0 && incSystem is r4:uri {
                    store_h2:CodeSystem|error filterCs = getStoreCodeSystemByURL(incSystem, inc.'version);
                    if filterCs is store_h2:CodeSystem && isCodeAdmittedByComposeFilters(filterCs.codeSystemId, incFilters, code) {
                        store_h2:Concept|r4:FHIRError filteredConcept = getStoreConceptByCode(filterCs.codeSystemId, code);
                        if filteredConcept is store_h2:Concept {
                            r4:CodeSystemConcept|error parsedConcept = byteToConcept(filteredConcept.concept);
                            if parsedConcept !is error {
                                return {
                                    url: system,
                                    concept: parsedConcept
                                };
                            }
                        }
                    }
                }
            }
        }
    }

    // checks for nested valueset references
    sqlQuery = sql:queryConcat(
            `SELECT vs_included.* FROM `, escapeToQuery("valuesets"), ` vs_parent JOIN `, escapeToQuery("valueset_compose_includes"), ` vci ON vs_parent.`, escapeToQuery("valueSetId"), ` = vci.`, escapeToQuery("valuesetValueSetId"),
            ` JOIN `, escapeToQuery("valueset_compose_include_value_sets"), ` vcivs ON vci.`, escapeToQuery("valueSetComposeIncludeId"), ` = vcivs.`, escapeToQuery("valuesetcomposeValueSetComposeIncludeId"),
            ` JOIN `, escapeToQuery("valuesets"), ` vs_included ON vcivs.`, escapeToQuery("valuesetValueSetId"), ` = vs_included.`, escapeToQuery("valueSetId"),
            ` WHERE vs_parent.`, escapeToQuery("valueSetId"), ` = ${valueset.valueSetId};`
    );

    stream<store_h2:ValueSet, persist:Error?> valueSetStream = sClient->queryNativeSQL(sqlQuery);
    store_h2:ValueSet[]|error nestedValueSets = streamToStoreValueSet(valueSetStream);

    if nestedValueSets is error {
        return r4:createFHIRError(
                "Error while searching for Concept, " + nestedValueSets.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = nestedValueSets,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }

    if nestedValueSets.length() > 0 {
        foreach store_h2:ValueSet nestedValueSet in nestedValueSets {
            var result = findConceptInValueSet(nestedValueSet.url, code, nestedValueSet.version);
            if result !is r4:FHIRError {
                return result;
            }
        }
    }

    // not found in the value set
    return r4:createFHIRError(
            "Concept not found",
            r4:ERROR,
            r4:INVALID_REQUIRED,
            cause = error("No matching Concept found"),
            httpStatusCode = http:STATUS_NOT_FOUND);
}

# Finds a concept by code within a CodeSystem.
#
# + system - Canonical URL of the CodeSystem to search
# + code - Code to look up
# + version - Optional version of the CodeSystem
# + return - The matching concept's details, or an `r4:FHIRError` if not found
isolated function findConceptInCodeSystem(r4:uri system, r4:code code, string? version) returns terminology:CodeConceptDetails|r4:FHIRError {
    // check whether the code system exists
    var codeSystem = getStoreCodeSystemByURL(system, version);

    if codeSystem !is store_h2:CodeSystem {
        return r4:createFHIRError(
                "CodeSystem not found",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = error("No matching CodeSystem found"),
                httpStatusCode = http:STATUS_NOT_FOUND);
    }

    var dbConcept = getStoreConceptByCode(codeSystem.codeSystemId, code);
    if dbConcept is error {
        return dbConcept;
    }

    r4:CodeSystemConcept|error codeSystemConcept = byteToConcept(dbConcept.concept);

    if codeSystemConcept is error {
        return r4:createFHIRError(
                "Error while parsing Concept, " + codeSystemConcept.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = codeSystemConcept,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }

    return {
        url: system,
        concept: codeSystemConcept
    };
}

# Retrieves a CodeSystem by its resource id, decoded into a FHIR `r4:CodeSystem`.
#
# + id - Resource id of the CodeSystem
# + version - Optional version; when omitted, the latest version is returned
# + return - The matching `r4:CodeSystem`, or an `error` if not found
isolated function getCodeSystemByID(string id, string? version = ()) returns r4:CodeSystem|error {
    // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
    // https://github.com/ballerina-platform/ballerina-library/issues/7920
    //
    // store_h2:CodeSystem[] codeSystems;
    // if version !is () {
    //     codeSystems = check from store_h2:CodeSystem codesystem in sClient->/codesystems(store_h2:CodeSystem)
    //         where codesystem.id == id && codesystem.'version == version
    //         select codesystem;
    // } else {
    //     codeSystems = check from store_h2:CodeSystem codesystem in sClient->/codesystems(store_h2:CodeSystem)
    //         where codesystem.id == id
    //         order by codesystem.version descending
    //         limit 1
    //         select codesystem;
    // }

    sql:ParameterizedQuery sqlQueryWhereClause = version is ()
        ? sql:queryConcat(escapeToQuery("id"), ` = ${id} ORDER BY `, escapeToQuery("version"), ` DESC LIMIT 1`)
        : sql:queryConcat(escapeToQuery("id"), ` = ${id} AND `, escapeToQuery("version"), ` = ${version}`);

    stream<store_h2:CodeSystem, persist:Error?> codeSystemStream = sClient->/codesystems(store_h2:CodeSystem, whereClause = sqlQueryWhereClause);
    store_h2:CodeSystem[] codeSystems = check streamToStoreCodeSystem(codeSystemStream);

    if codeSystems.length() == 0 {
        return r4:createFHIRError(
                "CodeSystem not found",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = error("No matching CodeSystem found"),
                httpStatusCode = http:STATUS_NOT_FOUND);
    }

    return byteToCodeSystem(codeSystems[0].codeSystem);
}

# Retrieves a CodeSystem by its canonical URL, decoded into a FHIR `r4:CodeSystem`.
#
# + system - Canonical URL of the CodeSystem
# + version - Optional version; when omitted, the latest version is returned
# + return - The matching `r4:CodeSystem`, or an `error` if not found
isolated function getCodeSystemByURL(string system, string? version = ()) returns r4:CodeSystem|error {
    store_h2:CodeSystem storeCodeSystem = check getStoreCodeSystemByURL(system, version);

    return byteToCodeSystem(storeCodeSystem.codeSystem);
}

# Resolves a CodeSystem's internal id back to its canonical URL, so expansion entries pulled up by codeSystemId (rather than by a lookup that already had the URL in hand) can still be tagged with `system`.
#
# + codeSystemId - Internal id of the CodeSystem
# + return - The CodeSystem's canonical URL, or `()` if it couldn't be resolved
isolated function getCodeSystemUrlById(int codeSystemId) returns string? {
    sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT `, escapeToQuery("url"), ` FROM `, escapeToQuery("codesystems"),
            ` WHERE `, escapeToQuery("codeSystemId"), ` = ${codeSystemId}`);
    stream<record {|string url;|}, persist:Error?> resultStream = sClient->queryNativeSQL(query);
    record {|string url;|}[]|error rows = from record {|string url;|} r in resultStream
        select r;
    if rows is error || rows.length() == 0 {
        return ();
    }
    return rows[0].url;
}

# Retrieves the stored (undecoded) CodeSystem row by its canonical URL.
#
# + system - Canonical URL of the CodeSystem
# + version - Optional version; when omitted, the latest version is returned
# + return - The matching `store_h2:CodeSystem` row, or an `error` if not found
isolated function getStoreCodeSystemByURL(string system, string? version = ()) returns store_h2:CodeSystem|error {
    // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
    // https://github.com/ballerina-platform/ballerina-library/issues/7920
    //
    // The recommended approach is:
    // store_h2:CodeSystem[] codeSystems;
    // if version !is () {
    //     codeSystems = check from store_h2:CodeSystem codesystem in sClient->/codesystems(store_h2:CodeSystem)
    //         where codesystem.url == system && codesystem.version == version
    //         select codesystem;
    // } else {
    //     codeSystems = check from store_h2:CodeSystem codesystem in sClient->/codesystems(store_h2:CodeSystem)
    //         where codesystem.url == system
    //         order by codesystem.version descending
    //         limit 1
    //         select codesystem;
    // }

    // url/version is meant to be unique, but a prior load's cleanup can fail and
    // leave a stale duplicate behind (see replacePriorLoads) - ordering by
    // codeSystemId DESC (the newest insert wins) as a tie-breaker ensures that
    // case still resolves to the current load instead of an arbitrary/stale
    // one.
    sql:ParameterizedQuery sqlQueryWhereClause = version is ()
        ? sql:queryConcat(escapeToQuery("url"), ` = ${system} ORDER BY `, escapeToQuery("version"), ` DESC, `,
                escapeToQuery("codeSystemId"), ` DESC LIMIT 1`)
        : sql:queryConcat(escapeToQuery("url"), ` = ${system} AND `, escapeToQuery("version"), ` = ${version}`,
                ` ORDER BY `, escapeToQuery("codeSystemId"), ` DESC LIMIT 1`);

    stream<store_h2:CodeSystem, persist:Error?> codeSystemStream = sClient->/codesystems(store_h2:CodeSystem, whereClause = sqlQueryWhereClause);
    store_h2:CodeSystem[] codeSystems = check streamToStoreCodeSystem(codeSystemStream);

    if codeSystems.length() == 0 {
        return r4:createFHIRError(
                "CodeSystem not found",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = error("No matching CodeSystem found"),
                httpStatusCode = http:STATUS_NOT_FOUND);
    }
    return codeSystems[0];
}

# Retrieves a ValueSet by its resource id, decoded into a FHIR `r4:ValueSet`.
#
# + id - Resource id of the ValueSet
# + version - Optional version; when omitted, the latest version is returned
# + return - The matching `r4:ValueSet`, or an `error` if not found
isolated function getValueSetByID(string id, string? version = ()) returns r4:ValueSet|error {
    // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
    // https://github.com/ballerina-platform/ballerina-library/issues/7920
    //
    // store_h2:ValueSet[] valueSets;
    // if version !is () {
    //     valueSets = check from store_h2:ValueSet valueSet in sClient->/valuesets(store_h2:ValueSet)
    //         where valueSet.id == id && valueSet.version == version
    //         select valueSet;
    // } else {
    //     valueSets = check from store_h2:ValueSet valueSet in sClient->/valuesets(store_h2:ValueSet)
    //         where valueSet.id == id
    //         order by valueSet.version descending
    //         limit 1
    //         select valueSet;
    // }

    sql:ParameterizedQuery sqlQueryWhereClause = version is ()
        ? sql:queryConcat(escapeToQuery("id"), ` = ${id} ORDER BY `, escapeToQuery("version"), ` DESC LIMIT 1`)
        : sql:queryConcat(escapeToQuery("id"), ` = ${id} AND `, escapeToQuery("version"), ` = ${version}`);

    stream<store_h2:ValueSet, persist:Error?> valueSetStream = sClient->/valuesets(store_h2:ValueSet, whereClause = sqlQueryWhereClause);
    store_h2:ValueSet[] valueSets = check streamToStoreValueSet(valueSetStream);

    if valueSets.length() == 0 {
        return r4:createFHIRError(
                "ValueSet not found",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = error("No matching ValueSet found"),
                httpStatusCode = http:STATUS_NOT_FOUND);
    }

    // Assuming byteToValueSet is available similar to byteToCodeSystem
    return byteToValueSet(valueSets[0].valueSet);
}

# Retrieves a ValueSet by its canonical URL, decoded into a FHIR `r4:ValueSet`.
#
# + system - Canonical URL of the ValueSet
# + version - Optional version; when omitted, the latest version is returned
# + return - The matching `r4:ValueSet`, or an `error` if not found
isolated function getValueSetByURL(string system, string? version = ()) returns r4:ValueSet|error {
    store_h2:ValueSet storeValueSet = check getStoreValueSetByURL(system, version);

    return byteToValueSet(storeValueSet.valueSet);
}

# Retrieves the stored (undecoded) ValueSet row by its canonical URL.
#
# + system - Canonical URL of the ValueSet
# + version - Optional version; when omitted, the latest version is returned
# + return - The matching `store_h2:ValueSet` row, or an `error` if not found
isolated function getStoreValueSetByURL(string system, string? version = ()) returns store_h2:ValueSet|error {
    // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
    // https://github.com/ballerina-platform/ballerina-library/issues/7920
    //
    // store_h2:ValueSet[] valueSets;
    // if version !is () {
    //     valueSets = check from store_h2:ValueSet valueSet in sClient->/valuesets(store_h2:ValueSet)
    //         where valueSet.url == system && valueSet.version == version
    //         select valueSet;
    // } else {
    //     valueSets = check from store_h2:ValueSet valueSet in sClient->/valuesets(store_h2:ValueSet)
    //         where valueSet.url == system
    //         order by valueSet.version descending
    //         limit 1
    //         select valueSet;
    // }

    sql:ParameterizedQuery sqlQueryWhereClause = version is ()
        ? sql:queryConcat(escapeToQuery("url"), ` = ${system} ORDER BY `, escapeToQuery("version"), ` DESC LIMIT 1`)
        : sql:queryConcat(escapeToQuery("url"), ` = ${system} AND `, escapeToQuery("version"), ` = ${version}`);

    stream<store_h2:ValueSet, persist:Error?> valueSetStream = sClient->/valuesets(store_h2:ValueSet, whereClause = sqlQueryWhereClause);
    store_h2:ValueSet[] valueSets = check streamToStoreValueSet(valueSetStream);

    if valueSets.length() == 0 {
        return r4:createFHIRError(
                "ValueSet not found",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = error("No matching ValueSet found"),
                httpStatusCode = http:STATUS_NOT_FOUND);
    }
    return valueSets[0];
}

# Retrieves the stored concept row matching a code within a CodeSystem.
#
# + codeSystemId - Internal id of the CodeSystem to search within
# + code - Code to look up
# + return - The matching `store_h2:Concept` row, or an `r4:FHIRError` if not found
isolated function getStoreConceptByCode(int codeSystemId, r4:code code) returns store_h2:Concept|r4:FHIRError {
    // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
    // https://github.com/ballerina-platform/ballerina-library/issues/7920
    //
    // store_h2:Concept[] concepts = check from store_h2:Concept concept in sClient->/concepts(store_h2:Concept)
    //     where concept.code == code && concept.codesystemCodeSystemId == codeSystemId
    //     select concept;
    // 
    // if concepts.length() > 0 {
    //     return concepts[0];
    // } else {
    //     return r4:createFHIRError(
    //             "Concept not found",
    //             r4:ERROR,
    //             r4:INVALID_REQUIRED,
    //             cause = error("No matching Concept found"),
    //             httpStatusCode = http:STATUS_NOT_FOUND);
    // }

    return getStoreConcept(sql:queryConcat(`SELECT * FROM `, escapeToQuery("concepts"), ` WHERE `, escapeToQuery("code"), ` = ${code} AND `, escapeToQuery("codesystemCodeSystemId"), ` = ${codeSystemId}`));
}

# Fetches a concept's direct parents (via `concept_closure` at depth=1, since a concept can have more than one is-a parent - e.g. SNOMED) and direct children (concepts whose `parentConceptId` points at this concept). Used to emit `parent` and `child` property entries in `$lookup` responses.
#
# + system - Canonical URL of the CodeSystem the concept belongs to
# + code - Code of the concept to look up
# + version - Optional version of the CodeSystem
# + return - A `[parents, children]` tuple; both empty if the concept has no parents/children, or if any DB lookup fails
isolated function getConceptHierarchy(r4:uri system, r4:code code, string? version = ())
        returns [r4:CodeSystemConcept[], r4:CodeSystemConcept[]] {
    store_h2:CodeSystem|error storeCs = getStoreCodeSystemByURL(system, version);
    if storeCs is error {
        return [[], []];
    }
    int csId = storeCs.codeSystemId;

    store_h2:Concept|r4:FHIRError storeConcept = getStoreConceptByCode(csId, code);
    if storeConcept is r4:FHIRError {
        return [[], []];
    }
    int myConceptId = storeConcept.conceptId;

    // Parent lookup — direct (depth=1) ancestors from concept_closure. Used
    // instead of the parentConceptId FK, which only ever holds a single parent
    // and is never populated for SNOMED (a concept can have multiple is-a
    // parents there); concept_closure is populated correctly and completely by
    // both the SNOMED and generic nested-CodeSystem import paths.
    r4:CodeSystemConcept[] parents = [];
    sql:ParameterizedQuery parentIdsQuery = sql:queryConcat(
            `SELECT `, escapeToQuery("ancestorConceptId"), ` FROM `, escapeToQuery("concept_closure"),
            ` WHERE `, escapeToQuery("descendantConceptId"), ` = ${myConceptId}`,
            ` AND `, escapeToQuery("codeSystemId"), ` = ${csId}`,
            ` AND `, escapeToQuery("depth"), ` = 1`);
    stream<record {|int ancestorConceptId;|}, persist:Error?> parentIdStream = sClient->queryNativeSQL(parentIdsQuery);
    record {|int ancestorConceptId;|}[]|error parentIdRows = from record {|int ancestorConceptId;|} r in parentIdStream
        select r;
    if parentIdRows is record {|int ancestorConceptId;|}[] {
        foreach var row in parentIdRows {
            sql:ParameterizedQuery parentQuery = sql:queryConcat(
                    `SELECT * FROM `, escapeToQuery("concepts"),
                    ` WHERE `, escapeToQuery("conceptId"), ` = ${row.ancestorConceptId}`);
            store_h2:Concept|r4:FHIRError storeParent = getStoreConcept(parentQuery);
            if storeParent is store_h2:Concept {
                r4:CodeSystemConcept|error parentConcept = byteToConcept(storeParent.concept);
                if parentConcept is r4:CodeSystemConcept {
                    parents.push(parentConcept);
                }
            }
        }
    }

    // Children lookup — direct (depth=1) descendants from concept_closure where
    // a closure exists, for the same reason the parent lookup above doesn't
    // use parentConceptId: SNOMED never populates it (a concept there can have
    // multiple is-a parents, so a single-parent FK can't represent it) - see
    // snomed_import.bal, which always inserts parentConceptId: () for SNOMED
    // concepts. Fall back to parentConceptId only for CodeSystems that have no
    // closure rows (e.g. LOINC), where it's the only source of the hierarchy.
    r4:CodeSystemConcept[] children = [];
    sql:ParameterizedQuery childQuery = hasClosureRows(csId)
        ? sql:queryConcat(
                `SELECT c.* FROM `, escapeToQuery("concepts"), ` c JOIN `, escapeToQuery("concept_closure"), ` cc`,
                ` ON c.`, escapeToQuery("conceptId"), ` = cc.`, escapeToQuery("descendantConceptId"),
                ` WHERE cc.`, escapeToQuery("ancestorConceptId"), ` = ${myConceptId}`,
                ` AND cc.`, escapeToQuery("codeSystemId"), ` = ${csId}`,
                ` AND cc.`, escapeToQuery("depth"), ` = 1`,
                ` ORDER BY c.`, escapeToQuery("code"))
        : sql:queryConcat(
                `SELECT * FROM `, escapeToQuery("concepts"),
                ` WHERE `, escapeToQuery("parentConceptId"), ` = ${myConceptId}`,
                ` AND `, escapeToQuery("codesystemCodeSystemId"), ` = ${csId}`,
                ` ORDER BY `, escapeToQuery("code"));
    stream<store_h2:Concept, persist:Error?> childStream = sClient->queryNativeSQL(childQuery);
    store_h2:Concept[]|error childArr = streamToStoreConcept(childStream);
    if childArr is store_h2:Concept[] {
        foreach var child in childArr {
            r4:CodeSystemConcept|error childConcept = byteToConcept(child.concept);
            if childConcept is r4:CodeSystemConcept {
                children.push(childConcept);
            }
        }
    }

    return [parents, children];
}

# Derives a concept's abstract/inactive flags from its stored properties. `abstract` is set when the concept has property notSelectable=true (or abstract=true); `inactive` is set when the concept has an explicit inactive=true property, an active=false property (as written by the SNOMED importer), or its status property is retired/deprecated.
#
# + system - Canonical URL of the CodeSystem the concept belongs to
# + code - Code of the concept to look up
# + version - Optional version of the CodeSystem
# + return - A `[isAbstract, isInactive]` tuple, defaulting to `[false, false]` if the concept or CodeSystem can't be found
isolated function getConceptFlags(r4:uri system, r4:code code, string? version = ()) returns [boolean, boolean] {
    store_h2:CodeSystem|error storeCs = getStoreCodeSystemByURL(system, version);
    if storeCs is error {
        return [false, false];
    }
    store_h2:Concept|r4:FHIRError storeConcept = getStoreConceptByCode(storeCs.codeSystemId, code);
    if storeConcept is r4:FHIRError {
        return [false, false];
    }
    r4:CodeSystemConcept|error concept = byteToConcept(storeConcept.concept);
    if concept is error {
        return [false, false];
    }

    boolean isAbstract = false;
    boolean isInactive = false;
    if concept.property is r4:CodeSystemConceptProperty[] {
        foreach var prop in <r4:CodeSystemConceptProperty[]>concept.property {
            if (prop.code == "notSelectable" || prop.code == "abstract")
                    && prop.valueBoolean is boolean && <boolean>prop.valueBoolean {
                isAbstract = true;
            }
            if prop.code == "inactive" && prop.valueBoolean is boolean && <boolean>prop.valueBoolean {
                isInactive = true;
            }
            if prop.code == "active" && prop.valueBoolean is boolean && !<boolean>prop.valueBoolean {
                isInactive = true;
            }
            if prop.code == "status" && prop.valueCode is r4:code {
                string s = <string>prop.valueCode;
                if s == "retired" || s == "deprecated" {
                    isInactive = true;
                }
            }
        }
    }
    return [isAbstract, isInactive];
}

# Reads a concept's raw `status` property value (e.g. `"retired"`), if it has one. Unlike `getConceptFlags`, which only derives the boolean `inactive` flag from it, this exposes the actual value - needed to echo it back as an `expansion.contains[].property` entry (via the R4 cross-version extension, since `ValueSetExpansionContains` has no native `property` field), the same way `postProcessExpansion` derives `abstract`/`inactive`.
#
# + system - Canonical URL of the CodeSystem the concept belongs to
# + code - Code of the concept to look up
# + version - Optional version of the CodeSystem
# + return - The concept's `status` property value, or `()` if it has none (or the concept/CodeSystem can't be found)
isolated function getConceptStatusPropertyValue(r4:uri system, r4:code code, string? version = ()) returns string? {
    store_h2:CodeSystem|error storeCs = getStoreCodeSystemByURL(system, version);
    if storeCs is error {
        return ();
    }
    store_h2:Concept|r4:FHIRError storeConcept = getStoreConceptByCode(storeCs.codeSystemId, code);
    if storeConcept is r4:FHIRError {
        return ();
    }
    r4:CodeSystemConcept|error concept = byteToConcept(storeConcept.concept);
    if concept is error {
        return ();
    }
    if concept.property is r4:CodeSystemConceptProperty[] {
        foreach var prop in <r4:CodeSystemConceptProperty[]>concept.property {
            if prop.code == "status" && prop.valueCode is r4:code {
                return <string>prop.valueCode;
            }
        }
    }
    return ();
}

type ConceptRelationshipQueryRow record {|
    int relationshipId;
    int sourceConceptId;
    string typeId;
    int destinationConceptId;
    int codeSystemId;
|};

# Fetches a concept's active non-is-a relationships (clinical attributes: Finding site, Associated morphology, etc, from `concept_relationships`) and resolves the type and destination codes' display text where available. A relationship whose destination concept can't be found is skipped - typeCode/valueCode (SCTIDs) are always meaningful on their own, but a property entry with neither a display for its code nor for its value isn't useful to emit.
#
# + system - Canonical URL of the CodeSystem the concept belongs to
# + code - Code of the concept to look up
# + version - Optional version of the CodeSystem
# + return - Resolved `ConceptAttributeRelationship` entries; a relationship whose destination concept can't be found is skipped
isolated function getConceptAttributeRelationships(r4:uri system, r4:code code, string? version = ())
        returns ConceptAttributeRelationship[] {
    store_h2:CodeSystem|error storeCs = getStoreCodeSystemByURL(system, version);
    if storeCs is error {
        return [];
    }
    int csId = storeCs.codeSystemId;

    store_h2:Concept|r4:FHIRError storeConcept = getStoreConceptByCode(csId, code);
    if storeConcept is r4:FHIRError {
        return [];
    }

    sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT * FROM `, escapeToQuery("concept_relationships"),
            ` WHERE `, escapeToQuery("sourceConceptId"), ` = ${storeConcept.conceptId}`,
            ` AND `, escapeToQuery("codeSystemId"), ` = ${csId}`);
    stream<ConceptRelationshipQueryRow, persist:Error?> relStream = sClient->queryNativeSQL(query);
    ConceptRelationshipQueryRow[]|error rows = from ConceptRelationshipQueryRow r in relStream
        select r;
    if rows is error {
        return [];
    }

    // Resolve every row's type code and destination concept in two bulk
    // queries instead of two round trips per row - a concept with many
    // attribute relationships (common in SNOMED) would otherwise turn one
    // $lookup into 2N+ queries.
    map<boolean> seenTypeIds = {};
    string[] distinctTypeIds = [];
    map<boolean> seenDestIds = {};
    int[] distinctDestIds = [];
    foreach ConceptRelationshipQueryRow row in rows {
        if !seenTypeIds.hasKey(row.typeId) {
            seenTypeIds[row.typeId] = true;
            distinctTypeIds.push(row.typeId);
        }
        string destKey = row.destinationConceptId.toString();
        if !seenDestIds.hasKey(destKey) {
            seenDestIds[destKey] = true;
            distinctDestIds.push(row.destinationConceptId);
        }
    }

    map<string?> typeDisplayByCode = getConceptDisplaysByCode(csId, distinctTypeIds);
    map<[string, string?]> destConceptById = getConceptCodeAndDisplayByIds(distinctDestIds);

    ConceptAttributeRelationship[] resolved = [];
    foreach ConceptRelationshipQueryRow row in rows {
        [string, string?]? destConcept = destConceptById[row.destinationConceptId.toString()];
        if destConcept is [string, string?] {
            resolved.push({
                typeCode: row.typeId,
                typeDisplay: typeDisplayByCode[row.typeId],
                valueCode: destConcept[0],
                valueDisplay: destConcept[1]
            });
        }
    }

    return resolved;
}

# Resolves a batch of concept codes (within one CodeSystem) to their display text, chunking the `IN (...)` clause so a large batch can't exceed a driver's bound-parameter limit.
#
# + codeSystemId - Internal id of the CodeSystem the codes belong to
# + codes - Concept codes to resolve
# + return - A map from code to display text; codes that couldn't be resolved (or decoded), or a chunk whose query failed, are simply absent
isolated function getConceptDisplaysByCode(int codeSystemId, string[] codes) returns map<string?> {
    map<string?> displaysByCode = {};
    int offset = 0;
    while offset < codes.length() {
        int chunkEnd = offset + BULK_LOOKUP_CHUNK_SIZE > codes.length() ? codes.length() : offset + BULK_LOOKUP_CHUNK_SIZE;
        string[] chunk = codes.slice(offset, chunkEnd);
        offset = chunkEnd;

        sql:ParameterizedQuery[] codeFragments = [];
        boolean first = true;
        foreach string code in chunk {
            if !first {
                codeFragments.push(`, `);
            }
            codeFragments.push(`${code}`);
            first = false;
        }
        sql:ParameterizedQuery query = sql:queryConcat(
                `SELECT * FROM `, escapeToQuery("concepts"),
                ` WHERE `, escapeToQuery("codesystemCodeSystemId"), ` = ${codeSystemId}`,
                ` AND `, escapeToQuery("code"), ` IN (`, sql:queryConcat(...codeFragments), `)`);
        stream<store_h2:Concept, persist:Error?> conceptStream = sClient->queryNativeSQL(query);
        store_h2:Concept[]|error dbConcepts = from store_h2:Concept c in conceptStream
            select c;
        if dbConcepts is error {
            continue;
        }
        foreach store_h2:Concept dbConcept in dbConcepts {
            r4:CodeSystemConcept|error decoded = byteToConcept(dbConcept.concept);
            if decoded is r4:CodeSystemConcept {
                displaysByCode[dbConcept.code] = decoded.display;
            }
        }
    }
    return displaysByCode;
}

# Resolves a batch of internal concept ids to their code and display text, chunking the `IN (...)` clause so a large batch can't exceed a driver's bound-parameter limit.
#
# + conceptIds - Internal ids of the concepts to resolve
# + return - A map from conceptId (as string) to `[code, display]`; ids that couldn't be resolved (or decoded), or a chunk whose query failed, are simply absent
isolated function getConceptCodeAndDisplayByIds(int[] conceptIds) returns map<[string, string?]> {
    map<[string, string?]> resultsById = {};
    int offset = 0;
    while offset < conceptIds.length() {
        int chunkEnd = offset + BULK_LOOKUP_CHUNK_SIZE > conceptIds.length() ? conceptIds.length() : offset + BULK_LOOKUP_CHUNK_SIZE;
        int[] chunk = conceptIds.slice(offset, chunkEnd);
        offset = chunkEnd;

        sql:ParameterizedQuery[] idFragments = [];
        boolean first = true;
        foreach int id in chunk {
            if !first {
                idFragments.push(`, `);
            }
            idFragments.push(`${id}`);
            first = false;
        }
        sql:ParameterizedQuery query = sql:queryConcat(
                `SELECT * FROM `, escapeToQuery("concepts"),
                ` WHERE `, escapeToQuery("conceptId"), ` IN (`, sql:queryConcat(...idFragments), `)`);
        stream<store_h2:Concept, persist:Error?> conceptStream = sClient->queryNativeSQL(query);
        store_h2:Concept[]|error dbConcepts = from store_h2:Concept c in conceptStream
            select c;
        if dbConcepts is error {
            continue;
        }
        foreach store_h2:Concept dbConcept in dbConcepts {
            r4:CodeSystemConcept|error decoded = byteToConcept(dbConcept.concept);
            if decoded is r4:CodeSystemConcept {
                resultsById[dbConcept.conceptId.toString()] = [dbConcept.code, decoded.display];
            }
        }
    }
    return resultsById;
}

# Runs a query for a single stored concept row and returns the first match.
#
# + sqlQuery - Parameterized SQL query selecting from the concepts table
# + return - The first matching `store_h2:Concept` row, or an `r4:FHIRError` if the query fails or no row matches
isolated function getStoreConcept(sql:ParameterizedQuery sqlQuery) returns store_h2:Concept|r4:FHIRError {
    stream<store_h2:Concept, persist:Error?> conceptStream = sClient->queryNativeSQL(sqlQuery);
    store_h2:Concept[]|error dbConcepts = streamToStoreConcept(conceptStream);

    if dbConcepts is error {
        return r4:createFHIRError(
                "Error while searching for Concept, " + dbConcepts.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = dbConcepts,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }

    if dbConcepts.length() > 0 {
        return dbConcepts[0];
    }

    // concept not found
    return r4:createFHIRError(
            "Concept not found",
            r4:ERROR,
            r4:INVALID_REQUIRED,
            cause = error("No matching Concept found"),
            httpStatusCode = http:STATUS_NOT_FOUND);
}

# Looks up a concept's node (id, code, parent) by code within a CodeSystem.
#
# + code - Code to look up
# + codeSystemId - Internal id of the CodeSystem to search within
# + return - The matching `ConceptNode`, or an `r4:FHIRError` if the query fails or no concept matches
isolated function getConceptNode(string code, int codeSystemId) returns ConceptNode|r4:FHIRError {
    // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
    // https://github.com/ballerina-platform/ballerina-library/issues/7920
    //
    // The recommended approach is:
    // ConceptNode[] conceptNodes = check from ConceptNode concept in sClient->/concepts(ConceptNode)
    //     where concept.code == code && concept.codesystemCodeSystemId == codeSystemId
    //     select concept;

    sql:ParameterizedQuery sqlQuery = sql:queryConcat(escapeToQuery("code"), ` = ${code} AND `, escapeToQuery("codesystemCodeSystemId"), ` = ${codeSystemId}`);
    stream<ConceptNode, persist:Error?> conceptStream = sClient->/concepts(ConceptNode, whereClause = sqlQuery);

    ConceptNode[]|error dbConcepts = from ConceptNode concept in conceptStream
        select concept;
    if dbConcepts is error {
        return r4:createFHIRError(
                "Error while searching for Concept, " + dbConcepts.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = dbConcepts,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }

    if dbConcepts.length() > 0 {
        return dbConcepts[0];
    }

    // concept not found
    return r4:createFHIRError(
            "Concept not found",
            r4:ERROR,
            r4:INVALID_REQUIRED,
            cause = error("No matching Concept found"),
            httpStatusCode = http:STATUS_NOT_FOUND);
}

# Kicks off asynchronous extraction and persistence of a CodeSystem's top-level concepts.
#
# + codeSystem - CodeSystem whose concepts are to be extracted
# + codeSystemId - Internal id of the already-persisted CodeSystem
isolated function extractConceptsFromCodeSystem(r4:CodeSystem codeSystem, int codeSystemId) {
    if codeSystem.concept !is () {
        r4:CodeSystemConcept[]? concepts = codeSystem.concept;
        // Flow will not go inside this if condition since the code system is already validated for concepts in a previous point
        if concepts !is () {
            foreach var concept in concepts {
                _ = start extractConceptsFromCodeSystemRecursive(concept.clone(), codeSystemId);
            }
        }
    }
}

# Saves a CodeSystem concept and its descendants, and writes the corresponding `concept_closure` rows so is-a / descendent-of / child-of queries can hit an indexed lookup.
#
# + var_concept - Concept to save
# + codeSystemId - Internal id of the CodeSystem the concept belongs to
# + parentId - Internal id of the parent concept, or `()` for a top-level concept
# + ancestorPath - Internal ids of the ancestors on the current recursion path, nearest ancestor last
isolated function extractConceptsFromCodeSystemRecursive(r4:CodeSystemConcept var_concept, int codeSystemId, int? parentId = (), int[] ancestorPath = []) {
    int|error result = saveCodeSystemConcept(var_concept, codeSystemId, parentId);
    if result is error {
        log:printError("Error while saving concept: " + result.message());
        return;
    }
    int conceptDbId = result;

    // Emit concept_closure rows so is-a / descendent-of / child-of queries can hit
    // an indexed lookup instead of the O(N) parentConceptId walk. Every concept
    // gets a depth-0 self row plus one row per ancestor in the current recursion
    // path (depth = distance up the tree). Mirrors what the SNOMED import path
    // does via writeClosure, so both ingest paths converge on the same shape.
    ClosureRow[] closureRows = [{ancestor: conceptDbId, descendant: conceptDbId, depth: 0}];
    foreach int i in 0 ..< ancestorPath.length() {
        closureRows.push({
            ancestor: ancestorPath[i],
            descendant: conceptDbId,
            depth: ancestorPath.length() - i
        });
    }
    int|r4:FHIRError flushed = flushClosureBatch(closureRows, codeSystemId);
    if flushed is r4:FHIRError {
        log:printError("Error writing closure rows for concept " + var_concept.code + ": " + flushed.message());
    }

    if var_concept.concept !is () {
        r4:CodeSystemConcept[]? concepts = var_concept.concept;
        if concepts != () && concepts.length() > 0 {
            int[] childPath = ancestorPath.clone();
            childPath.push(conceptDbId);
            // Recurse in the current strand rather than spawning one per
            // child (`start ...`): a deeply-nested or wide CodeSystem would
            // otherwise spawn an unbounded number of concurrent workers, each
            // holding a DB connection, exhausting the pool and starving
            // concurrent $lookup/$expand requests.
            foreach var subConcept in concepts {
                extractConceptsFromCodeSystemRecursive(subConcept.clone(), codeSystemId, conceptDbId, childPath.clone());
            }
        }
    }
}

# Persists a single CodeSystem concept.
#
# + concept - Concept to persist
# + codeSystemId - Internal id of the CodeSystem the concept belongs to
# + parentId - Internal id of the parent concept, or `()` for a top-level concept
# + return - The newly-inserted concept's internal id, or an `error` if the insert fails
isolated function saveCodeSystemConcept(r4:CodeSystemConcept concept, int codeSystemId, int? parentId) returns int|error {
    store_h2:ConceptInsert dbConceptInsert = {
        code: concept.code,
        display: concept.display,
        definition: concept.definition,
        concept: check conceptToByte(concept),
        codesystemCodeSystemId: codeSystemId,
        parentConceptId: parentId
    };

    int[] id = check sClient->/concepts.post([dbConceptInsert]);
    return id[0];
}

# Extracts and persists a ValueSet's compose.include entries.
#
# + valueSet - ValueSet whose compose includes are to be extracted
# + valueSetId - Internal id of the already-persisted ValueSet
isolated function extractConceptsFromValueSet(r4:ValueSet valueSet, int valueSetId) {
    r4:ValueSetCompose? compose = valueSet.compose;
    if compose !is () {
        foreach r4:ValueSetComposeInclude include in compose.include {
            error? result = saveValueSetComposeInclude(include, valueSetId);
            if result is error {
                log:printError("Error while saving ValueSet concept: " + result.message());
            }
        }
    }
}

# Persists a single `compose.include` entry: its referenced concepts, its whole CodeSystem, or its nested ValueSet references.
#
# + include - Compose include entry to persist
# + valueSetId - Internal id of the ValueSet the entry belongs to
# + return - An `error` if persistence fails, `()` otherwise
isolated function saveValueSetComposeInclude(r4:ValueSetComposeInclude include, int valueSetId) returns error? {
    // concept can be a code system or a set of concepts
    if include.system is r4:uri {
        // find he CodeSystem in the database
        store_h2:CodeSystem codesystem = check getStoreCodeSystemByURL(<string>include.system, include.'version);

        r4:ValueSetComposeIncludeConcept[]? valueSetComposeIncludeConcept = include.concept;
        if valueSetComposeIncludeConcept !is () {
            foreach r4:ValueSetComposeIncludeConcept item in valueSetComposeIncludeConcept {
                // save valueset concept
                _ = start saveValueSetConcept(item.clone(), valueSetId, codesystem.codeSystemId);
            }

        } else {
            r4:ValueSetComposeIncludeFilter[]? filters = include.filter;
            if filters is r4:ValueSetComposeIncludeFilter[] && filters.length() > 0 {
                return;
            }
            // save valueset code system
            _ = start saveValueSetCodeSystem(valueSetId, codesystem.codeSystemId);
        }
    }

    // check for nested ValueSet references
    else if include.valueSet is r4:canonical[] {
        // save valueset reference
        r4:canonical[]? canonicalArray = include.valueSet;
        if canonicalArray !is () {
            _ = start saveValueSetValueSet(valueSetId, canonicalArray.clone());
        }
    }
}

# Persists a reference from a ValueSet compose include to a single concept.
#
# + concept - Compose include concept entry naming the code to reference
# + valueSetId - Internal id of the ValueSet the reference belongs to
# + codeSystemId - Internal id of the CodeSystem the concept's code belongs to
# + return - An `error` if the concept can't be found or persistence fails, `()` otherwise
isolated function saveValueSetConcept(r4:ValueSetComposeIncludeConcept concept, int valueSetId, int codeSystemId) returns error? {
    // find the concept in the database
    store_h2:Concept dbConcept = check getStoreConceptByCode(codeSystemId, concept.code);

    store_h2:ValueSetComposeIncludeInsert dbValueSetComposeIncludeInsert = {
        systemFlag: false,
        valueSetFlag: false,
        conceptFlag: true,
        valuesetValueSetId: valueSetId,
        codeSystemId: ()
    };
    int[] result = check sClient->/valuesetcomposeincludes.post([dbValueSetComposeIncludeInsert]);

    // save the concept reference to the database
    store_h2:ValueSetComposeIncludeConceptInsert dbConceptInsert = {
        valuesetcomposeValueSetComposeIncludeId: result[0],
        conceptConceptId: dbConcept.conceptId
    };
    _ = check sClient->/valuesetcomposeincludeconcepts.post([dbConceptInsert]);
}

# Persists a reference from a ValueSet compose include to an entire CodeSystem.
#
# + valueSetId - Internal id of the ValueSet the reference belongs to
# + codeSystemId - Internal id of the referenced CodeSystem
# + return - An `error` if persistence fails, `()` otherwise
isolated function saveValueSetCodeSystem(int valueSetId, int codeSystemId) returns error? {
    store_h2:ValueSetComposeIncludeInsert dbValueSetComposeIncludeInsert = {
        systemFlag: true,
        valueSetFlag: false,
        conceptFlag: false,
        valuesetValueSetId: valueSetId,
        codeSystemId: codeSystemId
    };
    _ = check sClient->/valuesetcomposeincludes.post([dbValueSetComposeIncludeInsert]);
}

# Persists a reference from a ValueSet compose include to one or more nested ValueSets.
#
# + valueSetId - Internal id of the ValueSet the reference belongs to
# + valueSets - Canonical URLs (optionally with `|version`) of the nested ValueSets
# + return - An `error` if persistence fails, `()` otherwise
isolated function saveValueSetValueSet(int valueSetId, r4:canonical[] valueSets) returns error? {
    // valueset reference can't be with a system or concepts
    store_h2:ValueSetComposeIncludeInsert dbValueSetComposeIncludeInsert = {
        systemFlag: false,
        valueSetFlag: true,
        conceptFlag: false,
        valuesetValueSetId: valueSetId,
        codeSystemId: ()
    };

    int[] result = check sClient->/valuesetcomposeincludes.post([dbValueSetComposeIncludeInsert]);

    check saveNestedValueSetsInValueSetComposeInclude(valueSets, result[0]);
}

# Resolves each nested ValueSet canonical reference to its stored row and persists the link to the compose include.
#
# + valueSets - Canonical URLs (optionally with `|version`) of the nested ValueSets
# + dbValueSetComposeIncludeId - Internal id of the compose include the references belong to
# + return - An `r4:FHIRError` if a referenced ValueSet can't be found, or an `error` if persistence fails; `()` otherwise
isolated function saveNestedValueSetsInValueSetComposeInclude(r4:canonical[] valueSets, int dbValueSetComposeIncludeId) returns error? {
    // find for valueset in the database
    foreach r4:canonical valueSet in valueSets {
        string[] split = regex:split(valueSet, string `\|`);
        var dbValueSet = getStoreValueSetByURL(split[0], split.length() > 1 ? split[1] : ());

        if dbValueSet is error {
            return r4:createFHIRError(
                    "ValueSet not found",
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    cause = error("No matching ValueSet found"),
                    httpStatusCode = http:STATUS_NOT_FOUND);
        }

        // save the value set reference to the database
        store_h2:ValueSetComposeIncludeValueSetInsert dbValueSetInsert = {
            valuesetcomposeValueSetComposeIncludeId: dbValueSetComposeIncludeId,
            valuesetValueSetId: dbValueSet.valueSetId
        };
        _ = check sClient->/valuesetcomposeincludevaluesets.post([dbValueSetInsert]);
    }
}

