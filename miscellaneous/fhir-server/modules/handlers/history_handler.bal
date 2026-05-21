import ballerina_fhir_server.utils;

import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/java.jdbc;

public class HistoryHandler {
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
    }

    // Append a snapshot to resource_history. Called from create/update/delete flows.
    public isolated function saveToHistory(
        string resourceType,
        string resourceId,
        int versionId,
        string operation,
        json resourceJson
    ) returns error? {
        jdbc:Client jc = check utils:getValidatedJdbcClient(self.jdbcClient);
        string jsonStr = resourceJson.toJsonString();
        time:Civil now = time:utcToCivil(time:utcNow());

        boolean isPostgres = isPostgresDb();
        if isPostgres {
            _ = check jc->execute(`
                INSERT INTO resource_history (resource_id, resource_type, version_id, operation, recorded_at, resource_json)
                VALUES (${resourceId}, ${resourceType}, ${versionId}, ${operation}, ${now}, ${jsonStr}::jsonb)`);
        } else {
            _ = check jc->execute(`
                INSERT INTO "resource_history" ("resource_id", "resource_type", "version_id", "operation", "recorded_at", "resource_json")
                VALUES (${resourceId}, ${resourceType}, ${versionId}, ${operation}, ${now}, ${jsonStr})`);
        }
        log:printDebug(string `History: ${operation} ${resourceType}/${resourceId} v${versionId}`);
    }

    // Retrieve a specific version of a resource from history.
    public isolated function getResourceVersion(string resourceType, string resourceId, int versionId) returns map<json>|error {
        jdbc:Client jc = check utils:getValidatedJdbcClient(self.jdbcClient);
        HistoryRow|sql:Error row = queryHistoryRow(jc, resourceType, resourceId, versionId);
        if row is sql:NoRowsError {
            return error(string `${resourceType}/${resourceId}/_history/${versionId} not found`);
        }
        if row is sql:Error { return row; }
        return buildHistoryEntry(row);
    }

    // Retrieve full history for a single resource.
    public isolated function getResourceHistory(string resourceType, string resourceId) returns map<json>[]|error {
        jdbc:Client jc = check utils:getValidatedJdbcClient(self.jdbcClient);
        return queryHistoryRows(jc, resourceType, resourceId, ());
    }

    // Retrieve history across all instances of a resource type.
    public isolated function getAllHistory(string resourceType) returns map<json>[]|error {
        jdbc:Client jc = check utils:getValidatedJdbcClient(self.jdbcClient);
        return queryHistoryRows(jc, resourceType, (), ());
    }
}

// ─── Internal query helpers ───────────────────────────────────────────────────

type HistoryRow record {|
    string    resource_json;
    int       version_id;
    string    operation;
    time:Civil recorded_at;
|};

isolated function queryHistoryRow(
    jdbc:Client jc,
    string resourceType,
    string resourceId,
    int versionId
) returns HistoryRow|sql:Error {
    if isPostgresDb() {
        return jc->queryRow(`
            SELECT CAST(resource_json AS TEXT) AS resource_json, version_id, operation, recorded_at
            FROM resource_history
            WHERE resource_type = ${resourceType} AND resource_id = ${resourceId} AND version_id = ${versionId}`);
    }
    return jc->queryRow(`
        SELECT "resource_json", "version_id", "operation", "recorded_at"
        FROM "resource_history"
        WHERE "resource_type" = ${resourceType} AND "resource_id" = ${resourceId} AND "version_id" = ${versionId}`);
}

isolated function queryHistoryRows(
    jdbc:Client jc,
    string resourceType,
    string? resourceId,
    int? versionId
) returns map<json>[]|error {
    sql:ParameterizedQuery q;
    if isPostgresDb() {
        q = `SELECT CAST(resource_json AS TEXT) AS resource_json, version_id, operation, recorded_at
             FROM resource_history WHERE resource_type = ${resourceType}`;
        if resourceId is string {
            q = sql:queryConcat(q, ` AND resource_id = ${resourceId}`);
        }
        q = sql:queryConcat(q, ` ORDER BY version_id DESC`);
    } else {
        q = `SELECT "resource_json", "version_id", "operation", "recorded_at"
             FROM "resource_history" WHERE "resource_type" = ${resourceType}`;
        if resourceId is string {
            q = sql:queryConcat(q, ` AND "resource_id" = ${resourceId}`);
        }
        q = sql:queryConcat(q, ` ORDER BY "version_id" DESC`);
    }

    stream<HistoryRow, sql:Error?> rows = jc->query(q);
    map<json>[] result = [];
    check from HistoryRow row in rows
        do {
            result.push(check buildHistoryEntry(row));
        };
    return result;
}

isolated function buildHistoryEntry(HistoryRow row) returns map<json>|error {
    json res = check row.resource_json.fromJsonString();
    map<json> resMap = res is map<json> ? <map<json>>res : {"raw": res};
    map<json> meta = resMap["meta"] is map<json> ? <map<json>>resMap["meta"] : {};
    meta["versionId"]   = row.version_id.toString();
    meta["lastUpdated"] = utils:formatTimestampISO8601(row.recorded_at);
    resMap["meta"] = meta;
    return {
        resource: resMap,
        operation: row.operation,
        lastModified: meta["lastUpdated"]
    };
}
