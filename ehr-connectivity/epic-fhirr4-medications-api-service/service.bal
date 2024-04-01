import ballerinax/health.clients.fhir;
import ballerina/os;
import ballerinax/health.fhirr4;
import ballerinax/health.fhir.r4.uscore501 as uscore;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerina/http;


configurable string base = os:getEnv("EPIC_FHIR_SERVER_URL");
configurable string tokenUrl = os:getEnv("EPIC_FHIR_SERVER_TOKEN_URL");
configurable string clientId = os:getEnv("EPIC_FHIR_APP_CLIENT_ID");
configurable string keyFile = os:getEnv("EPIC_FHIR_APP_PRIVATE_KEY_FILE");

fhir:FHIRConnectorConfig epicConfig = {
    baseURL: base,
    mimeType: fhir:FHIR_JSON,
    authConfig: {
        clientId: clientId,
        tokenEndpoint: tokenUrl,
        keyFile: keyFile
    }
};

final fhir:FHIRConnector fhirConnectorObj = check new (epicConfig);

public type Medication uscore:USCoreMedicationProfile;

public type Immunization uscore:USCoreImmunizationProfile;

public type MedicationRequest uscore:USCoreMedicationRequestProfile;

public type MedicationStatement international401:MedicationStatement;

service / on new fhirr4:Listener(9090, medicationApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Medication/[string id](r4:FHIRContext fhirContext) returns Medication|r4:FHIRError {
        Medication|error fhirInteractionResult = executeFhirInteraction("Medication", fhirContext, id, (), Medication).ensureType(Medication);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Medication(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Medication", fhirContext, (), (), Medication).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Medication(r4:FHIRContext fhirContext, uscore:USCoreMedicationProfile medication) returns @http:Payload {mediaType: ["application/fhir+json"]} Medication|r4:FHIRError {
        Medication|error fhirInteractionResult = executeFhirInteraction("Medication", fhirContext, (), medication, Medication).ensureType(Medication);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9091, immunizationApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Immunication/[string id](r4:FHIRContext fhirContext) returns Immunization|r4:FHIRError {
        Immunization|error fhirInteractionResult = executeFhirInteraction("Immunization", fhirContext, id, (), Immunization).ensureType(Immunization);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Immunization(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Immunization", fhirContext, (), (), Immunization).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Immunization(r4:FHIRContext fhirContext, uscore:USCoreImmunizationProfile immunization) returns @http:Payload {mediaType: ["application/fhir+json"]} Immunization|r4:FHIRError {
        Immunization|error fhirInteractionResult = executeFhirInteraction("Immunization", fhirContext, (), immunization, Immunization).ensureType(Immunization);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9092, medicationrequestApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/MedicationRequest/[string id](r4:FHIRContext fhirContext) returns MedicationRequest|r4:FHIRError {
        MedicationRequest|error fhirInteractionResult = executeFhirInteraction("MedicationRequest", fhirContext, id, (), MedicationRequest).ensureType(MedicationRequest);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/MedicationRequest(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("MedicationRequest", fhirContext, (), (), MedicationRequest).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/MedicationRequest(r4:FHIRContext fhirContext, uscore:USCoreMedicationRequestProfile medicationRequest) returns @http:Payload {mediaType: ["application/fhir+json"]} MedicationRequest|r4:FHIRError {
        MedicationRequest|error fhirInteractionResult = executeFhirInteraction("MedicationRequest", fhirContext, (), medicationRequest, MedicationRequest).ensureType(MedicationRequest);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9093, medicationstatementApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/MedicationStatement/[string id](r4:FHIRContext fhirContext) returns MedicationStatement|r4:FHIRError {
        MedicationStatement|error fhirInteractionResult = executeFhirInteraction("MedicationStatement", fhirContext, id, (), MedicationStatement).ensureType(MedicationStatement);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/MedicationStatement(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("MedicationStatement", fhirContext, (), (), MedicationStatement).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/MedicationStatement(r4:FHIRContext fhirContext, international401:MedicationStatement medicationStatement) returns @http:Payload {mediaType: ["application/fhir+json"]} MedicationStatement|r4:FHIRError {
        MedicationStatement|error fhirInteractionResult = executeFhirInteraction("MedicationStatement", fhirContext, (), medicationStatement, MedicationStatement).ensureType(MedicationStatement);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}
