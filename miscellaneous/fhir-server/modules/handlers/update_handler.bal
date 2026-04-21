import ballerina_fhir_server.mappers;
import ballerina_fhir_server.utils;

import ballerina/log;
import ballerina/sql;
import ballerinax/java.jdbc;

public class UpdateHandler {
    private mappers:UpdateMapper updateMapper;
    private utils:TransactionHandler transactionHandler;
    private HistoryHandler historyHandler;
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
        self.updateMapper = new mappers:UpdateMapper(jdbcClient);
        self.transactionHandler = new utils:TransactionHandler();
        self.historyHandler = new HistoryHandler(jdbcClient);
    }

    // Main function for PUT (full update)
    public isolated function updateResourceWithTransaction(string resourceType, string resourceId, json resourceJson) returns string|error {

        // Begin transaction
        utils:TransactionContext 'transaction = self.transactionHandler.beginTransaction();
        'transaction.mainResourceId = resourceId;

        do {
            // Get JDBC client
            jdbc:Client? jdbcConn = self.jdbcClient;
            if jdbcConn is () {
                return error("JDBC client not initialized");
            }

            // Check if resource exists
            log:printDebug(string `Checking if ${resourceType}/${resourceId} exists`);
            boolean exists = check self.checkResourceExists(resourceType, resourceId);

            if !exists {
                log:printWarn(string `Update attempted on non-existent resource: ${resourceType}/${resourceId}`);
                return error(string `${resourceType}/${resourceId} not found`);
            }

            // Backup existing resource (for rollback)
            log:printDebug(string `Backing up existing ${resourceType}/${resourceId}`);
            record {|anydata...;|} backup = check self.backupResource(resourceType, resourceId);
            'transaction.backupResource = backup;

            // Delete old references (they will be recreated)
            log:printDebug(string `Deleting old references for ${resourceType}/${resourceId}`);
            int[] oldReferenceIds = check self.findSourceReferences(resourceType, resourceId);
            error? deleteRefsResult = utils:deleteReferences(self.jdbcClient, oldReferenceIds, 'transaction);

            if deleteRefsResult is error {
                log:printError(string `Failed to delete old references for ${resourceType}/${resourceId}: ${deleteRefsResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    self.jdbcClient, 'transaction, resourceType
                );
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                return deleteRefsResult;
            }

            // Get current VERSION_ID and increment it
            int currentVersion = check self.getCurrentVersionFromBackup(backup, resourceType);
            int newVersion = currentVersion + 1;

            // Map updated resource to update model
            log:printDebug(string `Mapping updated ${resourceType} to model (version ${newVersion})`);
            record {|anydata...;|}|error? updateModel = self.updateMapper.mapToUpdateModel(jdbcConn, resourceType, resourceJson, newVersion);

            if updateModel is () || updateModel is error {
                log:printError(string `Failed to map update model for ${resourceType}/${resourceId}: ${updateModel is error ? updateModel.message() : "mapper returned null"}`);
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    self.jdbcClient, 'transaction, resourceType
                );
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                return updateModel is error ? updateModel : error("Failed to create update model");
            }

            // Get extracted references after mapping
            json[] references = self.updateMapper.getReferences();

            // Update main resource
            // Note: reference existence is enforced by the DB FK on RESOURCE_TABLE — no app-level SELECT needed.
            log:printDebug(string `Updating main ${resourceType}/${resourceId} record`);
            error? updateResult = self.updateMainResource(resourceType, resourceId, updateModel);

            if updateResult is error {
                log:printError(string `Failed to update main resource ${resourceType}/${resourceId}: ${updateResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    self.jdbcClient, 'transaction, resourceType
                );
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                return updateResult;
            }

            // Special handling for SearchParameter resources - sync to expressions table
            if resourceType == "SearchParameter" {
                log:printDebug(string `Syncing updated SearchParameter/${resourceId} to SEARCH_PARAM_RES_EXPRESSIONS`);
                error? syncResult = utils:syncSearchParameterToExpressions(self.jdbcClient, resourceJson);
                if syncResult is error {
                    log:printError(string `Failed to sync SearchParameter/${resourceId}: ${syncResult.message()}`);
                    error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                        self.jdbcClient, 'transaction, resourceType
                    );
                    if (rollbackResult is error) {
                        log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                    }
                    return syncResult;
                }
                log:printInfo(string `Successfully synced updated SearchParameter/${resourceId} to expressions table`);
            }

            // Save new version to history after successful update
            log:printDebug(string `Saving new version of ${resourceType}/${resourceId} to history`);
            error? historyResult = self.historyHandler.saveToHistory(resourceType, resourceId, updateModel, "PUT");
            if historyResult is error {
                log:printError(string `Failed to save history for ${resourceType}/${resourceId}: ${historyResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    self.jdbcClient, 'transaction, resourceType
                );
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                return historyResult;
            }

            // Update search parameters for indexed searching
            log:printDebug(string `Updating search parameters for ${resourceType}/${resourceId}`);
            error? updateSearchResult = utils:updateSearchParametersForResource(jdbcConn, resourceType, resourceId, resourceJson);
            if updateSearchResult is error {
                log:printError(string `Failed to update search parameters for ${resourceType}/${resourceId}: ${updateSearchResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    self.jdbcClient, 'transaction, resourceType
                );
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                return updateSearchResult;
            }

            // Save new references
            log:printDebug(string `Saving new references for ${resourceType}/${resourceId}`);
            error? refResult = utils:saveReferences(self.jdbcClient, references, resourceType, resourceId, 'transaction);

            if refResult is error {
                log:printError(string `Failed to save references for ${resourceType}/${resourceId}: ${refResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    self.jdbcClient, 'transaction, resourceType
                );
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                string refMsg = refResult.message();
                if refMsg.includes("violates foreign key constraint") || refMsg.includes("FK_REFERENCES_TARGET") {
                    return error(string `Unresolved reference: one or more TARGET resources referenced by ${resourceType}/${resourceId} do not exist. Ensure all referenced resources are created first.`);
                }
                return refResult;
            }

            // Commit transaction
            log:printDebug(string `Committing update transaction for ${resourceType}/${resourceId}`);
            self.transactionHandler.commitTransaction('transaction, resourceType, resourceId);

            log:printDebug(string `Successfully updated ${resourceType}/${resourceId}`);
            return resourceId;

        } on fail error e {
            log:printError(string `Update transaction failed for ${resourceType}/${resourceId}: ${e.message()}`);
            error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                self.jdbcClient, 'transaction, resourceType
            );
            if (rollbackResult is error) {
                log:printError(string `Rollback failed during update transaction cleanup for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
            }
            return e;
        }
    }

    // Main function for PATCH (partial update) with transaction support
    public isolated function patchResourceWithTransaction(string resourceType, string resourceId, json patchJson) returns json|error {
        // Get JDBC client
        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client not initialized");
        }

        // Begin transaction
        utils:TransactionContext 'transaction = self.transactionHandler.beginTransaction();
        'transaction.mainResourceId = resourceId;

        do {
            // Check if resource exists and get current data
            log:printDebug(string `Fetching existing ${resourceType}/${resourceId}`);
            json existingResource = check self.getResourceAsJson(resourceType, resourceId);

            // Backup for rollback
            log:printDebug(string `Backing up existing resource`);
            record {|anydata...;|} backup = check self.backupResource(resourceType, resourceId);
            'transaction.backupResource = backup;

            // Apply patch to existing resource
            log:printDebug(string `Applying patch to ${resourceType}/${resourceId}`);
            json mergedResource = check self.applyPatch(existingResource, patchJson);

            // Delete old references
            log:printDebug(string `Deleting old references`);
            int[] oldReferenceIds = check self.findSourceReferences(resourceType, resourceId);
            error? deleteRefsResult = utils:deleteReferences(self.jdbcClient, oldReferenceIds, 'transaction);

            if deleteRefsResult is error {
                log:printError(string `Failed to delete old references for ${resourceType}/${resourceId}: ${deleteRefsResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(self.jdbcClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                return deleteRefsResult;
            }

            // Map merged resource to update model
            log:printDebug(string `Mapping patched resource to model`);
            record {|anydata...;|}|error? updateModel = self.updateMapper.mapToUpdateModel(jdbcConn, resourceType, mergedResource);

            if updateModel is () || updateModel is error {
                log:printError(string `Failed to map patched resource for ${resourceType}/${resourceId}: ${updateModel is error ? updateModel.message() : "mapper returned null"}`);
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(self.jdbcClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                return updateModel is error ? updateModel : error("Failed to create update model");
            }

            // Get extracted references after mapping
            json[] references = self.updateMapper.getReferences();

            // Update main resource
            // Note: reference existence is enforced by the DB FK on RESOURCE_TABLE — no app-level SELECT needed.
            log:printDebug(string `Updating main resource`);
            error? updateResult = self.updateMainResource(resourceType, resourceId, updateModel);

            if updateResult is error {
                log:printError(string `Failed to update main resource ${resourceType}/${resourceId}: ${updateResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    self.jdbcClient, 'transaction, resourceType
                );
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                return updateResult;
            }

            // Save new references
            log:printDebug(string `Saving new references`);
            error? refResult = utils:saveReferences(self.jdbcClient, references, resourceType, resourceId, 'transaction);

            if refResult is error {
                log:printError(string `Failed to save references for ${resourceType}/${resourceId}: ${refResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    self.jdbcClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(string `Rollback failed for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
                }
                string refMsg = refResult.message();
                if refMsg.includes("violates foreign key constraint") || refMsg.includes("FK_REFERENCES_TARGET") {
                    return error(string `Unresolved reference: one or more TARGET resources referenced by ${resourceType}/${resourceId} do not exist. Ensure all referenced resources are created first.`);
                }
                return refResult;
            }

            // Commit transaction
            log:printDebug(string `Committing patch transaction for ${resourceType}/${resourceId}`);
            self.transactionHandler.commitTransaction('transaction, resourceType, resourceId);

            log:printDebug(string `Successfully patched ${resourceType}/${resourceId}`);
            return mergedResource;

        } on fail error e {
            log:printError(string `Patch transaction failed for ${resourceType}/${resourceId}: ${e.message()}`);
            error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                self.jdbcClient, 'transaction, resourceType
            );
            if (rollbackResult is error) {
                log:printError(string `Rollback failed during patch transaction cleanup for ${resourceType}/${resourceId}: ${rollbackResult.message()}`);
            }
            return e;
        }
    }

    // Check if resource exists
    private isolated function checkResourceExists(string resourceType, string resourceId) returns boolean|error {
        return utils:resourceExists(self.jdbcClient, resourceType, resourceId);
    }

    // Backup resource for rollback
    private isolated function backupResource(string resourceType,
            string resourceId) returns record {|anydata...;|}|error {

        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client not initialized");
        }

        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);

        string sqlQuery = string `SELECT * FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        stream<record {|anydata...;|}, sql:Error?> resultStream = jdbcConn->query(query);

        record {|anydata...;|}[] results = check from var result in resultStream
            select result;

        if results.length() == 0 {
            return error(string `${resourceType}/${resourceId} not found for backup`);
        }

        return results[0];
    }

    // Get resource as JSON (for PATCH operations)
    private isolated function getResourceAsJson(string resourceType, string resourceId) returns json|error {

        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client not initialized");
        }

        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);

        string sqlQuery = string `SELECT "RESOURCE_JSON" FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;

        string jsonString;
        string normalizedDbType = dbType.toLowerAscii().trim();
        if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
            string pgSql = string `SELECT CAST("RESOURCE_JSON" AS TEXT) AS "RESOURCE_JSON" FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
            sql:ParameterizedQuery pgQuery = new utils:RawSQLQuery(pgSql);
            stream<record {|string RESOURCE_JSON;|}, sql:Error?> pgStream = jdbcConn->query(pgQuery);
            record {|string RESOURCE_JSON;|}[] pgResults = check from var r in pgStream select r;
            if pgResults.length() == 0 {
                return error(string `${resourceType}/${resourceId} not found`);
            }
            jsonString = pgResults[0].RESOURCE_JSON;
        } else {
            sql:ParameterizedQuery h2Query = new utils:RawSQLQuery(sqlQuery);
            stream<record {|byte[] RESOURCE_JSON;|}, sql:Error?> h2Stream = jdbcConn->query(h2Query);
            record {|byte[] RESOURCE_JSON;|}[] h2Results = check from var r in h2Stream select r;
            if h2Results.length() == 0 {
                return error(string `${resourceType}/${resourceId} not found`);
            }
            jsonString = check string:fromBytes(h2Results[0].RESOURCE_JSON);
        }

        json resourceJson = check jsonString.fromJsonString();

        return resourceJson;
    }

    // Apply JSON patch
    private isolated function applyPatch(json existing, json patch) returns json|error {
        if !(existing is map<json>) {
            return error(string `Existing resource is not a JSON object: ${existing.toString()}`);
        }

        if !(patch is map<json>) {
            return error(string `Patch is not a JSON object: ${patch.toString()}`);
        }

        map<json> existingMap = <map<json>>existing;
        map<json> patchMap = <map<json>>patch;

        // Create a new map to hold merged values
        map<json> mergedMap = existingMap.clone();

        // Patch values override existing values
        foreach var [key, value] in patchMap.entries() {
            mergedMap[key] = value;
        }

        return mergedMap;
    }

    // Find source references
    private isolated function findSourceReferences(string resourceType, string resourceId) returns int[]|error {

        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client not initialized");
        }

        string sqlQuery = string `SELECT "ID" FROM "REFERENCES" WHERE "SOURCE_RESOURCE_TYPE" = '${utils:escapeSql(resourceType)}' AND "SOURCE_RESOURCE_ID" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        stream<record {|int ID;|}, sql:Error?> resultStream = jdbcConn->query(query);

        record {|int ID;|}[] results = check from var result in resultStream
            select result;

        int[] referenceIds = from var ref in results
            select ref.ID;

        return referenceIds;
    }

    private isolated function updateMainResource(string resourceType, string resourceId, record {|anydata...;|} updateModel) returns error? {

        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client not initialized");
        }

        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);

        // Build UPDATE SET clause dynamically from updateModel fields
        string[] setClauses = [];
        foreach var [key, value] in updateModel.entries() {
            string formattedValue;
            // Use special formatting for DATE columns (date only, no time)
            if key == "DATE" {
                formattedValue = utils:formatDateValue(value);
            } else {
                formattedValue = self.transactionHandler.formatValue(value);
            }
            setClauses.push(string `"${key}" = ${formattedValue}`);
        }

        if setClauses.length() == 0 {
            return error("No fields to update");
        }

        string setClause = string:'join(", ", ...setClauses);
        string sqlQuery = string `UPDATE "${tableName}" SET ${setClause} WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        sql:ExecutionResult|sql:Error result = jdbcConn->execute(query);

        if result is sql:Error {
            return error(string `Failed to update ${resourceType}/${resourceId}: ${result.message()}`);
        }

        return;
    }

    // Extract current VERSION_ID from backup
    private isolated function getCurrentVersionFromBackup(record {|anydata...;|} backup, string resourceType) returns int|error {
        // Generic extraction - all resource tables have VERSION_ID
        anydata versionField = backup["VERSION_ID"];
        if versionField is int {
            return versionField;
        }
        return error(string `Could not extract VERSION_ID for ${resourceType}: field is ${versionField.toString()}`);
    }
}
