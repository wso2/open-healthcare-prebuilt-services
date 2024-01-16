import ballerina/http;
import ballerina/test;
import ballerina/io;
import ballerina/log;
import ballerinax/health.fhir.r4.international401;

http:Client testClient4 = check new ("http://localhost:9094");

@test:BeforeGroups { value:["service_request_api"] }
function before_service_request_api_test() {
    checkpanic log:setOutputFile("./tests/myfile.log", log:OVERWRITE);
    io:println("Starting the service_request api tests");
}

@test:Config { groups: ["service_request_api"] }
function test_get_service_request_with_valid_id() {
    string service_requestId = "1";
    http:Response response = checkpanic testClient4->get("/fhir/r4/ServiceRequest/" + service_requestId);
    test:assertEquals(response.statusCode, 200);
    string contentType = checkpanic response.getHeader("Content-Type");
    test:assertEquals(contentType , "application/fhir+json");
    json result = checkpanic response.getJsonPayload();
    test:assertEquals(result.resourceType , "service_request");
}

@test:Config { groups: ["service_request_api"]}
function test_get_service_request_with_invalid_id() {
    string service_requestId = "1";
    log:printInfo("Test with InValid Id");
    http:Response response = checkpanic testClient4->get("/fhir/r4/ServiceRequest/" + service_requestId);
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid Id");
    test:assertEquals(getLogMessage , "Error occurred while retrieving the response from Epic");
}

@test:Config { groups: ["service_request_api"]}
function test_get_service_request_with_invalid_fhir_response() {
    string service_requestId = "1";
    log:printInfo("Test with InValid fhir response");
    http:Response response = checkpanic testClient4->get("/fhir/r4/ServiceRequest/" + service_requestId);
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir response");
    test:assertEquals(getLogMessage , "Error occurred while parsing the response");
}

@test:Config { groups: ["service_request_api"]}
function test_get_service_request_with_valid_params() {
    http:Response response = checkpanic testClient4->get("/fhir/r4/ServiceRequest/?status=active" );
    test:assertEquals(response.statusCode, 200);
    string contentType = checkpanic response.getHeader("Content-Type");
    test:assertEquals(contentType , "application/fhir+json");
}

@test:Config { groups: ["service_request_api"]}
function test_get_service_request_with_invalid_params() {
    log:printInfo("Test with InValid service_request parameters");
    http:Response response = checkpanic testClient4->get("/fhir/r4/ServiceRequest/?status=something" );
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid service_request parameters");
    test:assertEquals(getLogMessage , "Error occurred while retrieving the response from Epic.");
}

@test:Config { groups: ["service_request_api"] }
function test_post_valid_service_request() {
    international401:ServiceRequest payload = {
        "resourceType": "ServiceRequest",
        "subject": {
            "reference": "Patient/example"
        },
        "intent": "proposal",
        "status": "active"
    };
    http:Response response = checkpanic testClient4->post("/fhir/r4/ServiceRequest", payload, { "Content-Type": "application/fhir+json" });
    test:assertEquals(response.statusCode, 201);
}

@test:Config { groups: ["service_request_api"] }
function test_post_invalid_service_request() {
    international401:ServiceRequest payload = {
        "resourceType": "ServiceRequest",
        "subject": {
            "reference": "Patient/example"
        },
        "intent": "proposal",
        "status": "active"
    };
    log:printInfo("Test with InValid fhir service_request");
    http:Response response = checkpanic testClient4->post("/fhir/r4/ServiceRequest", payload, { "Content-Type": "application/fhir+json" });
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir service_request");
    test:assertEquals(getLogMessage , "Error occurred while retrieving the response from Epic.");
}

@test:Config { groups: ["service_request_api"] }
function test_post_invalid_fhir_response_service_request() {
    international401:ServiceRequest payload = {
        "resourceType": "ServiceRequest",
        "subject": {
            "reference": "Patient/example"
        },
        "intent": "proposal",
        "status": "active"
    };
    log:printInfo("Test with InValid fhir response post service_request");
    http:Response response = checkpanic testClient4->post("/fhir/r4/ServiceRequest", payload, { "mediaType": "application/fhir+json" });
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid fhir response post service_request");
    test:assertEquals(getLogMessage , "Error occurred while parsing the response");
}

@test:Config { groups: ["service_request_api"]}
function test_service_request_with_invalid_method_put() {
    international401:ServiceRequest payload = {
        "resourceType": "ServiceRequest",
        "subject": {
            "reference": "Patient/example"
        },
        "intent": "proposal",
        "status": "active"
    };
    string service_requestId = "1";
    log:printInfo("Test with InValid method - put service_request");
    http:Response response = checkpanic testClient4->put("/fhir/r4/ServiceRequest/" + service_requestId, payload, { "Content-Type": "application/fhir+json" });
    test:assertEquals(response.statusCode, 500);
    string getLogMessage = get_log_message("Test with InValid method - put service_request");
    test:assertEquals(getLogMessage , "Unsupported interaction type.");
}

@test:AfterGroups { value:["service_request_api"] }
function after_service_request_api_test() {
    io:println("Completed the service_request api tests");
}
