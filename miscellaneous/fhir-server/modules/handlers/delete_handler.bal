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
        jdbc:Client jc = check utils:getValidatedJdbcClient(self.jdbcClient);

        transaction {
            // Read current resource for history snapshot (inside transaction for atomicity)
            json currentJson = check readCurrentJson(jc, resourceType, resourceId);

            // Determine current version
            int currentVersion = check readCurrentVersion(jc, resourceType, resourceId);

            // Persist DELETE snapshot in history
            check self.historyHandler.saveToHistory(resourceType, resourceId, currentVersion, "DELETE", currentJson);

            // Delete search index rows (sp_* tables) — explicitly since soft-delete
            // doesn't fire the ON DELETE CASCADE from the resources FK
            check utils:deleteAllSearchParams(jc, resourceId, resourceType);

            // Soft-delete the resource row (preserves it for _history endpoint)
            check softDelete(jc, resourceType, resourceId);

            check commit;
        } on fail error e {
            log:printError(string `Delete failed for ${resourceType}/${resourceId}: ${e.message()}`);
            return e;
        }

        log:printInfo(string `Deleted ${resourceType}/${resourceId}`);
        return true;
    }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

isolated function readCurrentJson(jdbc:Client jc, string resourceType, string resourceId) returns json|error {
    boolean isPostgres = utils:dbType.toLowerAscii().trim() == "postgresql" || utils:dbType.toLowerAscii().trim() == "postgres";
    type JsonRow record {| string resource_json; |};
    sql:ParameterizedQuery q;
    if isPostgres {
        q = `SELECT CAST(resource_json AS TEXT) AS resource_json FROM resources WHERE fhir_id = ${resourceId} AND resource_type = ${resourceType} FOR UPDATE`;
    } else {
        q = `SELECT "resource_json" FROM "resources" WHERE "fhir_id" = ${resourceId} AND "resource_type" = ${resourceType} FOR UPDATE`;
    }
    JsonRow|sql:Error row = jc->queryRow(q);
    if row is sql:NoRowsError {
        return error(string `${resourceType}/${resourceId} not found`);
    }
    if row is sql:Error {
        return row;
    }
    return check row.resource_json.fromJsonString();
}

isolated function readCurrentVersion(jdbc:Client jc, string resourceType, string resourceId) returns int|error {
    boolean isPostgres = utils:dbType.toLowerAscii().trim() == "postgresql" || utils:dbType.toLowerAscii().trim() == "postgres";
    type VerRow record {| int version_id; |};
    sql:ParameterizedQuery q;
    if isPostgres {
        q = `SELECT version_id FROM resources WHERE fhir_id = ${resourceId} AND resource_type = ${resourceType} FOR UPDATE`;
    } else {
        q = `SELECT "version_id" FROM "resources" WHERE "fhir_id" = ${resourceId} AND "resource_type" = ${resourceType} FOR UPDATE`;
    }
    VerRow|sql:Error row = jc->queryRow(q);
    if row is sql:NoRowsError {
        return error(string `${resourceType}/${resourceId} not found`);
    }
    if row is sql:Error {
        return row;
    }
    return row.version_id;
}

isolated function softDelete(jdbc:Client jc, string resourceType, string resourceId) returns error? {
    boolean isPostgres = utils:dbType.toLowerAscii().trim() == "postgresql" || utils:dbType.toLowerAscii().trim() == "postgres";
    if isPostgres {
        _ = check jc->execute(`UPDATE resources SET is_deleted = TRUE WHERE fhir_id = ${resourceId} AND resource_type = ${resourceType}`);
    } else {
        _ = check jc->execute(`UPDATE "resources" SET "is_deleted" = TRUE WHERE "fhir_id" = ${resourceId} AND "resource_type" = ${resourceType}`);
    }
}
