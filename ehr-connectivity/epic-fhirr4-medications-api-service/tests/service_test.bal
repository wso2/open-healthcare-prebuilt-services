import ballerina/http;
import ballerina/test;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.uscore501 as uscore;
import ballerinax/health.clients.fhir;

http:Client clientEndpoint9090 = check new ("http://localhost:9090");
http:Client clientEndpoint9091 = check new ("http://localhost:9091");
http:Client clientEndpoint9092 = check new ("http://localhost:9092");
http:Client clientEndpoint9093 = check new ("http://localhost:9093");

@test:BeforeSuite
function testEpicConnection(){
    fhir:FHIRConnector|error fhirConnectorObjtest = new(epicConfig);
    if (fhirConnectorObjtest is error) {
        test:assertFail("Connection failed");
    }
}

//Tests for Medication
@test:Config {}
function testGetMedication() returns error? {
    http:Response response = check clientEndpoint9090->get("/fhir/r4/Medication/123");
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }
    Medication|error medication = payload.cloneWithType();
    if medication is error {
        test:assertFail("Error while mapping response payload to Medication");
    }
}

@test:Config {}
function testGetMedicationWithoutId() returns error? {
    http:Response response = check clientEndpoint9090->get("/fhir/r4/Medication");
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }

    r4:Bundle|error bundle = payload.cloneWithType();
    if bundle is error {
        test:assertFail("Error while mapping response payload to R4 Bundle");
    }
}

@test:Config {}
function testPostMedication() returns error? {
    Medication medicationData = {
        code: {}
    };
    http:Response response = check clientEndpoint9090->post("/fhir/r4/Medication", medicationData, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }
    Medication|error medication = payload.cloneWithType();
    if medication is error {
        test:assertFail("Error while mapping response payload to Medication");
    }
}

//Tests for Immunization
@test:Config {}
function testGetImmunization() returns error? {
    http:Response response = check clientEndpoint9091->get("/fhir/r4/Immunication/1234");
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }
    Immunization|error immunication = payload.cloneWithType();
    if immunication is error {
        test:assertFail("Error while mapping response payload to Immunization");
    }
}

@test:Config {}
function testGetImmunizationWithoutId() returns error? {
    http:Response response = check clientEndpoint9091->get("/fhir/r4/Immunization");
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }

    r4:Bundle|error bundle = payload.cloneWithType();
    if bundle is error {
        test:assertFail("Error while mapping response payload to R4 Bundle");
    }
}

@test:Config {}

function testPostImmunization() returns error? {
    uscore:USCoreImmunizationProfile immunizationData = {
        primarySource: false,
        patient: {},
        occurrenceDateTime: "",
        occurrenceString: "",
        vaccineCode: {},
        status: "not-done"
    };
    http:Response response = check clientEndpoint9091->post("/fhir/r4/Immunization", immunizationData, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }
    Immunization|error immunication = payload.cloneWithType();
    if immunication is error {
        test:assertFail("Error while mapping response payload to Immunization");
    }
}

//Tests for MedicationRequest
@test:Config {}
function testGetMedicationRequest() returns error? {
    http:Response response = check clientEndpoint9092->get("/fhir/r4/MedicationRequest/123");
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }
    MedicationRequest|error medicationRequest = payload.cloneWithType();
    if medicationRequest is error {
        test:assertFail("Error while mapping response payload to MedicationRequest");
    }
}

@test:Config {}
function testGetMedicationRequestWithoutId() returns error? {
    http:Response response = check clientEndpoint9092->get("/fhir/r4/MedicationRequest");
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }

    r4:Bundle|error bundle = payload.cloneWithType();
    if bundle is error {
        test:assertFail("Error while mapping response payload to R4 Bundle");
    }
}

@test:Config {}
function testPostMedicationRequest() returns error? {
    uscore:USCoreMedicationRequestProfile medicationRequestData = {
        requester: {},
        medicationReference: {},
        subject: {},
        medicationCodeableConcept: {},
        intent: "option",
        status: "unknown"
    };
    http:Response response = check clientEndpoint9092->post("/fhir/r4/MedicationRequest", medicationRequestData, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }
    MedicationRequest|error medicationRequest = payload.cloneWithType();
    if medicationRequest is error {
        test:assertFail("Error while mapping response payload to MedicationRequest");
    }
}

//Tests for MedicationStatement
@test:Config {}
function testGetMedicationStatement() returns error? {
    http:Response response = check clientEndpoint9093->get("/fhir/r4/MedicationStatement/123");
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }
    MedicationStatement|error medicationStatement = payload.cloneWithType();
    if medicationStatement is error {
        test:assertFail("Error while mapping response payload to MedicationStatement");
    }
}

@test:Config {}
function testGetMedicationStatementWithoutId() returns error? {
    http:Response response = check clientEndpoint9093->get("/fhir/r4/MedicationStatement");
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }

    r4:Bundle|error bundle = payload.cloneWithType();
    if bundle is error {
        test:assertFail("Error while mapping response payload to R4 Bundle");
    }
}

@test:Config {}
function testPostMedicationStatement() returns error? {
    MedicationStatement medicationStatementData = {
        medicationReference: {},
        subject: {},
        medicationCodeableConcept: {},
        status: "unknown"
    };
    http:Response response = check clientEndpoint9093->post("/fhir/r4/MedicationStatement", medicationStatementData, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }
    MedicationStatement|error medicationStatement = payload.cloneWithType();
    if medicationStatement is error {
        test:assertFail("Error while mapping response payload to MedicationStatement");
    }
}
