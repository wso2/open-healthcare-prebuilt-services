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

        // Get RESOURCE_JSON from current version
        byte[] resourceJsonBytes = check currentVersion.get("RESOURCE_JSON").ensureType();

        // Read the VERSION_ID directly from the record that was just written/read —
        // this avoids a MAX(VERSION_ID) round-trip on every create/update/delete.
        // create_mapper always sets VERSION_ID=1, update_mapper increments it, and
        // the delete backup record carries the existing VERSION_ID from the SELECT.
        anydata rawVersion = currentVersion["VERSION_ID"];
        int newVersionId = rawVersion is int ? rawVersion : check int:fromString(rawVersion.toString());

        log:printDebug(string `New history version for ${resourceType}/${resourceId}: ${newVersionId}`);
        
        // Get current timestamp - use formatTimestamp for consistency and safety
        time:Civil now = time:utcToCivil(time:utcNow());
        string timestamp = string `'${utils:formatTimestamp(now)}'`;
        
        // Format binary data based on database type
        string normalizedDbType = dbType.toLowerAscii().trim();
        string resourceJsonValue = "";
        if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
            // PostgreSQL: Use decode() function for BYTEA
            resourceJsonValue = string `decode('${resourceJsonBytes.toBase16()}', 'hex')`;
        } else {
            // H2: Use X'...' hex literal format
            resourceJsonValue = string `X'${resourceJsonBytes.toBase16()}'`;
        }
        
        // Insert into unified RESOURCE_HISTORY table with incremented version
        string sqlQuery = string `INSERT INTO "RESOURCE_HISTORY" ("RESOURCE_TYPE", "RESOURCE_ID", "VERSION_ID", "OPERATION", "CREATED_AT", "RESOURCE_JSON") VALUES ('${utils:escapeSql(resourceType)}', '${utils:escapeSql(resourceId)}', ${newVersionId}, '${operation}', ${timestamp}, ${resourceJsonValue})`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);
        
        _ = check jdbcConn->execute(query);
        
        log:printDebug(string `Saved version ${newVersionId} of ${resourceType}/${resourceId} to unified history table`);
    }
    
    // Get a specific version of a resource from history
    public isolated function getResourceVersion(string resourceType, string resourceId, int versionId) returns map<json>|error {
        log:printDebug(string `Fetching ${resourceType}/${resourceId}/_history/${versionId}`);
        jdbc:Client jdbcConn = check utils:getValidatedJdbcClient(self.jdbcClient);

        string sqlQuery = string `SELECT "RESOURCE_JSON", "VERSION_ID", "OPERATION", "CREATED_AT" FROM "RESOURCE_HISTORY" WHERE "RESOURCE_TYPE" = '${utils:escapeSql(resourceType)}' AND "RESOURCE_ID" = '${utils:escapeSql(resourceId)}' AND "VERSION_ID" = ${versionId}`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        stream<record {|byte[] RESOURCE_JSON; int VERSION_ID; string OPERATION; time:Civil CREATED_AT;|}, sql:Error?> resultStream = jdbcConn->query(query);

        record {|byte[] RESOURCE_JSON; int VERSION_ID; string OPERATION; time:Civil CREATED_AT;|}[] results = check from var result in resultStream
            select result;

        if results.length() == 0 {
            log:printWarn(string `History version not found: ${resourceType}/${resourceId}/_history/${versionId}`);
            return error(string `${resourceType}/${resourceId}/_history/${versionId} not found`);
        }

        // Convert RESOURCE_JSON to json
        string jsonStr = check string:fromBytes(results[0].RESOURCE_JSON);
        json resourceJson = check jsonStr.fromJsonString();

        // Add/update meta section with versionId and lastUpdated
        map<json> resourceMap = <map<json>>resourceJson;
        json existingMeta = resourceMap["meta"];
        map<json> metaMap = existingMeta is map<json> ? existingMeta : {};
        
        metaMap["versionId"] = results[0].VERSION_ID.toString();
        
        // Format timestamp as ISO 8601 string
        time:Civil createdAt = results[0].CREATED_AT;
        string timestamp = utils:formatTimestampISO8601(createdAt);
        metaMap["lastUpdated"] = timestamp;
        
        resourceMap["meta"] = metaMap;

        log:printDebug(string `Retrieved version ${versionId} of ${resourceType}/${resourceId} from history`);
        return {"resource": resourceMap, "operation": results[0].OPERATION, "lastModified": timestamp};
    }
    
    // Get all history versions of a specific resource
    public isolated function getResourceHistory(string resourceType, string resourceId) returns map<json>[]|error {
        log:printDebug(string `Fetching all history for ${resourceType}/${resourceId}`);
        jdbc:Client jdbcConn = check utils:getValidatedJdbcClient(self.jdbcClient);

        string sqlQuery = string `SELECT "RESOURCE_JSON", "VERSION_ID", "OPERATION", "CREATED_AT" FROM "RESOURCE_HISTORY" WHERE "RESOURCE_TYPE" = '${utils:escapeSql(resourceType)}' AND "RESOURCE_ID" = '${utils:escapeSql(resourceId)}' ORDER BY "VERSION_ID" DESC`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        stream<record {|byte[] RESOURCE_JSON; int VERSION_ID; string OPERATION; time:Civil CREATED_AT;|}, sql:Error?> resultStream = jdbcConn->query(query);

        record {|byte[] RESOURCE_JSON; int VERSION_ID; string OPERATION; time:Civil CREATED_AT;|}[] results = check from var result in resultStream
            select result;

        map<json>[] versions = [];
        foreach var historyRecord in results {
            string jsonStr = check string:fromBytes(historyRecord.RESOURCE_JSON);
            json resourceJson = check jsonStr.fromJsonString();
            
            // Add/update meta section with versionId and lastUpdated
            map<json> resourceMap = <map<json>>resourceJson;
            json existingMeta = resourceMap["meta"];
            map<json> metaMap = existingMeta is map<json> ? existingMeta : {};
            
            metaMap["versionId"] = historyRecord.VERSION_ID.toString();
            
            // Format timestamp as ISO 8601 string
            time:Civil createdAt = historyRecord.CREATED_AT;
            string timestamp = utils:formatTimestampISO8601(createdAt);
            metaMap["lastUpdated"] = timestamp;
            
            resourceMap["meta"] = metaMap;
            
            versions.push({"resource": resourceMap, "operation": historyRecord.OPERATION, "lastModified": timestamp});
        }

        log:printDebug(string `Retrieved ${versions.length()} history version(s) for ${resourceType}/${resourceId}`);
        return versions;
    }
    
    // Get all history for all resources of a type
    public isolated function getAllHistory(string resourceType) returns map<json>[]|error {
        log:printDebug(string `Fetching all history for resource type: ${resourceType}`);
        jdbc:Client jdbcConn = check utils:getValidatedJdbcClient(self.jdbcClient);

        string sqlQuery = string `SELECT "RESOURCE_JSON", "VERSION_ID", "OPERATION", "CREATED_AT" FROM "RESOURCE_HISTORY" WHERE "RESOURCE_TYPE" = '${utils:escapeSql(resourceType)}' ORDER BY "CREATED_AT" DESC`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        stream<record {|byte[] RESOURCE_JSON; int VERSION_ID; string OPERATION; time:Civil CREATED_AT;|}, sql:Error?> resultStream = jdbcConn->query(query);

        record {|byte[] RESOURCE_JSON; int VERSION_ID; string OPERATION; time:Civil CREATED_AT;|}[] results = check from var result in resultStream
            select result;

        map<json>[] versions = [];
        foreach var historyRecord in results {
            string jsonStr = check string:fromBytes(historyRecord.RESOURCE_JSON);
            json resourceJson = check jsonStr.fromJsonString();
            
            // Add/update meta section with versionId and lastUpdated
            map<json> resourceMap = <map<json>>resourceJson;
            json existingMeta = resourceMap["meta"];
            map<json> metaMap = existingMeta is map<json> ? existingMeta : {};
            
            metaMap["versionId"] = historyRecord.VERSION_ID.toString();
            
            // Format timestamp as ISO 8601 string
            time:Civil createdAt = historyRecord.CREATED_AT;
            string timestamp = utils:formatTimestampISO8601(createdAt);
            metaMap["lastUpdated"] = timestamp;
            
            resourceMap["meta"] = metaMap;
            
            versions.push({"resource": resourceMap, "operation": historyRecord.OPERATION, "lastModified": timestamp});
        }

        log:printDebug(string `Retrieved ${versions.length()} history version(s) for all ${resourceType} resources`);
        return versions;
    }
}
