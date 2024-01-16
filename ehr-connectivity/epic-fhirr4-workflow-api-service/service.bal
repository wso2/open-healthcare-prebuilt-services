import ballerina/os;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhirr4;
import ballerinax/health.fhir.r4;
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

public type Schedule international401:Schedule;

public type Slot international401:Slot;

public type Appointment international401:Appointment;

public type AppointmentResponse international401:AppointmentResponse;

public type ServiceRequest international401:ServiceRequest;

service / on new fhirr4:Listener(9090, scheduleApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Schedule/[string id](r4:FHIRContext fhirContext) returns Schedule|r4:FHIRError {
        Schedule|error fhirInteractionResult = executeFhirInteraction("Schedule", fhirContext, id, (), Schedule).ensureType(Schedule);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Schedule read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Schedule(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Schedule", fhirContext, (), (), Schedule).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Schedule search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Schedule(r4:FHIRContext fhirContext, international401:Schedule schedule) returns @http:Payload {mediaType: ["application/fhir+json"]} Schedule|r4:FHIRError {
        Schedule|error fhirInteractionResult = executeFhirInteraction("Schedule", fhirContext, (), schedule, Schedule).ensureType(Schedule);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Schedule create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9091, slotApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Slot/[string id](r4:FHIRContext fhirContext) returns Slot|r4:FHIRError {
        Slot|error fhirInteractionResult = executeFhirInteraction("Slot", fhirContext, id, (), Slot).ensureType(Slot);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Slot read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Slot(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Slot", fhirContext, (), (), Slot).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Slot search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Slot(r4:FHIRContext fhirContext, international401:Slot slot) returns @http:Payload {mediaType: ["application/fhir+json"]} Slot|r4:FHIRError {
        Slot|error fhirInteractionResult = executeFhirInteraction("Slot", fhirContext, (), slot, Slot).ensureType(Slot);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Slot create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9092, appointmentApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Appointment/[string id](r4:FHIRContext fhirContext) returns Appointment|r4:FHIRError {
        Appointment|error fhirInteractionResult = executeFhirInteraction("Appointment", fhirContext, id, (), Appointment).ensureType(Appointment);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Appointment read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Appointment(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Appointment", fhirContext, (), (), Appointment).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Appointment search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Appointment(r4:FHIRContext fhirContext, international401:Appointment appointment) returns @http:Payload {mediaType: ["application/fhir+json"]} Appointment|r4:FHIRError {
        Appointment|error fhirInteractionResult = executeFhirInteraction("Appointment", fhirContext, (), appointment, Appointment).ensureType(Appointment);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Appointment create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9093, appointmentResponseApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/AppointmentResponse/[string id](r4:FHIRContext fhirContext) returns AppointmentResponse|r4:FHIRError {
        AppointmentResponse|error fhirInteractionResult = executeFhirInteraction("AppointmentResponse", fhirContext, id, (), AppointmentResponse).ensureType(AppointmentResponse);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the AppointmentResponse read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/AppointmentResponse(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("AppointmentResponse", fhirContext, (), (), AppointmentResponse).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the AppointmentResponse search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/AppointmentResponse(r4:FHIRContext fhirContext, international401:AppointmentResponse appointmentResponse) returns @http:Payload {mediaType: ["application/fhir+json"]} AppointmentResponse|r4:FHIRError {
        AppointmentResponse|error fhirInteractionResult = executeFhirInteraction("AppointmentResponse", fhirContext, (), appointmentResponse, AppointmentResponse).ensureType(AppointmentResponse);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the AppointmentResponse create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9094, serviceRequestApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/ServiceRequest/[string id](r4:FHIRContext fhirContext) returns ServiceRequest|r4:FHIRError {
        ServiceRequest|error fhirInteractionResult = executeFhirInteraction("ServiceRequest", fhirContext, id, (), ServiceRequest).ensureType(ServiceRequest);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the ServiceRequest read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/ServiceRequest(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("ServiceRequest", fhirContext, (), (), ServiceRequest).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the ServiceRequest search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/ServiceRequest(r4:FHIRContext fhirContext, international401:ServiceRequest serviceRequest) returns @http:Payload {mediaType: ["application/fhir+json"]} ServiceRequest|r4:FHIRError {
        ServiceRequest|error fhirInteractionResult = executeFhirInteraction("ServiceRequest", fhirContext, (), serviceRequest, ServiceRequest).ensureType(ServiceRequest);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the ServiceRequest create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}
