import ballerina_fhir_server.utils;
import ballerina_fhir_server.utils as mapperUtils;

import ballerina/lang.regexp;
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/health.fhir.r4;
import ballerinax/java.jdbc;

// Server base URL configuration
configurable string baseUrl = "http://localhost:9090";

public class ReadMapper {

    public isolated function init() {
    }

    // Main function to read a single resource by ID
    public isolated function readResourceById(jdbc:Client? jdbcClient, string resourceType, string resourceId, string? sinceFilter = ()) returns json|error {
        if jdbcClient is () {
            return error("JDBC client is not initialized");
        }

        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);

        string sqlQuery = string `SELECT "RESOURCE_JSON", "VERSION_ID", "LAST_UPDATED" FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
        // Filter by _since: only return resource if updated after the given timestamp
        if sinceFilter is string {
            string sqlTimestamp = regexp:replaceAll(re `T`, sinceFilter, " ");
            sqlTimestamp = regexp:replaceAll(re `Z$`, sqlTimestamp, "");
            sqlQuery += string ` AND "LAST_UPDATED" > '${utils:escapeSql(sqlTimestamp)}'`;
        }

        string resourceJsonString;
        int resVersionId;
        time:Civil resLastUpdated;
        string normalizedDbType = mapperUtils:dbType.toLowerAscii().trim();
        if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
            string pgSql = re `"RESOURCE_JSON"`.replaceAll(sqlQuery,
                string `CAST("RESOURCE_JSON" AS TEXT) AS "RESOURCE_JSON"`);
            sql:ParameterizedQuery pgQuery = new RawSQLQuery(pgSql);
            stream<record {|string RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED;|}, sql:Error?> pgStream = jdbcClient->query(pgQuery);
            record {|string RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED;|}[] pgResults = check from var r in pgStream
                select r;
            if pgResults.length() == 0 {
                log:printDebug(string `Resource not found: ${resourceType}/${resourceId}`);
                return error(string `${resourceType}/${resourceId} not found`);
            }
            resourceJsonString = pgResults[0].RESOURCE_JSON;
            resVersionId = pgResults[0].VERSION_ID;
            resLastUpdated = pgResults[0].LAST_UPDATED;
        } else {
            sql:ParameterizedQuery h2Query = new RawSQLQuery(sqlQuery);
            stream<record {|byte[] RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED;|}, sql:Error?> h2Stream = jdbcClient->query(h2Query);
            record {|byte[] RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED;|}[] h2Results = check from var r in h2Stream
                select r;
            if h2Results.length() == 0 {
                return error(string `${resourceType}/${resourceId} not found`);
            }
            resourceJsonString = check string:fromBytes(h2Results[0].RESOURCE_JSON);
            resVersionId = h2Results[0].VERSION_ID;
            resLastUpdated = h2Results[0].LAST_UPDATED;
        }
        json resourceJson = check resourceJsonString.fromJsonString();

        // Add/update meta section with versionId and lastUpdated
        map<json> resourceMap = <map<json>>resourceJson;
        json existingMeta = resourceMap["meta"];
        map<json> metaMap = existingMeta is map<json> ? existingMeta : {};

        metaMap["versionId"] = resVersionId.toString();

        // Format timestamp as ISO 8601 string
        string timestamp = utils:formatTimestampISO8601(resLastUpdated);
        metaMap["lastUpdated"] = timestamp;

        resourceMap["meta"] = metaMap;

        return resourceMap;
    }

    // Search resources with filters - basic implementation
    // Search resources with filters - basic implementation
    public isolated function searchResources(jdbc:Client? jdbcClient, string resourceType, map<string[]> queryParams, r4:PaginationContext? paginationContext = ()) returns json|error {
        if jdbcClient is () {
            return error("JDBC client is not initialized");
        }

        // Get table columns to validate search parameters
        string tableName = utils:getTableName(resourceType);
        string[] tableColumns = check mapperUtils:getTableColumns(jdbcClient, tableName);

        // First, check if there are any custom extension search parameters
        map<string[]> customParams = {};
        map<string[]> standardParams = {};

        foreach var [paramName, paramValues] in queryParams.entries() {
            // Skip control parameters
            if paramName.startsWith("_") || paramName.includes("/") {
                standardParams[paramName] = paramValues;
                continue;
            }

            // Check if this is a custom extension parameter
            boolean isCustom = check self.isCustomSearchParam(jdbcClient, resourceType, paramName);
            if isCustom {
                customParams[paramName] = paramValues;
            } else {
                standardParams[paramName] = paramValues;
            }
        }

        // Get resource IDs from custom extension search if applicable
        string[]? customResourceIds = ();
        if customParams.length() > 0 {
            customResourceIds = check utils:searchResourcesByCustomParams(jdbcClient, resourceType, customParams);

            // If custom search returned no results, return empty bundle
            if customResourceIds is string[] && customResourceIds.length() == 0 {
                return self.createEmptyBundle();
            }
        }

        string primaryKey = utils:getPrimaryKeyColumn(resourceType);

        // Check for reference parameters and query the REFERENCES table
        string[]? matchingResourceIds = ();
        boolean hasReferenceParams = false;

        foreach var [paramName, paramValues] in queryParams.entries() {
            if paramValues.length() == 0 {
                continue;
            }

            string paramValue = paramValues[0];

            // Check if this is a reference parameter
            // Either: 1) paramName contains "/" (e.g., "Patient/123" as key)
            //     or: 2) paramValue contains "/" (e.g., patient=Patient/123)
            boolean isReferenceParam = paramName.includes("/") || paramValue.includes("/");

            if isReferenceParam {
                hasReferenceParams = true;
                string refValue = "";

                // Case 1: paramName is "Patient/123" (old format)
                if paramName.includes("/") {
                    refValue = paramName;
                }
                // Case 2: patient=Patient/123 (proper FHIR search format)
                else {
                    refValue = paramValue;
                }

                string[] parts = regexp:split(re `/`, refValue);
                if parts.length() == 2 {
                    string targetType = parts[0];
                    string targetId = parts[1];

                    // Build query without SOURCE_EXPRESSION filter
                    // The TARGET_RESOURCE_TYPE already provides the specificity we need
                    // (e.g., searching patient=Patient/123 matches any reference to that Patient,
                    //  whether stored as "actor", "patient", "subject", etc.)
                    string refQuery = string `SELECT DISTINCT "SOURCE_RESOURCE_ID" FROM "REFERENCES" WHERE "SOURCE_RESOURCE_TYPE" = '${utils:escapeSql(resourceType)}' AND "TARGET_RESOURCE_TYPE" = '${utils:escapeSql(targetType)}' AND "TARGET_RESOURCE_ID" = '${utils:escapeSql(targetId)}'`;

                    sql:ParameterizedQuery query = new utils:RawSQLQuery(refQuery);

                    stream<record {|string SOURCE_RESOURCE_ID;|}, sql:Error?> refStream = jdbcClient->query(query);
                    record {|string SOURCE_RESOURCE_ID;|}[] refResults = check from var ref in refStream
                        select ref;

                    if refResults.length() == 0 {
                        // No matches found for this reference parameter
                        matchingResourceIds = [];
                        break;
                    }

                    string[] ids = from var ref in refResults
                        select ref.SOURCE_RESOURCE_ID;

                    if matchingResourceIds is () {
                        matchingResourceIds = ids;
                    } else {
                        // Intersect with previously found IDs using map for O(1) lookup
                        map<boolean> idMap = {};
                        foreach string id in matchingResourceIds {
                            idMap[id] = true;
                        }

                        string[] intersection = [];
                        foreach string id in ids {
                            if idMap.hasKey(id) {
                                intersection.push(id);
                            }
                        }
                        matchingResourceIds = intersection;
                    }
                }
            }
        }

        // If reference parameters were used but no matches found, return empty bundle
        if hasReferenceParams && (matchingResourceIds is string[] && matchingResourceIds.length() == 0) {
            json bundle = {
                "resourceType": "Bundle",
                "type": "searchset",
                "total": 0,
                "entry": []
            };
            return bundle;
        }

        // Build WHERE clause for ID filtering if we have reference matches or custom extension matches
        string whereClause = "";

        // Combine reference and custom resource IDs if both exist
        string[]? finalResourceIds = ();
        if matchingResourceIds is string[] && customResourceIds is string[] {
            // Intersect both lists efficiently
            map<boolean> matchingMap = {};
            foreach string id in matchingResourceIds {
                matchingMap[id] = true;
            }

            string[] intersection = [];
            foreach string id in customResourceIds {
                if matchingMap.hasKey(id) {
                    intersection.push(id);
                }
            }
            finalResourceIds = intersection;
        } else if matchingResourceIds is string[] {
            finalResourceIds = matchingResourceIds;
        } else if customResourceIds is string[] {
            finalResourceIds = customResourceIds;
        }

        if finalResourceIds is string[] && finalResourceIds.length() > 0 {
            string idList = string:'join("', '", ...finalResourceIds);
            whereClause = string ` WHERE "${primaryKey}" IN ('${idList}')`;
        } else if finalResourceIds is string[] && finalResourceIds.length() == 0 {
            // No matches from filtering, return empty bundle
            return self.createEmptyBundle();
        }

        // Handle _id parameter
        if queryParams.hasKey("_id") {
            string[] idValues = queryParams.get("_id");
            if idValues.length() > 0 {
                if whereClause == "" {
                    whereClause = string ` WHERE "${primaryKey}" = '${idValues[0]}'`;
                } else {
                    whereClause = whereClause + string ` AND "${primaryKey}" = '${idValues[0]}'`;
                }
            }
        }

        // Handle _profile parameter (search by meta.profile).
        // PostgreSQL: use JSONB containment (@>) so the body GIN index serves
        // the predicate (WORK.md §5.5.1). H2 falls back to LIKE since it has
        // no JSONB / GIN.
        string normalizedDbTypeForProfile = mapperUtils:dbType.toLowerAscii().trim();
        boolean isPgForProfile = normalizedDbTypeForProfile == "postgresql" || normalizedDbTypeForProfile == "postgres";
        if queryParams.hasKey("_profile") {
            string[] profileValues = queryParams.get("_profile");
            if profileValues.length() > 0 {
                string profileUrl = profileValues[0];
                string sanitizedProfile = utils:escapeSql(profileUrl);
                string profilePredicate;
                if isPgForProfile {
                    // {"meta":{"profile":["..."]}} — array containment is
                    // semantic, hits IDX_<Type>TABLE_JSON_GIN.
                    profilePredicate = string `"RESOURCE_JSON" @> '{"meta":{"profile":["${sanitizedProfile}"]}}'::jsonb`;
                } else {
                    profilePredicate = string `"RESOURCE_JSON" LIKE '%"profile":%"${sanitizedProfile}"%'`;
                }
                if whereClause == "" {
                    whereClause = string ` WHERE ${profilePredicate}`;
                } else {
                    whereClause = whereClause + string ` AND ${profilePredicate}`;
                }
            }
        }

        // Handle other search parameters (map to database columns) - skip custom params
        foreach var [paramName, paramValues] in standardParams.entries() {
            if paramValues.length() == 0 {
                continue;
            }

            string paramValue = paramValues[0];

            // Skip already processed parameters
            if paramName == "_id" {
                continue;
            }

            // Skip reference parameters (already processed above)
            // Reference params have "/" BUT not token params (which use | for system|code)
            // Token example: identifier=http://hospital.org|12345 (has "/" but is NOT a reference)
            // Reference example: patient=Patient/123 (has "/" and IS a reference)
            boolean isTokenParam = paramValue.includes("|");
            boolean hasSlash = paramName.includes("/") || paramValue.includes("/");

            if hasSlash && !isTokenParam {
                continue;
            }

            // Skip control params handled outside the WHERE-clause loop:
            //   _count, _include, _revinclude, _profile, _total, _summary, _elements
            if paramName == "_count" || paramName == "_include" || paramName == "_revinclude"
                    || paramName == "_profile" || paramName == "_total"
                    || paramName == "_summary" || paramName == "_elements" {
                continue;
            }

            // Handle other unsupported FHIR control parameters that start with _
            if paramName.startsWith("_") && paramName != "_lastUpdated" && paramName != "_id" {
                return error(string `Unsupported search parameter: ${paramName}. Only common resource parameters of _id, _lastUpdated, _profile, _include, _revinclude, and _total are currently supported.`);
            }

            string operator = "=";
            string searchValue = paramValue;
            string? tokenSystem = ();
            string? tokenCode = ();

            // Process token parameter (already detected above)
            // Token parameters support 4 formats per FHIR spec:
            // 1. [code]: Match code only, any system
            // 2. [system]|[code]: Match both system and code
            // 3. |[code]: Match code where system is absent
            // 4. [system]|: Match system only, any code
            // Note: case 1 vs case 3 (system-absent) are not distinguished —
            // both produce a code-only predicate. JSONB @> can't express the
            // "system must be absent" assertion concisely; the prior LIKE
            // didn't enforce it either, so behavior is unchanged.
            if isTokenParam {
                string[] tokenParts = regexp:split(re `\|`, paramValue);
                if tokenParts.length() == 2 {
                    string systemPart = tokenParts[0];
                    string codePart = tokenParts[1];

                    if systemPart == "" && codePart != "" {
                        // Case 3: |[code] - code with no system (best-effort: code-only)
                        tokenCode = codePart;
                    } else if systemPart != "" && codePart == "" {
                        // Case 4: [system]| - system only, any code
                        tokenSystem = systemPart;
                    } else if systemPart != "" && codePart != "" {
                        // Case 2: [system]|[code] - both system and code
                        tokenSystem = systemPart;
                        tokenCode = codePart;
                    }
                    // If both empty (just "|"), ignore this parameter
                } else {
                    // Case 1: No pipe, just [code] - will be handled as non-token param below
                    isTokenParam = false;
                    searchValue = paramValue;
                }
            }

            // Parse prefix for date/time and numeric parameters (not applicable to token params)
            if !isTokenParam {
                if paramValue.startsWith("gt") {
                    operator = ">";
                    searchValue = paramValue.substring(2);
                } else if paramValue.startsWith("ge") {
                    operator = ">=";
                    searchValue = paramValue.substring(2);
                } else if paramValue.startsWith("lt") {
                    operator = "<";
                    searchValue = paramValue.substring(2);
                } else if paramValue.startsWith("le") {
                    operator = "<=";
                    searchValue = paramValue.substring(2);
                } else if paramValue.startsWith("ne") {
                    operator = "!=";
                    searchValue = paramValue.substring(2);
                } else if paramValue.startsWith("eq") {
                    operator = "=";
                    searchValue = paramValue.substring(2);
                } else if paramValue.startsWith("sa") {
                    // starts after (same as gt)
                    operator = ">";
                    searchValue = paramValue.substring(2);
                } else if paramValue.startsWith("eb") {
                    // ends before (same as lt)
                    operator = "<";
                    searchValue = paramValue.substring(2);
                }
            }

            // Map FHIR search parameter names to database column names
            string? columnName = self.mapSearchParamToColumn(paramName);

            // Validate that the column exists in the table schema
            if columnName is string && !self.arrayContains(tableColumns, columnName) {
                // Column doesn't exist - skip this search parameter
                continue;
            }

            if columnName is string {
                // For token parameters with system|code format.
                // PostgreSQL: use RESOURCE_JSON @> containment so the body GIN
                // index (IDX_<Type>TABLE_JSON_GIN) serves the predicate in
                // O(log N + matches). H2: keep the legacy LIKE on the
                // denormalized column. WORK.md §5.5.2.
                if isTokenParam {
                    string sanitizedSystem = tokenSystem is string ? utils:escapeSql(tokenSystem) : "";
                    string sanitizedCode = tokenCode is string ? utils:escapeSql(tokenCode) : "";
                    string normalizedDbTypeForToken = mapperUtils:dbType.toLowerAscii().trim();
                    boolean isPgForToken = normalizedDbTypeForToken == "postgresql" || normalizedDbTypeForToken == "postgres";

                    // FHIR JSON path heuristic for the @> payload:
                    //   identifier  → {identifier:[{system,value}]}  (array, "value" key)
                    //   *           → {<param>:{coding:[{system,code}]}}  (CodeableConcept)
                    // For unrecognized shapes the @> may not match; this is the
                    // same correctness contract as the prior LIKE — both are
                    // best-effort and don't honor every edge of the FHIR token
                    // spec. The plan in WORK.md §5.7 will replace both with
                    // typed SPIDX side tables.
                    string jsonPath = paramName.toLowerAscii();
                    boolean isIdentifierShape = jsonPath == "identifier";
                    string codeKey = isIdentifierShape ? "value" : "code";

                    string predicate;
                    if isPgForToken {
                        string innerObj;
                        if tokenSystem is string && tokenCode is string {
                            innerObj = string `{"system":"${sanitizedSystem}","${codeKey}":"${sanitizedCode}"}`;
                        } else if tokenCode is string {
                            innerObj = string `{"${codeKey}":"${sanitizedCode}"}`;
                        } else if tokenSystem is string {
                            innerObj = string `{"system":"${sanitizedSystem}"}`;
                        } else {
                            innerObj = "";
                        }

                        if innerObj == "" {
                            predicate = "";
                        } else if isIdentifierShape {
                            predicate = string `"RESOURCE_JSON" @> '{"identifier":[${innerObj}]}'::jsonb`;
                        } else {
                            predicate = string `"RESOURCE_JSON" @> '{"${jsonPath}":{"coding":[${innerObj}]}}'::jsonb`;
                        }
                    } else {
                        // H2 fallback: original LIKE-on-denormalized-column logic.
                        if tokenSystem is string && tokenCode is string {
                            predicate = string `(${columnName} LIKE '%"system":"${sanitizedSystem}"%' OR ${columnName} LIKE '%"system": "${sanitizedSystem}"%') AND (${columnName} LIKE '%"${codeKey}":"${sanitizedCode}"%' OR ${columnName} LIKE '%"${codeKey}": "${sanitizedCode}"%')`;
                        } else if tokenCode is string {
                            predicate = string `(${columnName} LIKE '%"${codeKey}":"${sanitizedCode}"%' OR ${columnName} LIKE '%"${codeKey}": "${sanitizedCode}"%')`;
                        } else if tokenSystem is string {
                            predicate = string `("${columnName}" LIKE '%"system":"${sanitizedSystem}"%' OR "${columnName}" LIKE '%"system": "${sanitizedSystem}"%')`;
                        } else {
                            predicate = "";
                        }
                    }

                    if predicate != "" {
                        if whereClause == "" {
                            whereClause = string ` WHERE ${predicate}`;
                        } else {
                            whereClause = whereClause + string ` AND ${predicate}`;
                        }
                    }
                }
                // Case 1: [code] only (no pipe) - Use LIKE for string columns to support partial matching
                else if operator == "=" {
                    string sanitizedValue = utils:escapeSql(searchValue);
                    if whereClause == "" {
                        whereClause = string ` WHERE "${columnName}" LIKE '%${sanitizedValue}%'`;
                    } else {
                        whereClause = whereClause + string ` AND "${columnName}" LIKE '%${sanitizedValue}%'`;
                    }
                } else {
                    // Use exact comparison for date/numeric operators
                    string sanitizedValue = utils:escapeSql(searchValue);
                    if whereClause == "" {
                        whereClause = string ` WHERE "${columnName}" ${operator} '${sanitizedValue}'`;
                    } else {
                        whereClause = whereClause + string ` AND "${columnName}" ${operator} '${sanitizedValue}'`;
                    }
                }
            }
        }

        // Calculate total count before pagination — but only if the caller asked.
        // FHIR R4 §3.1.0 Bundle: `total` is optional for searchset bundles. The
        // unconditional COUNT(*) was duplicating every search's work; per
        // WORK.md §5.8 we now honor `_total=none|estimate|accurate` and default
        // to "none" so the search planner does one scan instead of two.
        // - none     : skip COUNT entirely (Bundle.total omitted).
        // - estimate : use pg_class.reltuples (PG only); on H2 falls back to none.
        // - accurate : run the full COUNT(*) (the previous unconditional path).
        // See https://www.hl7.org/fhir/search.html#total
        int? totalCount = ();
        string totalMode = "none";
        if queryParams.hasKey("_total") {
            string[] vals = queryParams.get("_total");
            if vals.length() > 0 {
                string v = vals[0].toLowerAscii();
                if v == "accurate" || v == "estimate" || v == "none" {
                    totalMode = v;
                }
            }
        }
        string normalizedDbTypeForCount = mapperUtils:dbType.toLowerAscii().trim();
        boolean isPg = normalizedDbTypeForCount == "postgresql" || normalizedDbTypeForCount == "postgres";
        if totalMode == "accurate" {
            string countQuery = string `SELECT COUNT(*) AS "COUNT" FROM "${tableName}"${whereClause}`;
            log:printDebug(string `Executing accurate count query for resource type: ${resourceType}`);
            sql:ParameterizedQuery cQuery = new RawSQLQuery(countQuery);
            record {|int COUNT;|}? countResult = check jdbcClient->queryRow(cQuery);
            if countResult != () {
                totalCount = countResult.COUNT;
            }
        } else if totalMode == "estimate" && isPg && whereClause == "" {
            // Cheap planner-stat estimate; only meaningful for unfiltered counts.
            // Filtered estimates would need EXPLAIN parsing — defer.
            sql:ParameterizedQuery cQuery = `SELECT reltuples::BIGINT AS "COUNT" FROM pg_class WHERE relname = ${tableName}`;
            record {|int COUNT;|}? estResult = check jdbcClient->queryRow(cQuery);
            if estResult != () {
                totalCount = estResult.COUNT;
            }
        }

        // Add pagination clause
        string paginationClause = "";
        if paginationContext is r4:PaginationContext {
            int pageSize = paginationContext.pageSize;
            int page = paginationContext.page;
            int offset = (page - 1) * pageSize;
            paginationClause = string ` LIMIT ${pageSize} OFFSET ${offset}`;
        }

        string sqlQuery = string `SELECT "${primaryKey}", "RESOURCE_JSON", "VERSION_ID", "LAST_UPDATED" FROM "${tableName}"${whereClause}${paginationClause}`;

        record {|string RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED; string...;|}[] results;
        string normalizedDbType2 = mapperUtils:dbType.toLowerAscii().trim();
        if normalizedDbType2 == "postgresql" || normalizedDbType2 == "postgres" {
            string pgSql = re `"RESOURCE_JSON"`.replaceAll(sqlQuery,
                string `CAST("RESOURCE_JSON" AS TEXT) AS "RESOURCE_JSON"`);
            sql:ParameterizedQuery pgQuery = new RawSQLQuery(pgSql);
            stream<record {|string RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED; string...;|}, sql:Error?> pgStream = jdbcClient->query(pgQuery);
            results = check from var r in pgStream
                select r;
        } else {
            sql:ParameterizedQuery h2Query = new RawSQLQuery(sqlQuery);
            stream<record {|byte[] RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED; string...;|}, sql:Error?> h2Stream = jdbcClient->query(h2Query);
            record {|byte[] RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED; string...;|}[] h2Results = check from var r in h2Stream
                select r;
            results = [];
            foreach var r in h2Results {
                string jsonStr = check string:fromBytes(r.RESOURCE_JSON);
                record {|string RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED; string...;|} converted = {RESOURCE_JSON: jsonStr, VERSION_ID: r.VERSION_ID, LAST_UPDATED: r.LAST_UPDATED};
                foreach var [k, v] in r.entries() {
                    if k != "RESOURCE_JSON" && k != "VERSION_ID" && k != "LAST_UPDATED" && v is string {
                        converted[k] = v;
                    }
                }
                results.push(converted);
            }
        }

        // Convert to FHIR Bundle
        json[] entries = [];
        string[] matchedResourceIds = [];

        foreach var result in results {
            string resourceJsonString = result.RESOURCE_JSON;
            json resourceJson = check resourceJsonString.fromJsonString();

            // Add/update meta section with versionId and lastUpdated
            map<json> resourceMap = <map<json>>resourceJson;
            json existingMeta = resourceMap["meta"];
            map<json> metaMap = existingMeta is map<json> ? existingMeta : {};

            metaMap["versionId"] = result.VERSION_ID.toString();

            // Format timestamp as ISO 8601 string
            time:Civil lastUpdated = result.LAST_UPDATED;
            string timestamp = utils:formatTimestampISO8601(lastUpdated);
            metaMap["lastUpdated"] = timestamp;

            resourceMap["meta"] = metaMap;

            // Get the resource ID
            string resourceId = "";
            foreach var [key, value] in result.entries() {
                if key != "RESOURCE_JSON" && key != "VERSION_ID" && key != "LAST_UPDATED" && value is string {
                    resourceId = value;
                    matchedResourceIds.push(resourceId);
                    break;
                }
            }

            json entry = {
                "fullUrl": string `${baseUrl}/fhir/r4/${resourceType}/${resourceId}`,
                "resource": resourceMap,
                "search": {
                    "mode": "match"
                }
            };
            entries.push(entry);
        }

        // Handle _include parameters
        // Track included resources to avoid duplicates (same resource shouldn't appear multiple times)
        map<boolean> includedResourceKeys = {};

        if queryParams.hasKey("_include") {
            string[] includeParams = queryParams.get("_include");
            foreach string includeParam in includeParams {
                // Parse _include parameter: format is ResourceType:searchParam or ResourceType:searchParam:targetType
                // Example: Appointment:patient or Appointment:patient:Patient
                // Also support wildcard: _include=* (include all references).
                //
                // Batched (WORK.md §7): one REFERENCES query for ALL matched
                // IDs + one batch read per distinct target type, instead of
                // O(matched × refs) round-trips.

                if includeParam == "*" {
                    json[] includedResources = check self.fetchAllReferencedResourcesBatch(jdbcClient, resourceType, matchedResourceIds);
                    foreach json includedEntry in includedResources {
                        map<json> entryMap = <map<json>>includedEntry;
                        json includedResource = entryMap.get("resource");
                        map<json> resourceMap = <map<json>>includedResource;
                        string resType = resourceMap.get("resourceType").toString();
                        string resId = resourceMap.get("id").toString();
                        string resourceKey = string `${resType}/${resId}`;
                        if !includedResourceKeys.hasKey(resourceKey) {
                            entries.push(includedEntry);
                            includedResourceKeys[resourceKey] = true;
                        }
                    }
                } else {
                    string[] parts = regexp:split(re `:`, includeParam);
                    if parts.length() >= 2 {
                        string sourceResourceType = parts[0];
                        string searchParamName = parts[1];
                        string? targetResourceType = parts.length() > 2 ? parts[2] : ();
                        if sourceResourceType == resourceType {
                            json[] includedResources = check self.fetchIncludedResourcesBatch(jdbcClient, sourceResourceType, matchedResourceIds, searchParamName, targetResourceType);
                            foreach json includedEntry in includedResources {
                                map<json> entryMap = <map<json>>includedEntry;
                                json includedResource = entryMap.get("resource");
                                map<json> resourceMap = <map<json>>includedResource;
                                string resType = resourceMap.get("resourceType").toString();
                                string resId = resourceMap.get("id").toString();
                                string resourceKey = string `${resType}/${resId}`;
                                if !includedResourceKeys.hasKey(resourceKey) {
                                    entries.push(includedEntry);
                                    includedResourceKeys[resourceKey] = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Handle _revinclude parameters (reverse include) — batched.
        if queryParams.hasKey("_revinclude") {
            string[] revIncludeParams = queryParams.get("_revinclude");
            foreach string revIncludeParam in revIncludeParams {
                if revIncludeParam == "*" {
                    json[] revIncludedResources = check self.fetchAllReferencingResourcesBatch(jdbcClient, resourceType, matchedResourceIds);
                    foreach json revIncludedEntry in revIncludedResources {
                        map<json> entryMap = <map<json>>revIncludedEntry;
                        json revIncludedResource = entryMap.get("resource");
                        map<json> resourceMap = <map<json>>revIncludedResource;
                        string resType = resourceMap.get("resourceType").toString();
                        string resId = resourceMap.get("id").toString();
                        string resourceKey = string `${resType}/${resId}`;
                        if !includedResourceKeys.hasKey(resourceKey) {
                            entries.push(revIncludedEntry);
                            includedResourceKeys[resourceKey] = true;
                        }
                    }
                } else {
                    string[] parts = regexp:split(re `:`, revIncludeParam);
                    if parts.length() >= 2 {
                        string sourceResourceType = parts[0];
                        string searchParamName = parts[1];
                        string? targetResourceFilter = parts.length() > 2 ? parts[2] : ();
                        json[] revIncludedResources = check self.fetchReverseIncludedResourcesBatch(
                            jdbcClient,
                            sourceResourceType,
                            searchParamName,
                            resourceType,
                            matchedResourceIds,
                            targetResourceFilter
                        );
                        foreach json revIncludedEntry in revIncludedResources {
                            map<json> entryMap = <map<json>>revIncludedEntry;
                            json revIncludedResource = entryMap.get("resource");
                            map<json> resourceMap = <map<json>>revIncludedResource;
                            string resType = resourceMap.get("resourceType").toString();
                            string resId = resourceMap.get("id").toString();
                            string resourceKey = string `${resType}/${resId}`;
                            if !includedResourceKeys.hasKey(resourceKey) {
                                entries.push(revIncludedEntry);
                                includedResourceKeys[resourceKey] = true;
                            }
                        }
                    }
                }
            }
        }

        map<json> bundle = {
            "resourceType": "Bundle",
            "type": "searchset",
            "entry": entries
        };
        // Omit Bundle.total when caller didn't ask for it (default _total=none).
        if totalCount is int {
            bundle["total"] = totalCount;
        }

        return bundle;
    }

    // Read all resources of a given type (with optional limit)
    public isolated function readAllResources(jdbc:Client? jdbcClient, string resourceType, int? 'limit = ()) returns json|error {
        if jdbcClient is () {
            return error("JDBC client is not initialized");
        }

        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);

        int totalCount = 0;
        string countQuery = string `SELECT COUNT(*) AS "COUNT" FROM "${tableName}"`;
        log:printDebug(string `Getting total count for all resources of type: ${resourceType}`);
        sql:ParameterizedQuery cQuery = new RawSQLQuery(countQuery);
        record {|int COUNT;|}? countResult = check jdbcClient->queryRow(cQuery);
        if countResult != () {
            totalCount = countResult.COUNT;
        }

        string limitClause = 'limit is int ? string ` LIMIT ${'limit}` : "";
        string sqlQuery = string `SELECT "${primaryKey}", "RESOURCE_JSON", "VERSION_ID", "LAST_UPDATED" FROM "${tableName}"${limitClause}`;

        record {|string RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED; string...;|}[] results3;
        string normalizedDbType3 = mapperUtils:dbType.toLowerAscii().trim();
        if normalizedDbType3 == "postgresql" || normalizedDbType3 == "postgres" {
            string pgSql = re `"RESOURCE_JSON"`.replaceAll(sqlQuery,
                string `CAST("RESOURCE_JSON" AS TEXT) AS "RESOURCE_JSON"`);
            sql:ParameterizedQuery pgQuery = new RawSQLQuery(pgSql);
            stream<record {|string RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED; string...;|}, sql:Error?> pgStream = jdbcClient->query(pgQuery);
            results3 = check from var r in pgStream
                select r;
        } else {
            sql:ParameterizedQuery h2Query = new RawSQLQuery(sqlQuery);
            stream<record {|byte[] RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED; string...;|}, sql:Error?> h2Stream = jdbcClient->query(h2Query);
            record {|byte[] RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED; string...;|}[] h2Results3 = check from var r in h2Stream
                select r;
            results3 = [];
            foreach var r in h2Results3 {
                string jsonStr = check string:fromBytes(r.RESOURCE_JSON);
                record {|string RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED; string...;|} converted = {RESOURCE_JSON: jsonStr, VERSION_ID: r.VERSION_ID, LAST_UPDATED: r.LAST_UPDATED};
                foreach var [k, v] in r.entries() {
                    if k != "RESOURCE_JSON" && k != "VERSION_ID" && k != "LAST_UPDATED" && v is string {
                        converted[k] = v;
                    }
                }
                results3.push(converted);
            }
        }

        json[] entries = [];
        foreach var result in results3 {
            string resourceJsonString = result.RESOURCE_JSON;
            json resourceJson = check resourceJsonString.fromJsonString();

            // Add/update meta section with versionId and lastUpdated
            map<json> resourceMap = <map<json>>resourceJson;
            json existingMeta = resourceMap["meta"];
            map<json> metaMap = existingMeta is map<json> ? existingMeta : {};

            metaMap["versionId"] = result.VERSION_ID.toString();

            // Format timestamp as ISO 8601 string
            time:Civil lastUpdated = result.LAST_UPDATED;
            string timestamp = utils:formatTimestampISO8601(lastUpdated);
            metaMap["lastUpdated"] = timestamp;

            resourceMap["meta"] = metaMap;

            // Get the resource ID
            string resourceId = "";
            foreach var [key, value] in result.entries() {
                if key != "RESOURCE_JSON" && key != "VERSION_ID" && key != "LAST_UPDATED" && value is string {
                    resourceId = value;
                    break;
                }
            }

            json entry = {
                "fullUrl": string `${baseUrl}/fhir/r4/${resourceType}/${resourceId}`,
                "resource": resourceMap
            };
            entries.push(entry);
        }

        json bundle = {
            "resourceType": "Bundle",
            "type": "collection",
            "total": totalCount,
            "entry": entries
        };

        return bundle;
    }

