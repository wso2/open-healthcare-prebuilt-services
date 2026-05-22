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
import ballerina/time;
import ballerinax/health.fhir.r4utils.fhirpath;
import ballerinax/java.jdbc;

# Represents an extracted search parameter value ready for database insertion
# 
# + paramName - Name of the search parameter
# + paramType - Type of the search parameter (string, token, number, etc.)
# + valueString - String value (for string/uri types)
# + valueNumber - Numeric value (for number types)
# + valueDate - Date value (for date/datetime types)
# + valueTokenSystem - Token system (for token types)
# + valueTokenCode - Token code (for token types)
# + valueReferenceType - Reference resource type (for reference types)
# + valueReferenceId - Reference resource ID (for reference types)
public type ExtractedSearchParam record {|
    string paramName;
    string paramType;
    string? valueString = ();
    decimal? valueNumber = ();
    time:Civil? valueDate = ();
    string? valueTokenSystem = ();
    string? valueTokenCode = ();
    string? valueReferenceType = ();
    string? valueReferenceId = ();
|};

# Extract all search parameters for a resource and prepare for database insertion
# 
# + jdbcClient - JDBC client for database access
# + resourceType - The FHIR resource type
# + resourceId - The resource ID
# + resourceJson - The resource JSON
# + return - Error if extraction fails
public isolated function extractSearchParametersForResource(
    jdbc:Client jdbcClient,
    string resourceType,
    string resourceId,
    json resourceJson
) returns error? {
    
    log:printDebug(string `Extracting search parameters for ${resourceType}/${resourceId}`);
    
    // Get only CUSTOM search parameter expressions for this resource type
    SearchParamExpression[] expressions = check getCustomSearchParamExpressions(jdbcClient, resourceType);
    
    if expressions.length() == 0 {
        log:printDebug(string `No custom search parameters defined for ${resourceType}`);
        return;
    }
    
    log:printInfo(string `Found ${expressions.length()} custom search parameter(s) for ${resourceType}`);
    
    // Extract each parameter
    ExtractedSearchParam[] extractedParams = [];
    
    foreach SearchParamExpression expr in expressions {
        ExtractedSearchParam[]? params = extractSingleSearchParam(resourceJson, expr);
        if params is ExtractedSearchParam[] {
            foreach ExtractedSearchParam param in params {
                extractedParams.push(param);
            }
        }
    }
    
    // Save to database
    if extractedParams.length() > 0 {
        check saveExtractedSearchParams(jdbcClient, resourceType, resourceId, extractedParams);
        log:printInfo(string `Extracted and saved ${extractedParams.length()} search parameter value(s) for ${resourceType}/${resourceId}`);
    }
}

# Extract values for a single search parameter using FHIRPath or custom extraction
# 
# + resourceJson - The resource JSON
# + expr - Search parameter expression details
# + return - Array of extracted parameter values or () if none found
isolated function extractSingleSearchParam(
    json resourceJson,
    SearchParamExpression expr
) returns ExtractedSearchParam[]? {
    
    log:printDebug(string `Extracting '${expr.SEARCH_PARAM_NAME}' using expression: ${expr.EXPRESSION}`);
    
    // Check if expression uses .where() function (not supported by basic FHIRPath)
    if expr.EXPRESSION.includes(".where(") {
        log:printDebug(string `Using custom extraction for '${expr.SEARCH_PARAM_NAME}' (contains .where())`);
        return extractFromExtensionArray(resourceJson, expr);
    }
    
    // Use FHIRPath for simple expressions
    json|error result = fhirpath:getValuesFromFhirPath(resourceJson, expr.EXPRESSION);
    
    if result is error {
        log:printError(string `Failed to extract ${expr.SEARCH_PARAM_NAME}: ${result.message()}`);
        return ();
    }
    
    if result is () {
        log:printDebug(string `FHIRPath returned null for ${expr.SEARCH_PARAM_NAME}`);
        return ();
    }
    
    log:printDebug(string `FHIRPath result for '${expr.SEARCH_PARAM_NAME}': ${result.toString()}`);
    
    // Convert result to array if needed
    json[] values = result is json[] ? result : [result];
    
    ExtractedSearchParam[] params = [];
    
    foreach json value in values {
        if value is () {
            continue;
        }
        
        ExtractedSearchParam? param = convertToExtractedParam(expr.SEARCH_PARAM_NAME, expr.SEARCH_PARAM_TYPE, value);
        if param is ExtractedSearchParam {
            params.push(param);
            log:printDebug(string `Extracted value for '${expr.SEARCH_PARAM_NAME}': ${param.toString()}`);
        } else {
            log:printWarn(string `Failed to convert value for '${expr.SEARCH_PARAM_NAME}': ${value.toString()}`);
        }
    }
    
    if params.length() == 0 {
        log:printWarn(string `No values extracted for '${expr.SEARCH_PARAM_NAME}'`);
    }
    
    return params.length() > 0 ? params : ();
}

