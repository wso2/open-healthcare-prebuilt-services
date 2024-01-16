import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/test;
import ballerinax/health.fhir.r4.international401;

http:Client testClient = check new ("http://localhost:9090");

function get_log_message(string key, boolean next=true) returns string {
    string[] lines = checkpanic io:fileReadLines("./resources/myfile.log");
    boolean found = false;
    foreach string line in lines {
        string:RegExp r = re `message=`;
        string[] parts = r.split(line);
        if parts.length() > 1 {
            string message = parts[1];
            message = message.substring(1, message.length() - 2);
            if (found) {
                return message;
            }
            if (message == key) {
                found = true;
                if (!next){
                    return message;
                }
            }
        }
    }
    return "";
}

@test:BeforeGroups {value: ["schedule_api"]}
function before_schedule_api_test() {
    checkpanic log:setOutputFile("./tests/myfile.log", log:OVERWRITE);
    io:println("Starting the schedule api tests");
}

@test:Config {groups: ["schedule_api"]}
function test_get_schedule_with_valid_id() {
    string scheduleId = "1";
    http:Response response = checkpanic testClient->get("/fhir/r4/Schedule/" + scheduleId);
    test:assertEquals(response.statusCode, 200);
    string contentType = checkpanic response.getHeader("Content-Type");
    test:assertEquals(contentType, "application/fhir+json");
    json result = checkpanic response.getJsonPayload();
    test:assertEquals(result.resourceType, "Schedule");
}

@test:Config {groups: ["schedule_api"]}
function test_get_schedule_with_invalid_id() {
    string scheduleId = "1";
    log:printInfo("Test with InValid Id");
    http:Response response = checkpanic testClient->get("/fhir/r4/Schedule/" + scheduleId);
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid Id");
    test:assertEquals(getLogMessage, "Error occurred while retrieving the response from Epic");
}

@test:Config {groups: ["schedule_api"]}
function test_get_schedule_with_invalid_fhir_response() {
    string scheduleId = "1";
    log:printInfo("Test with InValid fhir response");
    http:Response response = checkpanic testClient->get("/fhir/r4/Schedule/" + scheduleId);
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir response");
    test:assertEquals(getLogMessage, "Error occurred while parsing the response");
}

@test:Config {groups: ["schedule_api"]}
function test_get_schedule_with_valid_params() {
    http:Response response = checkpanic testClient->get("/fhir/r4/Schedule/?active=true");
    test:assertEquals(response.statusCode, 200);
    string contentType = checkpanic response.getHeader("Content-Type");
    test:assertEquals(contentType, "application/fhir+json");
}

@test:Config {groups: ["schedule_api"]}
function test_get_schedule_with_invalid_params() {
    log:printInfo("Test with InValid parameters");
    http:Response response = checkpanic testClient->get("/fhir/r4/Schedule/?active=abcd");
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid parameters");
    test:assertEquals(getLogMessage, "Error occurred while retrieving the response from Epic.");
}

@test:Config {groups: ["schedule_api"]}
function test_post_valid_schedule() {
    international401:Schedule payload = {
        "resourceType": "Schedule",
        "actor": [
            {
                "reference": "Practitioner/example"
            }
        ]
    };
    http:Response response = checkpanic testClient->post("/fhir/r4/Schedule", payload, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 201);
}

@test:Config {groups: ["schedule_api"]}
function test_post_invalid_schedule() {
    international401:Schedule payload = {
        "resourceType": "Schedule",
        "actor": [
            {
                "reference": "Practitioner/example"
            }
        ]
    };
    log:printInfo("Test with InValid fhir schedule");
    http:Response response = checkpanic testClient->post("/fhir/r4/Schedule", payload, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir schedule");
    test:assertEquals(getLogMessage, "Error occurred while retrieving the response from Epic.");
}

@test:Config {groups: ["schedule_api"]}
function test_post_invalid_fhir_response_xml_response() {
    international401:Schedule payload = {
        "resourceType": "Schedule",
        "actor": [
            {
                "reference": "Practitioner/example"
            }
        ]
    };
    log:printInfo("FHIR response result contains xml");
    http:Response response = checkpanic testClient->post("/fhir/r4/Schedule", payload, {"mediaType": "application/fhir+json"});
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("FHIR response result contains xml");
    test:assertEquals(getLogMessage, "XML response type is not supported.");
}

@test:Config {groups: ["schedule_api"]}
function test_post_error_while_extraction(){
    international401:Schedule payload = {
        "resourceType": "Schedule",
        "actor": [
            {
                "reference": "Practitioner/example"
            }
        ]
    };
    log:printInfo("Error occurred while extracting the resource type.");
    http:Response response = checkpanic testClient->post("/fhir/r4/Schedule", payload, {"mediaType": "application/fhir+json"});
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Error occurred while extracting the resource type.");
    test:assertEquals(getLogMessage, "Error occurred while extracting the resource type.");
}

@test:Config {groups: ["schedule_api"]}
function test_schedule_with_invalid_method_put() {
    international401:Schedule payload = {
        "resourceType": "Schedule",
        "actor": [
            {
                "reference": "Practitioner/example"
            }
        ]
    };
    string scheduleId = "1";
    log:printInfo("Test with InValid method - put");
    http:Response response = checkpanic testClient->put("/fhir/r4/Schedule/" + scheduleId, payload, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid method - put");
    test:assertEquals(getLogMessage, "Unsupported interaction type.");
}

@test:AfterGroups {value: ["schedule_api"]}
function after_schedule_api_test() {
    io:println("Completed the schedule api tests");
}
