import ballerina_fhir_server.utils;

import ballerina/log;
import ballerina/sql;
import ballerinax/java.jdbc;

public class DeleteHandler {
    private utils:TransactionHandler transactionHandler;
    private HistoryHandler historyHandler;
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
        self.transactionHandler = new utils:TransactionHandler();
        self.historyHandler = new HistoryHandler(jdbcClient);
    }

    // Main function to delete resource with full transaction support
    public isolated function deleteResourceWithTransaction(string resourceType, string resourceId) returns boolean|error {

        utils:TransactionContext 'transaction = self.transactionHandler.beginTransaction();
        'transaction.mainResourceId = resourceId;

        do {
            // Check if resource exists
            log:printDebug(string `Checking if ${resourceType}/${resourceId} exists`);
            boolean exists = check self.checkResourceExists(resourceType, resourceId);

            if !exists {
                log:printWarn(string `Delete attempted on non-existent resource: ${resourceType}/${resourceId}`);
                return error(string `${resourceType}/${resourceId} not found`);
            }

            // Backup before delete
            log:printDebug(string `Backing up ${resourceType}/${resourceId} before deletion`);
            record {|anydata...;|}? backup = check self.backupResource(resourceType, resourceId);
            'transaction.backupResource = backup;
            'transaction.backupReferences = check self.backupReferences(resourceType, resourceId);

            // Save to history before deletion
            if backup is record {|anydata...;|} {
                int versionId = check int:fromString(backup.get("VERSION_ID").toString());
                log:printDebug(string `Saving version ${versionId} of ${resourceType}/${resourceId} to history before deletion`);
                error? historyResult = self.historyHandler.saveToHistory(resourceType, resourceId, backup, "DELETE");
                if historyResult is error {
                    log:printError(string `Failed to save history for ${resourceType}/${resourceId}: ${historyResult.message()}`);
                    error? rollbackResult = self.transactionHandler.rollbackDeleteTransaction(
                        self.jdbcClient, 'transaction, resourceType
                    );
                    if (rollbackResult is error) {
                        log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                    }
                    return historyResult;
                }
            }

            // Find references
            log:printDebug(string `Finding references for ${resourceType}/${resourceId}`);
            int[] referenceIds = check self.findSourceReferences(resourceType, resourceId);
            log:printDebug(string `Found ${referenceIds.length()} reference(s) to delete for ${resourceType}/${resourceId}`);

            // Delete references
            error? refResult = utils:deleteReferences(self.jdbcClient, referenceIds, 'transaction);

            if refResult is error {
                log:printError(string `Failed to delete references for ${resourceType}/${resourceId}: ${refResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackDeleteTransaction(self.jdbcClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                return refResult;
            }

            // Delete main resource
            log:printDebug(string `Deleting main ${resourceType}/${resourceId} record`);
            
            // Delete search parameters for this resource
            jdbc:Client? jdbcConn = self.jdbcClient;
            if jdbcConn is jdbc:Client {
                log:printDebug(string `Deleting search parameters for ${resourceType}/${resourceId}`);
                error? deleteSearchResult = utils:deleteSearchParametersForResource(jdbcConn, resourceType, resourceId);
                if deleteSearchResult is error {
                    log:printError(string `Failed to delete search parameters for ${resourceType}/${resourceId}: ${deleteSearchResult.message()}`);
                    // Continue with delete even if search param cleanup fails
                    log:printWarn(string `Continuing with delete despite search parameter cleanup failure`);
                }
            }
            
            // Special handling for SearchParameter resources - remove from expressions table
            if resourceType == "SearchParameter" {
                log:printDebug(string `Removing SearchParameter/${resourceId} from SEARCH_PARAM_RES_EXPRESSIONS`);
                error? syncResult = utils:removeSearchParameterById(self.jdbcClient, resourceId);
                if syncResult is error {
                    log:printError(string `Failed to remove SearchParameter/${resourceId} from expressions: ${syncResult.message()}`);
                    // Continue with delete even if sync fails (log warning)
                    log:printWarn(string `Continuing with delete despite expression cleanup failure`);
                } else {
                    log:printInfo(string `Successfully removed SearchParameter/${resourceId} from expressions table`);
                }
            }
            
            error? deleteResult = utils:deleteResource(self.jdbcClient, resourceType, resourceId);

            if deleteResult is error {
                log:printError(string `Failed to delete main resource ${resourceType}/${resourceId}: ${deleteResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackDeleteTransaction(self.jdbcClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                return deleteResult;
            }

            // Remove from RESOURCE_TABLE so cascaded REFERENCES rows (target side)
            // pointing to this resource are also cleaned up via ON DELETE CASCADE.
            error? rtResult = utils:deleteFromResourceTable(self.jdbcClient, resourceType, resourceId);
            if rtResult is error {
                // Non-fatal: log the error but continue — main resource is already gone
                log:printWarn(string `Failed to remove ${resourceType}/${resourceId} from RESOURCE_TABLE: ${rtResult.message()}`);
            }

            // Commit Transaction
            log:printDebug(string `Committing delete transaction for ${resourceType}/${resourceId}`);
            self.transactionHandler.commitTransaction('transaction, resourceType, resourceId);

            log:printInfo(string `Successfully deleted ${resourceType}/${resourceId}`);
            return true;

        } on fail error e {
            log:printError(string `Delete transaction failed for ${resourceType}/${resourceId}: ${e.message()}`);
            error? rollbackResult = self.transactionHandler.rollbackDeleteTransaction(self.jdbcClient, 'transaction, resourceType);
            if (rollbackResult is error) {
                log:printError(string `Rollback failed during delete transaction cleanup for ${resourceType}: ${rollbackResult.message()}`);
            }
            return e;
        }
    }

    // Check if resource exists
    private isolated function checkResourceExists(string resourceType, string resourceId) returns boolean|error {
        return utils:resourceExists(self.jdbcClient, resourceType, resourceId);
    }

    // Find all references where this resource is the SOURCE
    private isolated function findSourceReferences(string resourceType, string resourceId) returns int[]|error {

        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client not initialized");
        }

        string sqlQuery = string `SELECT "ID" FROM "REFERENCES" WHERE "SOURCE_RESOURCE_TYPE" = '${utils:escapeSql(resourceType)}' AND "SOURCE_RESOURCE_ID" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        stream<record {|int ID;|}, sql:Error?> resultStream = jdbcConn->query(query);

        record {|int ID;|}[] results = check from var result in resultStream
            select result;

        int[] referenceIds = from var ref in results
            select ref.ID;

        return referenceIds;
    }

    // Add backup methods to DeleteHandler
    private isolated function backupResource(string resourceType, string resourceId) returns record {|anydata...;|}|error {

        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client not initialized");
        }

        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);

        string sqlQuery = string `SELECT * FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        stream<record {|anydata...;|}, sql:Error?> resultStream = jdbcConn->query(query);

        record {|anydata...;|}[] results = check from var result in resultStream
            select result;

        if results.length() == 0 {
            return error(string `${resourceType}/${resourceId} not found for backup`);
        }

        return results[0];
    }

    private isolated function backupReferences(string resourceType, string resourceId) returns record {|anydata...;|}[]|error {

        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client not initialized");
        }

        string sqlQuery = string `SELECT * FROM "REFERENCES" WHERE "SOURCE_RESOURCE_TYPE" = '${utils:escapeSql(resourceType)}' AND "SOURCE_RESOURCE_ID" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        stream<record {|anydata...;|}, sql:Error?> resultStream = jdbcConn->query(query);

        record {|anydata...;|}[] results = check from var ref in resultStream
            select ref;

        return results;
    }
}
