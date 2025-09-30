import ballerina_fhir_server.db_store;

import ballerina/log;
import ballerina/regex;
import ballerina/time;

// Delete main resource
public isolated function deleteResource(db_store:Client persistClient, string resourceType, string resourceId) returns error? {

    match resourceType {
        "Appointment" => {
            _ = check persistClient->/appointmenttables/[resourceId].delete();
        }
    }
}

// Delete references
public isolated function deleteReferences(db_store:Client persistClient, int[] referenceIds, TransactionContext 'transaction) returns error? {

    foreach int refId in referenceIds {
        _ = check persistClient->/references/[refId].delete();
        'transaction.deletedReferenceIds.push(refId);
    }
}

public isolated function saveReferences(db_store:Client persistClient, json[] references, string sourceResType, string sourceResId, TransactionContext 'transaction) returns error? {
    if references.length() == 0 {
        log:printDebug("No references to save");
        return;
    }

    log:printInfo(string `Saving ${references.length()} reference(s) for ${sourceResType}/${sourceResId}`);

    foreach json referenceEntry in references {

        // referenceEntry is a map with param name as key
        if referenceEntry is map<json> {
            foreach var [paramName, paramValue] in referenceEntry.entries() {

                // Handle array of references
                if paramValue is json[] {
                    foreach json singleRef in paramValue {
                        error? result = saveSingleReference(persistClient, sourceResType, sourceResId, paramName, singleRef, 'transaction);
                        if result is error {
                            return result;
                        }
                    }
                }
                // Handle single reference
                else {
                    error? result = saveSingleReference(persistClient, sourceResType, sourceResId, paramName, paramValue, 'transaction);
                    if result is error {
                        return result;
                    }
                }
            }
        }
    }

    log:printInfo(string `Successfully saved all references for ${sourceResType}/${sourceResId}`);
}

public isolated function saveSingleReference(db_store:Client persistClient, string sourceResType, string sourceResId, string sourceExpression, json fhirReference, TransactionContext 'transaction) returns error? {

    // Extract reference details
    if !(fhirReference is map<json>) {
        log:printDebug(string `Skipping non-object reference: ${fhirReference.toString()}`);
        return;
    }

    map<json> refMap = <map<json>>fhirReference;

    // Get reference string (e.g., "Patient/123")
    json refString = refMap["reference"];
    if !(refString is string) || refString == "" {
        log:printDebug("Empty or invalid reference, skipping");
        return;
    }

    // Parse reference string
    string[] refParts = regex:split(<string>refString, "/");
    if refParts.length() != 2 {
        return error(string `Invalid reference format: ${refString}. Expected format: ResourceType/id`);
    }

    string targetResourceType = refParts[0];
    string targetResourceId = refParts[1];

    // Get display value (optional)
    json displayJson = refMap["display"];
    string displayValue = displayJson is string ? displayJson : "";

    // Create reference insert record
    db_store:REFERENCESInsert referencesInsert = {
        SOURCE_RESOURCE_TYPE: sourceResType,
        SOURCE_RESOURCE_ID: sourceResId,
        SOURCE_EXPRESSION: sourceExpression,
        TARGET_RESOURCE_TYPE: targetResourceType,
        TARGET_RESOURCE_ID: targetResourceId,
        DISPLAY_VALUE: displayValue,
        CREATED_AT: time:utcToCivil(time:utcNow()),
        UPDATED_AT: time:utcToCivil(time:utcNow()),
        LAST_UPDATED: time:utcToCivil(time:utcNow())
    };

    // Save to database
    int[] recordIds = check persistClient->/references.post([referencesInsert]);
    int savedRefId = recordIds[0];

    // Track in transaction context for rollback
    'transaction.savedReferenceIds.push(savedRefId);

    log:printInfo(string `Saved reference [${savedRefId}]: ${sourceResType}/${sourceResId} --(${sourceExpression})--> ${targetResourceType}/${targetResourceId}`);
}