    // Read references for a specific resource
    public isolated function readReferences(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns json[]|error {
        if jdbcClient is () {
            return error("JDBC client is not initialized");
        }

        string sqlQuery = string `SELECT "ID", "SOURCE_RESOURCE_TYPE", "SOURCE_RESOURCE_ID", "SOURCE_EXPRESSION", "TARGET_RESOURCE_TYPE", "TARGET_RESOURCE_ID", "DISPLAY_VALUE" FROM "REFERENCES" WHERE "SOURCE_RESOURCE_TYPE" = '${utils:escapeSql(resourceType)}' AND "SOURCE_RESOURCE_ID" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        stream<record {|string ID; string SOURCE_RESOURCE_TYPE; string SOURCE_RESOURCE_ID; string SOURCE_EXPRESSION; string? TARGET_RESOURCE_TYPE; string? TARGET_RESOURCE_ID; string? DISPLAY_VALUE;|}, sql:Error?> resultStream = jdbcClient->query(query);

        record {|string ID; string SOURCE_RESOURCE_TYPE; string SOURCE_RESOURCE_ID; string SOURCE_EXPRESSION; string? TARGET_RESOURCE_TYPE; string? TARGET_RESOURCE_ID; string? DISPLAY_VALUE;|}[] results = check from var ref in resultStream
            select ref;

        json[] referenceList = [];
        foreach var ref in results {
            json referenceJson = {
                "id": ref.ID,
                "sourceResourceType": ref.SOURCE_RESOURCE_TYPE,
                "sourceResourceId": ref.SOURCE_RESOURCE_ID,
                "sourceExpression": ref.SOURCE_EXPRESSION,
                "targetResourceType": ref.TARGET_RESOURCE_TYPE,
                "targetResourceId": ref.TARGET_RESOURCE_ID,
                "display": ref.DISPLAY_VALUE
            };
            referenceList.push(referenceJson);
        }

        return referenceList;
    }

    // Check if a resource exists
    public isolated function resourceExists(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns boolean|error {
        if jdbcClient is () {
            return error("JDBC client is not initialized");
        }

        return utils:resourceExists(jdbcClient, resourceType, resourceId);
    }

    // Get resource count by type
    public isolated function getResourceCount(jdbc:Client? jdbcClient, string resourceType) returns int|error {
        if jdbcClient is () {
            return error("JDBC client is not initialized");
        }

        string tableName = utils:getTableName(resourceType);

        string sqlQuery = string `SELECT COUNT(*) AS "COUNT" FROM "${tableName}"`;
        sql:ParameterizedQuery query = new RawSQLQuery(sqlQuery);

        record {|int COUNT;|}? result = check jdbcClient->queryRow(query);

        if result is () {
            return 0;
        }

        return result.COUNT;
    }

    // Get resource metadata (without full RESOURCE_JSON)
    public isolated function getResourceMetadata(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns record {|anydata...;|}|error {
        if jdbcClient is () {
            return error("JDBC client is not initialized");
        }

        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);

        string sqlQuery = string `SELECT "${primaryKey}", "VERSION_ID", "LAST_UPDATED", "CREATED_AT" FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        stream<record {|anydata...;|}, sql:Error?> resultStream = jdbcClient->query(query);

        record {|anydata...;|}[] results = check from var result in resultStream
            select result;

        if results.length() == 0 {
            return error(string `${resourceType}/${resourceId} not found`);
        }

        return results[0];
    }

    // Helper function to check if array contains a string
    private isolated function arrayContains(string[] arr, string value) returns boolean {
        foreach string item in arr {
            if item == value {
                return true;
            }
        }
        return false;
    }

    // Map FHIR search parameter names to database column names
    private isolated function mapSearchParamToColumn(string searchParam) returns string? {
        // Handle special cases for FHIR standard parameters
        if searchParam == "_lastUpdated" {
            return "LAST_UPDATED";
        }

        // Convert to UPPER_SNAKE_CASE: uppercase and replace hyphens with underscores
        string upperParam = searchParam.toUpperAscii();
        string columnName = regexp:replaceAll(re `-`, upperParam, "_");
        return columnName;
    }

    // Fetch included resources based on _include parameter
    private isolated function fetchIncludedResources(jdbc:Client? jdbcClient, string sourceResourceType, string sourceResourceId, string searchParamName, string? targetResourceType) returns json[]|error {
        if jdbcClient is () {
            return error("JDBC client is not initialized");
        }

        json[] includedEntries = [];

        // Query REFERENCES table to find target resources
        // The search parameter FHIRPath expressions now include complete where clauses:
        // - "Appointment.participant.actor.where(resolve() is Patient)" for patient references
        // - "ActivityDefinition.relatedArtifact.where(type='composed-of').resource" for related artifacts
        // - "Patient.telecom.where(system='email')" for telecom filters
        // We extract the reference field name (the part before .where) to match SOURCE_EXPRESSION

        // Get the FHIRPath expression for this search parameter from the search_param_res_expressions table
        string searchParamQuery = string `SELECT "EXPRESSION" FROM "SEARCH_PARAM_RES_EXPRESSIONS" WHERE "RESOURCE_NAME" = '${utils:escapeSql(sourceResourceType)}' AND "SEARCH_PARAM_NAME" = '${utils:escapeSql(searchParamName)}' AND "SEARCH_PARAM_TYPE" = 'reference'`;
        sql:ParameterizedQuery spQuery = new utils:RawSQLQuery(searchParamQuery);

        stream<record {|string EXPRESSION;|}, sql:Error?> spStream = jdbcClient->query(spQuery);
        record {|string EXPRESSION;|}[] spResults = check from var sp in spStream
            select sp;

        // If we can't find the search parameter, return empty (the search parameter might not exist for this resource type)
        if spResults.length() == 0 {
            return includedEntries;
        }

        // Build WHERE clause for REFERENCES table
        // Since SOURCE_EXPRESSION stores the actual JSON path leaf field (e.g., "actor"),
        // and we have the FHIRPath expression (e.g., "Appointment.participant.actor.where"),
        // we need to extract the actual reference field name (the last field before .where)
        string fhirPathExpr = spResults[0].EXPRESSION;

        // Extract the reference field name and target resource type from FHIRPath
        // Examples:
        //   "Appointment.participant.actor.where(resolve() is Patient)" -> field: "actor", type: "Patient"
        //   "ActivityDefinition.relatedArtifact.where(type='composed-of').resource" -> field: "relatedArtifact", type: null
        //   "Patient.telecom.where(system='email')" -> field: "telecom", type: null
        //   "Patient.generalPractitioner" -> field: "generalPractitioner", type: null
        string[] pathParts = regexp:split(re `\.`, fhirPathExpr);
        string? referenceField = ();
        string? extractedTargetType = ();

        // Find the last field before ".where" or the last field if no ".where"
        foreach int i in 0 ..< pathParts.length() {
            string part = pathParts[i];
            if part == "where" {
                // The field before "where" is our reference field
                if i > 0 {
                    referenceField = pathParts[i - 1];
                }
                break;
            } else if part.startsWith("where(") {
                // The field before "where(" is our reference field
                if i > 0 {
                    referenceField = pathParts[i - 1];
                }

                // Try to extract target resource type from "where(resolve() is ResourceType)"
                string wherePattern = "where(resolve() is ";
                if part.startsWith(wherePattern) {
                    string whereContent = part.substring(wherePattern.length()); // Skip "where(resolve() is "
                    int? closeParenPos = whereContent.indexOf(")");
                    if closeParenPos is int && closeParenPos > 0 {
                        extractedTargetType = whereContent.substring(0, closeParenPos).trim();
                    }
                }
                break;
            } else if i == pathParts.length() - 1 {
                // Last field and no "where" found
                referenceField = part;
            }
        }

        string whereClause = string `"SOURCE_RESOURCE_TYPE" = '${utils:escapeSql(sourceResourceType)}' AND "SOURCE_RESOURCE_ID" = '${utils:escapeSql(sourceResourceId)}'`;

        // Filter by SOURCE_EXPRESSION matching the reference field name
        if referenceField is string {
            whereClause = whereClause + string ` AND "SOURCE_EXPRESSION" = '${utils:escapeSql(referenceField)}'`;
        }

        // Filter by target resource type - use extracted type from expression if available, otherwise use provided targetResourceType
        string? finalTargetType = extractedTargetType is string ? extractedTargetType : targetResourceType;
        if finalTargetType is string {
            whereClause = whereClause + string ` AND "TARGET_RESOURCE_TYPE" = '${utils:escapeSql(finalTargetType)}'`;
        }

        string refQuery = string `SELECT DISTINCT "TARGET_RESOURCE_TYPE", "TARGET_RESOURCE_ID" FROM "REFERENCES" WHERE ${whereClause}`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(refQuery);

        stream<record {|string TARGET_RESOURCE_TYPE; string TARGET_RESOURCE_ID;|}, sql:Error?> refStream = jdbcClient->query(query);
        record {|string TARGET_RESOURCE_TYPE; string TARGET_RESOURCE_ID;|}[] refResults = check from var ref in refStream
            select ref;

        // Fetch each referenced resource
        foreach var refRecord in refResults {
            string targetType = refRecord.TARGET_RESOURCE_TYPE;
            string targetId = refRecord.TARGET_RESOURCE_ID;

            // Use existing readResourceById to fetch the resource
            json|error resourceResult = self.readResourceById(jdbcClient, targetType, targetId);

            if resourceResult is json {
                json entry = {
                    "fullUrl": string `${baseUrl}/fhir/r4/${targetType}/${targetId}`,
                    "resource": resourceResult,
                    "search": {
                        "mode": "include"
                    }
                };
                includedEntries.push(entry);
            }
            // Silently skip resources that can't be fetched (they may have been deleted)
        }

        return includedEntries;
    }

    // Fetch all referenced resources for wildcard _include=*
    public isolated function fetchAllReferencedResources(jdbc:Client? jdbcClient, string sourceResourceType, string sourceResourceId, string? sinceFilter = (), string[]? typeFilter = ()) returns json[]|error {
        if jdbcClient is () {
            return error("JDBC client is not initialized");
        }

        json[] includedEntries = [];

        // Query all references for this source resource
        string refQuery = string `SELECT DISTINCT "TARGET_RESOURCE_TYPE", "TARGET_RESOURCE_ID" FROM "REFERENCES" WHERE "SOURCE_RESOURCE_TYPE" = '${utils:escapeSql(sourceResourceType)}' AND "SOURCE_RESOURCE_ID" = '${utils:escapeSql(sourceResourceId)}'`;
        // Filter by target resource types if _type specified
        if typeFilter is string[] && typeFilter.length() > 0 {
            string[] escapedTypes = from string t in typeFilter
                select "'" + utils:escapeSql(t) + "'";
            refQuery += string ` AND "TARGET_RESOURCE_TYPE" IN (${string:'join(",", ...escapedTypes)})`;
        }
        sql:ParameterizedQuery query = new utils:RawSQLQuery(refQuery);

        stream<record {|string TARGET_RESOURCE_TYPE; string TARGET_RESOURCE_ID;|}, sql:Error?> refStream = jdbcClient->query(query);
        record {|string TARGET_RESOURCE_TYPE; string TARGET_RESOURCE_ID;|}[] refResults = check from var ref in refStream
            select ref;

        // Fetch each referenced resource
        foreach var refRecord in refResults {
            string targetType = refRecord.TARGET_RESOURCE_TYPE;
            string targetId = refRecord.TARGET_RESOURCE_ID;

            // Use existing readResourceById to fetch the resource (with optional _since filter)
            json|error resourceResult = self.readResourceById(jdbcClient, targetType, targetId, sinceFilter);

            if resourceResult is json {
                json entry = {
                    "fullUrl": string `${baseUrl}/fhir/r4/${targetType}/${targetId}`,
                    "resource": resourceResult,
                    "search": {
                        "mode": "include"
                    }
                };
                includedEntries.push(entry);
            }
            // Silently skip resources that can't be fetched (they may have been deleted or filtered out)
        }

        return includedEntries;
    }

    // Fetch resources that reference the target resource (reverse include)
    // Example: GET /MedicationRequest?_revinclude=Provenance:target
    // This finds Provenance resources where their "target" search parameter points to the MedicationRequest
    private isolated function fetchReverseIncludedResources(
            jdbc:Client? jdbcClient,
            string sourceResourceType, // e.g., "Provenance" - the resource type that references our results
            string searchParamName, // e.g., "target" - the search parameter on Provenance
            string targetResourceType, // e.g., "MedicationRequest" - the resource type we searched for
            string targetResourceId, // e.g., "med-123" - the ID of the matched resource
            string? sourceResourceFilter // Optional filter for source resource type
    ) returns json[]|error {
        if jdbcClient is () {
            return error("JDBC client is not initialized");
        }

        json[] revIncludedEntries = [];

        // Get the FHIRPath expression for this search parameter
        // For Provenance:target, we get the expression like "Provenance.target.where(resolve() is MedicationRequest)"
        string searchParamQuery = string `SELECT "EXPRESSION" FROM "SEARCH_PARAM_RES_EXPRESSIONS" WHERE "RESOURCE_NAME" = '${utils:escapeSql(sourceResourceType)}' AND "SEARCH_PARAM_NAME" = '${utils:escapeSql(searchParamName)}' AND "SEARCH_PARAM_TYPE" = 'reference'`;
        sql:ParameterizedQuery spQuery = new utils:RawSQLQuery(searchParamQuery);

        stream<record {|string EXPRESSION;|}, sql:Error?> spStream = jdbcClient->query(spQuery);
        record {|string EXPRESSION;|}[] spResults = check from var sp in spStream
            select sp;

        if spResults.length() == 0 {
            return revIncludedEntries;
        }

        string fhirPathExpr = spResults[0].EXPRESSION;

        // Extract the reference field name and expected target type from FHIRPath
        // Example: "Provenance.target.where(resolve() is MedicationRequest)" -> field: "target", type: "MedicationRequest"
        string[] pathParts = regexp:split(re `\.`, fhirPathExpr);
        string? referenceField = ();
        string? extractedTargetType = ();

        foreach int i in 0 ..< pathParts.length() {
            string part = pathParts[i];
            if part == "where" {
                if i > 0 {
                    referenceField = pathParts[i - 1];
                }
                break;
            } else if part.startsWith("where(") {
                if i > 0 {
                    referenceField = pathParts[i - 1];
                }

                // Extract target resource type from "where(resolve() is ResourceType)"
                string wherePattern = "where(resolve() is ";
                if part.startsWith(wherePattern) {
                    string whereContent = part.substring(wherePattern.length());
                    int? closeParenPos = whereContent.indexOf(")");
                    if closeParenPos is int && closeParenPos > 0 {
                        extractedTargetType = whereContent.substring(0, closeParenPos).trim();
                    }
                }
                break;
            } else if i == pathParts.length() - 1 {
                referenceField = part;
            }
        }

        // Build query to find resources that reference our target
        // We're looking in REFERENCES table where:
        // - SOURCE_RESOURCE_TYPE = the resource type that references us (e.g., "Provenance")
        // - TARGET_RESOURCE_TYPE = the resource type we searched for (e.g., "MedicationRequest")
        // - TARGET_RESOURCE_ID = the ID of our matched resource
        // - SOURCE_EXPRESSION = the field name (e.g., "target")

        string whereClause = string `"TARGET_RESOURCE_TYPE" = '${utils:escapeSql(targetResourceType)}' AND "TARGET_RESOURCE_ID" = '${utils:escapeSql(targetResourceId)}' AND "SOURCE_RESOURCE_TYPE" = '${utils:escapeSql(sourceResourceType)}'`;

        if referenceField is string {
            whereClause = whereClause + string ` AND "SOURCE_EXPRESSION" = '${utils:escapeSql(referenceField)}'`;
        }

        // Optional: filter by expected target type from the expression
        // This ensures we only get references where the search parameter actually points to our resource type
        if extractedTargetType is string && extractedTargetType == targetResourceType {
            // The expression specifies the exact target type, which matches our target
            // This is already filtered by TARGET_RESOURCE_TYPE above
        }

        string refQuery = string `SELECT DISTINCT "SOURCE_RESOURCE_TYPE", "SOURCE_RESOURCE_ID" FROM "REFERENCES" WHERE ${whereClause}`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(refQuery);

        stream<record {|string SOURCE_RESOURCE_TYPE; string SOURCE_RESOURCE_ID;|}, sql:Error?> refStream = jdbcClient->query(query);
        record {|string SOURCE_RESOURCE_TYPE; string SOURCE_RESOURCE_ID;|}[] refResults = check from var ref in refStream
            select ref;

        // Fetch each referencing resource
        foreach var refRecord in refResults {
            string sourceType = refRecord.SOURCE_RESOURCE_TYPE;
            string sourceId = refRecord.SOURCE_RESOURCE_ID;

            // Use existing readResourceById to fetch the resource
            json|error resourceResult = self.readResourceById(jdbcClient, sourceType, sourceId);

            if resourceResult is json {
                json entry = {
                    "fullUrl": string `${baseUrl}/fhir/r4/${sourceType}/${sourceId}`,
                    "resource": resourceResult,
                    "search": {
                        "mode": "include"
                    }
                };
                revIncludedEntries.push(entry);
            }
            // Silently skip resources that can't be fetched
        }

        return revIncludedEntries;
    }

    // Fetch all resources that reference the target resource (wildcard _revinclude=*)
    public isolated function fetchAllReferencingResources(jdbc:Client? jdbcClient, string targetResourceType, string targetResourceId, string? sinceFilter = (), string[]? typeFilter = ()) returns json[]|error {
        if jdbcClient is () {
            return error("JDBC client is not initialized");
        }

        json[] revIncludedEntries = [];

        // Query all resources that reference this target resource
        string refQuery = string `SELECT DISTINCT "SOURCE_RESOURCE_TYPE", "SOURCE_RESOURCE_ID" FROM "REFERENCES" WHERE "TARGET_RESOURCE_TYPE" = '${utils:escapeSql(targetResourceType)}' AND "TARGET_RESOURCE_ID" = '${utils:escapeSql(targetResourceId)}'`;
        // Filter by source resource types if _type specified
        if typeFilter is string[] && typeFilter.length() > 0 {
            string[] escapedTypes = from string t in typeFilter
                select "'" + utils:escapeSql(t) + "'";
            refQuery += string ` AND "SOURCE_RESOURCE_TYPE" IN (${string:'join(",", ...escapedTypes)})`;
        }
        sql:ParameterizedQuery query = new utils:RawSQLQuery(refQuery);

        stream<record {|string SOURCE_RESOURCE_TYPE; string SOURCE_RESOURCE_ID;|}, sql:Error?> refStream = jdbcClient->query(query);
        record {|string SOURCE_RESOURCE_TYPE; string SOURCE_RESOURCE_ID;|}[] refResults = check from var ref in refStream
            select ref;

        // Fetch each referencing resource
        foreach var refRecord in refResults {
            string sourceType = refRecord.SOURCE_RESOURCE_TYPE;
            string sourceId = refRecord.SOURCE_RESOURCE_ID;

            // Use existing readResourceById to fetch the resource (with optional _since filter)
            json|error resourceResult = self.readResourceById(jdbcClient, sourceType, sourceId, sinceFilter);

            if resourceResult is json {
                json entry = {
                    "fullUrl": string `${baseUrl}/fhir/r4/${sourceType}/${sourceId}`,
                    "resource": resourceResult,
                    "search": {
                        "mode": "include"
                    }
                };
                revIncludedEntries.push(entry);
            }
            // Silently skip resources that can't be fetched or filtered out
        }

        return revIncludedEntries;
    }

    // ---------------------------------------------------------------------
    // Batched fetchers for _include / _revinclude (WORK.md §5.5.4 / §7).
    // Replace the prior O(matched × refs) round-trip pattern with:
    //   1. ONE REFERENCES query (IN-clause over all matched IDs)
    //   2. ONE batch SELECT per distinct target resource type (IN-clause over IDs)
    // For 50 matched results × 5 refs each this drops 300+ round-trips to ~3.
    // ---------------------------------------------------------------------

    // Batch-fetch resources of one type by primary-key IN-list, reusing the
    // meta-enrichment / fullUrl shaping that readResourceById does per-row.
    private isolated function batchReadResources(jdbc:Client jdbcClient, string targetType, string[] targetIds, string? sinceFilter = (), string searchMode = "include") returns json[]|error {
        if targetIds.length() == 0 {
            return [];
        }
        string tableName = utils:getTableName(targetType);
        string primaryKey = utils:getPrimaryKeyColumn(targetType);

        string[] escaped = from string id in targetIds
            select string `'${utils:escapeSql(id)}'`;
        string idList = string:'join(", ", ...escaped);

        string sqlQuery = string `SELECT "${primaryKey}" AS "RES_ID", "RESOURCE_JSON", "VERSION_ID", "LAST_UPDATED" FROM "${tableName}" WHERE "${primaryKey}" IN (${idList})`;
        if sinceFilter is string {
            string sqlTimestamp = regexp:replaceAll(re `T`, sinceFilter, " ");
            sqlTimestamp = regexp:replaceAll(re `Z$`, sqlTimestamp, "");
            sqlQuery += string ` AND "LAST_UPDATED" > '${utils:escapeSql(sqlTimestamp)}'`;
        }

        json[] entries = [];
        string normalizedDbType = mapperUtils:dbType.toLowerAscii().trim();
        if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
            string pgSql = re `"RESOURCE_JSON"`.replaceAll(sqlQuery,
                string `CAST("RESOURCE_JSON" AS TEXT) AS "RESOURCE_JSON"`);
            sql:ParameterizedQuery pgQuery = new RawSQLQuery(pgSql);
            stream<record {|string RES_ID; string RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED;|}, sql:Error?> pgStream = jdbcClient->query(pgQuery);
            record {|string RES_ID; string RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED;|}[] rows = check from var r in pgStream
                select r;
            foreach var r in rows {
                json resourceJson = check r.RESOURCE_JSON.fromJsonString();
                map<json> resourceMap = <map<json>>resourceJson;
                json existingMeta = resourceMap["meta"];
                map<json> metaMap = existingMeta is map<json> ? existingMeta : {};
                metaMap["versionId"] = r.VERSION_ID.toString();
                metaMap["lastUpdated"] = utils:formatTimestampISO8601(r.LAST_UPDATED);
                resourceMap["meta"] = metaMap;
                entries.push({
                    "fullUrl": string `${baseUrl}/fhir/r4/${targetType}/${r.RES_ID}`,
                    "resource": resourceMap,
                    "search": {"mode": searchMode}
                });
            }
        } else {
            sql:ParameterizedQuery h2Query = new RawSQLQuery(sqlQuery);
            stream<record {|string RES_ID; byte[] RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED;|}, sql:Error?> h2Stream = jdbcClient->query(h2Query);
            record {|string RES_ID; byte[] RESOURCE_JSON; int VERSION_ID; time:Civil LAST_UPDATED;|}[] rows = check from var r in h2Stream
                select r;
            foreach var r in rows {
                string jsonStr = check string:fromBytes(r.RESOURCE_JSON);
                json resourceJson = check jsonStr.fromJsonString();
                map<json> resourceMap = <map<json>>resourceJson;
                json existingMeta = resourceMap["meta"];
                map<json> metaMap = existingMeta is map<json> ? existingMeta : {};
                metaMap["versionId"] = r.VERSION_ID.toString();
                metaMap["lastUpdated"] = utils:formatTimestampISO8601(r.LAST_UPDATED);
                resourceMap["meta"] = metaMap;
                entries.push({
                    "fullUrl": string `${baseUrl}/fhir/r4/${targetType}/${r.RES_ID}`,
                    "resource": resourceMap,
                    "search": {"mode": searchMode}
                });
            }
        }
        return entries;
    }

