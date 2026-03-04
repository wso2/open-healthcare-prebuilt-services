import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/java.jdbc;

// Database type configuration (shared from handlers module)
public configurable string dbType = "h2";

// ============================================================================
// CACHE
// ============================================================================

// Cache for table columns to avoid repeated database queries
// Isolated variable with lock for thread safety
isolated map<string[]> tableColumnsCache = {};

// ============================================================================
// NAMING CONVENTION UTILITIES
// ============================================================================

// Helper function to convert resource type to table name
// Example: "Appointment" -> "AppointmentTable" (matches the quoted table name in SQL)
public isolated function getTableName(string resourceType) returns string {
    return resourceType + "Table";
}

// Helper function to convert search parameter to database column name
// Example: "service-category" -> "SERVICE_CATEGORY"
public isolated function toDbColumnName(string searchParam) returns string {
    // Replace hyphens with underscores and convert to uppercase
    string replaced = re `-`.replaceAll(searchParam, "_");
    return replaced.toUpperAscii();
}

// Helper function to convert database column name back to search parameter
// Example: "SERVICE_CATEGORY" -> "service-category"
public isolated function toSearchParamName(string dbColumn) returns string {
    // Convert to lowercase and replace underscores with hyphens
    string lowered = dbColumn.toLowerAscii();
    return re `_`.replaceAll(lowered, "-");
}

// Helper function to get primary key column name
// Example: "Appointment" -> "APPOINTMENTTABLE_ID" (matches column naming in SQL)
public isolated function getPrimaryKeyColumn(string resourceType) returns string {
    return resourceType.toUpperAscii() + "TABLE_ID";
}

// ============================================================================
// DATE PARSING UTILITIES
// ============================================================================

// Helper function to parse date string in YYYY-MM-DD format to time:Date
public isolated function parseDateString(string dateStr) returns time:Date|error {
    // Handle empty or whitespace-only strings
    if dateStr.trim().length() == 0 {
        return error("Date string is empty");
    }
    
    // If the string contains time component (T or space followed by time), extract only date part
    string datePart = dateStr;
    if dateStr.includes("T") {
        // ISO 8601 format: 2025-04-24T00:03:08.000Z
        string[] splitByT = re `T`.split(dateStr);
        datePart = splitByT[0];
    } else if dateStr.includes(" ") && dateStr.length() > 10 {
        // SQL format: 2025-04-24 00:03:08.000
        datePart = dateStr.substring(0, 10);
    }
    
    // Parse date string "YYYY-MM-DD" into components
    string[] parts = re `-`.split(datePart);
    if parts.length() != 3 {
        return error(string `Invalid date format: ${dateStr}. Expected YYYY-MM-DD`);
    }
    
    // Validate each part is not empty
    if parts[0].trim().length() == 0 || parts[1].trim().length() == 0 || parts[2].trim().length() == 0 {
        return error(string `Invalid date format: ${dateStr}. One or more components are empty`);
    }
    
    int year = check int:fromString(parts[0]);
    int month = check int:fromString(parts[1]);
    int day = check int:fromString(parts[2]);
    
    time:Date date = {year: year, month: month, day: day};
    return date;
}

// ============================================================================
// DATABASE SCHEMA UTILITIES
// ============================================================================

// Helper function to get table columns from database metadata
// Queries INFORMATION_SCHEMA to get actual column names for a table
public isolated function getTableColumns(jdbc:Client jdbcClient, string tableName) returns string[]|error {
    
    // Check cache first (thread-safe read)
    lock {
        if tableColumnsCache.hasKey(tableName) {
            log:printDebug(string `Cache hit for table: ${tableName}`);
            string[] cachedColumns = tableColumnsCache.get(tableName);
            return cachedColumns.clone();
        }
    }
    
    log:printDebug(string `Cache miss - querying columns for table: ${tableName}`);
    
    // Get the database-specific query based on dbType
    sql:ParameterizedQuery query = getTableColumnsQuery(tableName, dbType);
    
    stream<record {|string COLUMN_NAME;|}, sql:Error?> columnStream = jdbcClient->query(query);
    
    string[] columns = [];
    check from record {|string COLUMN_NAME;|} columnRecord in columnStream
        do {
            columns.push(columnRecord.COLUMN_NAME);
        };
    
    check columnStream.close();
    
    log:printDebug(string `Total columns found for ${tableName}: ${columns.length()}`);
    
    // Store in cache for future requests (thread-safe write)
    lock {
        tableColumnsCache[tableName] = columns.clone();
    }
    
    return columns;
}

// Helper function to get database-specific query for table columns
isolated function getTableColumnsQuery(string tableName, string databaseType) returns sql:ParameterizedQuery {
    string normalizedType = databaseType.toLowerAscii().trim();
    
    match normalizedType {
        "postgresql" | "postgres" => {
            // PostgreSQL: lowercase schema and column names
            return `SELECT column_name AS COLUMN_NAME
                    FROM information_schema.columns 
                    WHERE table_schema = 'public' 
                      AND table_name = ${tableName}
                    ORDER BY ordinal_position`;
        }
        _ => {
            // H2 (default): uppercase schema, standard column names
            return `SELECT COLUMN_NAME 
                    FROM INFORMATION_SCHEMA.COLUMNS 
                    WHERE TABLE_SCHEMA = 'PUBLIC' 
                      AND TABLE_NAME = ${tableName}
                    ORDER BY ORDINAL_POSITION`;
        }
    }
}
