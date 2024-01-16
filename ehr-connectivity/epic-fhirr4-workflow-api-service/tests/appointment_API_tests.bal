import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/test;
import ballerinax/health.fhir.r4.international401;

http:Client testClient2 = check new ("http://localhost:9092");

@test:BeforeGroups {value: ["appointment_api"]}
function before_appointment_api_test() {
    checkpanic log:setOutputFile("./tests/myfile.log", log:OVERWRITE);
    io:println("Starting the appointment api tests");
}

@test:Config {groups: ["appointment_api"]}
function test_get_appointment_with_valid_id() {
    string appointmentId = "1";
    http:Response response = checkpanic testClient2->get("/fhir/r4/Appointment/" + appointmentId);
    test:assertEquals(response.statusCode, 200);
    string contentType = checkpanic response.getHeader("Content-Type");
    test:assertEquals(contentType, "application/fhir+json");
    json result = checkpanic response.getJsonPayload();
    test:assertEquals(result.resourceType, "appointment");
}

@test:Config {groups: ["appointment_api"]}
function test_get_appointment_with_invalid_id() {
    string appointmentId = "1";
    log:printInfo("Test with InValid Id");
    http:Response response = checkpanic testClient2->get("/fhir/r4/Appointment/" + appointmentId);
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid Id");
    test:assertEquals(getLogMessage, "Error occurred while retrieving the response from Epic");
}

@test:Config {groups: ["appointment_api"]}
function test_get_appointment_with_invalid_fhir_response() {
    string appointmentId = "1";
    log:printInfo("Test with InValid fhir response");
    http:Response response = checkpanic testClient2->get("/fhir/r4/Appointment/" + appointmentId);
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir response");
    test:assertEquals(getLogMessage, "Error occurred while parsing the response");
}

@test:Config {groups: ["appointment_api"]}
function test_get_appointment_with_valid_params() {
    http:Response response = checkpanic testClient2->get("/fhir/r4/Appointment/?status=free");
    test:assertEquals(response.statusCode, 200);
    string contentType = checkpanic response.getHeader("Content-Type");
    test:assertEquals(contentType, "application/fhir+json");
}

@test:Config {groups: ["appointment_api"]}
function test_get_appointment_with_invalid_params() {
    log:printInfo("Test with InValid appointment parameters");
    http:Response response = checkpanic testClient2->get("/fhir/r4/Appointment/?status=adbc");
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid appointment parameters");
    test:assertEquals(getLogMessage, "Error occurred while retrieving the response from Epic.");
}

@test:Config {groups: ["appointment_api"]}
function test_post_valid_appointment() {
    international401:Appointment payload = {
        resourceType: "Appointment",
        participant: [
            {
                actor: {
                    reference: "Practitioner/example"
                },
                required: "required",
                status: "accepted"
            }
        ],
        status: "booked"
    };
    http:Response response = checkpanic testClient2->post("/fhir/r4/Appointment", payload, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 201);
}

@test:Config {groups: ["appointment_api"]}
function test_post_invalid_appointment() {
    international401:Appointment payload = {
        resourceType: "Appointment",
        participant: [
            {
                actor: {
                    reference: "Practitioner/example"
                },
                required: "required",
                status: "accepted"
            }
        ],
        status: "booked"
    };
    log:printInfo("Test with InValid fhir appointment");
    http:Response response = checkpanic testClient2->post("/fhir/r4/Appointment", payload, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir appointment");
    test:assertEquals(getLogMessage, "Error occurred while retrieving the response from Epic.");
}

@test:Config {groups: ["appointment_api"]}
function test_post_invalid_fhir_response_appointment() {
    international401:Appointment payload = {
        resourceType: "Appointment",
        participant: [
            {
                actor: {
                    reference: "Practitioner/example"
                },
                required: "required",
                status: "accepted"
            }
        ],
        status: "booked"
    };
    log:printInfo("Test with InValid fhir response post appointment");
    http:Response response = checkpanic testClient2->post("/fhir/r4/Appointment", payload, {"mediaType": "application/fhir+json"});
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir response post appointment");
    test:assertEquals(getLogMessage, "Error occurred while parsing the response");
}

@test:Config {groups: ["appointment_api"]}
function test_appointment_with_invalid_method_put() {
    international401:Appointment payload = {
        resourceType: "Appointment",
        participant: [
            {
                actor: {
                    reference: "Practitioner/example"
                },
                required: "required",
                status: "accepted"
            }
        ],
        status: "booked"
    };
    string appointmentId = "1";
    log:printInfo("Test with InValid method - put appointment");
    http:Response response = checkpanic testClient2->put("/fhir/r4/Appointment/" + appointmentId, payload, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid method - put appointment");
    test:assertEquals(getLogMessage, "Unsupported interaction type.");
}

@test:AfterGroups {value: ["appointment_api"]}
function after_appointment_api_test() {
    io:println("Completed the appointment api tests");
}