    // Helper: build "'a','b','c'" SQL literal from a string[] (already escaped).
    private isolated function buildEscapedInList(string[] ids) returns string {
        string[] escaped = from string id in ids
            select string `'${utils:escapeSql(id)}'`;
        return string:'join(", ", ...escaped);
    }

    // Wildcard _include=* across all matched source IDs.
    private isolated function fetchAllReferencedResourcesBatch(jdbc:Client jdbcClient, string sourceResourceType, string[] sourceIds) returns json[]|error {
        if sourceIds.length() == 0 {
            return [];
        }
        string idList = self.buildEscapedInList(sourceIds);
        string refQuery = string `SELECT DISTINCT "TARGET_RESOURCE_TYPE", "TARGET_RESOURCE_ID" FROM "REFERENCES" WHERE "SOURCE_RESOURCE_TYPE" = '${utils:escapeSql(sourceResourceType)}' AND "SOURCE_RESOURCE_ID" IN (${idList})`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(refQuery);
        stream<record {|string TARGET_RESOURCE_TYPE; string TARGET_RESOURCE_ID;|}, sql:Error?> refStream = jdbcClient->query(query);
        record {|string TARGET_RESOURCE_TYPE; string TARGET_RESOURCE_ID;|}[] refRows = check from var r in refStream
            select r;

        map<string[]> byType = {};
        foreach var r in refRows {
            string[] ids = byType.hasKey(r.TARGET_RESOURCE_TYPE) ? byType.get(r.TARGET_RESOURCE_TYPE) : [];
            ids.push(r.TARGET_RESOURCE_ID);
            byType[r.TARGET_RESOURCE_TYPE] = ids;
        }

        json[] entries = [];
        foreach var [tt, ids] in byType.entries() {
            json[] sub = check self.batchReadResources(jdbcClient, tt, ids);
            foreach json e in sub {
                entries.push(e);
            }
        }
        return entries;
    }

