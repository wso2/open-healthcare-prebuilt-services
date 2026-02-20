import ballerina/log;
import ballerina/uuid;
import ballerina/regex;
import ballerina/sql;
import ballerina/time;

import ballerinax/java.jdbc;

// Configuration for ID generation strategy
public configurable boolean useServerGeneratedIds = false;

// Common constants
const string JDBC_NOT_INITIALIZED = "JDBC Client is not initialized";
const string RESOURCE_JSON_COLUMN = "RESOURCE_JSON";
const string VERSION_ID_COLUMN = "VERSION_ID";
const string CREATED_AT_COLUMN = "CREATED_AT";
const string UPDATED_AT_COLUMN = "UPDATED_AT";
const string LAST_UPDATED_COLUMN = "LAST_UPDATED";

// Escape single quotes in SQL string values to prevent SQL injection
public isolated function escapeSql(string value) returns string {
    return regex:replaceAll(value, "'", "''");
}

// Validate and return JDBC client or throw error
// Use this instead of repeating validation logic in every method
public isolated function getValidatedJdbcClient(jdbc:Client? jdbcClient) returns jdbc:Client|error {
    if jdbcClient is () {
        return error(JDBC_NOT_INITIALIZED);
    }
    return jdbcClient;
}

// Generate a unique resource ID using UUID
// Returns full UUID without dashes for maximum uniqueness (32 characters)
// This prevents collisions during high-concurrency performance tests
public isolated function generateResourceId() returns string {
    string fullUuid = uuid:createType1AsString();
    return regex:replaceAll(fullUuid, "-", "");
}

// Format a value for SQL INSERT/UPDATE statements
public isolated function formatSqlValue(anydata value) returns string {
    if value is () {
        return "NULL";
    } else if value is string {
        string escaped = escapeSql(value);
        return string `'${escaped}'`;
    } else if value is int|float|decimal {
        return value.toString();
    } else if value is boolean {
        return value ? "TRUE" : "FALSE";
    } else if value is time:Civil {
        return string `'${formatTimestamp(value)}'`;
    } else if value is time:Date {
        time:Date dateVal = <time:Date>value;
        return string `'${dateVal.year}-${padZero(dateVal.month)}-${padZero(dateVal.day)}'`;
    } else if value is byte[] {
        byte[] bytes = <byte[]>value;
        // Database-specific binary data formatting
        string normalizedDbType = dbType.toLowerAscii().trim();
        if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
            // PostgreSQL: Use decode() function for BYTEA
            return string `decode('${bytes.toBase16()}', 'hex')`;
        } else {
            // H2: Use X'...' hex literal format
            return string `X'${bytes.toBase16()}'`;
        }
    } else {
        string escaped = escapeSql(value.toString());
        return string `'${escaped}'`;
    }
}

// Format value specifically for DATE columns (date only, no time)
public isolated function formatDateValue(anydata value) returns string {
    if value is () {
        return "NULL";
    } else if value is time:Date {
        time:Date dateVal = <time:Date>value;
        return string `'${dateVal.year}-${padZero(dateVal.month)}-${padZero(dateVal.day)}'`;
    } else if value is time:Civil {
        // Extract only the date part from Civil
        return string `'${value.year}-${padZero(value.month)}-${padZero(value.day)}'`;
    } else if value is string {
        // If it's already a string, try to parse and extract date part
        string escaped = escapeSql(value);
        // If format is YYYY-MM-DD or YYYY-MM-DD..., extract date part
        if escaped.length() >= 10 {
            return string `'${escaped.substring(0, 10)}'`;
        }
        return string `'${escaped}'`;
    } else {
        string escaped = escapeSql(value.toString());
        return string `'${escaped}'`;
    }
}

// Pad numbers with leading zero
public isolated function padZero(int value) returns string {
    return value < 10 ? string `0${value}` : value.toString();
}

// Format timestamp to SQL DATETIME format
public isolated function formatTimestamp(time:Civil timestamp) returns string {
    decimal seconds = timestamp.second ?: 0.0d;
    return string `${timestamp.year}-${padZero(timestamp.month)}-${padZero(timestamp.day)} ${padZero(timestamp.hour)}:${padZero(timestamp.minute)}:${formatSeconds(seconds)}`;
}

// Format timestamp to ISO 8601 format (for FHIR responses)
public isolated function formatTimestampISO8601(time:Civil timestamp) returns string {
    decimal seconds = timestamp.second ?: 0.0d;
    // Extract just the whole seconds part safely (0-59)
    int wholeSeconds = <int>seconds;
    if wholeSeconds >= 60 {
        wholeSeconds = 59;
    }
    return string `${timestamp.year}-${padZero(timestamp.month)}-${padZero(timestamp.day)}T${padZero(timestamp.hour)}:${padZero(timestamp.minute)}:${padZero(wholeSeconds)}.000Z`;
}

