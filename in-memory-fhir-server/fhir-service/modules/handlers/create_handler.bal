import ballerina_fhir_server.db_store;
import ballerina_fhir_server.mappers;
import ballerina_fhir_server.utils;

import ballerina/log;

public class CreateHandler {
    private mappers:CreateMapper createMapper = new mappers:CreateMapper();
    private utils:TransactionHandler transactionHandler;

    public isolated function init() {
        self.transactionHandler = new utils:TransactionHandler();
    }

    // Main function to save resource
    public isolated function saveResourceWithTransaction(db_store:Client persistClient, string resourceType, json resourceJson) returns string|error {

        // Begin transaction
        utils:TransactionContext 'transaction = self.transactionHandler.beginTransaction();
        json[] references = self.createMapper.getReferences();

        do {
            // Map resource to insert model
            log:printInfo(string `Mapping ${resourceType} to insert model`);
            record {|anydata...;|}|error? insertModel = self.createMapper.mapToInsertModel(
                persistClient, resourceType, resourceJson
            );

            if insertModel is () {
                return error(string `Failed to create insert model for ${resourceType}`);
            }

            if insertModel is error {
                return insertModel;
            }

            // Save main resource
            log:printInfo(string `Saving main ${resourceType} record`);
            string resourceId = check self.saveMainResource(persistClient, resourceType, insertModel);
            'transaction.mainResourceId = resourceId;

            log:printInfo(string `Saved ${resourceType} with ID: ${resourceId}`);

            // Save all references
            log:printInfo(string `Saving references for ${resourceType}/${resourceId}`);
            error? refResult = utils:saveReferences(persistClient, references, resourceType, resourceId, 'transaction);

            if refResult is error {
                // Rollback on reference save failure
                log:printError(string `Reference save failed: ${refResult.message()}`);
                error? rollbackResult = self.transactionHandler.rollbackCreateTransaction(persistClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(`Rollback Status: ${rollbackResult.toString()}`);
                }
                return refResult;
            }

            // Commit transaction
            self.transactionHandler.commitTransaction('transaction, resourceType, resourceId);

            log:printInfo(string `Successfully saved ${resourceType}/${resourceId} with all references`);
            return resourceId;

        } on fail error e {
            // Rollback on any failure
            log:printError(string `Transaction failed for ${resourceType}: ${e.message()}`);
            error? rollbackResult = check self.transactionHandler.rollbackCreateTransaction(persistClient, 'transaction, resourceType);
            if (rollbackResult is error) {
                log:printError(`Rollback Status: ${rollbackResult.toString()}`);
            }
            return e;
        }
    }

    private isolated function saveMainResource(db_store:Client persistClient, string resourceType, record {|anydata...;|} insertModel) returns string|error {

        match resourceType {
            "Appointment" => {
                db_store:AppointmentTableInsert appointmentInsert = check insertModel.cloneWithType();
                string[] recordIds = check persistClient->/appointmenttables.post([appointmentInsert]);
                return recordIds[0];
            }
            _ => {
                return error(string `Unsupported resource type for saving: ${resourceType}`);
            }
        }
    }
}