    // Wildcard _revinclude=* across all matched target IDs.
    private isolated function fetchAllReferencingResourcesBatch(jdbc:Client jdbcClient, string targetResourceType, string[] targetIds) returns json[]|error {
        if targetIds.length() == 0 {
            return [];
        }
        string idList = self.buildEscapedInList(targetIds);
        string refQuery = string `SELECT DISTINCT "SOURCE_RESOURCE_TYPE", "SOURCE_RESOURCE_ID" FROM "REFERENCES" WHERE "TARGET_RESOURCE_TYPE" = '${utils:escapeSql(targetResourceType)}' AND "TARGET_RESOURCE_ID" IN (${idList})`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(refQuery);
        stream<record {|string SOURCE_RESOURCE_TYPE; string SOURCE_RESOURCE_ID;|}, sql:Error?> refStream = jdbcClient->query(query);
        record {|string SOURCE_RESOURCE_TYPE; string SOURCE_RESOURCE_ID;|}[] refRows = check from var r in refStream
            select r;

        map<string[]> bySrcType = {};
        foreach var r in refRows {
            string[] ids = bySrcType.hasKey(r.SOURCE_RESOURCE_TYPE) ? bySrcType.get(r.SOURCE_RESOURCE_TYPE) : [];
            ids.push(r.SOURCE_RESOURCE_ID);
            bySrcType[r.SOURCE_RESOURCE_TYPE] = ids;
        }

        json[] entries = [];
        foreach var [st, ids] in bySrcType.entries() {
            json[] sub = check self.batchReadResources(jdbcClient, st, ids);
            foreach json e in sub {
                entries.push(e);
            }
        }
        return entries;
    }

