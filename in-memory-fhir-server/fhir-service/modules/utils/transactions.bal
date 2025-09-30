import ballerina_fhir_server.db_store;

import ballerina/log;

public type TransactionContext record {|
    string? mainResourceId = ();
    int[] savedReferenceIds = [];
    int[] deletedReferenceIds = [];
    record {|anydata...;|}? backupResource = ();
    db_store:REFERENCES[]? backupReferences = ();
    boolean committed = false;
|};

public class TransactionHandler {

    public isolated function beginTransaction() returns TransactionContext {
        log:printInfo("Beginning new transaction");
        return {
            mainResourceId: (),
            savedReferenceIds: [],
            deletedReferenceIds: [],
            backupResource: (),
            committed: false
        };
    }

    // Rollback for CREATE operations
    public isolated function rollbackCreateTransaction(db_store:Client persistClient, TransactionContext 'transaction, string resourceType) returns error? {
        if 'transaction.committed {
            log:printWarn("Cannot rollback a committed transaction");
            return;
        }

        log:printWarn(string `Rolling back ${resourceType} CREATE transaction`);

        int deletedRefs = 0;
        int failedRefs = 0;

        // Delete references
        int[] referenceIds = 'transaction.savedReferenceIds.reverse();
        error? refDeleteResult = deleteReferences(persistClient, referenceIds, 'transaction);
        if (refDeleteResult is error) {
            log:printError(refDeleteResult.toString());
        }

        // Delete main resource if it was saved
        if 'transaction.mainResourceId is string {
            string resourceId = <string>'transaction.mainResourceId;
            error? deleteResult = deleteResource(persistClient, resourceType, resourceId);

            if deleteResult is error {
                log:printError(string `Failed to delete main resource ${resourceId}: ${deleteResult.message()}`);
                return deleteResult;
            } else {
                log:printInfo(string `Deleted main resource: ${resourceType}/${resourceId}`);
            }
        }

        log:printInfo(string `Rollback completed: deleted ${deletedRefs} references, failed ${failedRefs}`);
    }

    // Rollback for DELETE operations (restore deleted items)
    public isolated function rollbackDeleteTransaction(db_store:Client persistClient, TransactionContext 'transaction, string resourceType) returns error? {

        if 'transaction.committed {
            log:printWarn("Cannot rollback a committed transaction");
            return;
        }

        log:printWarn(string `Rolling back ${resourceType} DELETE transaction`);

        // Restore main resource
        if 'transaction.backupResource is record {|anydata...;|} {
            string resourceId = <string>'transaction.mainResourceId;
            error? restoreResult = self.restoreResource(persistClient, resourceType, resourceId, 'transaction.backupResource);

            if restoreResult is error {
                log:printError(string `Failed to restore resource: ${restoreResult.message()}`);
                return restoreResult;
            } else {
                log:printInfo(string `Restored ${resourceType}/${resourceId}`);
            }
        }

        // Restore deleted references
        if 'transaction.backupReferences is db_store:REFERENCES[] {
            db_store:REFERENCES[] backupRefs = <db_store:REFERENCES[]>'transaction.backupReferences;
            foreach db_store:REFERENCES ref in backupRefs {
                db_store:REFERENCESInsert refInsert = {
                    SOURCE_RESOURCE_TYPE: ref.SOURCE_RESOURCE_TYPE,
                    SOURCE_RESOURCE_ID: ref.SOURCE_RESOURCE_ID,
                    SOURCE_EXPRESSION: ref.SOURCE_EXPRESSION,
                    TARGET_RESOURCE_TYPE: ref.TARGET_RESOURCE_TYPE,
                    TARGET_RESOURCE_ID: ref.TARGET_RESOURCE_ID,
                    DISPLAY_VALUE: ref.DISPLAY_VALUE,
                    CREATED_AT: ref.CREATED_AT,
                    UPDATED_AT: ref.UPDATED_AT,
                    LAST_UPDATED: ref.LAST_UPDATED
                };

                int[]|error result = persistClient->/references.post([refInsert]);
                if result is error {
                    log:printError(string `Failed to restore reference: ${result.message()}`);
                } else {
                    log:printInfo(string `Restored reference: ${ref.ID}`);
                }
            }
        }

        log:printInfo("Delete rollback completed successfully");
    }

    public isolated function commitTransaction(TransactionContext 'transaction, string resourceType, string resourceId) {
        'transaction.committed = true;
        log:printInfo(string `Transaction committed successfully for ${resourceType}/${resourceId}`);

        if 'transaction.savedReferenceIds.length() > 0 {
            log:printInfo(string `   - Main resource: ${<string>'transaction.mainResourceId}`);
            log:printInfo(string `   - References saved: ${'transaction.savedReferenceIds.length()}`);
        }

        if 'transaction.deletedReferenceIds.length() > 0 {
            log:printInfo(string `   - Main resource: ${<string>'transaction.mainResourceId}`);
            log:printInfo(string `   - References deleted: ${'transaction.deletedReferenceIds.length()}`);
        }
    }

    // Rollback for UPDATE operations (restore from backup)
    public isolated function rollbackUpdateTransaction(db_store:Client persistClient, TransactionContext 'transaction, string resourceType) returns error? {

        if 'transaction.committed {
            log:printWarn("Cannot rollback a committed transaction");
            return;
        }

        log:printWarn(string `Rolling back ${resourceType} UPDATE transaction`);

        // Restore backed up resource
        if 'transaction.backupResource is record {|anydata...;|} {
            string resourceId = <string>'transaction.mainResourceId;
            error? restoreResult = self.restoreResource(persistClient, resourceType, resourceId, 'transaction.backupResource);
            if restoreResult is error {
                log:printError(string `Failed to restore resource: ${restoreResult.message()}`);
            } else {
                log:printInfo(string `Restored ${resourceType}/${resourceId} from backup`);
            }
        }

        // Delete newly created references
        foreach int refId in 'transaction.savedReferenceIds.reverse() {
            _ = check persistClient->/references/[refId].delete();
        }

        log:printInfo("Update rollback completed");
    }

    private isolated function restoreResource(db_store:Client persistClient, string resourceType, string resourceId, record {|anydata...;|}? backup) returns error? {

        if backup is () {
            return error("No backup available for restore");
        }

        match resourceType {
            "Appointment" => {
                db_store:AppointmentTableUpdate updateRecord = check backup.cloneWithType();
                _ = check persistClient->/appointmenttables/[resourceId].put(updateRecord);
            }
            "Patient" => {
                db_store:PatientTableUpdate updateRecord = check backup.cloneWithType();
                _ = check persistClient->/patienttables/[resourceId].put(updateRecord);
            }
            _ => {
                return error(string `Unsupported resource type: ${resourceType}`);
            }
        }
    }
}
