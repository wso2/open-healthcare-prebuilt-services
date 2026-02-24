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

// Sync SearchParameter to SEARCH_PARAM_RES_EXPRESSIONS table
public isolated function syncSearchParameterToExpressions(jdbc:Client? jdbcClient, json searchParamJson) returns error? {
    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);
    
    // Extract required fields from SearchParameter JSON
    string code = check searchParamJson.code;
    string 'type = check searchParamJson.'type;
    string expression = check searchParamJson.expression;
    json baseArray = check searchParamJson.base;
    
    // Handle base as array (it's an array of resource types)
    json[] baseResources = <json[]>baseArray;
    
    log:printInfo(string `Syncing SearchParameter '${code}' to SEARCH_PARAM_RES_EXPRESSIONS for ${baseResources.length()} resource type(s)`);
    
    // Insert entry for each base resource type
    foreach json baseResource in baseResources {
        string resourceName = baseResource.toString();
        
        // Check if entry already exists
        sql:ParameterizedQuery checkQuery = `
            SELECT COUNT(*) as count FROM "SEARCH_PARAM_RES_EXPRESSIONS" 
            WHERE "SEARCH_PARAM_NAME" = ${code} 
            AND "RESOURCE_NAME" = ${resourceName}
            AND "IS_CUSTOM" = ${true}
        `;
        
        stream<record {int count;}, error?> checkResult = validatedClient->query(checkQuery);
        record {|record {int count;} value;|}|error? nextRecord = checkResult.next();
        check checkResult.close();
        
        boolean exists = false;
        if nextRecord is record {|record {int count;} value;|} {
            exists = nextRecord.value.count > 0;
        }
        
        if exists {
            // Update existing entry
            log:printDebug(string `Updating existing SearchParameter expression for '${code}' on ${resourceName}`);
            sql:ParameterizedQuery updateQuery = `
                UPDATE "SEARCH_PARAM_RES_EXPRESSIONS" 
                SET "SEARCH_PARAM_TYPE" = ${('type)},
                    "EXPRESSION" = ${expression}
                WHERE "SEARCH_PARAM_NAME" = ${code}
                AND "RESOURCE_NAME" = ${resourceName}
                AND "IS_CUSTOM" = ${true}
            `;
            _ = check validatedClient->execute(updateQuery);
        } else {
            // Insert new entry
            log:printDebug(string `Inserting new SearchParameter expression for '${code}' on ${resourceName}`);
            sql:ParameterizedQuery insertQuery = `
                INSERT INTO "SEARCH_PARAM_RES_EXPRESSIONS" 
                ("SEARCH_PARAM_NAME", "SEARCH_PARAM_TYPE", "RESOURCE_NAME", "EXPRESSION", "IS_CUSTOM")
                VALUES (${code}, ${('type)}, ${resourceName}, ${expression}, ${true})
            `;
            _ = check validatedClient->execute(insertQuery);
        }
        
        log:printInfo(string `Successfully synced SearchParameter '${code}' for resource type '${resourceName}'`);
    }
    
    // Clear the search parameter cache
    clearSearchParamCache();
    
    return;
}

// Remove SearchParameter from SEARCH_PARAM_RES_EXPRESSIONS table
public isolated function removeSearchParameterFromExpressions(jdbc:Client? jdbcClient, json searchParamJson) returns error? {
    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);
    
    // Extract code from SearchParameter
    string code = check searchParamJson.code;
    
    log:printInfo(string `Removing SearchParameter '${code}' from SEARCH_PARAM_RES_EXPRESSIONS`);
    
    sql:ParameterizedQuery deleteQuery = `
        DELETE FROM "SEARCH_PARAM_RES_EXPRESSIONS" 
        WHERE "SEARCH_PARAM_NAME" = ${code}
        AND "IS_CUSTOM" = ${true}
    `;
    
    sql:ExecutionResult result = check validatedClient->execute(deleteQuery);
    
    // Clear the search parameter cache
    clearSearchParamCache();
    
    int affectedRows = result.affectedRowCount ?: 0;
    log:printInfo(string `Removed ${affectedRows} SearchParameter expression(s) for '${code}'`);
    
    return;
}

// Remove SearchParameter by ID (when we only have the resource ID)
public isolated function removeSearchParameterById(jdbc:Client? jdbcClient, string resourceId) returns error? {
    jdbc:Client validatedClient = check getValidatedJdbcClient(jdbcClient);
    
    // First, read the SearchParameter resource to get the code
    sql:ParameterizedQuery readQuery = `
        SELECT "RESOURCE_JSON" FROM "SearchParameterTable" 
        WHERE "SEARCHPARAMETERTABLE_ID" = ${resourceId}
    `;
    
    stream<record {byte[] RESOURCE_JSON;}, error?> resultStream = validatedClient->query(readQuery);
    record {|record {byte[] RESOURCE_JSON;} value;|}|error? nextRecord = resultStream.next();
    check resultStream.close();
    
    if nextRecord is () || nextRecord is error {
        log:printWarn(string `SearchParameter with ID '${resourceId}' not found, skipping expression cleanup`);
        return;
    }
    
    // Parse the JSON to get the code
    byte[] resourceBytes = nextRecord.value.RESOURCE_JSON;
    string jsonString = check string:fromBytes(resourceBytes);
    json searchParamJson = check jsonString.fromJsonString();
    string code = check searchParamJson.code;
    
    log:printInfo(string `Removing SearchParameter '${code}' (ID: ${resourceId}) from SEARCH_PARAM_RES_EXPRESSIONS`);
    
    sql:ParameterizedQuery deleteQuery = `
        DELETE FROM "SEARCH_PARAM_RES_EXPRESSIONS" 
        WHERE "SEARCH_PARAM_NAME" = ${code}
        AND "IS_CUSTOM" = ${true}
    `;
    
    sql:ExecutionResult result = check validatedClient->execute(deleteQuery);
    int affectedRows = result.affectedRowCount ?: 0;
    log:printInfo(string `Removed ${affectedRows} SearchParameter expression(s) for '${code}'`);
    
    return;
}