    // Specific _include=Type:param[:targetType] across all matched source IDs.
    private isolated function fetchIncludedResourcesBatch(jdbc:Client jdbcClient, string sourceResourceType, string[] sourceIds, string searchParamName, string? targetResourceType) returns json[]|error {
        if sourceIds.length() == 0 {
            return [];
        }

        // Resolve the FHIRPath expression once (per directive), not per source.
        sql:ParameterizedQuery spQuery = `SELECT "EXPRESSION" FROM "SEARCH_PARAM_RES_EXPRESSIONS" WHERE "RESOURCE_NAME" = ${sourceResourceType} AND "SEARCH_PARAM_NAME" = ${searchParamName} AND "SEARCH_PARAM_TYPE" = 'reference'`;
        stream<record {|string EXPRESSION;|}, sql:Error?> spStream = jdbcClient->query(spQuery);
        record {|string EXPRESSION;|}[] spResults = check from var sp in spStream
            select sp;
        if spResults.length() == 0 {
            return [];
        }

        string fhirPathExpr = spResults[0].EXPRESSION;
        string? referenceField;
        string? extractedTargetType;
        [referenceField, extractedTargetType] = self.parseReferenceFieldFromExpression(fhirPathExpr);

        string idList = self.buildEscapedInList(sourceIds);
        string whereClause = string `"SOURCE_RESOURCE_TYPE" = '${utils:escapeSql(sourceResourceType)}' AND "SOURCE_RESOURCE_ID" IN (${idList})`;
        if referenceField is string {
            whereClause = whereClause + string ` AND "SOURCE_EXPRESSION" = '${utils:escapeSql(referenceField)}'`;
        }
        string? finalTargetType = extractedTargetType is string ? extractedTargetType : targetResourceType;
        if finalTargetType is string {
            whereClause = whereClause + string ` AND "TARGET_RESOURCE_TYPE" = '${utils:escapeSql(finalTargetType)}'`;
        }

        string refQuery = string `SELECT DISTINCT "TARGET_RESOURCE_TYPE", "TARGET_RESOURCE_ID" FROM "REFERENCES" WHERE ${whereClause}`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(refQuery);
        stream<record {|string TARGET_RESOURCE_TYPE; string TARGET_RESOURCE_ID;|}, sql:Error?> refStream = jdbcClient->query(query);
        record {|string TARGET_RESOURCE_TYPE; string TARGET_RESOURCE_ID;|}[] refRows = check from var r in refStream
            select r;

        map<string[]> byType = {};
        foreach var r in refRows {
            string[] ids = byType.hasKey(r.TARGET_RESOURCE_TYPE) ? byType.get(r.TARGET_RESOURCE_TYPE) : [];
            ids.push(r.TARGET_RESOURCE_ID);
            byType[r.TARGET_RESOURCE_TYPE] = ids;
        }

        json[] entries = [];
        foreach var [tt, ids] in byType.entries() {
            json[] sub = check self.batchReadResources(jdbcClient, tt, ids);
            foreach json e in sub {
                entries.push(e);
            }
        }
        return entries;
    }

