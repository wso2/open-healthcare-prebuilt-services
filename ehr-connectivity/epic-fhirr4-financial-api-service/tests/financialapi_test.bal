import ballerina/test;
import ballerina/http;
import ballerinax/health.fhir.r4;

http:Client clientEndpoint9090 = check new ("http://localhost:9090");
http:Client clientEndpoint9092 = check new ("http://localhost:9092");
http:Client clientEndpoint9102 = check new ("http://localhost:9102");


@test:Config {}
function accountAPIvalidId_test() returns error? {
    http:Response response = check clientEndpoint9090->get("/fhir/r4/Account/eaQa1KcZVdi2T9YYsfu6tFw3");
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }

    Account|error account = payload.cloneWithType();
    if account is error {
        test:assertFail("Error while getting the Account resource.");
    }
}

@test:Config {}
function accountAPIInvalidId_test() returns error? {
    http:Response response = check clientEndpoint9090->get("/fhir/r4/Account/invalid");
    test:assertEquals(response.statusCode, 404, "Status code should be 404");

}

@test:Config {}
function accountAPISearch_test() returns error? {
    http:Response response = check clientEndpoint9090->get("/fhir/r4/Account?_id= eAYf7QIMQBmXU-2KXgT9UcQ3");
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
function accountAPIPost_test() returns error? {
    Account accountData = {
        status: "active",
        name: "John Doe"
    };
    http:Response response = check clientEndpoint9090->post("/fhir/r4/Account", accountData, {"Content-Type": "application/fhir+json"});
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }
    Account|error account = payload.cloneWithType();
    if account is error {
        test:assertFail("Error while mapping response payload to Account");
    }
}

//FHIR Resource - Coverage
@test:Config {}
function coverageAPIvalidId_test() returns error? {
    http:Response response = check clientEndpoint9092->get("/fhir/r4/Coverage/eS72vnDj387lBv1vJqjUKhGFkkNw3RVMhZzABgnZ0kwk3");
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }

    Coverage|error coverage = payload.cloneWithType();
    if coverage is error {
        test:assertFail("Error while getting the Coverage resource.");
    }
}

@test:Config {}
function coverageAPISearch_test() returns error? {
    http:Response response = check clientEndpoint9092->get("/fhir/r4/Coverage?beneficiary=Patient/e63wRTbPfr1p8UW81d8Seiw3");
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

// EOB API
@test:Config {}
function eobAPIvalidId_test() returns error? {
    http:Response response = check clientEndpoint9102->get("/fhir/r4/ExplanationOfBenefit/eW3fiTdz5NQ07OSglGVVHZQ3");
    test:assertEquals(response.statusCode, 200, "Status code should be 200");

    json|error payload = response.getJsonPayload();
    if payload is error {
        test:assertFail("Error while parsing response payload");
    }

    ExplanationOfBenefit|error eob = payload.cloneWithType();
    if eob is error {
        test:assertFail("Error while getting the Account resource.");
    }
}

@test:Config {}
function eobAPISearch_test() returns error? {
    http:Response response = check clientEndpoint9102->get("/fhir/r4/ExplanationOfBenefit?patient=e7WJINuEm7c1-TcyVd4GoPg3");
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