# Extract values from extension array using custom logic (for .where() expressions)
# 
# + resourceJson - The resource JSON
# + expr - Search parameter expression details
# + return - Array of extracted parameter values or () if none found
isolated function extractFromExtensionArray(
    json resourceJson,
    SearchParamExpression expr
) returns ExtractedSearchParam[]? {
    
    // Parse expression to extract URL filter
    // Format: Resource.extension.where(url='URL').valueX
    string expression = expr.EXPRESSION;
    
    // Extract the URL from where clause
    int? whereStart = expression.indexOf(".where(url='");
    if whereStart is () {
        log:printError(string `Invalid where expression for ${expr.SEARCH_PARAM_NAME}: ${expression}`);
        return ();
    }
    
    int urlStart = whereStart + ".where(url='".length();
    int? urlEnd = expression.indexOf("')", urlStart);
    if urlEnd is () {
        log:printError(string `Invalid where expression for ${expr.SEARCH_PARAM_NAME}: ${expression}`);
        return ();
    }
    
    string extensionUrl = expression.substring(urlStart, urlEnd);
    
    log:printDebug(string `[${expr.SEARCH_PARAM_NAME}] Searching for extension with URL: ${extensionUrl}`);
    
    // Get extensions array from resource
    if resourceJson is map<json> {
        map<json> resourceMap = <map<json>>resourceJson;
        json extensionsJson = resourceMap["extension"];
        
        if extensionsJson is () {
            log:printDebug(string `[${expr.SEARCH_PARAM_NAME}] No extensions found in resource`);
            return ();
        }
        
        if extensionsJson !is json[] {
            log:printWarn(string `[${expr.SEARCH_PARAM_NAME}] Extension field is not an array`);
            return ();
        }
        
        json[] extensions = <json[]>extensionsJson;
        ExtractedSearchParam[] params = [];
        
        // Search for matching extension optimized with map
        foreach json ext in extensions {
            if ext is map<json> {
                map<json> extMap = <map<json>>ext;
                json urlJson = extMap["url"];
                
                if urlJson is string && urlJson == extensionUrl {
                    // Found matching extension, extract valueString
                    json valueJson = extMap["valueString"];
                    
                    if valueJson !is () {
                        ExtractedSearchParam? param = convertToExtractedParam(expr.SEARCH_PARAM_NAME, expr.SEARCH_PARAM_TYPE, valueJson);
                        if param is ExtractedSearchParam {
                            params.push(param);
                            log:printInfo(string `[${expr.SEARCH_PARAM_NAME}] Extracted extension value: ${valueJson.toString()}`);
                        }
                    } else {
                        log:printDebug(string `[${expr.SEARCH_PARAM_NAME}] Found matching extension but valueString is null`);
                    }
                }
            }
        }
        
        return params.length() > 0 ? params : ();
    }
    
    return ();
}