    // Specific _revinclude=SourceType:param across all matched target IDs.
    private isolated function fetchReverseIncludedResourcesBatch(jdbc:Client jdbcClient, string sourceResourceType, string searchParamName, string targetResourceType, string[] targetIds, string? sourceResourceFilter) returns json[]|error {
        if targetIds.length() == 0 {
            return [];
        }

        sql:ParameterizedQuery spQuery = `SELECT "EXPRESSION" FROM "SEARCH_PARAM_RES_EXPRESSIONS" WHERE "RESOURCE_NAME" = ${sourceResourceType} AND "SEARCH_PARAM_NAME" = ${searchParamName} AND "SEARCH_PARAM_TYPE" = 'reference'`;
        stream<record {|string EXPRESSION;|}, sql:Error?> spStream = jdbcClient->query(spQuery);
        record {|string EXPRESSION;|}[] spResults = check from var sp in spStream
            select sp;
        if spResults.length() == 0 {
            return [];
        }

        string fhirPathExpr = spResults[0].EXPRESSION;
        // The expression's target type (extracted via parseReferenceFieldFromExpression)
        // is intentionally ignored here — the reverse-include caller already
        // pinned TARGET_RESOURCE_TYPE in the WHERE clause below.
        [string?, string?] parsed = self.parseReferenceFieldFromExpression(fhirPathExpr);
        string? referenceField = parsed[0];

        string idList = self.buildEscapedInList(targetIds);
        string whereClause = string `"TARGET_RESOURCE_TYPE" = '${utils:escapeSql(targetResourceType)}' AND "TARGET_RESOURCE_ID" IN (${idList}) AND "SOURCE_RESOURCE_TYPE" = '${utils:escapeSql(sourceResourceType)}'`;
        if referenceField is string {
            whereClause = whereClause + string ` AND "SOURCE_EXPRESSION" = '${utils:escapeSql(referenceField)}'`;
        }

        string refQuery = string `SELECT DISTINCT "SOURCE_RESOURCE_TYPE", "SOURCE_RESOURCE_ID" FROM "REFERENCES" WHERE ${whereClause}`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(refQuery);
        stream<record {|string SOURCE_RESOURCE_TYPE; string SOURCE_RESOURCE_ID;|}, sql:Error?> refStream = jdbcClient->query(query);
        record {|string SOURCE_RESOURCE_TYPE; string SOURCE_RESOURCE_ID;|}[] refRows = check from var r in refStream
            select r;

        map<string[]> bySrcType = {};
        foreach var r in refRows {
            string[] ids = bySrcType.hasKey(r.SOURCE_RESOURCE_TYPE) ? bySrcType.get(r.SOURCE_RESOURCE_TYPE) : [];
            ids.push(r.SOURCE_RESOURCE_ID);
            bySrcType[r.SOURCE_RESOURCE_TYPE] = ids;
        }

        json[] entries = [];
        foreach var [st, ids] in bySrcType.entries() {
            json[] sub = check self.batchReadResources(jdbcClient, st, ids);
            foreach json e in sub {
                entries.push(e);
            }
        }
        return entries;
    }

