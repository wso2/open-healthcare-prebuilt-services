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
    string escaped = regex:replaceAll(value, "'", "''");
    return regex:replaceAll(escaped, "%", "\\%");
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

// Check whether a resource exists by looking it up in RESOURCE_TABLE.
// Replaces the old per-type-table validateReferenceExists with a single generic query.
public isolated function resourceExists(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns boolean|error {
    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);
    sql:ParameterizedQuery q = `SELECT 1 FROM "RESOURCE_TABLE" WHERE "ID" = ${resourceId} AND "TYPE" = ${resourceType} LIMIT 1`;
    stream<record {int '1;}, sql:Error?> resultStream = validatedClient->query(q);
    record {int '1;}[] rows = check from var r in resultStream select r;
    return rows.length() > 0;
}

// Insert a row into RESOURCE_TABLE so the DB can enforce FK constraints on REFERENCES.
// Called immediately after a new resource is persisted in its own table.
public isolated function saveToResourceTable(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns error? {
    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);
    // H2 does not support ON CONFLICT DO NOTHING;
    sql:ParameterizedQuery insertQuery;
    if dbType.toLowerAscii().trim() == "h2" {
        insertQuery = `MERGE INTO "RESOURCE_TABLE" ("ID", "TYPE") KEY("ID", "TYPE") VALUES (${resourceId}, ${resourceType})`;
    } else {
        insertQuery = `INSERT INTO "RESOURCE_TABLE" ("ID", "TYPE") VALUES (${resourceId}, ${resourceType}) ON CONFLICT DO NOTHING`;
    }
    _ = check validatedClient->execute(insertQuery);
    log:printDebug(string `Registered ${resourceType}/${resourceId} in RESOURCE_TABLE`);
}

// Remove the row from RESOURCE_TABLE for a deleted resource.
// The ON DELETE CASCADE on REFERENCES means child rows are cleaned up automatically.
// Called after the main resource row has been successfully deleted.
public isolated function deleteFromResourceTable(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns error? {
    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);
    sql:ParameterizedQuery deleteQuery = `DELETE FROM "RESOURCE_TABLE" WHERE "ID" = ${resourceId} AND "TYPE" = ${resourceType}`;
    _ = check validatedClient->execute(deleteQuery);
    log:printDebug(string `Removed ${resourceType}/${resourceId} from RESOURCE_TABLE`);
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
    sql:ParameterizedQuery[] queries = [];
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