# Convert a JSON value to ExtractedSearchParam based on type
# 
# + paramName - Name of the search parameter
# + paramType - Type of the search parameter
# + value - The JSON value to convert
# + return - Extracted search parameter or () if conversion fails
isolated function convertToExtractedParam(
    string paramName,
    string paramType,
    json value
) returns ExtractedSearchParam? {
    
    match paramType {
        "string" => {
            return {
                paramName: paramName,
                paramType: paramType,
                valueString: value.toString()
            };
        }
        "number" => {
            decimal? numValue = value is decimal ? value : (value is int ? <decimal>value : ());
            if numValue is () {
                return ();
            }
            return {
                paramName: paramName,
                paramType: paramType,
                valueNumber: numValue
            };
        }
        "date" => {
            string? dateStr = value is string ? value : ();
            if dateStr is () {
                return ();
            }
            time:Civil|error civilTime = convertFhirDateToCivil(dateStr);
            if civilTime is error {
                log:printDebug(string `Failed to parse date for ${paramName}: ${civilTime.message()}`);
                return ();
            }
            return {
                paramName: paramName,
                paramType: paramType,
                valueDate: civilTime
            };
        }
        "token" => {
            // Token can be string, Coding, or CodeableConcept
            if value is string {
                return {
                    paramName: paramName,
                    paramType: paramType,
                    valueTokenCode: value
                };
            } else if value is map<json> {
                // Extract code and system from Coding or CodeableConcept
                json|error code = value.code;
                json|error system = value.system;
                
                return {
                    paramName: paramName,
                    paramType: paramType,
                    valueTokenSystem: system is string ? system : (),
                    valueTokenCode: code is string ? code : ()
                };
            }
            return ();
        }
        "reference" => {
            if value is string {
                // Parse "ResourceType/id" format
                string[] parts = re `/`.split(value);
                if parts.length() == 2 {
                    return {
                        paramName: paramName,
                        paramType: paramType,
                        valueReferenceType: parts[0],
                        valueReferenceId: parts[1]
                    };
                }
            } else if value is map<json> {
                json|error reference = value.reference;
                if reference is string {
                    string[] parts = re `/`.split(reference);
                    if parts.length() == 2 {
                        return {
                            paramName: paramName,
                            paramType: paramType,
                            valueReferenceType: parts[0],
                            valueReferenceId: parts[1]
                        };
                    }
                }
            }
            return ();
        }
        "uri" => {
            return {
                paramName: paramName,
                paramType: paramType,
                valueString: value.toString()
            };
        }
        _ => {
            // Default to string for unknown types
            return {
                paramName: paramName,
                paramType: paramType,
                valueString: value.toString()
            };
        }
    }
}

# Save extracted search parameters to database
# 
# + jdbcClient - JDBC client for database access
# + resourceType - The FHIR resource type
# + resourceId - The resource ID
# + params - Array of extracted search parameters to save
# + return - Error if save fails
isolated function saveExtractedSearchParams(
    jdbc:Client jdbcClient,
    string resourceType,
    string resourceId,
    ExtractedSearchParam[] params
) returns error? {
    
    if params.length() == 0 {
        return;
    }

    sql:ParameterizedQuery[] queries = [];
    
    foreach ExtractedSearchParam param in params {
        sql:ParameterizedQuery insertQuery = `
            INSERT INTO "CUSTOM_EXTENSION_SEARCH_PARAMS" 
            ("RESOURCE_TYPE", "RESOURCE_ID", "PARAM_NAME", "PARAM_TYPE", 
             "VALUE_STRING", "VALUE_NUMBER", "VALUE_DATE", 
             "VALUE_TOKEN_SYSTEM", "VALUE_TOKEN_CODE",
             "VALUE_REFERENCE_TYPE", "VALUE_REFERENCE_ID")
            VALUES (
                ${resourceType}, 
                ${resourceId}, 
                ${param.paramName}, 
                ${param.paramType},
                ${param.valueString},
                ${param.valueNumber},
                ${param.valueDate},
                ${param.valueTokenSystem},
                ${param.valueTokenCode},
                ${param.valueReferenceType},
                ${param.valueReferenceId}
            )
        `;
        queries.push(insertQuery);
    }
        
    _ = check jdbcClient->batchExecute(queries);
}

