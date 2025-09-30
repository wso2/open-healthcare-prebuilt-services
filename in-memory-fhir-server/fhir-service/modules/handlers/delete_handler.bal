import ballerina_fhir_server.db_store;
import ballerina_fhir_server.utils;

import ballerina/log;

public class DeleteHandler {
    private utils:TransactionHandler transactionHandler;

    public isolated function init() {
        self.transactionHandler = new utils:TransactionHandler();
    }

    // Main function to delete resource with full transaction support
    public isolated function deleteResourceWithTransaction(db_store:Client persistClient, string resourceType, string resourceId) returns boolean|error {

        utils:TransactionContext 'transaction = self.transactionHandler.beginTransaction();
        'transaction.mainResourceId = resourceId;

        do {
            // Check if resource exists
            log:printInfo(string `Checking if ${resourceType}/${resourceId} exists`);
            boolean exists = check self.checkResourceExists(persistClient, resourceType, resourceId);

            if !exists {
                return error(string `${resourceType}/${resourceId} not found`);
            }

            // Backup before delete
            log:printInfo(string `Backing up ${resourceType}/${resourceId} before deletion`);
            record {|anydata...;|}? backup = check self.backupResource(persistClient, resourceType, resourceId);
            'transaction.backupResource = backup;
            'transaction.backupReferences = check self.backupReferences(persistClient, resourceType, resourceId);

            // Find references
            log:printInfo(string `Finding references for ${resourceType}/${resourceId}`);
            int[] referenceIds = check self.findSourceReferences(persistClient, resourceType, resourceId);

            // Delete references
            error? refResult = self.deleteReferences(persistClient, referenceIds, 'transaction);

            if refResult is error {
                error? rollbackResult = self.transactionHandler.rollbackDeleteTransaction(persistClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(rollbackResult.toString());
                }
                return refResult;
            }

            // Delete main resource
            log:printInfo(string `Deleting main ${resourceType}/${resourceId} record`);
            error? deleteResult = utils:deleteResource(persistClient, resourceType, resourceId);

            if deleteResult is error {
                error? rollbackResult = self.transactionHandler.rollbackDeleteTransaction(persistClient, 'transaction, resourceType);
                if (rollbackResult is error) {
                    log:printError(rollbackResult.toString());
                }
                return deleteResult;
            }

            // Commit Transaction
            self.transactionHandler.commitTransaction('transaction, resourceType, resourceId);

            log:printInfo(string `Successfully deleted ${resourceType}/${resourceId}`);
            return true;

        } on fail error e {
            error? rollbackResult = self.transactionHandler.rollbackDeleteTransaction(persistClient, 'transaction, resourceType);
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
                stream<db_store:AppointmentTable, error?> appointmentStream =
                    persistClient->/appointmenttables(targetType = db_store:AppointmentTable);

                db_store:AppointmentTable[] appointments = check from var appointment in appointmentStream
                    where appointment.APPOINTMENTTABLE_ID == resourceId
                    select appointment;

                return appointments.length() > 0;
            }
            _ => {
                return error(string `Unsupported resource type: ${resourceType}`);
            }
        }
    }

    // Find all references where this resource is the SOURCE
    private isolated function findSourceReferences(db_store:Client persistClient, string resourceType, string resourceId) returns int[]|error {

        stream<db_store:REFERENCES, error?> referenceStream = persistClient->/references(targetType = db_store:REFERENCES);

        db_store:REFERENCES[] references = check from var ref in referenceStream
            where ref.SOURCE_RESOURCE_TYPE == resourceType && ref.SOURCE_RESOURCE_ID == resourceId
            select ref;

        // Extract reference IDs
        int[] referenceIds = [];
        foreach var ref in references {
            referenceIds.push(ref.ID);
        }

        return referenceIds;
    }

    // Delete all references and track for rollback
    private isolated function deleteReferences(db_store:Client persistClient, int[] referenceIds, utils:TransactionContext 'transaction) returns error? {

        if referenceIds.length() == 0 {
            log:printDebug("No references to delete");
            return;
        }

        foreach int refId in referenceIds {
            _ = check persistClient->/references/[refId].delete();

            // Track deleted reference for potential rollback
            'transaction.deletedReferenceIds.push(refId);
            log:printInfo(string `Deleted reference: ${refId}`);
        }
    }

    // Add backup methods to DeleteHandler
    private isolated function backupResource(db_store:Client persistClient, string resourceType, string resourceId) returns record {|anydata...;|}|error {
        match resourceType {
            "Appointment" => {
                stream<db_store:AppointmentTable, error?> 'stream = persistClient->/appointmenttables(targetType = db_store:AppointmentTable);

                db_store:AppointmentTable[] results = check from var item in 'stream
                    where item.APPOINTMENTTABLE_ID == resourceId
                    select item;

                return results.length() > 0 ? results[0] : error("Resource not found");
            }
        }
        return error("Delete Handler Backup Resource: Error");
    }

    private isolated function backupReferences(db_store:Client persistClient, string resourceType, string resourceId) returns db_store:REFERENCES[]|error {

        stream<db_store:REFERENCES, error?> 'stream = persistClient->/references(targetType = db_store:REFERENCES);

        db_store:REFERENCES[] references = check from var ref in 'stream
            where ref.SOURCE_RESOURCE_TYPE == resourceType && ref.SOURCE_RESOURCE_ID == resourceId
            select ref;

        return references;
    }
}
