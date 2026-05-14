// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

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

import ballerina_fhir_server.mappers;
import ballerina_fhir_server.utils;
import ballerina_fhir_server.utils as mapperUtils;

import ballerina/log;
import ballerina/sql;

import ballerinax/java.jdbc;

public class CreateHandler {
    private HistoryHandler historyHandler;
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
        self.historyHandler = new HistoryHandler(jdbcClient);
    }

    public isolated function saveResourceWithTransaction(string resourceType, json resourceJson) returns json|error {
        json result;
        transaction {
            result = check self.persistResource(resourceType, resourceJson);
            check commit;
        } on fail error e {
            log:printError(string `Create transaction failed for ${resourceType}: ${e.message()}`);
            return e;
        }
        return result;
    }

    public isolated function persistResource(string resourceType, json resourceJson) returns json|error {
        // Create mapper with jdbcClient
        jdbc:Client validatedClient = check utils:getValidatedJdbcClient(self.jdbcClient);
        mappers:CreateMapper mapper = new mappers:CreateMapper(validatedClient);

        // Map resource to insert model
        log:printDebug(string `Mapping ${resourceType} to insert model`);
        record {|anydata...;|}|error? insertModel = mapper.mapToInsertModel(
                validatedClient, resourceType, resourceJson
        );

        if insertModel is () {
            return error(string `Failed to create insert model for ${resourceType}: mapper returned null`);
        }
        if insertModel is error {
            return insertModel;
        }

        json[] references = mapper.getReferences();
        json resourceWithId = mapper.getResourceJsonWithId();
        log:printDebug(string `Extracted ${references.length()} reference(s) from ${resourceType}`);

        // Save main resource
        string resourceId = check self.saveMainResource(resourceType, insertModel);
        log:printDebug(string `Created ${resourceType} with ID: ${resourceId}`);

        // Register in RESOURCE_TABLE so the DB FK on REFERENCES is satisfiable.
        check utils:saveToResourceTable(self.jdbcClient, resourceType, resourceId);

        error? friResult = utils:upsertFhirResourceIndex(self.jdbcClient, resourceType, resourceId, 1);
        if friResult is error {
            log:printWarn(string `Failed to upsert FHIR_RESOURCE_INDEX for ${resourceType}/${resourceId}: ${friResult.message()} (non-fatal)`);
        }

        // Special handling for SearchParameter resources - sync to expressions table
        if resourceType == "SearchParameter" {
            log:printDebug(string `Syncing SearchParameter/${resourceId} to SEARCH_PARAM_RES_EXPRESSIONS`);
            check utils:syncSearchParameterToExpressions(self.jdbcClient, resourceJson);
            log:printInfo(string `Successfully synced SearchParameter/${resourceId} to expressions table`);
        }

        // Save to history after creation
        check self.historyHandler.saveToHistory(resourceType, resourceId, insertModel, "POST");

        // Extract and save search parameters for indexed searching
        check utils:extractSearchParametersForResource(validatedClient, resourceType, resourceId, resourceJson);

        // Save all references — translate FK violation to a descriptive error
        // so the service layer can return 422 instead of 500.
        utils:TransactionContext refCtx = utils:newTransactionContext();
        refCtx.mainResourceId = resourceId;
        error? refResult = utils:saveReferences(self.jdbcClient, references, resourceType, resourceId, refCtx);
        if refResult is error {
            string refMsg = refResult.message();
            if refMsg.includes("violates foreign key constraint") || refMsg.includes("FK_REFERENCES_TARGET") {
                return error(string `Unresolved reference: one or more TARGET resources referenced by ${resourceType}/${resourceId} do not exist. Ensure all referenced resources are created first.`);
            }
            return refResult;
        }

        log:printDebug(string `Successfully created ${resourceType}/${resourceId} with ${references.length()} reference(s)`);
        return resourceWithId;
    }

    // Generic insert method
    private isolated function saveMainResource(string resourceType, record {|anydata...;|} insertModel) returns string|error {

        // Get table name
        string tableName = mapperUtils:getTableName(resourceType);
        log:printDebug(string `Target table for ${resourceType}: ${tableName}`);

        // Validate JDBC client
        jdbc:Client jdbcClient = check utils:getValidatedJdbcClient(self.jdbcClient);

        // Get primary key value
        string primaryKeyColumn = mapperUtils:getPrimaryKeyColumn(resourceType);
        any resourceIdValue = insertModel[primaryKeyColumn];
        string resourceId = resourceIdValue is string ? resourceIdValue : resourceIdValue.toString();

        // Extract column names and values from insertModel
        string[] columnNames = insertModel.keys();
        anydata[] columnValues = insertModel.toArray();

        log:printDebug(string `Prepared insert with ${columnNames.length()} columns for ${resourceType}/${resourceId}`);

        // Build INSERT query string with quoted column names for PostgreSQL compatibility
        string[] quotedColumnNames = from string colName in columnNames
            select string `"${colName}"`;
        string columnNamesStr = string:'join(", ", ...quotedColumnNames);

        // Build values string using consolidated formatting utility
        string[] valueStrings = [];
        int index = 0;
        foreach any val in columnValues {
            string columnName = columnNames[index];
            // Use special formatting for DATE columns (date only, no time)
            if columnName == "DATE" {
                valueStrings.push(utils:formatDateValue(val));
            } else {
                valueStrings.push(utils:formatSqlValue(val));
            }
            index = index + 1;
        }

        string valuesStr = string:'join(", ", ...valueStrings);

        // Build complete INSERT query string with table name in double quotes
        string completeQueryStr = "INSERT INTO \"" + tableName + "\"(" + columnNamesStr + ") VALUES (" + valuesStr + ")";
        log:printDebug(string `Executing INSERT query for ${resourceType}/${resourceId}`);

        utils:RawSQLQuery rawQuery = new (completeQueryStr);
        sql:ExecutionResult|error result = jdbcClient->execute(rawQuery);

        if result is error {
            string errMsg = result.message();
            string lowerMsg = errMsg.toLowerAscii();
            if lowerMsg.includes("duplicate") || lowerMsg.includes("unique") || lowerMsg.includes("primary key") {
                log:printWarn(string `Duplicate resource creation attempted: ${resourceType}/${resourceId}`);
                return error(string `Resource already exists: ${resourceType}/${resourceId}. Use PUT to update the resource.`);
            }
            log:printError(string `Database insert failed for ${resourceType}/${resourceId}: ${errMsg}`);
            return result;
        }

        log:printDebug(string `Successfully inserted ${resourceType}/${resourceId} into database`);
        return resourceId;
    }
}
