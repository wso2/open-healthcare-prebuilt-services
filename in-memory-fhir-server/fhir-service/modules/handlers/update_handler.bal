import ballerina_fhir_server.db_store;
import ballerina_fhir_server.mappers;
import ballerina_fhir_server.utils;

import ballerina/log;

public class UpdateHandler {
    private mappers:UpdateMapper updateMapper;
    private utils:TransactionHandler transactionHandler;

    public isolated function init() {
        self.updateMapper = new mappers:UpdateMapper();
        self.transactionHandler = new utils:TransactionHandler();
    }

    // Main function for PUT (full update)
    public isolated function updateResourceWithTransaction(db_store:Client persistClient, string resourceType, string resourceId, json resourceJson) returns string|error {

        // Begin transaction
        utils:TransactionContext 'transaction = self.transactionHandler.beginTransaction();
        'transaction.mainResourceId = resourceId;

        do {
            // Check if resource exists
            log:printInfo(string `Checking if ${resourceType}/${resourceId} exists`);
            boolean exists = check self.checkResourceExists(persistClient, resourceType, resourceId);

            if !exists {
                return error(string `${resourceType}/${resourceId} not found`);
            }

            // Backup existing resource (for rollback)
            log:printInfo(string `Backing up existing ${resourceType}/${resourceId}`);
            record {|anydata...;|}? backup = check self.backupResource(persistClient, resourceType, resourceId);
            'transaction.backupResource = backup;

            // Delete old references (they will be recreated)
            log:printInfo(string `Deleting old references for ${resourceType}/${resourceId}`);
            int[] oldReferenceIds = check self.findSourceReferences(persistClient, resourceType, resourceId);
            error? deleteRefsResult = utils:deleteReferences(persistClient, oldReferenceIds, 'transaction);

            if deleteRefsResult is error {
                log:printError(string `Failed to delete old references: ${deleteRefsResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    persistClient, 'transaction, resourceType
                );
                if (rollbackResult is error) {
                    log:printError(rollbackResult.toString());
                }
                return deleteRefsResult;
            }

            // Map updated resource to update model
            log:printInfo(string `Mapping updated ${resourceType} to model`);
            record {|anydata...;|}|error? updateModel = self.updateMapper.mapToUpdateModel(persistClient, resourceType, resourceJson);

            if updateModel is () || updateModel is error {
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    persistClient, 'transaction, resourceType
                );
                if (rollbackResult is error) {
                    log:printError(rollbackResult.toString());
                }
                return updateModel is error ? updateModel : error("Failed to create update model");
            }

            // Update main resource
            log:printInfo(string `Updating main ${resourceType}/${resourceId} record`);
            error? updateResult = self.updateMainResource(persistClient, resourceType, resourceId, updateModel);

            if updateResult is error {
                log:printError(string `Main resource update failed: ${updateResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    persistClient, 'transaction, resourceType
                );
                if (rollbackResult is error) {
                    log:printError(rollbackResult.toString());
                }
                return updateResult;
            }

            // Save new references
            log:printInfo(string `Saving new references for ${resourceType}/${resourceId}`);
            json[] references = self.updateMapper.getReferences();
            error? refResult = utils:saveReferences(persistClient, references, resourceType, resourceId, 'transaction);

            if refResult is error {
                log:printError(string `Reference save failed: ${refResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    persistClient, 'transaction, resourceType
                );
                if (rollbackResult is error) {
                    log:printError(rollbackResult.toString());
                }
                return refResult;
            }

            // Commit transaction
            self.transactionHandler.commitTransaction('transaction, resourceType, resourceId);

            log:printInfo(string `Successfully updated ${resourceType}/${resourceId}`);
            return resourceId;

        } on fail error e {
            log:printError(string `Update transaction failed for ${resourceType}/${resourceId}: ${e.message()}`);
            error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                persistClient, 'transaction, resourceType
            );
            if (rollbackResult is error) {
                log:printError(rollbackResult.toString());
            }
            return e;
        }
    }

    // Main function for PATCH (partial update) with transaction support
    public isolated function patchResourceWithTransaction(db_store:Client persistClient, string resourceType, string resourceId, json patchJson) returns json|error {
        // Begin transaction
        utils:TransactionContext 'transaction = self.transactionHandler.beginTransaction();
        'transaction.mainResourceId = resourceId;

        do {
            // Check if resource exists and get current data
            log:printInfo(string `Fetching existing ${resourceType}/${resourceId}`);
            json existingResource = check self.getResourceAsJson(persistClient, resourceType, resourceId);

            // Backup for rollback
            log:printInfo(string `Backing up existing resource`);
            record {|anydata...;|}? backup = check self.backupResource(persistClient, resourceType, resourceId);
            'transaction.backupResource = backup;

            // Apply patch to existing resource
            log:printInfo(string `Applying patch to ${resourceType}/${resourceId}`);
            json mergedResource = check self.applyPatch(existingResource, patchJson);

            // Delete old references
            log:printInfo(string `Deleting old references`);
            int[] oldReferenceIds = check self.findSourceReferences(persistClient, resourceType, resourceId);
            error? deleteRefsResult = utils:deleteReferences(persistClient, oldReferenceIds, 'transaction);

            if deleteRefsResult is error {
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(persistClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(rollbackResult.toString());
                }
                return deleteRefsResult;
            }

            // Map merged resource to update model
            log:printInfo(string `Mapping patched resource to model`);
            record {|anydata...;|}|error? updateModel = self.updateMapper.mapToUpdateModel(persistClient, resourceType, mergedResource);

            if updateModel is () || updateModel is error {
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(persistClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(rollbackResult.toString());
                }
                return updateModel is error ? updateModel : error("Failed to create update model");
            }

            // Update main resource
            log:printInfo(string `Updating main resource`);
            error? updateResult = self.updateMainResource(persistClient, resourceType, resourceId, updateModel);

            if updateResult is error {
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    persistClient, 'transaction, resourceType
                );
                if (rollbackResult is error) {
                    log:printError(rollbackResult.toString());
                }
                return updateResult;
            }

            // Save new references
            log:printInfo(string `Saving new references`);
            json[] references = self.updateMapper.getReferences();
            error? refResult = utils:saveReferences(persistClient, references, resourceType, resourceId, 'transaction);

            if refResult is error {
                error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                    persistClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(rollbackResult.toString());
                }
                return refResult;
            }

            // Commit transaction
            self.transactionHandler.commitTransaction('transaction, resourceType, resourceId);

            log:printInfo(string `Successfully patched ${resourceType}/${resourceId}`);
            return updateModel.toJson();

        } on fail error e {
            log:printError(string `Patch transaction failed: ${e.message()}`);
            error? rollbackResult = self.transactionHandler.rollbackUpdateTransaction(
                persistClient, 'transaction, resourceType
            );
            if (rollbackResult is error) {
                log:printError(rollbackResult.toString());
            }
            return e;
        }
    }

    // Check if resource exists
    private isolated function checkResourceExists(db_store:Client persistClient, string resourceType, string resourceId) returns boolean|error {

        match resourceType {
            "Appointment" => {
                stream<db_store:AppointmentTable, error?> 'stream = persistClient->/appointmenttables(targetType = db_store:AppointmentTable);

                db_store:AppointmentTable[] results = check from var item in 'stream
                    where item.APPOINTMENTTABLE_ID == resourceId
                    select item;

                return results.length() > 0;
            }
            _ => {
                return error(string `Unsupported resource type: ${resourceType}`);
            }
        }
    }

    // Backup resource for rollback
    private isolated function backupResource(db_store:Client persistClient,
            string resourceType,
            string resourceId) returns record {|anydata...;|}|error {

        match resourceType {
            "Appointment" => {
                stream<db_store:AppointmentTable, error?> 'stream = persistClient->/appointmenttables(targetType = db_store:AppointmentTable);

                db_store:AppointmentTable[] results = check from var item in 'stream
                    where item.APPOINTMENTTABLE_ID == resourceId
                    select item;

                if results.length() == 0 {
                    return error("Resource not found for backup");
                }

                return results[0];
            }
            _ => {
                return error(string `Unsupported resource type: ${resourceType}`);
            }
        }
    }

    // Get resource as JSON (for PATCH operations)
    private isolated function getResourceAsJson(db_store:Client persistClient, string resourceType, string resourceId) returns json|error {

        record {|anydata...;|} backup = check self.backupResource(persistClient, resourceType, resourceId);

        // Extract RESOURCE_JSON field
        byte[]? resourceBlob = ();

        match resourceType {
            "Appointment" => {
                db_store:AppointmentTable appointment = check backup.cloneWithType();
                resourceBlob = appointment.RESOURCE_JSON;
            }
        }

        if resourceBlob is byte[] {
            string jsonString = check string:fromBytes(resourceBlob);
            json resourceJson = check jsonString.fromJsonString();
            return resourceJson;
        }

        return error("Could not extract resource JSON");
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
    private isolated function findSourceReferences(db_store:Client persistClient, string resourceType, string resourceId) returns int[]|error {

        stream<db_store:REFERENCES, error?> 'stream = persistClient->/references(targetType = db_store:REFERENCES);

        db_store:REFERENCES[] references = check from var ref in 'stream
            where ref.SOURCE_RESOURCE_TYPE == resourceType && ref.SOURCE_RESOURCE_ID == resourceId
            select ref;

        int[] referenceIds = [];
        foreach var ref in references {
            referenceIds.push(ref.ID);
        }

        return referenceIds;
    }

    private isolated function updateMainResource(db_store:Client persistClient, string resourceType, string resourceId, record {|anydata...;|} updateModel) returns error? {

        match resourceType {
            "Appointment" => {
                db_store:AppointmentTableUpdate updateRecord = check updateModel.cloneWithType();
                _ = check persistClient->/appointmenttables/[resourceId].put(updateRecord);
            }
            _ => {
                return error(string `Unsupported resource type: ${resourceType}`);
            }
        }
    }
}
