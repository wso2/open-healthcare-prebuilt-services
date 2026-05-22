import ballerinax/health.fhirr4;
import ballerina/os;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4.uscore501 as uscore;
import ballerinax/health.fhir.r4;
import ballerina/http;
import ballerinax/health.fhir.r4.international401;

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

public type Condition uscore:USCoreCondition;

public type AllergyIntolerance uscore:USCoreAllergyIntolerance;

public type Procedure uscore:USCoreProcedureProfile;

public type ServiceRequest international401:ServiceRequest;

service / on new fhirr4:Listener(9090, conditionApiConfig) {
    
    // Read the current state of the resource.
    isolated resource function get fhir/r4/Condition/[string id](r4:FHIRContext fhirContext) returns Condition|r4:FHIRError {
        Condition|error fhirInteractionResult = executeFhirInteraction("Condition", fhirContext, id, (), uscore:USCoreCondition).ensureType(Condition);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Condition read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Condition(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Condition", fhirContext, (), (), uscore:USCoreCondition).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Condition search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Condition(r4:FHIRContext fhirContext, uscore:USCoreCondition payload) returns @http:Payload {mediaType: ["application/fhir+json"]} Condition|r4:FHIRError {
        Condition|error fhirInteractionResult = executeFhirInteraction("Condition", fhirContext, (), payload, uscore:USCoreCondition).ensureType(Condition);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Condition create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9091, allergyIntoleranceApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/AllergyIntolerance/[string id](r4:FHIRContext fhirContext) returns uscore:USCoreAllergyIntolerance|r4:FHIRError {
        AllergyIntolerance|error fhirInteractionResult = executeFhirInteraction("AllergyIntolerance", fhirContext, id, (), uscore:USCoreAllergyIntolerance).ensureType(AllergyIntolerance);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the AllergyIntolerance read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/AllergyIntolerance(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("AllergyIntolerance", fhirContext, (), (), uscore:USCoreAllergyIntolerance).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the AllergyIntolerance search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/AllergyIntolerance(r4:FHIRContext fhirContext, uscore:USCoreAllergyIntolerance payload) returns @http:Payload {mediaType: ["application/fhir+json"]} uscore:USCoreAllergyIntolerance|r4:FHIRError {
        AllergyIntolerance|error fhirInteractionResult = executeFhirInteraction("AllergyIntolerance", fhirContext, (), payload, uscore:USCoreAllergyIntolerance).ensureType(AllergyIntolerance);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the AllergyIntolerance create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9092, procedureApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Procedure/[string id](r4:FHIRContext fhirContext) returns uscore:USCoreProcedureProfile|r4:FHIRError {
        Procedure|error fhirInteractionResult = executeFhirInteraction("Procedure", fhirContext, id, (), uscore:USCoreProcedureProfile).ensureType(Procedure);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Procedure read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Procedure(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Procedure", fhirContext, (), (), uscore:USCoreProcedureProfile).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Procedure search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Procedure(r4:FHIRContext fhirContext, uscore:USCoreProcedureProfile payload) returns @http:Payload {mediaType: ["application/fhir+json"]} uscore:USCoreProcedureProfile|r4:FHIRError {
        Procedure|error fhirInteractionResult = executeFhirInteraction("Procedure", fhirContext, (), payload, uscore:USCoreProcedureProfile).ensureType(Procedure);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Procedure create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

//TODO: migrate with USCore ServiceRequest profile. currently it's missing in the package.
service / on new fhirr4:Listener(9093, serviceRequestApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/ServiceRequest/[string id](r4:FHIRContext fhirContext) returns international401:ServiceRequest|r4:FHIRError {
        ServiceRequest|error fhirInteractionResult = executeFhirInteraction("ServiceRequest", fhirContext, id, (), international401:ServiceRequest).ensureType(ServiceRequest);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the ServiceRequest read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/ServiceRequest(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("ServiceRequest", fhirContext, (), (), international401:ServiceRequest).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the ServiceRequest search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/ServiceRequest(r4:FHIRContext fhirContext, international401:ServiceRequest payload) returns @http:Payload {mediaType: ["application/fhir+json"]} international401:ServiceRequest|r4:FHIRError {
        ServiceRequest|error fhirInteractionResult = executeFhirInteraction("ServiceRequest", fhirContext, (), payload, international401:ServiceRequest).ensureType(ServiceRequest);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the ServiceRequest create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}
