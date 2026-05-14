import ballerina_fhir_server.mappers;
import ballerina_fhir_server.utils;

import ballerina/log;
import ballerina/sql;
import ballerinax/java.jdbc;

public class UpdateHandler {
    private mappers:UpdateMapper updateMapper;
    private HistoryHandler historyHandler;
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
        self.updateMapper = new mappers:UpdateMapper(jdbcClient);
        self.historyHandler = new HistoryHandler(jdbcClient);
    }

    // Full resource replacement (PUT)
    public isolated function updateResourceWithTransaction(string resourceType, string resourceId, json resourceJson) returns string|error {
        jdbc:Client validatedClient = check utils:getValidatedJdbcClient(self.jdbcClient);

        transaction {
            // Existence check inside the transaction for a consistent read-modify-write
            boolean exists = check utils:resourceExists(self.jdbcClient, resourceType, resourceId);
            if !exists {
                fail error(string `${resourceType}/${resourceId} not found`);
            }

            // Delete old source-side references before replacing them
            int[] oldReferenceIds = check self.findSourceReferences(validatedClient, resourceType, resourceId);
            check utils:deleteReferences(self.jdbcClient, oldReferenceIds);

            // Read current version so we can increment it
            int currentVersion = check self.getCurrentVersion(validatedClient, resourceType, resourceId);
            int newVersion = currentVersion + 1;

            // Map incoming JSON to update model — pure computation using DB config
            record {|anydata...;|}|error? updateModel = self.updateMapper.mapToUpdateModel(validatedClient, resourceType, resourceJson, newVersion);
            if updateModel is () || updateModel is error {
                fail updateModel is error ? updateModel : error("Failed to create update model");
            }

            json[] references = self.updateMapper.getReferences();

            check self.updateMainResource(validatedClient, resourceType, resourceId, updateModel);

            if resourceType == "SearchParameter" {
                check utils:syncSearchParameterToExpressions(self.jdbcClient, resourceJson);
            }

            check self.historyHandler.saveToHistory(resourceType, resourceId, updateModel, "PUT");
            check utils:updateSearchParametersForResource(validatedClient, resourceType, resourceId, resourceJson);
            check utils:saveReferences(self.jdbcClient, references, resourceType, resourceId);

            check commit;
        } on fail error e {
            log:printError(string `Update transaction rolled back for ${resourceType}/${resourceId}: ${e.message()}`);
            return e;
        }

        log:printDebug(string `Successfully updated ${resourceType}/${resourceId}`);
        return resourceId;
    }

    // Partial update (PATCH — shallow merge)
    public isolated function patchResourceWithTransaction(string resourceType, string resourceId, json patchJson) returns json|error {
        jdbc:Client validatedClient = check utils:getValidatedJdbcClient(self.jdbcClient);

        // Capture the merged result outside the transaction block so we can return it
        json mergedResource = {};

        transaction {
            // Read, merge, and write atomically
            json existingResource = check self.getResourceAsJson(validatedClient, resourceType, resourceId);
            mergedResource = check self.applyPatch(existingResource, patchJson);

            int[] oldReferenceIds = check self.findSourceReferences(validatedClient, resourceType, resourceId);
            check utils:deleteReferences(self.jdbcClient, oldReferenceIds);

            int currentVersion = check self.getCurrentVersion(validatedClient, resourceType, resourceId);
            int newVersion = currentVersion + 1;

            record {|anydata...;|}|error? updateModel = self.updateMapper.mapToUpdateModel(validatedClient, resourceType, mergedResource, newVersion);
            if updateModel is () || updateModel is error {
                fail updateModel is error ? updateModel : error("Failed to create update model");
            }

            json[] references = self.updateMapper.getReferences();

            check self.updateMainResource(validatedClient, resourceType, resourceId, updateModel);

            if resourceType == "SearchParameter" {
                check utils:syncSearchParameterToExpressions(self.jdbcClient, mergedResource);
            }

            check self.historyHandler.saveToHistory(resourceType, resourceId, updateModel, "PUT");
            check utils:updateSearchParametersForResource(validatedClient, resourceType, resourceId, mergedResource);
            check utils:saveReferences(self.jdbcClient, references, resourceType, resourceId);

            check commit;
        } on fail error e {
            log:printError(string `Patch transaction rolled back for ${resourceType}/${resourceId}: ${e.message()}`);
            return e;
        }

        log:printDebug(string `Successfully patched ${resourceType}/${resourceId}`);
        return mergedResource;
    }

    private isolated function getCurrentVersion(jdbc:Client jdbcClient, string resourceType, string resourceId) returns int|error {
        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);
        string sqlQuery = string `SELECT "VERSION_ID" FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);
        stream<record {|int VERSION_ID;|}, sql:Error?> resultStream = jdbcClient->query(query);
        record {|int VERSION_ID;|}[] results = check from var row in resultStream select row;
        if results.length() == 0 {
            return error(string `${resourceType}/${resourceId} not found`);
        }
        return results[0].VERSION_ID;
    }

    private isolated function getResourceAsJson(jdbc:Client jdbcClient, string resourceType, string resourceId) returns json|error {
        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);
        string jsonString;

        string normalizedDbType = dbType.toLowerAscii().trim();
        if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
            string pgSql = string `SELECT CAST("RESOURCE_JSON" AS TEXT) AS "RESOURCE_JSON" FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
            stream<record {|string RESOURCE_JSON;|}, sql:Error?> pgStream = jdbcClient->query(new utils:RawSQLQuery(pgSql));
            record {|string RESOURCE_JSON;|}[] pgResults = check from var r in pgStream select r;
            if pgResults.length() == 0 {
                return error(string `${resourceType}/${resourceId} not found`);
            }
            jsonString = pgResults[0].RESOURCE_JSON;
        } else {
            string sqlQuery = string `SELECT "RESOURCE_JSON" FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
            stream<record {|byte[] RESOURCE_JSON;|}, sql:Error?> h2Stream = jdbcClient->query(new utils:RawSQLQuery(sqlQuery));
            record {|byte[] RESOURCE_JSON;|}[] h2Results = check from var r in h2Stream select r;
            if h2Results.length() == 0 {
                return error(string `${resourceType}/${resourceId} not found`);
            }
            jsonString = check string:fromBytes(h2Results[0].RESOURCE_JSON);
        }

        return check jsonString.fromJsonString();
    }

    private isolated function applyPatch(json existing, json patch) returns json|error {
        if !(existing is map<json>) {
            return error(string `Existing resource is not a JSON object`);
        }
        if !(patch is map<json>) {
            return error(string `Patch is not a JSON object`);
        }
        map<json> mergedMap = (<map<json>>existing).clone();
        foreach var [key, value] in (<map<json>>patch).entries() {
            mergedMap[key] = value;
        }
        return mergedMap;
    }

    private isolated function findSourceReferences(jdbc:Client jdbcClient, string resourceType, string resourceId) returns int[]|error {
        string sqlQuery = string `SELECT "ID" FROM "REFERENCES" WHERE "SOURCE_RESOURCE_TYPE" = '${utils:escapeSql(resourceType)}' AND "SOURCE_RESOURCE_ID" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);
        stream<record {|int ID;|}, sql:Error?> resultStream = jdbcClient->query(query);
        record {|int ID;|}[] results = check from var row in resultStream select row;
        return from var ref in results select ref.ID;
    }

    private isolated function updateMainResource(jdbc:Client jdbcClient, string resourceType, string resourceId, record {|anydata...;|} updateModel) returns error? {
        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);

        string[] setClauses = [];
        foreach var [key, value] in updateModel.entries() {
            string formattedValue = key == "DATE" ? utils:formatDateValue(value) : utils:formatSqlValue(value);
            setClauses.push(string `"${key}" = ${formattedValue}`);
        }

        if setClauses.length() == 0 {
            return error("No fields to update");
        }

        string setClause = string:'join(", ", ...setClauses);
        string sqlQuery = string `UPDATE "${tableName}" SET ${setClause} WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
        sql:ExecutionResult|sql:Error result = jdbcClient->execute(new utils:RawSQLQuery(sqlQuery));
        if result is sql:Error {
            return error(string `Failed to update ${resourceType}/${resourceId}: ${result.message()}`);
        }
    }
}
