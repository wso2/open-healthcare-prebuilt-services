import ballerina/log;
import ballerina/time;
import ballerinax/java.jdbc;
import ballerina/sql;
import ballerina_fhir_server.utils;

// Handler for managing resource version history
public class HistoryHandler {
    private final jdbc:Client? jdbcClient;
    private utils:TransactionHandler transactionHandler;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
        self.transactionHandler = new utils:TransactionHandler();
    }

    // Save current version to history before update/delete
    public isolated function saveToHistory(string resourceType, string resourceId,
                                          record {|anydata...;|} currentVersion, string operation) returns error? {
        log:printDebug(string `Saving ${resourceType}/${resourceId} to history (operation: ${operation})`);
        jdbc:Client jdbcConn = check utils:getValidatedJdbcClient(self.jdbcClient);

        // Get RESOURCE_JSON from current version — may be byte[] (H2) or json/string (PostgreSQL JSONB)
        anydata rawResourceJson = currentVersion.get("RESOURCE_JSON");

        anydata rawVersion = currentVersion["VERSION_ID"];
        int newVersionId = rawVersion is int ? rawVersion : check int:fromString(rawVersion.toString());

        log:printDebug(string `New history version for ${resourceType}/${resourceId}: ${newVersionId}`);

        time:Civil now = time:utcToCivil(time:utcNow());
        string timestamp = string `'${utils:formatTimestamp(now)}'`;

        // Format resource JSON for insertion based on database type
        string normalizedDbType = dbType.toLowerAscii().trim();
        string resourceJsonValue = "";
        if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
            // PostgreSQL JSONB: embed JSON string directly (SQL-escape single quotes)
            string jsonStr;
            if rawResourceJson is byte[] {
                jsonStr = check string:fromBytes(rawResourceJson);
            } else if rawResourceJson is string {
                jsonStr = rawResourceJson;
            } else {
                jsonStr = rawResourceJson.toJsonString();
            }
            string escapedJson = re `'`.replaceAll(jsonStr, "''");
            resourceJsonValue = string `'${escapedJson}'`;
        } else {
            // H2: Use X'...' hex literal format
            byte[] resourceJsonBytes = rawResourceJson is byte[]
                ? rawResourceJson
                : (rawResourceJson is string ? rawResourceJson.toBytes() : rawResourceJson.toJsonString().toBytes());
            resourceJsonValue = string `X'${resourceJsonBytes.toBase16()}'`;
        }

        // Insert into unified RESOURCE_HISTORY table with incremented version
        string sqlQuery = string `INSERT INTO "RESOURCE_HISTORY" ("RESOURCE_TYPE", "RESOURCE_ID", "VERSION_ID", "OPERATION", "CREATED_AT", "RESOURCE_JSON") VALUES ('${utils:escapeSql(resourceType)}', '${utils:escapeSql(resourceId)}', ${newVersionId}, '${operation}', ${timestamp}, ${resourceJsonValue})`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        _ = check jdbcConn->execute(query);

        log:printDebug(string `Saved version ${newVersionId} of ${resourceType}/${resourceId} to unified history table`);
    }

    // Build a history entry map from a raw JSON string and metadata fields
    private isolated function buildHistoryEntry(string jsonStr, int versionId, string operation, time:Civil createdAt) returns map<json>|error {
        json resourceJson = check jsonStr.fromJsonString();
        map<json> resourceMap = <map<json>>resourceJson;
        json existingMeta = resourceMap["meta"];
        map<json> metaMap = existingMeta is map<json> ? existingMeta : {};
        metaMap["versionId"] = versionId.toString();
        string timestamp = utils:formatTimestampISO8601(createdAt);
        metaMap["lastUpdated"] = timestamp;
        resourceMap["meta"] = metaMap;
        return {"resource": resourceMap, "operation": operation, "lastModified": timestamp};
    }

    // Fetch RESOURCE_JSON rows from RESOURCE_HISTORY and return normalised JSON strings.
    // Uses db-type-specific SELECT and result record types to satisfy Ballerina SQL module
    // type constraints (byte[] for H2 BINARY LARGE OBJECT, string for PostgreSQL JSONB).
    private isolated function queryHistoryRows(jdbc:Client jdbcConn, string sqlQuery)
            returns [string, int, string, time:Civil][]|error {
        string normalizedDbType = dbType.toLowerAscii().trim();
        [string, int, string, time:Civil][] rows = [];

        if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
            string pgSql = re `"RESOURCE_JSON"`.replace(sqlQuery,
                string `CAST("RESOURCE_JSON" AS TEXT) AS "RESOURCE_JSON"`);
            sql:ParameterizedQuery pgQuery = new utils:RawSQLQuery(pgSql);
            stream<record {|string RESOURCE_JSON; int VERSION_ID; string OPERATION; time:Civil CREATED_AT;|}, sql:Error?> pgStream = jdbcConn->query(pgQuery);
            record {|string RESOURCE_JSON; int VERSION_ID; string OPERATION; time:Civil CREATED_AT;|}[] pgResults = check from var r in pgStream select r;
            foreach var r in pgResults {
                rows.push([r.RESOURCE_JSON, r.VERSION_ID, r.OPERATION, r.CREATED_AT]);
            }
        } else {
            sql:ParameterizedQuery h2Query = new utils:RawSQLQuery(sqlQuery);
            stream<record {|byte[] RESOURCE_JSON; int VERSION_ID; string OPERATION; time:Civil CREATED_AT;|}, sql:Error?> h2Stream = jdbcConn->query(h2Query);
            record {|byte[] RESOURCE_JSON; int VERSION_ID; string OPERATION; time:Civil CREATED_AT;|}[] h2Results = check from var r in h2Stream select r;
            foreach var r in h2Results {
                string jsonStr = check string:fromBytes(r.RESOURCE_JSON);
                rows.push([jsonStr, r.VERSION_ID, r.OPERATION, r.CREATED_AT]);
            }
        }
        return rows;
    }

    // Get a specific version of a resource from history
    public isolated function getResourceVersion(string resourceType, string resourceId, int versionId) returns map<json>|error {
        log:printDebug(string `Fetching ${resourceType}/${resourceId}/_history/${versionId}`);
        jdbc:Client jdbcConn = check utils:getValidatedJdbcClient(self.jdbcClient);

        string sqlQuery = string `SELECT "RESOURCE_JSON", "VERSION_ID", "OPERATION", "CREATED_AT" FROM "RESOURCE_HISTORY" WHERE "RESOURCE_TYPE" = '${utils:escapeSql(resourceType)}' AND "RESOURCE_ID" = '${utils:escapeSql(resourceId)}' AND "VERSION_ID" = ${versionId}`;

        [string, int, string, time:Civil][] rows = check self.queryHistoryRows(jdbcConn, sqlQuery);

        if rows.length() == 0 {
            log:printWarn(string `History version not found: ${resourceType}/${resourceId}/_history/${versionId}`);
            return error(string `${resourceType}/${resourceId}/_history/${versionId} not found`);
        }

        var [jsonStr, rowVersionId, operation, createdAt] = rows[0];
        map<json> entry = check self.buildHistoryEntry(jsonStr, rowVersionId, operation, createdAt);

        log:printDebug(string `Retrieved version ${versionId} of ${resourceType}/${resourceId} from history`);
        return entry;
    }

    // Get all history versions of a specific resource
    public isolated function getResourceHistory(string resourceType, string resourceId) returns map<json>[]|error {
        log:printDebug(string `Fetching all history for ${resourceType}/${resourceId}`);
        jdbc:Client jdbcConn = check utils:getValidatedJdbcClient(self.jdbcClient);

        string sqlQuery = string `SELECT "RESOURCE_JSON", "VERSION_ID", "OPERATION", "CREATED_AT" FROM "RESOURCE_HISTORY" WHERE "RESOURCE_TYPE" = '${utils:escapeSql(resourceType)}' AND "RESOURCE_ID" = '${utils:escapeSql(resourceId)}' ORDER BY "VERSION_ID" DESC`;

        [string, int, string, time:Civil][] rows = check self.queryHistoryRows(jdbcConn, sqlQuery);

        map<json>[] versions = [];
        foreach var [jsonStr, rowVersionId, operation, createdAt] in rows {
            versions.push(check self.buildHistoryEntry(jsonStr, rowVersionId, operation, createdAt));
        }

        log:printDebug(string `Retrieved ${versions.length()} history version(s) for ${resourceType}/${resourceId}`);
        return versions;
    }

    // Get all history for all resources of a type
    public isolated function getAllHistory(string resourceType) returns map<json>[]|error {
        log:printDebug(string `Fetching all history for resource type: ${resourceType}`);
        jdbc:Client jdbcConn = check utils:getValidatedJdbcClient(self.jdbcClient);

        string sqlQuery = string `SELECT "RESOURCE_JSON", "VERSION_ID", "OPERATION", "CREATED_AT" FROM "RESOURCE_HISTORY" WHERE "RESOURCE_TYPE" = '${utils:escapeSql(resourceType)}' ORDER BY "CREATED_AT" DESC`;

        [string, int, string, time:Civil][] rows = check self.queryHistoryRows(jdbcConn, sqlQuery);

        map<json>[] versions = [];
        foreach var [jsonStr, rowVersionId, operation, createdAt] in rows {
            versions.push(check self.buildHistoryEntry(jsonStr, rowVersionId, operation, createdAt));
        }

        log:printDebug(string `Retrieved ${versions.length()} history version(s) for all ${resourceType} resources`);
        return versions;
    }
}