    // Extract reference field + optional target type from a FHIRPath expression.
    // Examples:
    //   "Appointment.participant.actor.where(resolve() is Patient)"
    //     -> ("actor", "Patient")
    //   "Patient.generalPractitioner" -> ("generalPractitioner", ())
    private isolated function parseReferenceFieldFromExpression(string fhirPathExpr) returns [string?, string?] {
        string[] pathParts = regexp:split(re `\.`, fhirPathExpr);
        string? referenceField = ();
        string? extractedTargetType = ();
        foreach int i in 0 ..< pathParts.length() {
            string part = pathParts[i];
            if part == "where" {
                if i > 0 {
                    referenceField = pathParts[i - 1];
                }
                break;
            } else if part.startsWith("where(") {
                if i > 0 {
                    referenceField = pathParts[i - 1];
                }
                string wherePattern = "where(resolve() is ";
                if part.startsWith(wherePattern) {
                    string whereContent = part.substring(wherePattern.length());
                    int? closeParenPos = whereContent.indexOf(")");
                    if closeParenPos is int && closeParenPos > 0 {
                        extractedTargetType = whereContent.substring(0, closeParenPos).trim();
                    }
                }
                break;
            } else if i == pathParts.length() - 1 {
                referenceField = part;
            }
        }
        return [referenceField, extractedTargetType];
    }

