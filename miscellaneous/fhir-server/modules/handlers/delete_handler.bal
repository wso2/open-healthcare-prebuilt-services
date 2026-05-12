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

    // Public entry point for single-resource deletes.
    //
    // WORK.md §5.1 / Phase 3: a real Ballerina `transaction { }` block makes
    // the multi-step delete (history snapshot → references → resource →
    // FHIR_RESOURCE_INDEX tombstone) atomic. The previous backup/restore
    // plumbing is gone — JDBC rollback handles failures.
    public isolated function deleteResourceWithTransaction(string resourceType, string resourceId) returns boolean|error {
        boolean result;
        transaction {
            result = check self.persistDelete(resourceType, resourceId);
            check commit;
        } on fail error e {
            log:printError(string `Delete transaction failed for ${resourceType}/${resourceId}: ${e.message()}`);
            return e;
        }
        return result;
    }

    // Core delete pipeline. Callable from inside an outer transaction (Bundle
    // handler / Phase 5).
    public isolated function persistDelete(string resourceType, string resourceId) returns boolean|error {
        // Check if resource exists
        boolean exists = check utils:resourceExists(self.jdbcClient, resourceType, resourceId);
        if !exists {
            log:printWarn(string `Delete attempted on non-existent resource: ${resourceType}/${resourceId}`);
            return error(string `${resourceType}/${resourceId} not found`);
        }

        // Read the current row so we can write it to RESOURCE_HISTORY before
        // deleting. Used purely for the history snapshot now — no longer for
        // rollback (the JDBC transaction handles that).
        record {|anydata...;|} snapshot = check self.fetchResourceForHistory(resourceType, resourceId);

        int versionId = check int:fromString(snapshot.get("VERSION_ID").toString());
        log:printDebug(string `Saving version ${versionId} of ${resourceType}/${resourceId} to history before deletion`);
        check self.historyHandler.saveToHistory(resourceType, resourceId, snapshot, "DELETE");

        // Bulk-delete outgoing references in one statement.
        utils:TransactionContext refCtx = utils:newTransactionContext();
        refCtx.mainResourceId = resourceId;
        check utils:deleteReferencesBySource(self.jdbcClient, resourceType, resourceId, refCtx);

        // Delete search parameters for this resource. Non-fatal: drift in the
        // search-param side tables is recoverable, but a failed primary delete
        // must roll the whole transaction back — so search-param failures are
        // only logged.
        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is jdbc:Client {
            error? deleteSearchResult = utils:deleteSearchParametersForResource(jdbcConn, resourceType, resourceId);
            if deleteSearchResult is error {
                log:printWarn(string `Failed to delete search parameters for ${resourceType}/${resourceId}: ${deleteSearchResult.message()} (continuing)`);
            }
        }

        // Special handling for SearchParameter resources - remove from expressions table
        if resourceType == "SearchParameter" {
            error? syncResult = utils:removeSearchParameterById(self.jdbcClient, resourceId);
            if syncResult is error {
                log:printWarn(string `Failed to remove SearchParameter/${resourceId} from expressions: ${syncResult.message()} (continuing)`);
            } else {
                log:printInfo(string `Successfully removed SearchParameter/${resourceId} from expressions table`);
            }
        }

        // Delete the main resource row.
        check utils:deleteResource(self.jdbcClient, resourceType, resourceId);

        // Remove from RESOURCE_TABLE — ON DELETE CASCADE on REFERENCES
        // cleans up rows pointing TO this resource.
        error? rtResult = utils:deleteFromResourceTable(self.jdbcClient, resourceType, resourceId);
        if rtResult is error {
            log:printWarn(string `Failed to remove ${resourceType}/${resourceId} from RESOURCE_TABLE: ${rtResult.message()} (non-fatal)`);
        }

        // WORK.md §6 Phase 10: tombstone the row in FHIR_RESOURCE_INDEX so
        // downstream cross-type history feeds can observe the deletion.
        // PG-only; non-fatal.
        error? friResult = utils:markFhirResourceIndexDeleted(self.jdbcClient, resourceType, resourceId);
        if friResult is error {
            log:printWarn(string `Failed to mark FHIR_RESOURCE_INDEX deleted for ${resourceType}/${resourceId}: ${friResult.message()} (non-fatal)`);
        }

        log:printInfo(string `Successfully deleted ${resourceType}/${resourceId}`);
        return true;
    }

    // Read the row (with all columns) so we can write it to RESOURCE_HISTORY.
    private isolated function fetchResourceForHistory(string resourceType, string resourceId) returns record {|anydata...;|}|error {

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
            return error(string `${resourceType}/${resourceId} not found for history snapshot`);
        }

        return results[0];
    }
}
