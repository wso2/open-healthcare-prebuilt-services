import ballerina/log;
import ballerina/sql;
import ballerinax/java.jdbc;

// Sync a SearchParameter resource into search_param_definitions (is_custom = true).
public isolated function syncSearchParameterToExpressions(jdbc:Client? jdbcClient, json searchParamJson) returns error? {
    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);

    string code       = check searchParamJson.code;
    string paramType  = check searchParamJson.'type;
    string expression = check searchParamJson.expression;
    json   baseArray  = check searchParamJson.base;
    if !(baseArray is json[]) {
        return error("SearchParameter.base must be an array");
    }
    json[] baseResources = baseArray;

    log:printInfo(string `Syncing SearchParameter '${code}' to search_param_definitions for ${baseResources.length()} resource type(s)`);

    boolean isPostgres = dbType.toLowerAscii().trim() == "postgresql" || dbType.toLowerAscii().trim() == "postgres";

    foreach json baseResource in baseResources {
        if !(baseResource is string) {
            return error("SearchParameter.base entries must be strings");
        }
        string resourceName = baseResource;

        if isPostgres {
            _ = check validatedClient->execute(`
                INSERT INTO search_param_definitions (resource_type, param_name, param_type, fhirpath_expr, is_custom)
                VALUES (${resourceName}, ${code}, ${paramType}, ${expression}, TRUE)
                ON CONFLICT (resource_type, param_name)
                DO UPDATE SET param_type = EXCLUDED.param_type,
                              fhirpath_expr = EXCLUDED.fhirpath_expr
                WHERE search_param_definitions.is_custom = TRUE`);
        } else {
            _ = check validatedClient->execute(`
                MERGE INTO "search_param_definitions" ("resource_type", "param_name", "param_type", "fhirpath_expr", "is_custom")
                KEY ("resource_type", "param_name")
                VALUES (${resourceName}, ${code}, ${paramType}, ${expression}, TRUE)`);
        }

        log:printDebug(string `Synced SearchParameter '${code}' for resource type '${resourceName}'`);
    }

    clearSearchParamCache();
    log:printInfo(string `Successfully synced SearchParameter '${code}'`);
}

// Remove a SearchParameter's custom definitions by code.
public isolated function removeSearchParameterFromExpressions(jdbc:Client? jdbcClient, json searchParamJson) returns error? {
    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);
    string code = check searchParamJson.code;

    log:printInfo(string `Removing SearchParameter '${code}' from search_param_definitions`);

    boolean isPostgres = dbType.toLowerAscii().trim() == "postgresql" || dbType.toLowerAscii().trim() == "postgres";
    sql:ExecutionResult result;
    if isPostgres {
        result = check validatedClient->execute(`
            DELETE FROM search_param_definitions WHERE param_name = ${code} AND is_custom = TRUE`);
    } else {
        result = check validatedClient->execute(`
            DELETE FROM "search_param_definitions" WHERE "param_name" = ${code} AND "is_custom" = TRUE`);
    }

    clearSearchParamCache();
    int affectedRows = result.affectedRowCount ?: 0;
    log:printInfo(string `Removed ${affectedRows} SearchParameter definition(s) for '${code}'`);
}

// Remove a SearchParameter by its resource ID (reads the code from the resources table first).
public isolated function removeSearchParameterById(jdbc:Client? jdbcClient, string resourceId) returns error? {
    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);

    boolean isPostgres = dbType.toLowerAscii().trim() == "postgresql" || dbType.toLowerAscii().trim() == "postgres";
    type JsonRow record {| string resource_json; |};
    sql:ParameterizedQuery readQuery;
    if isPostgres {
        readQuery = `SELECT CAST(resource_json AS TEXT) AS resource_json FROM resources WHERE fhir_id = ${resourceId} AND resource_type = 'SearchParameter'`;
    } else {
        readQuery = `SELECT "resource_json" FROM "resources" WHERE "fhir_id" = ${resourceId} AND "resource_type" = 'SearchParameter'`;
    }

    JsonRow|sql:Error row = validatedClient->queryRow(readQuery);
    if row is sql:NoRowsError {
        log:printWarn(string `SearchParameter with ID '${resourceId}' not found, skipping expression cleanup`);
        return;
    }
    if row is sql:Error {
        log:printError(string `Failed to read SearchParameter '${resourceId}' for cleanup: ${row.message()}`);
        return row;
    }

    json searchParamJson = check row.resource_json.fromJsonString();
    string code = check searchParamJson.code;
    log:printInfo(string `Removing SearchParameter '${code}' (ID: ${resourceId}) from search_param_definitions`);

    if isPostgres {
        _ = check validatedClient->execute(`
            DELETE FROM search_param_definitions WHERE param_name = ${code} AND is_custom = TRUE`);
    } else {
        _ = check validatedClient->execute(`
            DELETE FROM "search_param_definitions" WHERE "param_name" = ${code} AND "is_custom" = TRUE`);
    }

    clearSearchParamCache();
    log:printInfo(string `Removed SearchParameter definitions for '${code}'`);
}
