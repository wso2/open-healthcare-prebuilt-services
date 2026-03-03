// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerina/sql;
import ballerinax/java.jdbc;

# Search for resources using custom extension search parameters
# Queries the CUSTOM_EXTENSION_SEARCH_PARAMS table which contains pre-extracted
# values from extensions for fast searching without JSON parsing
# 
# + jdbcClient - JDBC client for database access
# + resourceType - The FHIR resource type (e.g., "Patient")
# + searchParams - Map of custom search parameter names to value arrays
# + return - Array of resource IDs matching the search criteria or error
public isolated function searchResourcesByCustomParams(jdbc:Client jdbcClient, string resourceType, map<string[]> searchParams) returns string[]|error {
    
    if searchParams.length() == 0 {
        // No search parameters - return empty to indicate full scan needed
        return [];
    }
    
    log:printDebug(string `Searching ${resourceType} using custom extension parameters: ${searchParams.toString()}`);
    
    // Build the search query
    sql:ParameterizedQuery query = check buildCustomExtensionSearchQuery(jdbcClient, resourceType, searchParams);
    
    // Execute query
    stream<record {string RESOURCE_ID;}, error?> resultStream = jdbcClient->query(query);
    
    string[] resourceIds = [];
    check from var row in resultStream
        do {
            resourceIds.push(row.RESOURCE_ID);
        };
    
    log:printInfo(string `Found ${resourceIds.length()} ${resourceType} resource(s) matching search criteria`);
    return resourceIds;
}

# Build SQL query for custom extension search
# Constructs query against CUSTOM_EXTENSION_SEARCH_PARAMS table
# 
# + jdbcClient - JDBC client for database access
# + resourceType - The FHIR resource type
# + searchParams - Map of custom search parameter names to value arrays
# + return - Parameterized SQL query or error
isolated function buildCustomExtensionSearchQuery(jdbc:Client jdbcClient, string resourceType, map<string[]> searchParams) returns sql:ParameterizedQuery|error {
    
    // Start building the query
    string baseQuery = string `SELECT DISTINCT "RESOURCE_ID" FROM "CUSTOM_EXTENSION_SEARCH_PARAMS" WHERE "RESOURCE_TYPE" = '${escapeSql(resourceType)}'`;
    
    // Add conditions for each search parameter
    string[] conditions = [];
    
    foreach var [paramName, paramValues] in searchParams.entries() {
        if paramValues.length() == 0 {
            continue;
        }
        
        // Get parameter type from expressions table
        string? paramType = check getSearchParamType(jdbcClient, resourceType, paramName);
        if paramType is () {
            log:printWarn(string `Unknown search parameter '${paramName}' for ${resourceType}, skipping`);
            continue;
        }
        
        // Build condition based on parameter type
        string? condition = buildSearchCondition(paramName, paramType, paramValues);
        if condition is string {
            conditions.push(condition);
        }
    }
    
    if conditions.length() == 0 {
        return error("No valid search parameters found");
    }
    
    // Combine all conditions with AND
    string whereClause = " AND " + string:'join(" AND ", ...conditions);
    string finalQuery = baseQuery + whereClause;
    
    log:printDebug(string `Built custom extension search query: ${finalQuery}`);
    
    return new RawSQLQuery(finalQuery);
}

