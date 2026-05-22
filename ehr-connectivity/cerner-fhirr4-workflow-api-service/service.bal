import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhirr4;
import ballerinax/health.fhir.r4;
import ballerina/http;


configurable string baseServerHost = ?;
configurable string cernerUrl = ?;
configurable string tokenUrl = ?;
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string[] scopes = ?;

fhir:FHIRConnectorConfig cernerConfig = {
    baseURL: cernerUrl,
    mimeType: fhir:FHIR_JSON,
    authConfig: {
        tokenUrl: tokenUrl,
        clientId: clientId,
        clientSecret: clientSecret,
        scopes: scopes
    }
};

final fhir:FHIRConnector fhirConnectorObj = check new (cernerConfig);

public type Schedule international401:Schedule;

public type Slot international401:Slot;

public type Appointment international401:Appointment;

public type AppointmentResponse international401:AppointmentResponse;

public type ServiceRequest international401:ServiceRequest;

service / on new fhirr4:Listener(9097, scheduleApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Schedule/[string id](r4:FHIRContext fhirContext) returns Schedule|r4:FHIRError {
        Schedule|error fhirInteractionResult = executeFhirInteraction("Schedule", fhirContext, id, (), international401:Schedule).ensureType(Schedule);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Schedule read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Schedule(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Schedule", fhirContext, (), (), international401:Schedule).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Schedule search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Schedule(r4:FHIRContext fhirContext, international401:Schedule schedule) returns @http:Payload {mediaType: ["application/fhir+json"]} http:Response|r4:FHIRError {
        anydata|error fhirInteractionResult = executeFhirInteraction("Schedule", fhirContext, (), schedule, international401:Schedule);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Schedule create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return buildCreateInteractionResponse("fhir/r4/Schedule", <map<anydata>>fhirInteractionResult);
    }
}

service / on new fhirr4:Listener(9098, slotApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Slot/[string id](r4:FHIRContext fhirContext) returns Slot|r4:FHIRError {
        Slot|error fhirInteractionResult = executeFhirInteraction("Slot", fhirContext, id, (), international401:Slot).ensureType(Slot);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Slot read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Slot(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Slot", fhirContext, (), (), international401:Slot).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Slot search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Slot(r4:FHIRContext fhirContext, international401:Slot slot) returns @http:Payload {mediaType: ["application/fhir+json"]} http:Response|r4:FHIRError {
        anydata|error fhirInteractionResult = executeFhirInteraction("Slot", fhirContext, (), slot, international401:Slot);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Slot create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return buildCreateInteractionResponse("fhir/r4/Slot", <map<anydata>>fhirInteractionResult);
    }
}

service / on new fhirr4:Listener(9099, appointmentApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Appointment/[string id](r4:FHIRContext fhirContext) returns Appointment|r4:FHIRError {
        Appointment|error fhirInteractionResult = executeFhirInteraction("Appointment", fhirContext, id, (), international401:Appointment).ensureType(Appointment);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Appointment read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Appointment(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Appointment", fhirContext, (), (), international401:Appointment).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Appointment search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Appointment(r4:FHIRContext fhirContext, international401:Appointment appointment) returns @http:Payload {mediaType: ["application/fhir+json"]} http:Response|r4:FHIRError {
        anydata|error fhirInteractionResult = executeFhirInteraction("Appointment", fhirContext, (), appointment, international401:Appointment);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Appointment create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return buildCreateInteractionResponse("fhir/r4/Appointment", <map<anydata>>fhirInteractionResult);
    }
}

service / on new fhirr4:Listener(9100, appointmentResponseApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/AppointmentResponse/[string id](r4:FHIRContext fhirContext) returns AppointmentResponse|r4:FHIRError {
        AppointmentResponse|error fhirInteractionResult = executeFhirInteraction("AppointmentResponse", fhirContext, id, (), international401:AppointmentResponse).ensureType(AppointmentResponse);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the AppointmentResponse read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/AppointmentResponse(r4:FHIRContext fhirContext) returns @http:Payload {mediaType: ["application/fhir+json"]} r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("AppointmentResponse", fhirContext, (), (), international401:AppointmentResponse).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the AppointmentResponse search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/AppointmentResponse(r4:FHIRContext fhirContext, international401:AppointmentResponse appointmentResponse) returns @http:Payload {mediaType: ["application/fhir+json"]} http:Response|r4:FHIRError {
        anydata|error fhirInteractionResult = executeFhirInteraction("AppointmentResponse", fhirContext, (), appointmentResponse, international401:AppointmentResponse);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the AppointmentResponse create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return buildCreateInteractionResponse("fhir/r4/AppointmentResponse", <map<anydata>>fhirInteractionResult);
    }
}

service / on new fhirr4:Listener(9101, serviceRequestApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/ServiceRequest/[string id](r4:FHIRContext fhirContext) returns ServiceRequest|r4:FHIRError {
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
    isolated resource function post fhir/r4/ServiceRequest(r4:FHIRContext fhirContext, international401:ServiceRequest serviceRequest) returns @http:Payload {mediaType: ["application/fhir+json"]} http:Response|r4:FHIRError {
        anydata|error fhirInteractionResult = executeFhirInteraction("ServiceRequest", fhirContext, (), serviceRequest, international401:ServiceRequest);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the ServiceRequest create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return buildCreateInteractionResponse("fhir/r4/ServiceRequest", <map<anydata>>fhirInteractionResult);
    }
}
