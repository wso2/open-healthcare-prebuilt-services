import ballerina_fhir_server.mappers;
import ballerina_fhir_server.utils;
import ballerina_fhir_server.utils as mapperUtils;

import ballerina/log;
import ballerina/sql;

import ballerinax/java.jdbc;

public class CreateHandler {
    private utils:TransactionHandler transactionHandler;
    private HistoryHandler historyHandler;
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
        self.transactionHandler = new utils:TransactionHandler();
        self.historyHandler = new HistoryHandler(jdbcClient);
    }

    // Main function to save resource
    public isolated function saveResourceWithTransaction(string resourceType, json resourceJson) returns string|error {

        // Begin transaction
        utils:TransactionContext 'transaction = self.transactionHandler.beginTransaction();

        do {
            // Create mapper with jdbcClient
            jdbc:Client validatedClient = check utils:getValidatedJdbcClient(self.jdbcClient);
            mappers:CreateMapper mapper = new mappers:CreateMapper(validatedClient);
            
            // Map resource to insert model
            log:printDebug(string `Mapping ${resourceType} to insert model`);
            record {|anydata...;|}|error? insertModel = mapper.mapToInsertModel(
                validatedClient, resourceType, resourceJson
            );

            if insertModel is () {
                log:printError(string `Failed to create insert model for ${resourceType}: mapper returned null`);
                return error(string `Failed to create insert model for ${resourceType}`);
            }

            if insertModel is error {
                log:printError(string `Mapping failed for ${resourceType}: ${insertModel.message()}`);
                return insertModel;
            }

            // Get extracted references after mapping
            json[] references = mapper.getReferences();
            log:printDebug(string `Extracted ${references.length()} reference(s) from ${resourceType}`);

            // Validate all references BEFORE saving main resource
            log:printDebug(string `Validating ${references.length()} reference(s) for ${resourceType}`);
            error? validationResult = utils:validateReferences(self.jdbcClient, references);
            if validationResult is error {
                log:printError(string `Reference validation failed: ${validationResult.message()}`);
                return validationResult;
            }

            // Save main resource
            log:printDebug(string `Saving main ${resourceType} record`);
            string resourceId = check self.saveMainResource(resourceType, insertModel);
            'transaction.mainResourceId = resourceId;

            log:printDebug(string `Created ${resourceType} with ID: ${resourceId}`);

            // Special handling for SearchParameter resources - sync to expressions table
            if resourceType == "SearchParameter" {
                log:printDebug(string `Syncing SearchParameter/${resourceId} to SEARCH_PARAM_RES_EXPRESSIONS`);
                error? syncResult = utils:syncSearchParameterToExpressions(self.jdbcClient, resourceJson);
                if syncResult is error {
                    log:printError(string `Failed to sync SearchParameter/${resourceId}: ${syncResult.message()}`);
                    error? rollbackResult = self.transactionHandler.rollbackCreateTransaction(self.jdbcClient, 'transaction, resourceType);
                    if (rollbackResult is error) {
                        log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                    }
                    return syncResult;
                }
                log:printInfo(string `Successfully synced SearchParameter/${resourceId} to expressions table`);
            }

            // Save to history after creation
            log:printDebug(string `Saving initial version of ${resourceType}/${resourceId} to history`);
            error? historyResult = self.historyHandler.saveToHistory(resourceType, resourceId, insertModel, "POST");
            if historyResult is error {
                log:printError(string `Failed to save history for ${resourceType}/${resourceId}: ${historyResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackCreateTransaction(self.jdbcClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                return historyResult;
            }

            // Extract and save search parameters for indexed searching
            log:printDebug(string `Extracting search parameters for ${resourceType}/${resourceId}`);
            error? extractResult = utils:extractSearchParametersForResource(validatedClient, resourceType, resourceId, resourceJson);
            if extractResult is error {
                log:printError(string `Failed to extract search parameters for ${resourceType}/${resourceId}: ${extractResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackCreateTransaction(self.jdbcClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                return extractResult;
            }

            // Save all references
            log:printDebug(string `Saving ${references.length()} reference(s) for ${resourceType}/${resourceId}`);
            error? refResult = utils:saveReferences(self.jdbcClient, references, resourceType, resourceId, 'transaction);

            if refResult is error {
                // Rollback on reference save failure
                log:printError(string `Failed to save references for ${resourceType}/${resourceId}: ${refResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackCreateTransaction(self.jdbcClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                return refResult;
            }

            // Commit transaction
            log:printDebug(string `Committing transaction for ${resourceType}/${resourceId}`);
            self.transactionHandler.commitTransaction('transaction, resourceType, resourceId);

            log:printDebug(string `Successfully created ${resourceType}/${resourceId} with ${references.length()} reference(s)`);
            return resourceId;

        } on fail error e {
            // Rollback on any failure
            log:printError(string `Create transaction failed for ${resourceType}: ${e.message()}`);
            error? rollbackResult = check self.transactionHandler.rollbackCreateTransaction(self.jdbcClient, 'transaction, resourceType);
            if (rollbackResult is error) {
                log:printError(string `Rollback failed during create transaction cleanup for ${resourceType}: ${rollbackResult.message()}`);
            }
            return e;
        }
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
        
        // Execute raw SQL by creating a custom ParameterizedQuery implementation.
        // No pre-check SELECT — let the PK constraint detect duplicates to save a round-trip.
        utils:RawSQLQuery rawQuery = new(completeQueryStr);
        sql:ExecutionResult|error result = jdbcClient->execute(rawQuery);
        
        if result is error {
            string errMsg = result.message();
            // Translate PK / unique-constraint violation into a meaningful FHIR error
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