# Delete all search parameters for a resource
# 
# + jdbcClient - JDBC client for database access
# + resourceType - The FHIR resource type
# + resourceId - The resource ID
# + return - Error if deletion fails
public isolated function deleteSearchParametersForResource(
    jdbc:Client jdbcClient,
    string resourceType,
    string resourceId
) returns error? {
    
    sql:ParameterizedQuery deleteQuery = `
        DELETE FROM "CUSTOM_EXTENSION_SEARCH_PARAMS" 
        WHERE "RESOURCE_TYPE" = ${resourceType} 
        AND "RESOURCE_ID" = ${resourceId}
    `;
    
    sql:ExecutionResult result = check jdbcClient->execute(deleteQuery);
    int affectedRows = result.affectedRowCount ?: 0;
    log:printDebug(string `Deleted ${affectedRows} search parameter value(s) for ${resourceType}/${resourceId}`);
}

# Update search parameters for a resource (delete old, insert new)
# 
# + jdbcClient - JDBC client for database access
# + resourceType - The FHIR resource type
# + resourceId - The resource ID
# + resourceJson - The updated resource JSON
# + return - Error if update fails
public isolated function updateSearchParametersForResource(
    jdbc:Client jdbcClient,
    string resourceType,
    string resourceId,
    json resourceJson
) returns error? {
    
    // Delete existing parameters
    check deleteSearchParametersForResource(jdbcClient, resourceType, resourceId);
    
    // Extract and save new parameters
    check extractSearchParametersForResource(jdbcClient, resourceType, resourceId, resourceJson);
}

# Helper function to convert FHIR date/datetime string to Civil time
# 
# + fhirDate - FHIR date string (YYYY, YYYY-MM, YYYY-MM-DD, or ISO datetime)
# + return - Civil time or error if parsing fails
isolated function convertFhirDateToCivil(string fhirDate) returns time:Civil|error {
    // FHIR dates can be: YYYY, YYYY-MM, YYYY-MM-DD, or full ISO datetime
    // For simplicity, we'll try to parse as ISO datetime, falling back to date
    
    time:Utc|error utcTime = time:utcFromString(fhirDate);
    if utcTime is time:Utc {
        return time:utcToCivil(utcTime);
    }
    
    // Try date-only format
    if fhirDate.length() == 10 {
        // YYYY-MM-DD
        return time:utcToCivil(check time:utcFromString(fhirDate + "T00:00:00Z"));
    }
    
    return error(string `Unable to parse FHIR date: ${fhirDate}`);
}

# Get CUSTOM search parameter expressions from database (IS_CUSTOM = true only)
# 
# + jdbcClient - JDBC client for database access
# + resourceType - The FHIR resource type
# + return - Array of custom search parameter expressions or error
isolated function getCustomSearchParamExpressions(
    jdbc:Client jdbcClient,
    string resourceType
) returns SearchParamExpression[]|error {
    
    // Check cache first
    SearchParamExpression[]? cachedExpressions = ();
    lock {
        if searchParamCache.hasKey(resourceType) {
            cachedExpressions = searchParamCache.get(resourceType).cloneReadOnly();
        }
    }
    
    if cachedExpressions is SearchParamExpression[] {
        return cachedExpressions;
    }

    sql:ParameterizedQuery query = `
        SELECT "SEARCH_PARAM_NAME", "SEARCH_PARAM_TYPE", "RESOURCE_NAME", "EXPRESSION" 
        FROM "SEARCH_PARAM_RES_EXPRESSIONS" 
        WHERE "RESOURCE_NAME" = ${resourceType}
        AND "IS_CUSTOM" = ${true}
    `;
    
    stream<record {|
        string SEARCH_PARAM_NAME;
        string SEARCH_PARAM_TYPE;
        string RESOURCE_NAME;
        string EXPRESSION;
    |}, error?> resultStream = jdbcClient->query(query);
    
    SearchParamExpression[] expressions = [];
    
    check from var row in resultStream
        do {
            expressions.push({
                SEARCH_PARAM_NAME: row.SEARCH_PARAM_NAME,
                SEARCH_PARAM_TYPE: row.SEARCH_PARAM_TYPE,
                RESOURCE_NAME: row.RESOURCE_NAME,
                EXPRESSION: row.EXPRESSION
            });
        };
    
    // Cache the result
    lock {
        searchParamCache[resourceType] = expressions.cloneReadOnly();
    }
    
    return expressions;
}