// Validate if a referenced resource exists in the database.
// Uses SELECT 1 LIMIT 1 which is cheaper than COUNT(*) as the DB stops at the first match.
public isolated function validateReferenceExists(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns boolean|error {
    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);

    string tableName = getTableName(resourceType);
    string primaryKeyColumn = getPrimaryKeyColumn(resourceType);

    string existsQuery = string `SELECT 1 as found FROM "${tableName}" WHERE "${primaryKeyColumn}" = '${escapeSql(resourceId)}' LIMIT 1`;
    RawSQLQuery query = new(existsQuery);
    stream<record {int found;}, sql:Error?> resultStream = validatedClient->query(query);
    record {int found;}[] results = check from var result in resultStream select result;
    return results.length() > 0;
}

// Validate all references before saving.
// Optimised: deduplicates references and issues one IN-clause query per referenced
// resource type instead of one query per individual reference.
public isolated function validateReferences(jdbc:Client? jdbcClient, json[] references) returns error? {
    if references.length() == 0 {
        return;
    }

    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);

    // Collect unique (resourceType -> set of IDs) from all reference entries
    map<map<boolean>> byType = {};
    string? firstBadFormat = ();

    foreach json referenceEntry in references {
        if referenceEntry is map<json> {
            foreach var [_, paramValue] in referenceEntry.entries() {
                json[] refs = paramValue is json[] ? <json[]>paramValue : [paramValue];
                foreach json ref in refs {
                    if !(ref is map<json>) {
                        continue;
                    }
                    map<json> refMap = <map<json>>ref;
                    json refString = refMap["reference"];
                    if !(refString is string) || refString == "" {
                        continue;
                    }
                    string[] parts = regex:split(<string>refString, "/");
                    if parts.length() != 2 {
                        firstBadFormat = <string>refString;
                        continue;
                    }
                    string rType = parts[0];
                    string rId   = parts[1];
                    if !byType.hasKey(rType) {
                        byType[rType] = {};
                    }
                    byType[rType][rId] = true;
                }
            }
        }
    }

    if firstBadFormat is string {
        return error(string `Invalid reference format: ${firstBadFormat}. Expected format: ResourceType/id`);
    }

    // One query per resource type with an IN clause over all referenced IDs
    foreach var [resourceType, idSet] in byType.entries() {
        string[] ids = idSet.keys();
        string tableName      = getTableName(resourceType);
        string primaryKeyCol  = getPrimaryKeyColumn(resourceType);

        // Build  WHERE pk IN ('id1','id2',...)
        string[] quotedIds = from string id in ids select string `'${escapeSql(id)}'`;
        string idList = string:'join(", ", ...quotedIds);
        string batchQuery = string `SELECT "${primaryKeyCol}" FROM "${tableName}" WHERE "${primaryKeyCol}" IN (${idList})`;

        RawSQLQuery query = new(batchQuery);
        stream<record {|string...;|}, sql:Error?> resultStream = validatedClient->query(query);
        record {|string...;|}[] rows = check from var row in resultStream select row;

        // Build a set of found IDs
        map<boolean> foundIds = {};
        foreach record {|string...;|} row in rows {
            string? foundId = row[primaryKeyCol];
            if foundId is string {
                foundIds[foundId] = true;
            }
        }

        // Report the first missing reference
        foreach string id in ids {
            if !foundIds.hasKey(id) {
                return error(string `Referenced resource does not exist: ${resourceType}/${id}`);
            }
        }
    }

    log:printDebug("All references validated successfully");
}

// Delete main resource using generic JDBC query
public isolated function deleteResource(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns error? {
    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);

    // Get table name and primary key column
    string tableName = getTableName(resourceType);
    string primaryKeyColumn = getPrimaryKeyColumn(resourceType);
    
    // Build DELETE query with escaped resourceId
    string deleteQuery = string `DELETE FROM "${tableName}" WHERE "${primaryKeyColumn}" = '${escapeSql(resourceId)}'`;
    
    // Execute query using RawSQLQuery
    RawSQLQuery query = new(deleteQuery);
    sql:ExecutionResult result = check validatedClient->execute(query);
    
    // Check if resource was deleted
    if result.affectedRowCount == 0 {
        return error(string `Resource not found: ${resourceType}/${resourceId}`);
    }
    
    log:printDebug(string `Deleted resource: ${resourceType}/${resourceId}`);
}

// Delete references using generic JDBC query
public isolated function deleteReferences(jdbc:Client? jdbcClient, int[] referenceIds, TransactionContext 'transaction) returns error? {
    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);

    foreach int refId in referenceIds {
        // Build DELETE query for REFERENCES table
        string deleteQuery = string `DELETE FROM "REFERENCES" WHERE "ID" = ${refId}`;
        
        // Execute query using RawSQLQuery
        RawSQLQuery query = new(deleteQuery);
        sql:ExecutionResult result = check validatedClient->execute(query);
        
        if result.affectedRowCount > 0 {
            'transaction.deletedReferenceIds.push(refId);
            log:printDebug(string `Deleted reference [${refId}]`);
        } else {
            log:printWarn(string `Reference [${refId}] not found, skipping`);
        }
    }
}

