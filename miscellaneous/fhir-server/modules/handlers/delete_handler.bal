import ballerina_fhir_server.utils;

import ballerina/log;
import ballerina/sql;
import ballerinax/java.jdbc;

public class DeleteHandler {
    private HistoryHandler historyHandler;
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
        self.historyHandler = new HistoryHandler(jdbcClient);
    }

    public isolated function deleteResourceWithTransaction(string resourceType, string resourceId) returns boolean|error {
        jdbc:Client validatedClient = check utils:getValidatedJdbcClient(self.jdbcClient);

        transaction {
            // Read current state for history snapshot — must be inside the transaction
            // so the read and delete are atomic.
            // Exits via `on fail` (auto-rollback) when resource is not found
            record {|anydata...;|} backup = check self.readResourceRecord(validatedClient, resourceType, resourceId);

            check self.historyHandler.saveToHistory(resourceType, resourceId, backup, "DELETE");

            // Delete source-side references for this resource
            int[] referenceIds = check self.findSourceReferences(validatedClient, resourceType, resourceId);
            check utils:deleteReferences(self.jdbcClient, referenceIds);

            // Clean up custom search-param index (non-fatal — do not abort the transaction)
            error? deleteSearchResult = utils:deleteSearchParametersForResource(validatedClient, resourceType, resourceId);
            if deleteSearchResult is error {
                log:printWarn(string `Search param cleanup failed for ${resourceType}/${resourceId}: ${deleteSearchResult.message()}`);
            }

            if resourceType == "SearchParameter" {
                error? syncResult = utils:removeSearchParameterById(self.jdbcClient, resourceId);
                if syncResult is error {
                    log:printWarn(string `Expression cleanup failed for SearchParameter/${resourceId}: ${syncResult.message()}`);
                }
            }

            check utils:deleteResource(self.jdbcClient, resourceType, resourceId);

            // Removing from RESOURCE_TABLE triggers ON DELETE CASCADE on REFERENCES
            // (target side). A failure here is fatal — roll back so the resource row
            // and its ghost RESOURCE_TABLE entry stay consistent.
            check utils:deleteFromResourceTable(self.jdbcClient, resourceType, resourceId);

            check commit;
        } on fail error e {
            string msg = e.message();
            log:printError(string `Delete transaction rolled back for ${resourceType}/${resourceId}: ${msg}`);
            return e;
        }

        log:printInfo(string `Successfully deleted ${resourceType}/${resourceId}`);
        return true;
    }

    private isolated function readResourceRecord(jdbc:Client jdbcClient, string resourceType, string resourceId) returns record {|anydata...;|}|error {
        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);
        string sqlQuery = string `SELECT * FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);
        stream<record {|anydata...;|}, sql:Error?> resultStream = jdbcClient->query(query);
        record {|anydata...;|}[] results = check from var row in resultStream select row;
        if results.length() == 0 {
            return error(string `${resourceType}/${resourceId} not found`);
        }
        return results[0];
    }

    private isolated function findSourceReferences(jdbc:Client jdbcClient, string resourceType, string resourceId) returns int[]|error {
        string sqlQuery = string `SELECT "ID" FROM "REFERENCES" WHERE "SOURCE_RESOURCE_TYPE" = '${utils:escapeSql(resourceType)}' AND "SOURCE_RESOURCE_ID" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);
        stream<record {|int ID;|}, sql:Error?> resultStream = jdbcClient->query(query);
        record {|int ID;|}[] results = check from var row in resultStream select row;
        return from var ref in results select ref.ID;
    }
}