# Build search condition for a specific parameter
# 
# + paramName - Search parameter name
# + paramType - Search parameter type (string, token, number, date, etc.)
# + paramValues - Array of values to search for
# + return - SQL WHERE condition string or () if invalid
isolated function buildSearchCondition(string paramName, string paramType, string[] paramValues) returns string? {
    
    match paramType {
        "string" => {
            // For string type, use exact match
            string[] valueClauses = [];
            foreach string value in paramValues {
                valueClauses.push(string `"VALUE_STRING" = '${escapeSql(value)}'`);
            }
            string valueCondition = string:'join(" OR ", ...valueClauses);
            return string `"PARAM_NAME" = '${escapeSql(paramName)}' AND (${valueCondition})`;
        }
        "token" => {
            // For token type, exact match on code (with optional system)
            string[] valueClauses = [];
            foreach string value in paramValues {
                // Check if value includes system (format: system|code)
                string[] parts = re `\|`.split(value);
                if parts.length() == 2 {
                    // System and code provided
                    valueClauses.push(string `("VALUE_TOKEN_SYSTEM" = '${escapeSql(parts[0])}' AND "VALUE_TOKEN_CODE" = '${escapeSql(parts[1])}')`);
                } else {
                    // Just code provided
                    valueClauses.push(string `"VALUE_TOKEN_CODE" = '${escapeSql(value)}'`);
                }
            }
            string valueCondition = string:'join(" OR ", ...valueClauses);
            return string `"PARAM_NAME" = '${escapeSql(paramName)}' AND (${valueCondition})`;
        }
        "number" => {
            // For number type, exact match or range
            string[] valueClauses = [];
            foreach string value in paramValues {
                decimal|error numValue = decimal:fromString(value);
                if numValue is decimal {
                    valueClauses.push(string `"VALUE_NUMBER" = ${numValue.toString()}`);
                }
            }
            if valueClauses.length() == 0 {
                return ();
            }
            string valueCondition = string:'join(" OR ", ...valueClauses);
            return string `"PARAM_NAME" = '${escapeSql(paramName)}' AND (${valueCondition})`;
        }
        "date" => {
            // For date type, exact match or range (simplified - can be enhanced)
            string[] valueClauses = [];
            foreach string value in paramValues {
                valueClauses.push(string `"VALUE_DATE" = '${escapeSql(value)}'`);
            }
            string valueCondition = string:'join(" OR ", ...valueClauses);
            return string `"PARAM_NAME" = '${escapeSql(paramName)}' AND (${valueCondition})`;
        }
        "reference" => {
            // For reference type, match on type and ID
            string[] valueClauses = [];
            foreach string value in paramValues {
                string[] parts = re `/`.split(value);
                if parts.length() == 2 {
                    valueClauses.push(string `("VALUE_REFERENCE_TYPE" = '${escapeSql(parts[0])}' AND "VALUE_REFERENCE_ID" = '${escapeSql(parts[1])}')`);
                } else {
                    // Just ID provided, match any type
                    valueClauses.push(string `"VALUE_REFERENCE_ID" = '${escapeSql(value)}'`);
                }
            }
            string valueCondition = string:'join(" OR ", ...valueClauses);
            return string `"PARAM_NAME" = '${escapeSql(paramName)}' AND (${valueCondition})`;
        }
        "uri" => {
            // For URI type, exact match
            string[] valueClauses = [];
            foreach string value in paramValues {
                valueClauses.push(string `"VALUE_STRING" = '${escapeSql(value)}'`);
            }
            string valueCondition = string:'join(" OR ", ...valueClauses);
            return string `"PARAM_NAME" = '${escapeSql(paramName)}' AND (${valueCondition})`;
        }
        _ => {
            log:printWarn(string `Unsupported search parameter type '${paramType}' for '${paramName}'`);
            return ();
        }
    }
}

# Get search parameter type from expressions table
# 
# + jdbcClient - JDBC client for database access
# + resourceType - The FHIR resource type
# + paramName - Search parameter name
# + return - Parameter type (string, token, etc.) or () if not found, or error
isolated function getSearchParamType(jdbc:Client jdbcClient, string resourceType, string paramName) returns string?|error {
    sql:ParameterizedQuery query = `
        SELECT "SEARCH_PARAM_TYPE" 
        FROM "SEARCH_PARAM_RES_EXPRESSIONS" 
        WHERE "RESOURCE_NAME" = ${resourceType} 
        AND "SEARCH_PARAM_NAME" = ${paramName}
        AND "IS_CUSTOM" = ${true}
        LIMIT 1
    `;
    
    stream<record {string SEARCH_PARAM_TYPE;}, error?> resultStream = jdbcClient->query(query);
    record {|record {string SEARCH_PARAM_TYPE;} value;|}|error? result = resultStream.next();
    check resultStream.close();
    
    if result is record {|record {string SEARCH_PARAM_TYPE;} value;|} {
        return result.value.SEARCH_PARAM_TYPE;
    }
    
    return ();
}

# Helper function to get parameter type (with caching support)
# This should be called from handlers with jdbcClient access
# 
# + jdbcClient - JDBC client for database access
# + resourceType - The FHIR resource type
# + paramName - Search parameter name
# + return - Parameter type or () if not found, or error
public isolated function getSearchParameterType(jdbc:Client jdbcClient, string resourceType, string paramName) returns string?|error {
    
    sql:ParameterizedQuery query = `
        SELECT "SEARCH_PARAM_TYPE" 
        FROM "SEARCH_PARAM_RES_EXPRESSIONS" 
        WHERE "RESOURCE_NAME" = ${resourceType} 
        AND "SEARCH_PARAM_NAME" = ${paramName}
        LIMIT 1
    `;
    
    stream<record {string SEARCH_PARAM_TYPE;}, error?> resultStream = jdbcClient->query(query);
    record {|record {string SEARCH_PARAM_TYPE;} value;|}|error? result = resultStream.next();
    check resultStream.close();
    
    if result is record {|record {string SEARCH_PARAM_TYPE;} value;|} {
        return result.value.SEARCH_PARAM_TYPE;
    }
    
    return ();
}