    // Check if a search parameter is a custom extension parameter
    private isolated function isCustomSearchParam(jdbc:Client jdbcClient, string resourceType, string paramName) returns boolean|error {
        sql:ParameterizedQuery query = `
            SELECT COUNT(*) as count
            FROM "SEARCH_PARAM_RES_EXPRESSIONS" 
            WHERE "RESOURCE_NAME" = ${resourceType}
            AND "SEARCH_PARAM_NAME" = ${paramName}
            AND "IS_CUSTOM" = ${true}
        `;

        stream<record {int count;}, sql:Error?> resultStream = jdbcClient->query(query);
        record {|record {int count;} value;|}|sql:Error? nextRecord = resultStream.next();
        check resultStream.close();

        if nextRecord is record {|record {int count;} value;|} {
            return nextRecord.value.count > 0;
        }

        return false;
    }

    // Create an empty FHIR Bundle
    private isolated function createEmptyBundle() returns json {
        return {
            "resourceType": "Bundle",
            "type": "searchset",
            "total": 0,
            "entry": []
        };
    }
}

// RawSQLQuery class for dynamic SQL execution
class RawSQLQuery {
    *sql:ParameterizedQuery;
    public final string[] & readonly strings;
    public final sql:Value[] & readonly insertions;

    isolated function init(string sqlQuery) {
        self.strings = [sqlQuery].cloneReadOnly();
        self.insertions = [].cloneReadOnly();
    }
}
