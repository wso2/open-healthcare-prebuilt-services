import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/test;
import ballerinax/health.fhir.r4.international401;

http:Client testClient1 = check new ("http://localhost:9091");

@test:BeforeGroups {value: ["slot_api"]}
function before_slot_api_test() {
    checkpanic log:setOutputFile("./tests/myfile.log", log:OVERWRITE);
    io:println("Starting the slot api tests");
}

@test:Config {groups: ["slot_api"]}
function test_get_slot_with_valid_id() {
    string slotId = "1";
    http:Response response = checkpanic testClient1->get("/fhir/r4/Slot/" + slotId);
    test:assertEquals(response.statusCode, 200);
    string contentType = checkpanic response.getHeader("Content-Type");
    test:assertEquals(contentType, "application/fhir+json");
    json result = checkpanic response.getJsonPayload();
    test:assertEquals(result.resourceType, "Slot");
}

@test:Config {groups: ["slot_api"]}
function test_get_slot_with_invalid_id() {
    string slotId = "1";
    log:printInfo("Test with InValid Id");
    http:Response response = checkpanic testClient1->get("/fhir/r4/Slot/" + slotId);
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid Id");
    test:assertEquals(getLogMessage, "Error occurred while retrieving the response from Epic");
}

@test:Config {groups: ["slot_api"]}
function test_get_slot_with_invalid_fhir_response() {
    string slotId = "1";
    log:printInfo("Test with InValid fhir response");
    http:Response response = checkpanic testClient1->get("/fhir/r4/Slot/" + slotId);
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir response");
    test:assertEquals(getLogMessage, "Error occurred while parsing the response");
}

@test:Config {groups: ["slot_api"]}
function test_get_slot_with_valid_params() {
    http:Response response = checkpanic testClient1->get("/fhir/r4/Slot/?status=free");
    test:assertEquals(response.statusCode, 200);
    string contentType = checkpanic response.getHeader("Content-Type");
    test:assertEquals(contentType, "application/fhir+json");
}

@test:Config {groups: ["slot_api"]}
function test_get_slot_with_invalid_params() {
    log:printInfo("Test with InValid slot parameters");
    http:Response response = checkpanic testClient1->get("/fhir/r4/Slot/?status=adbc");
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid slot parameters");
    test:assertEquals(getLogMessage, "Error occurred while retrieving the response from Epic.");
}

@test:Config {groups: ["slot_api"]}
function test_post_valid_slot() {
    international401:Slot payload = {
        resourceType: "Slot",
        'start: "2022-12-10T09:00:00Z",
        end: "2022-12-10T11:00:00Z",
        schedule: {
            reference: "Schedule/example"
        },
        status: "free"
    };
    http:Response response = checkpanic testClient1->post("/fhir/r4/Slot", payload, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 201);
}

@test:Config {groups: ["slot_api"]}
function test_post_invalid_slot() {
    international401:Slot payload = {
        resourceType: "Slot",
        'start: "2022-12-10T09:00:00Z",
        end: "2022-12-10T11:00:00Z",
        schedule: {
            reference: "Schedule/example"
        },
        status: "free"
    };
    log:printInfo("Test with InValid fhir slot");
    http:Response response = checkpanic testClient1->post("/fhir/r4/Slot", payload, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir slot");
    test:assertEquals(getLogMessage, "Error occurred while retrieving the response from Epic.");
}

@test:Config {groups: ["slot_api"]}
function test_post_invalid_fhir_response_slot() {
    international401:Slot payload = {
        resourceType: "Slot",
        'start: "2022-12-10T09:00:00Z",
        end: "2022-12-10T11:00:00Z",
        schedule: {
            reference: "Schedule/example"
        },
        status: "free"
    };
    log:printInfo("Test with InValid fhir response post SLOT");
    http:Response response = checkpanic testClient1->post("/fhir/r4/Slot", payload, {"mediaType": "application/fhir+json"});
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir response post SLOT");
    test:assertEquals(getLogMessage, "Error occurred while parsing the response");
}

@test:Config {groups: ["slot_api"]}
function test_slot_with_invalid_method_put() {
    international401:Slot payload = {
        resourceType: "Slot",
        'start: "2022-12-10T09:00:00Z",
        end: "2022-12-10T11:00:00Z",
        schedule: {
            reference: "Schedule/example"
        },
        status: "free"
    };
    string slotId = "1";
    log:printInfo("Test with InValid method - put SLOT");
    http:Response response = checkpanic testClient1->put("/fhir/r4/Slot/" + slotId, payload, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid method - put SLOT");
    test:assertEquals(getLogMessage, "Unsupported interaction type.");
}

@test:AfterGroups {value: ["slot_api"]}
function after_slot_api_test() {
    io:println("Completed the slot api tests");
}