# Get search parameter expressions from database (all - kept for compatibility)
# 
# + jdbcClient - JDBC client for database access
# + resourceType - The FHIR resource type
# + return - Array of all search parameter expressions or error
isolated function getSearchParamExpressions(
    jdbc:Client jdbcClient,
    string resourceType
) returns SearchParamExpression[]|error {
    
    // Check cache first
    SearchParamExpression[]? cachedExpressions = ();
    lock {
        if searchParamCache.hasKey(resourceType) {
            cachedExpressions = searchParamCache.get(resourceType).cloneReadOnly();
        }
    }
    
    if cachedExpressions is SearchParamExpression[] {
        return cachedExpressions;
    }

    sql:ParameterizedQuery query = `
        SELECT "SEARCH_PARAM_NAME", "SEARCH_PARAM_TYPE", "RESOURCE_NAME", "EXPRESSION" 
        FROM "SEARCH_PARAM_RES_EXPRESSIONS" 
        WHERE "RESOURCE_NAME" = ${resourceType}
    `;
    
    stream<record {|
        string SEARCH_PARAM_NAME;
        string SEARCH_PARAM_TYPE;
        string RESOURCE_NAME;
        string EXPRESSION;
    |}, error?> resultStream = jdbcClient->query(query);
    
    SearchParamExpression[] expressions = [];
    
    check from var row in resultStream
        do {
            expressions.push({
                SEARCH_PARAM_NAME: row.SEARCH_PARAM_NAME,
                SEARCH_PARAM_TYPE: row.SEARCH_PARAM_TYPE,
                RESOURCE_NAME: row.RESOURCE_NAME,
                EXPRESSION: row.EXPRESSION
            });
        };
    
    // Cache the result
    lock {
        searchParamCache[resourceType] = expressions.cloneReadOnly();
    }
    
    return expressions;
}

// Cache for CUSTOM search parameter expressions (IS_CUSTOM=true)
// Key: ResourceType, Value: Array of SearchParamExpression
isolated map<SearchParamExpression[]> searchParamCache = {};

// Cache for ALL search parameter expressions (used by FHIRMapper for column mapping)
// Key: ResourceType, Value: Array of SearchParamExpression
isolated map<SearchParamExpression[]> allSearchParamCache = {};

// Clear cache function (to be called when SearchParameters are updated)
public isolated function clearSearchParamCache() {
    log:printDebug("Clearing search parameter cache");
    lock {
        searchParamCache.removeAll();
    }
    lock {
        allSearchParamCache.removeAll();
    }
}

// Get all-params cache entry for a resource type
public isolated function getCachedAllSearchParamExpressions(string resourceType) returns SearchParamExpression[]? {
    lock {
        if allSearchParamCache.hasKey(resourceType) {
            return allSearchParamCache.get(resourceType).cloneReadOnly();
        }
    }
    return ();
}

// Populate all-params cache for a resource type
public isolated function cacheAllSearchParamExpressions(string resourceType, SearchParamExpression[] expressions) {
    lock {
        allSearchParamCache[resourceType] = expressions.cloneReadOnly();
    }
}