public isolated function saveReferences(jdbc:Client? jdbcClient, json[] references, string sourceResType, string sourceResId, TransactionContext 'transaction) returns error? {
    if references.length() == 0 {
        log:printDebug("No references to save");
        return;
    }

    log:printDebug(string `Saving references for ${sourceResType}/${sourceResId}`);

    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);

    // Build one parameterised INSERT per reference row using sql: template literals so
    // batchExecute sees the same SQL structure for every row (only bound values differ).
    sql:ParameterizedQuery[] queries = [];

    // Get current timestamp once for all rows.
    // Pass as time:Civil so the JDBC driver binds it as a proper timestamp type —
    // passing a string causes PostgreSQL to reject it with "character varying vs timestamp".
    time:Civil currentTime = time:utcToCivil(time:utcNow());

    foreach json referenceEntry in references {
        if !(referenceEntry is map<json>) {
            continue;
        }
        foreach var [paramName, paramValue] in (<map<json>>referenceEntry).entries() {
            json[] refs = paramValue is json[] ? <json[]>paramValue : [paramValue];
            foreach json singleRef in refs {
                if !(singleRef is map<json>) {
                    log:printDebug(string `Skipping non-object reference: ${singleRef.toString()}`);
                    continue;
                }
                map<json> refMap = <map<json>>singleRef;
                json refString = refMap["reference"];
                if !(refString is string) || refString == "" {
                    log:printDebug("Empty or invalid reference, skipping");
                    continue;
                }
                string[] refParts = regex:split(<string>refString, "/");
                if refParts.length() != 2 {
                    return error(string `Invalid reference format: ${refString}. Expected format: ResourceType/id`);
                }
                string targetResourceType = refParts[0];
                string targetResourceId = refParts[1];
                json displayJson = refMap["display"];
                string displayValue = displayJson is string ? displayJson : "";

                // Use sql: template literal so all rows share the same query structure.
                // batchExecute requires identical SQL templates — only bound values may differ.
                sql:ParameterizedQuery insertQuery = `INSERT INTO "REFERENCES" ("SOURCE_RESOURCE_TYPE", "SOURCE_RESOURCE_ID", "SOURCE_EXPRESSION", "TARGET_RESOURCE_TYPE", "TARGET_RESOURCE_ID", "DISPLAY_VALUE", "CREATED_AT", "UPDATED_AT", "LAST_UPDATED") VALUES (${sourceResType}, ${sourceResId}, ${paramName}, ${targetResourceType}, ${targetResourceId}, ${displayValue}, ${currentTime}, ${currentTime}, ${currentTime})`;
                queries.push(insertQuery);
            }
        }
    }

    if queries.length() == 0 {
        log:printDebug("No valid reference rows to insert");
        return;
    }

    _ = check validatedClient->batchExecute(queries);
    // Mark references as saved so rollback can delete by source in one statement
    'transaction.referencesSaved = true;

    log:printDebug(string `Batch-inserted ${queries.length()} reference(s) for ${sourceResType}/${sourceResId}`);
}

// Helper function to format numbers to two digits
isolated function formatTwoDigits(int value) returns string {
    if value < 10 {
        return string `0${value}`;
    }
    return value.toString();
}

// Helper function to format seconds with milliseconds
isolated function formatSeconds(decimal seconds) returns string {
    // Ensure seconds is non-negative
    decimal absSeconds = seconds < 0.0d ? 0.0d : seconds;
    
    // Handle edge case where seconds might be >= 60 (should not happen but just in case)
    if absSeconds >= 60.0d {
        absSeconds = 59.999d;
    }
    
    // Round to 3 decimal places to avoid precision issues
    decimal roundedSeconds = <decimal>(<int>(absSeconds * 1000.0d)) / 1000.0d;
    
    int wholePart = <int>roundedSeconds;
    decimal fractionalPart = roundedSeconds - <decimal>wholePart;
    int millis = <int>(fractionalPart * 1000.0d);
    
    // Final safety check: if rounding caused seconds to reach 60, cap at 59.999
    if wholePart >= 60 {
        wholePart = 59;
        millis = 999;
    }
    
    // Ensure millis is within valid range
    if millis < 0 {
        millis = 0;
    }
    if millis >= 1000 {
        wholePart = wholePart + 1;
        millis = 0;
        // Check again if this pushed seconds to 60
        if wholePart >= 60 {
            wholePart = 59;
            millis = 999;
        }
    }
    
    string secondStr = wholePart < 10 ? string `0${wholePart}` : wholePart.toString();
    
    // Format milliseconds with leading zeros if needed
    string millisStr = millis.toString();
    if millis < 10 {
        millisStr = string `00${millis}`;
    } else if millis < 100 {
        millisStr = string `0${millis}`;
    }
    
    return string `${secondStr}.${millisStr}`;
}

// Custom class to execute raw SQL queries
public class RawSQLQuery {
    *sql:ParameterizedQuery;
    public final string[] & readonly strings;
    public final sql:Value[] & readonly insertions;

    public isolated function init(string sqlQuery) {
        self.strings = [sqlQuery].cloneReadOnly();
        self.insertions = [].cloneReadOnly();
    }
}
