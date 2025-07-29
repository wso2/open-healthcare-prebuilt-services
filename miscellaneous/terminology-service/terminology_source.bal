import terminology_service_api.store;

import ballerina/http;
import ballerina/lang.regexp;
import ballerina/log;
import ballerina/persist;
import ballerina/regex;
import ballerina/sql;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.terminology;

final store:Client sClient = check initializeClient();

function initializeClient() returns store:Client|error {
    return new ();
}

public isolated class TerminologySource {
    *terminology:Terminology;

    public isolated function addCodeSystem(r4:CodeSystem codeSystem) returns r4:FHIRError? {
        // add the code system to the database
        store:CodeSystemInsert dbCodeSystemInsert = {
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

    public isolated function addValueSet(r4:ValueSet valueSet) returns r4:FHIRError? {
        // add the value set to the database
        store:ValueSetInsert dbValueSetInsert = {
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

    public isolated function isCodeSystemExist(r4:uri system, string version) returns boolean {
        // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
        // https://github.com/ballerina-platform/ballerina-library/issues/7920
        //
        // The recommended approach is:
        // store:CodeSystem[] codeSystems = check from store:CodeSystem codesystem in sClient->/codesystems(store:CodeSystem)
        //     where codesystem.url == system && codesystem.version == version
        //     select codesystem;
        // return codeSystems.length() > 0;

        sql:ParameterizedQuery sqlQuery = sql:queryConcat(`SELECT 1 FROM `, escapeToQuery("codesystems"), ` WHERE `, escapeToQuery("url"), ` = ${system} AND `, escapeToQuery("version"), ` = ${version} LIMIT 1`);

        stream<record {}, persist:Error?> resultStream = sClient->queryNativeSQL(sqlQuery);
        record {}[]|error results = from record {} result in resultStream
            select result;

        return results is error ? false : results.length() > 0;
    }

    public isolated function isValueSetExist(r4:uri system, string version) returns boolean {
        // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
        // https://github.com/ballerina-platform/ballerina-library/issues/7920
        //
        // store:ValueSet[] valueSets = check from store:ValueSet valueSet in sClient->/valuesets(store:ValueSet)
        //     where valueSet.url == system && valueSet.version == version
        //     select valueSet;
        // return valueSets.length() > 0;

        sql:ParameterizedQuery sqlQuery = sql:queryConcat(`SELECT 1 FROM `, escapeToQuery("valuesets"), ` WHERE `, escapeToQuery("url"), ` = ${system} AND `, escapeToQuery("version"), ` = ${version} LIMIT 1`);

        stream<record {}, persist:Error?> resultStream = sClient->queryNativeSQL(sqlQuery);
        record {}[]|error results = from record {} result in resultStream
            select result;

        return results is error ? false : results.length() > 0;
    }

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
            whereClause = sql:queryConcat(whereClause, getLimitClause(count, offset));
        }

        stream<store:CodeSystem, persist:Error?> codeSystemStream = sClient->/codesystems(store:CodeSystem, whereClause);
        store:CodeSystem[]|error dbCodeSystems = streamToStoreCodeSystem(codeSystemStream);

        if dbCodeSystems is error {
            return r4:createFHIRError(
                    dbCodeSystems.message(),
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    cause = dbCodeSystems,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }

        r4:CodeSystem[] codeSystemArray = [];
        foreach store:CodeSystem dbCodeSystem in dbCodeSystems {
            r4:CodeSystem|error parsedCodeSystem = byteToCodeSystem(dbCodeSystem.codeSystem);
            if parsedCodeSystem is error {
                // Skip this CodeSystem if parsing fails
                continue;
            }
            codeSystemArray.push(parsedCodeSystem);
        }

        return codeSystemArray;
    }

    public isolated function searchValueSet(map<r4:RequestSearchParameter[]> params, int? offset, int? count) returns r4:ValueSet[]|r4:FHIRError {
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
            whereClause = sql:queryConcat(whereClause, getLimitClause(count, offset));
        }

        stream<store:ValueSet, persist:Error?> valueSetStream = sClient->/valuesets(store:ValueSet, whereClause);
        store:ValueSet[]|error dbValueSets = streamToStoreValueSet(valueSetStream);

        if dbValueSets is error {
            return r4:createFHIRError(
                    dbValueSets.message(),
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    cause = dbValueSets,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }

        r4:ValueSet[] valueSetArray = [];
        foreach store:ValueSet dbValueSet in dbValueSets {
            r4:ValueSet|error parsedValueSet = byteToValueSet(dbValueSet.valueSet);
            if parsedValueSet is error {
                // Skip this ValueSet if parsing fails
                continue;
            }
            valueSetArray.push(parsedValueSet);
        }

        return valueSetArray;
    }

    public isolated function expandValueSet(map<r4:RequestSearchParameter[]> searchParameters, r4:ValueSet valueSet, int offset, int count) returns r4:ValueSet|r4:FHIRError {
        store:ValueSet|error dbValueSet = getStoreValueSetByURL(valueSet.url.toString(), valueSet.version);
        if dbValueSet is error {
            return r4:createFHIRError(
                    "ValueSet not found for expansion",
                    r4:ERROR,
                    r4:PROCESSING_NOT_FOUND,
                    cause = dbValueSet,
                    httpStatusCode = http:STATUS_NOT_FOUND);
        }
        int valueSetId = dbValueSet.valueSetId;

        // Get all includes for this ValueSet
        sql:ParameterizedQuery includeQuery = sql:queryConcat(escapeToQuery("valuesetValueSetId"), ` = ${valueSetId}`);
        stream<store:ValueSetComposeInclude, persist:Error?> includeStream = sClient->/valuesetcomposeincludes(store:ValueSetComposeInclude, whereClause = includeQuery);
        store:ValueSetComposeInclude[]|error includes = from store:ValueSetComposeInclude inc in includeStream
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

        foreach store:ValueSetComposeInclude include in includes {
            // If conceptFlag, get concepts from valueset_compose_include_concepts
            if include.conceptFlag {
                sql:ParameterizedQuery q = sql:queryConcat(
                        `SELECT c.* FROM `, escapeToQuery("concepts"), ` c JOIN `, escapeToQuery("valueset_compose_include_concepts"), ` vcic ON c.`, escapeToQuery("conceptId"), ` = vcic.`, escapeToQuery("conceptConceptId"),
                        ` WHERE vcic.`, escapeToQuery("valuesetcomposeValueSetComposeIncludeId"), ` = ${include.valueSetComposeIncludeId}`
                );
                stream<store:Concept, persist:Error?> conceptStream = sClient->queryNativeSQL(q);
                store:Concept[]|error dbConcepts = from store:Concept c in conceptStream
                    select c;
                if dbConcepts is error {
                    continue;
                }
                foreach store:Concept c in dbConcepts {
                    r4:CodeSystemConcept|error concept = byteToConcept(c.concept);
                    if concept is r4:CodeSystemConcept {
                        if filter is string {
                            if concept.display is string && !regexp:isFullMatch(re `.*${filter.toUpperAscii()}.*`, (<string>concept.display).toUpperAscii()) {
                                continue;
                            }
                        }
                        r4:ValueSetExpansionContains exp = {code: concept.code, display: concept.display, id: concept.id};
                        allConcepts.push(exp);
                    }
                }
            }
            // If systemFlag, get all concepts for the code system
            else if include.systemFlag && include.codeSystemId is int {
                sql:ParameterizedQuery query = sql:queryConcat(escapeToQuery("codesystemCodeSystemId"), ` = ${include.codeSystemId}`);
                stream<store:Concept, persist:Error?> conceptStream = sClient->/concepts(store:Concept, query);
                store:Concept[]|error dbConcepts = from store:Concept c in conceptStream
                    select c;
                if dbConcepts is error {
                    continue;
                }
                foreach store:Concept c in dbConcepts {
                    r4:CodeSystemConcept|error concept = byteToConcept(c.concept);
                    if concept is r4:CodeSystemConcept {
                        if filter is string {
                            if concept.display is string && !regexp:isFullMatch(re `.*${filter.toUpperAscii()}.*`, (<string>concept.display).toUpperAscii()) {
                                continue;
                            }
                        }
                        r4:ValueSetExpansionContains exp = {code: concept.code, display: concept.display, id: concept.id};
                        allConcepts.push(exp);
                    }
                }
            }
            // If valueSetFlag, get nested value sets and expand recursively
            else if include.valueSetFlag {
                sql:ParameterizedQuery q = sql:queryConcat(
                        `SELECT vs.* FROM `, escapeToQuery("valuesets"), ` vs JOIN `, escapeToQuery("valueset_compose_include_value_sets"), ` vcivs ON vs.`, escapeToQuery("valueSetId"), ` = vcivs.`, escapeToQuery("valuesetValueSetId"),
                        ` WHERE vcivs.`, escapeToQuery("valuesetcomposeValueSetComposeIncludeId"), ` = ${include.valueSetComposeIncludeId}`
                );
                stream<store:ValueSet, persist:Error?> vsStream = sClient->queryNativeSQL(q);
                store:ValueSet[]|error nestedVS = from store:ValueSet v in vsStream
                    select v;
                if nestedVS is error {
                    continue;
                }
                foreach store:ValueSet v in nestedVS {
                    r4:ValueSet|error parsedVS = byteToValueSet(v.valueSet);
                    if parsedVS is r4:ValueSet {
                        r4:ValueSet|r4:FHIRError expanded = self.expandValueSet(searchParameters, parsedVS, 0, 1000); // Recursively expand, no offset/count for nested
                        if expanded is r4:ValueSet {
                            if expanded.expansion is r4:ValueSetExpansion {
                                r4:ValueSetExpansion expansionVal = <r4:ValueSetExpansion>expanded.expansion;
                                if expansionVal.contains is r4:ValueSetExpansionContains[] {
                                    r4:ValueSetExpansionContains[] containsArr = <r4:ValueSetExpansionContains[]>expansionVal.contains;
                                    foreach r4:ValueSetExpansionContains c in containsArr {
                                        allConcepts.push(c);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Pagination
        int totalCount = allConcepts.length();
        r4:ValueSetExpansionContains[] pagedConcepts;
        if totalCount > offset + count {
            pagedConcepts = allConcepts.slice(offset, offset + count);
        } else if totalCount >= offset {
            pagedConcepts = allConcepts.slice(offset);
        } else {
            pagedConcepts = [];
        }

        r4:ValueSetExpansion expansion = createExpandedValueSet(valueSet, pagedConcepts);
        expansion.total = totalCount;
        expansion.offset = offset;
        valueSet.expansion = expansion.clone();
        return valueSet;
    }

    public isolated function subsumes(r4:uri system, r4:code codeA, r4:code codeB, string? version) returns international401:Parameters|r4:FHIRError {
        var codeSystem = getStoreCodeSystemByURL(system, version);

        if codeSystem !is store:CodeSystem {
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

        ConceptNode conceptA = check getConceptNode(codeA, codeSystem.codeSystemId);
        ConceptNode conceptB = check getConceptNode(codeB, codeSystem.codeSystemId);

        // Check if A is ancestor of B
        boolean aSubsumesB = isInParentChain(conceptA.conceptId, conceptB);
        if aSubsumesB {
            return {'parameter: [{name: terminology:OUTCOME, valueCode: terminology:SUBSUMED}]};
        }

        // Check if B is ancestor of A
        boolean bSubsumesA = isInParentChain(conceptB.conceptId, conceptA);
        if bSubsumesA {
            return {'parameter: [{name: terminology:OUTCOME, valueCode: terminology:SUBSUMED_BY}]};
        }

        return {'parameter: [{name: terminology:OUTCOME, valueCode: terminology:NOT_SUBSUMED}]};
    }

    public isolated function searchConcept(DISPLAY|DEFINITION property, string filter, string? system, int offset, int count) returns terminology:CodeConceptDetails[]|r4:FHIRError {
        sql:ParameterizedQuery whereClause = sql:queryConcat(
                escapeToQuery(property), getRegexOperator(), stringToParameterizedQuery("'.*" + filter + ".*'"),
                    system is () ? `` : sql:queryConcat(` AND c.`, escapeToQuery("url"), ` = ${system}`),
                getLimitClause(count, offset)
        );

        stream<store:ConceptWithRelations, persist:Error?> conceptStream = sClient->/concepts(store:ConceptWithRelations, whereClause);
        store:ConceptWithRelations[]|error dbConcepts = from store:ConceptWithRelations concept in conceptStream
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
        foreach store:ConceptWithRelations dbConcept in dbConcepts {
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
}

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

isolated function findConceptInValueSet(r4:uri system, r4:code code, string? version) returns terminology:CodeConceptDetails|r4:FHIRError {
    // check whether the value set exists
    var valueset = getStoreValueSetByURL(system, version);

    if valueset !is store:ValueSet {
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

    store:Concept|r4:FHIRError dbConcept = getStoreConcept(sqlQuery);
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

    // checks for nested valueset references
    sqlQuery = sql:queryConcat(
            `SELECT vs_included.* FROM `, escapeToQuery("valuesets"), ` vs_parent JOIN `, escapeToQuery("valueset_compose_includes"), ` vci ON vs_parent.`, escapeToQuery("valueSetId"), ` = vci.`, escapeToQuery("valuesetValueSetId"),
            ` JOIN `, escapeToQuery("valueset_compose_include_value_sets"), ` vcivs ON vci.`, escapeToQuery("valueSetComposeIncludeId"), ` = vcivs.`, escapeToQuery("valuesetcomposeValueSetComposeIncludeId"),
            ` JOIN `, escapeToQuery("valuesets"), ` vs_included ON vcivs.`, escapeToQuery("valuesetValueSetId"), ` = vs_included.`, escapeToQuery("valueSetId"),
            ` WHERE vs_parent.`, escapeToQuery("valueSetId"), ` = ${valueset.valueSetId};`
    );

    stream<store:ValueSet, persist:Error?> valueSetStream = sClient->queryNativeSQL(sqlQuery);
    store:ValueSet[]|error nestedValueSets = streamToStoreValueSet(valueSetStream);

    if nestedValueSets is error {
        return r4:createFHIRError(
                "Error while searching for Concept, " + nestedValueSets.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = nestedValueSets,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }

    if nestedValueSets.length() > 0 {
        foreach store:ValueSet nestedValueSet in nestedValueSets {
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

isolated function findConceptInCodeSystem(r4:uri system, r4:code code, string? version) returns terminology:CodeConceptDetails|r4:FHIRError {
    // check whether the code system exists
    var codeSystem = getStoreCodeSystemByURL(system, version);

    if codeSystem !is store:CodeSystem {
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

isolated function getCodeSystemByID(string id, string? version = ()) returns r4:CodeSystem|error {
    // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
    // https://github.com/ballerina-platform/ballerina-library/issues/7920
    //
    // store:CodeSystem[] codeSystems;
    // if version !is () {
    //     codeSystems = check from store:CodeSystem codesystem in sClient->/codesystems(store:CodeSystem)
    //         where codesystem.id == id && codesystem.'version == version
    //         select codesystem;
    // } else {
    //     codeSystems = check from store:CodeSystem codesystem in sClient->/codesystems(store:CodeSystem)
    //         where codesystem.id == id
    //         order by codesystem.version descending
    //         limit 1
    //         select codesystem;
    // }

    sql:ParameterizedQuery sqlQueryWhereClause = version is ()
        ? sql:queryConcat(escapeToQuery("id"), ` = ${id} ORDER BY `, escapeToQuery("version"), ` DESC LIMIT 1`)
        : sql:queryConcat(escapeToQuery("id"), ` = ${id} AND `, escapeToQuery("version"), ` = ${version}`);

    stream<store:CodeSystem, persist:Error?> codeSystemStream = sClient->/codesystems(store:CodeSystem, whereClause = sqlQueryWhereClause);
    store:CodeSystem[] codeSystems = check streamToStoreCodeSystem(codeSystemStream);

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

isolated function getCodeSystemByURL(string system, string? version = ()) returns r4:CodeSystem|error {
    store:CodeSystem storeCodeSystem = check getStoreCodeSystemByURL(system, version);

    return byteToCodeSystem(storeCodeSystem.codeSystem);
}

isolated function getStoreCodeSystemByURL(string system, string? version = ()) returns store:CodeSystem|error {
    // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
    // https://github.com/ballerina-platform/ballerina-library/issues/7920
    //
    // The recommended approach is:
    // store:CodeSystem[] codeSystems;
    // if version !is () {
    //     codeSystems = check from store:CodeSystem codesystem in sClient->/codesystems(store:CodeSystem)
    //         where codesystem.url == system && codesystem.version == version
    //         select codesystem;
    // } else {
    //     codeSystems = check from store:CodeSystem codesystem in sClient->/codesystems(store:CodeSystem)
    //         where codesystem.url == system
    //         order by codesystem.version descending
    //         limit 1
    //         select codesystem;
    // }

    sql:ParameterizedQuery sqlQueryWhereClause = version is ()
        ? sql:queryConcat(escapeToQuery("url"), ` = ${system} ORDER BY `, escapeToQuery("version"), ` DESC LIMIT 1`)
        : sql:queryConcat(escapeToQuery("url"), ` = ${system} AND `, escapeToQuery("version"), ` = ${version}`);

    stream<store:CodeSystem, persist:Error?> codeSystemStream = sClient->/codesystems(store:CodeSystem, whereClause = sqlQueryWhereClause);
    store:CodeSystem[] codeSystems = check streamToStoreCodeSystem(codeSystemStream);

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

isolated function getValueSetByID(string id, string? version = ()) returns r4:ValueSet|error {
    // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
    // https://github.com/ballerina-platform/ballerina-library/issues/7920
    //
    // store:ValueSet[] valueSets;
    // if version !is () {
    //     valueSets = check from store:ValueSet valueSet in sClient->/valuesets(store:ValueSet)
    //         where valueSet.id == id && valueSet.version == version
    //         select valueSet;
    // } else {
    //     valueSets = check from store:ValueSet valueSet in sClient->/valuesets(store:ValueSet)
    //         where valueSet.id == id
    //         order by valueSet.version descending
    //         limit 1
    //         select valueSet;
    // }

    sql:ParameterizedQuery sqlQueryWhereClause = version is ()
        ? sql:queryConcat(escapeToQuery("id"), ` = ${id} ORDER BY `, escapeToQuery("version"), ` DESC LIMIT 1`)
        : sql:queryConcat(escapeToQuery("id"), ` = ${id} AND `, escapeToQuery("version"), ` = ${version}`);

    stream<store:ValueSet, persist:Error?> valueSetStream = sClient->/valuesets(store:ValueSet, whereClause = sqlQueryWhereClause);
    store:ValueSet[] valueSets = check streamToStoreValueSet(valueSetStream);

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

isolated function getValueSetByURL(string system, string? version = ()) returns r4:ValueSet|error {
    store:ValueSet storeValueSet = check getStoreValueSetByURL(system, version);

    return byteToValueSet(storeValueSet.valueSet);
}

isolated function getStoreValueSetByURL(string system, string? version = ()) returns store:ValueSet|error {
    // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
    // https://github.com/ballerina-platform/ballerina-library/issues/7920
    //
    // store:ValueSet[] valueSets;
    // if version !is () {
    //     valueSets = check from store:ValueSet valueSet in sClient->/valuesets(store:ValueSet)
    //         where valueSet.url == system && valueSet.version == version
    //         select valueSet;
    // } else {
    //     valueSets = check from store:ValueSet valueSet in sClient->/valuesets(store:ValueSet)
    //         where valueSet.url == system
    //         order by valueSet.version descending
    //         limit 1
    //         select valueSet;
    // }

    sql:ParameterizedQuery sqlQueryWhereClause = version is ()
        ? sql:queryConcat(escapeToQuery("url"), ` = ${system} ORDER BY `, escapeToQuery("version"), ` DESC LIMIT 1`)
        : sql:queryConcat(escapeToQuery("url"), ` = ${system} AND `, escapeToQuery("version"), ` = ${version}`);

    stream<store:ValueSet, persist:Error?> valueSetStream = sClient->/valuesets(store:ValueSet, whereClause = sqlQueryWhereClause);
    store:ValueSet[] valueSets = check streamToStoreValueSet(valueSetStream);

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

isolated function getStoreConceptByCode(int codeSystemId, r4:code code) returns store:Concept|r4:FHIRError {
    // TODO: Replace the manual query-based search operation below with the commented logic once the following persist issue is resolved:
    // https://github.com/ballerina-platform/ballerina-library/issues/7920
    //
    // store:Concept[] concepts = check from store:Concept concept in sClient->/concepts(store:Concept)
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

isolated function getStoreConcept(sql:ParameterizedQuery sqlQuery) returns store:Concept|r4:FHIRError {
    stream<store:Concept, persist:Error?> conceptStream = sClient->queryNativeSQL(sqlQuery);
    store:Concept[]|error dbConcepts = streamToStoreConcept(conceptStream);

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

isolated function extractConceptsFromCodeSystem(r4:CodeSystem codeSystem, int codeSystemId) {
    if codeSystem.concept !is () {
        foreach var concept in <r4:CodeSystemConcept[]>codeSystem.concept {
            _ = start extractConceptsFromCodeSystemRecursive(concept.clone(), codeSystemId);
        }
    }
}

isolated function extractConceptsFromCodeSystemRecursive(r4:CodeSystemConcept var_concept, int codeSystemId, int? parentId = ()) {
    int|error result = saveCodeSystemConcept(var_concept, codeSystemId, parentId);
    if result is error {
        log:printError("Error while saving concept: " + result.message());
    }

    if var_concept.concept !is () {
        foreach var subConcept in <r4:CodeSystemConcept[]>var_concept.concept {
            _ = start extractConceptsFromCodeSystemRecursive(subConcept.clone(), codeSystemId, (result is int) ? result : ());
        }
    }
}

isolated function saveCodeSystemConcept(r4:CodeSystemConcept concept, int codeSystemId, int? parentId) returns int|error {
    store:ConceptInsert dbConceptInsert = {
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

// Extract concepts from a ValueSet and save them recursively
isolated function extractConceptsFromValueSet(r4:ValueSet valueSet, int valueSetId) {
    if valueSet.compose is r4:ValueSetCompose {
        foreach r4:ValueSetComposeInclude include in (<r4:ValueSetCompose>valueSet.compose).include {
            error? result = saveValueSetComposeInclude(include, valueSetId);
            if result is error {
                log:printError("Error while saving ValueSet concept: " + result.message());
            }
        }
    }
}

// Save a ValueSet concept to the database
isolated function saveValueSetComposeInclude(r4:ValueSetComposeInclude include, int valueSetId) returns error? {
    // concept can be a code system or a set of concepts
    if include.system is r4:uri {
        // find he CodeSystem in the database
        store:CodeSystem codesystem = check getStoreCodeSystemByURL(<string>include.system, include.'version);

        if include.concept is r4:ValueSetComposeIncludeConcept[] {
            foreach r4:ValueSetComposeIncludeConcept item in <r4:ValueSetComposeIncludeConcept[]>include.concept {
                // save valueset concept
                _ = start saveValueSetConcept(item.clone(), valueSetId, codesystem.codeSystemId);
            }
        } else {
            // save valueset code system
            _ = start saveValueSetCodeSystem(valueSetId, codesystem.codeSystemId);
        }
    }

    // check for nested ValueSet references
    else if include.valueSet is r4:canonical[] {
        // save valueset reference
        _ = start saveValueSetValueSet(valueSetId, <r4:canonical[]>include.valueSet.clone());
    }
}

isolated function saveValueSetConcept(r4:ValueSetComposeIncludeConcept concept, int valueSetId, int codeSystemId) returns error? {
    // find the concept in the database
    store:Concept dbConcept = check getStoreConceptByCode(codeSystemId, concept.code);

    store:ValueSetComposeIncludeInsert dbValueSetComposeIncludeInsert = {
        systemFlag: false,
        valueSetFlag: false,
        conceptFlag: true,
        valuesetValueSetId: valueSetId,
        codeSystemId: ()
    };
    int[] result = check sClient->/valuesetcomposeincludes.post([dbValueSetComposeIncludeInsert]);

    // save the concept reference to the database
    store:ValueSetComposeIncludeConceptInsert dbConceptInsert = {
        valuesetcomposeValueSetComposeIncludeId: result[0],
        conceptConceptId: dbConcept.conceptId
    };
    _ = check sClient->/valuesetcomposeincludeconcepts.post([dbConceptInsert]);
}

isolated function saveValueSetCodeSystem(int valueSetId, int codeSystemId) returns error? {
    store:ValueSetComposeIncludeInsert dbValueSetComposeIncludeInsert = {
        systemFlag: true,
        valueSetFlag: false,
        conceptFlag: false,
        valuesetValueSetId: valueSetId,
        codeSystemId: codeSystemId
    };
    _ = check sClient->/valuesetcomposeincludes.post([dbValueSetComposeIncludeInsert]);
}

isolated function saveValueSetValueSet(int valueSetId, r4:canonical[] valueSets) returns error? {
    // valueset reference can't be with a system or concepts
    store:ValueSetComposeIncludeInsert dbValueSetComposeIncludeInsert = {
        systemFlag: false,
        valueSetFlag: true,
        conceptFlag: false,
        valuesetValueSetId: valueSetId,
        codeSystemId: ()
    };

    int[] result = check sClient->/valuesetcomposeincludes.post([dbValueSetComposeIncludeInsert]);

    check saveNestedValueSetsInValueSetComposeInclude(valueSets, result[0]);
}

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
        store:ValueSetComposeIncludeValueSetInsert dbValueSetInsert = {
            valuesetcomposeValueSetComposeIncludeId: dbValueSetComposeIncludeId,
            valuesetValueSetId: dbValueSet.valueSetId
        };
        _ = check sClient->/valuesetcomposeincludevaluesets.post([dbValueSetInsert]);
    }
}
