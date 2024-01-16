import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/test;
import ballerinax/health.fhir.r4.international401;

http:Client testClient3 = check new ("http://localhost:9093");

@test:BeforeGroups {value: ["appointmentResponse_api"]}
function before_appointmentResponse_api_test() {
    checkpanic log:setOutputFile("./tests/myfile.log", log:OVERWRITE);
    io:println("Starting the appointmentResponse api tests");
}

@test:Config {groups: ["appointmentResponse_api"]}
function test_get_appointmentResponse_with_valid_id() {
    string appointmentResponseId = "1";
    http:Response response = checkpanic testClient3->get("/fhir/r4/AppointmentResponse/" + appointmentResponseId);
    test:assertEquals(response.statusCode, 200);
    string contentType = checkpanic response.getHeader("Content-Type");
    test:assertEquals(contentType, "application/fhir+json");
    json result = checkpanic response.getJsonPayload();
    test:assertEquals(result.resourceType, "appointmentResponse");
}

@test:Config {groups: ["appointmentResponse_api"]}
function test_get_appointmentResponse_with_invalid_id() {
    string appointmentResponseId = "1";
    log:printInfo("Test with InValid Id");
    http:Response response = checkpanic testClient3->get("/fhir/r4/AppointmentResponse/" + appointmentResponseId);
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid Id");
    test:assertEquals(getLogMessage, "Error occurred while retrieving the response from Epic");
}

@test:Config {groups: ["appointmentResponse_api"]}
function test_get_appointmentResponse_with_invalid_fhir_response() {
    string appointmentResponseId = "1";
    log:printInfo("Test with InValid fhir response");
    http:Response response = checkpanic testClient3->get("/fhir/r4/AppointmentResponse/" + appointmentResponseId);
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir response");
    test:assertEquals(getLogMessage, "Error occurred while parsing the response");
}

@test:Config {groups: ["appointmentResponse_api"]}
function test_get_appointmentResponse_with_valid_params() {
    http:Response response = checkpanic testClient3->get("/fhir/r4/AppointmentResponse/?identifier=123");
    test:assertEquals(response.statusCode, 200);
    string contentType = checkpanic response.getHeader("Content-Type");
    test:assertEquals(contentType, "application/fhir+json");
}

@test:Config {groups: ["appointmentResponse_api"]}
function test_get_appointmentResponse_with_invalid_params() {
    log:printInfo("Test with InValid appointmentResponse parameters");
    http:Response response = checkpanic testClient3->get("/fhir/r4/AppointmentResponse/?identifier=something");
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid appointmentResponse parameters");
    test:assertEquals(getLogMessage, "Error occurred while retrieving the response from Epic.");
}

@test:Config {groups: ["appointmentResponse_api"]}
function test_post_valid_appointmentResponse() {
    international401:AppointmentResponse payload = {
        "resourceType": "AppointmentResponse",
        "appointment": {
            "reference": "Appointment/example"
        },
        "participantStatus": "accepted"
    };
    http:Response response = checkpanic testClient3->post("/fhir/r4/AppointmentResponse", payload, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 201);
}

@test:Config {groups: ["appointmentResponse_api"]}
function test_post_invalid_appointmentResponse() {
    international401:AppointmentResponse payload = {
        resourceType: "AppointmentResponse",
        appointment: {
            reference: "Appointment/example"
        },
        participantStatus: "accepted"
    };
    log:printInfo("Test with InValid fhir appointmentResponse");
    http:Response response = checkpanic testClient3->post("/fhir/r4/AppointmentResponse", payload, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir appointmentResponse");
    test:assertEquals(getLogMessage, "Error occurred while retrieving the response from Epic.");
}

@test:Config {groups: ["appointmentResponse_api"]}
function test_post_invalid_fhir_response_appointmentResponse() {
    international401:AppointmentResponse payload = {
        resourceType: "AppointmentResponse",
        appointment: {
            reference: "Appointment/example"
        },
        participantStatus: "accepted"
    };
    log:printInfo("Test with InValid fhir response post appointmentResponse");
    http:Response response = checkpanic testClient3->post("/fhir/r4/AppointmentResponse", payload, {"mediaType": "application/fhir+json"});
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir response post appointmentResponse");
    test:assertEquals(getLogMessage, "Error occurred while parsing the response");
}

@test:Config {groups: ["appointmentResponse_api"]}
function test_appointmentResponse_with_invalid_method_put() {
    international401:AppointmentResponse payload = {
        resourceType: "AppointmentResponse",
        appointment: {
            reference: "Appointment/example"
        },
        participantStatus: "accepted"
    };
    string appointmentResponseId = "1";
    log:printInfo("Test with InValid method - put appointmentResponse");
    http:Response response = checkpanic testClient3->put("/fhir/r4/AppointmentResponse/" + appointmentResponseId, payload, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid method - put appointmentResponse");
    test:assertEquals(getLogMessage, "Unsupported interaction type.");
}

@test:AfterGroups {value: ["appointmentResponse_api"]}
function after_appointmentResponse_api_test() {
    io:println("Completed the appointmentResponse api tests");
}
