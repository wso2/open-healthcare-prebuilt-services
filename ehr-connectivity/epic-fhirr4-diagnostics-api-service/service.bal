import ballerinax/health.clients.fhir;
import ballerina/os;
import ballerinax/health.fhirr4;
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

//TODO: Add missing observation profiles to the package.
public type Observation international401:Observation;

public type DiagnosticReport international401:DiagnosticReport;

service / on new fhirr4:Listener(9090, observationApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Observation/[string id](r4:FHIRContext fhirContext) returns Observation|r4:FHIRError {
        Observation|error fhirInteractionResult = executeFhirInteraction("Observation", fhirContext, id, (), Observation).ensureType(Observation);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Observation(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Observation", fhirContext, (), (), Observation).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    // TODO: fix the payload type to accept all the union types supported for observation.
    isolated resource function post fhir/r4/Observation(r4:FHIRContext fhirContext, international401:Observation payload) returns @http:Payload {mediaType: ["application/fhir+json"]} Observation|r4:FHIRError {
        Observation|error fhirInteractionResult = executeFhirInteraction("Observation", fhirContext, (), payload, Observation).ensureType(Observation);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Observation create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9091, diagnosticreportApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/DiagnosticReport/[string id](r4:FHIRContext fhirContext) returns DiagnosticReport|r4:FHIRError {
        DiagnosticReport|error fhirInteractionResult = executeFhirInteraction("DiagnosticReport", fhirContext, id, (), DiagnosticReport).ensureType(DiagnosticReport);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the DiagnosticReport read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/DiagnosticReport(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("DiagnosticReport", fhirContext, (), (), DiagnosticReport).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the DiagnosticReport search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/DiagnosticReport(r4:FHIRContext fhirContext, international401:DiagnosticReport payload) returns @http:Payload {mediaType: ["application/fhir+json"]} DiagnosticReport|r4:FHIRError {
        DiagnosticReport|error fhirInteractionResult = executeFhirInteraction("DiagnosticReport", fhirContext, (), payload, DiagnosticReport).ensureType(DiagnosticReport);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the DiagnosticReport create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

}
