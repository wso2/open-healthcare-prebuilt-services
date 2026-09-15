// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
import terminology_service.store_h2;

import ballerina/http;
import ballerina/lang.runtime;
import ballerina/persist;
import ballerina/sql;
import ballerina/test;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.terminology;

http:Client baseClient = check new ("http://localhost:9089/fhir/r4");
http:Client csClient = check new ("http://localhost:9089/fhir/r4/CodeSystem");
http:Client vsClient = check new ("http://localhost:9089/fhir/r4/ValueSet");

@test:BeforeSuite
isolated function beforeSuite() returns error? {
    check store_h2:setupTestDB();
    check store_h2:setupNativeSqlTestTables();
    check addExampleDataToTestDB();
}

@test:AfterSuite
function afterSuite() returns error? {
    check store_h2:cleanupNativeSqlTestTables();
    check store_h2:cleanupTestDB();
}

@test:Mock {functionName: "initializeClient"}
isolated function getMockClient() returns store_h2:Client|error {
    return test:mock(store_h2:Client, check new store_h2:H2Client("jdbc:h2:./tests/test", "sa", ""));
}

@test:Config {
    groups: ["codesystem", "get_by_id_codesystem", "successful_scenario"]
}
public function getByIdCodeSystem1() returns error? {
    http:Response response = check csClient->get("/account-status");

    r4:CodeSystem expected = check returnCodeSystemData("account-status").cloneWithType(r4:CodeSystem);
    expected.concept = ();
    test:assertEquals(response.getJsonPayload(), expected.toJson());
}

@test:Config {
    groups: ["codesystem", "get_by_id_codesystem", "successful_scenario"]
}
public function getByIdCodeSystem2() returns error? {
    http:Response response = check csClient->get("/account-status|4.0.1");

    r4:CodeSystem expected = check returnCodeSystemData("account-status").cloneWithType(r4:CodeSystem);
    expected.concept = ();
    test:assertEquals(response.getJsonPayload(), expected.toJson());
}

@test:Config {
    groups: ["codesystem", "get_by_id_codesystem", "failure_scenario"]
}
public function getByIdCodeSystem3() returns error? {
    http:Response response = check csClient->get("/loinc");
    test:assertEquals(response.statusCode, 404);
}

@test:Config {
    groups: ["codesystem", "get_by_id_codesystem", "successful_scenario"]
}
public function searchCodeSystem1() returns error? {
    http:Response response = check csClient->get("?url=http://hl7.org/fhir/account-status");

    json actualJson = check response.getJsonPayload();
    r4:Bundle actual = check actualJson.cloneWithType(r4:Bundle);

    r4:Bundle expected = check returnCodeSystemData("empty-bundle").cloneWithType(r4:Bundle);
    r4:CodeSystem codeSystem = check returnCodeSystemData("account-status").cloneWithType(r4:CodeSystem);
    codeSystem.concept = ();
    r4:BundleEntry entry = {
        'resource: codeSystem,
        search: {mode: "match"}
    };
    expected.entry = [entry];
    expected.total = 1;
    expected.meta.lastUpdated = actual.meta.lastUpdated;

    test:assertEquals(actual.toJson(), expected.toJson());
}

@test:Config {
    groups: ["codesystem", "get_by_id_codesystem", "successful_scenario"]
}
public function searchCodeSystem2() returns error? {
    http:Response response = check csClient->get("?url=http://hl7.org/fhir/account-status&version=4.0.1&title=AccountStatus&status=draft&name=AccountStatus&publisher=HL7%20%28FHIR%20Project%29");

    json actualJson = check response.getJsonPayload();
    r4:Bundle actual = check actualJson.cloneWithType(r4:Bundle);

    r4:Bundle expected = check returnCodeSystemData("empty-bundle").cloneWithType(r4:Bundle);
    r4:CodeSystem codeSystem = check returnCodeSystemData("account-status").cloneWithType(r4:CodeSystem);
    codeSystem.concept = ();
    r4:BundleEntry entry = {
        'resource: codeSystem,
        search: {mode: "match"}
    };
    expected.entry = [entry];
    expected.total = 1;
    expected.meta.lastUpdated = actual.meta.lastUpdated;

    test:assertEquals(actual.toJson(), expected.toJson());
}

@test:Config {
    groups: ["codesystem", "get_by_id_codesystem", "failure_scenario"]
}
public function searchCodeSystem3() returns error? {
    http:Response response = check csClient->get("?url=www.loinc.org");
    json actualJson = check response.getJsonPayload();
    r4:Bundle actual = check actualJson.cloneWithType(r4:Bundle);

    r4:Bundle expected = check returnCodeSystemData("empty-bundle").cloneWithType(r4:Bundle);
    expected.meta.lastUpdated = actual.meta.lastUpdated;

    test:assertEquals(actual.toJson(), expected.toJson());
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "successful_scenario"]
}
public function lookupCodeSystem1() returns error? {
    http:Response response = check csClient->get("/$lookup?system=http://hl7.org/fhir/account-status&code=inactive");
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("account-status-inactive");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "successful_scenario"]
}
public function lookupCodeSystem3() returns error? {
    r4:Coding|r4:FHIRError coding = terminology:createCoding("http://hl7.org/fhir/account-status", "inactive", terminology = terminology_source);
    r4:Parameters p = {'parameter: [{name: "coding", valueCoding: check coding}]};
    http:Response response = check csClient->post("/$lookup", p, {"Content-Type": FHIR_JSON});
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("account-status-inactive");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "failure_scenario"]
}
public function lookupCodeSystem4() returns error? {
    http:Response response = check csClient->post("/$lookup", (), {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid request payload");
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "failure_scenario"]
}
public function lookupCodeSystem5() returns error? {
    http:Response response = check csClient->get("/$lookup?code=inactive", ());
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedjson = returnCodeSystemData("lookup-error");
    r4:OperationOutcome expected = check expectedjson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "failure_scenario"]
}
public function lookupCodeSystem6() returns error? {
    json codingJson = returnCodeSystemData("invalid-json-payload");
    http:Response response = check csClient->post("/$lookup", codingJson, {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedjson = returnCodeSystemData("lookup-error2");
    r4:OperationOutcome expected = check expectedjson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "failure_scenario"]
}
public function lookupCodeSystem7() returns error? {
    http:Response response = check csClient->post("/$lookup", (), {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid request payload");
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "failure_scenario"]
}
public function lookupCodeSystem8() returns error? {
    http:Response response = check csClient->post("/$lookup", {}, {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text,
            "Invalid operation payload due to Payload must be a valid FHIR Parameters or Bundle resource.");
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "failure_scenario"]
}
public function lookupCodeSystem9() returns error? {
    // $lookup now tolerates unrecognised parameters (lenientOperationPreProcessor,
    // conformance_shim.bal) rather than rejecting them outright - "sample" is
    // simply ignored, and the request fails instead because no coding/system+code
    // was actually provided.
    r4:Parameters parameters = {'parameter: [{name: "sample"}]};
    http:Response response = check csClient->post("/$lookup", parameters, {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text,
            "Can not find a CodeSystem due to Provide either a 'coding' parameter or 'system' and 'code' parameters");
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "failure_scenario"]
}
public function lookupCodeSystem10() returns error? {
    r4:Coding coding = check terminology:createCoding("http://hl7.org/fhir/account-status", "inactive", terminology = terminology_source);
    coding.system = ();
    r4:Parameters parameters = {'parameter: [{name: "coding", valueCoding: coding}]};
    http:Response response = check csClient->post("/$lookup", parameters, {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text,
            "Can not find a CodeSystem due to Provide either a 'coding' parameter or 'system' and 'code' parameters");
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "successful_scenario"]
}
public function validateCodeCodeSystem1() returns error? {
    http:Response response = check csClient->get("/$validate-code?url=http://hl7.org/fhir/account-status&code=inactive", ());
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("validate-code");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "successful_scenario"]
}
public function validateCodeCodeSystem2() returns error? {
    http:Response response = check csClient->get("/account-status/$validate-code?code=inactive", ());
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("validate-code");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "successful_scenario"]
}
public function validateCodeCodeSystem3() returns error? {
    r4:Coding|r4:FHIRError coding = terminology:createCoding("http://hl7.org/fhir/account-status", "inactive", terminology = terminology_source);
    r4:Parameters p = {'parameter: [{name: "coding", valueCoding: check coding}]};
    http:Response response = check csClient->post("/$validate-code", p, {"Content-Type": FHIR_JSON});
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("validate-code");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "successful_scenario"]
}
public function validateCodeCodeSystem4() returns error? {
    r4:ParametersParameter urlParam = {name: "url", valueUri: "http://hl7.org/fhir/account-status"};
    r4:ParametersParameter codeParam = {name: "code", valueCode: "inactive"};
    r4:Parameters p = {'parameter: [urlParam, codeParam]};
    http:Response response = check csClient->post("/$validate-code", p, {"Content-Type": FHIR_JSON});
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("validate-code");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "successful_scenario"]
}
public function validateCodeCodeSystem5() returns error? {
    json requestPayload = returnCodeSystemData("codeableconcept-inline-codesystem");
    http:Response response = check csClient->post("/$validate-code", requestPayload, {"Content-Type": FHIR_JSON});
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("validate-code-inline");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "successful_scenario"]
}
public function validateCodeCodeSystem6() returns error? {
    r4:ParametersParameter urlParam = {name: "url", valueUri: "http://hl7.org/fhir/account-status"};
    r4:ParametersParameter codeParam = {name: "code", valueCode: "inactive"};
    r4:ParametersParameter displayParam = {name: "display", valueString: "Inactive"};
    r4:Parameters p = {'parameter: [urlParam, codeParam, displayParam]};
    http:Response response = check csClient->post("/$validate-code", p, {"Content-Type": FHIR_JSON});
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("validate-code");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "successful_scenario"]
}
public function validateCodeCodeSystem7() returns error? {
    r4:ParametersParameter urlParam = {name: "url", valueUri: "http://hl7.org/fhir/account-status"};
    r4:ParametersParameter codeParam = {name: "code", valueCode: "inactive"};
    r4:ParametersParameter displayParam = {name: "display", valueString: "Not The Right Display"};
    r4:Parameters p = {'parameter: [urlParam, codeParam, displayParam]};
    http:Response response = check csClient->post("/$validate-code", p, {"Content-Type": FHIR_JSON});
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("validate-code-display-mismatch");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "failure_scenario"]
}
public function validateCodeCodeSystem8() returns error? {
    http:Response response = check csClient->post("/$validate-code", (), {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid request payload");
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "failure_scenario"]
}
public function validateCodeCodeSystem9() returns error? {
    http:Response response = check csClient->post("/$validate-code", {}, {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text,
            "Invalid operation payload due to Payload must be a valid FHIR Parameters or Bundle resource.");
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "failure_scenario"]
}
public function validateCodeCodeSystem10() returns error? {
    r4:ParametersParameter urlParam = {name: "url", valueUri: "http://hl7.org/fhir/account-status"};
    r4:Parameters p = {'parameter: [urlParam]};
    http:Response response = check csClient->post("/$validate-code", p, {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text,
            "Can not find a valid code to validate due to Provide (coding|codeableConcept) or (code), and (codeSystem resource) or (url).");
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "failure_scenario"]
}
public function validateCodeCodeSystem11() returns error? {
    r4:ParametersParameter codeParam = {name: "code", valueCode: "inactive"};
    r4:Parameters p = {'parameter: [codeParam]};
    http:Response response = check csClient->post("/$validate-code", p, {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text,
            "Can not find a CodeSystem due to Provide either a 'codeSystem' resource or a 'url' parameter");
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "failure_scenario"]
}
public function validateCodeCodeSystem12() returns error? {
    http:Response response = check csClient->get("/$validate-code?url=http://hl7.org/fhir/account-status", ());
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Can not find a CodeSystem, Code value is missing");
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "successful_scenario"]
}
public function validateCodeCodeSystem13() returns error? {
    // A code that doesn't exist in an otherwise-resolved CodeSystem must
    // convert to a result:false Parameters response, not an error.
    http:Response response = check csClient->get("/$validate-code?url=http://hl7.org/fhir/account-status&code=does-not-exist", ());
    test:assertEquals(response.statusCode, 200);
    json actualJson = check response.getJsonPayload();
    r4:Parameters actual = check actualJson.cloneWithType(r4:Parameters);
    test:assertEquals((<r4:ParametersParameter>findParam(actual, "result")).valueBoolean, false);
}

@test:Config {
    groups: ["codesystem", "validate_code_codesystem", "failure_scenario"]
}
public function validateCodeCodeSystem14() returns error? {
    // A url that doesn't resolve to any known CodeSystem must fail with an
    // error, not a result:false Parameters response.
    http:Response response = check csClient->get("/$validate-code?url=http://hl7.org/fhir/does-not-exist&code=inactive", ());
    test:assertEquals(response.statusCode, 404);
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals(actual.resourceType, "OperationOutcome");
}

@test:Config {
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem1() returns error? {
    http:Response response = check csClient->get("/$subsumes?codeA=Type&codeB=Any&system=http://hl7.org/fhir/abstract-types", ());
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("subsume-notequal");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem2() returns error? {
    http:Response response = check csClient->get("/$subsumes?codeA=Type&codeB=Type&system=http://hl7.org/fhir/abstract-types", ());
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("subsume-equal");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem3() returns error? {

    r4:Coding codingA = check terminology:createCoding("http://hl7.org/fhir/account-status", "inactive", terminology = terminology_source);
    r4:Coding codingB = check terminology:createCoding("http://hl7.org/fhir/account-status", "inactive", terminology = terminology_source);

    r4:ParametersParameter cA = {name: "codingA", valueCoding: codingA};
    r4:ParametersParameter cB = {name: "codingB", valueCoding: codingB};
    r4:ParametersParameter system = {name: "system", valueUri: "http://hl7.org/fhir/account-status"};
    r4:Parameters requestPayload = {'parameter: [cA, cB, system]};

    http:Response response = check csClient->post("/$subsumes", requestPayload, {"Content-Type": FHIR_JSON});
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("subsume-equal");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "subsume_codesystem", "failure_scenario"]
}
public function subsumeCodeSystem5() returns error? {

    http:Response response = check csClient->get("/$subsumes?codeA=Type&codeB=Type", ());
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedjson = returnCodeSystemData("subsume-error");
    r4:OperationOutcome expected = check expectedjson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "subsume_codesystem", "failure_scenario"]
}
public function subsumeCodeSystem6() returns error? {

    json requestJson = returnCodeSystemData("invalid-json-payload");
    http:Response response = check csClient->post("/$subsumes", requestJson, {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedjson = returnCodeSystemData("subsume-error2");
    r4:OperationOutcome expected = check expectedjson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "subsume_codesystem", "failure_scenario"]
}
public function subsumeCodeSystem7() returns error? {
    http:Response response = check csClient->post("/$subsumes", (), {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid request payload");
}

@test:Config {
    dependsOn: [testAddValidCodeSystemJson],
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem8() returns error? {
    http:Response response = check csClient->get("/$subsumes?codeA=2133-7&codeB=2135-2&system=urn:oid:2.16.840.1.113883.6.238");
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("subsumed");
    test:assertEquals(actual, expected);
}

@test:Config {
    dependsOn: [testAddValidCodeSystemJson],
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem9() returns error? {
    http:Response response = check csClient->get("/$subsumes?codeA=2186-5&codeB=2133-7&system=urn:oid:2.16.840.1.113883.6.238");
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("subsumed-by");
    test:assertEquals(actual, expected);
}

@test:Config {
    dependsOn: [testAddValidCodeSystemJson],
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem10() returns error? {
    http:Response response = check csClient->get("/$subsumes?codeA=2155-0&codeB=2133-7&system=urn:oid:2.16.840.1.113883.6.238");
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("subsumed-by");
    test:assertEquals(actual, expected);
}

@test:Config {
    dependsOn: [testAddValidCodeSystemJson],
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem11() returns error? {
    http:Response response = check csClient->get("/$subsumes?codeA=2155-0&codeB=1000-9&system=urn:oid:2.16.840.1.113883.6.238");
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("subsume-notequal");
    test:assertEquals(actual, expected);
}

@test:Config {
    dependsOn: [testAddValidCodeSystemJson],
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem12() returns error? {
    r4:Coding codingA = {system: "urn:oid:2.16.840.1.113883.6.238", code: "1000-9"};
    r4:Coding codingB = {system: "urn:oid:2.16.840.1.113883.6.238", code: "1002-5"};

    r4:ParametersParameter cA = {name: "codingA", valueCoding: codingA};
    r4:ParametersParameter cB = {name: "codingB", valueCoding: codingB};
    r4:ParametersParameter system = {name: "system", valueUri: "urn:oid:2.16.840.1.113883.6.238"};
    r4:Parameters requestPayload = {'parameter: [cA, cB, system]};

    http:Response response2 = check csClient->post("/$subsumes", requestPayload, {"Content-Type": FHIR_JSON});
    json actual = check response2.getJsonPayload();

    json expected = returnCodeSystemData("subsumed");
    test:assertEquals(actual, expected);
}

// ===========================Value set======================================

@test:Config {
    groups: ["valueSet", "get_by_id_valueSet", "successful_scenario"]
}
public function getByIdValueSet1() returns error? {
    http:Response response = check vsClient->get("/account-status");

    json expected = returnValueSetData("account-status");
    test:assertEquals(response.getJsonPayload(), expected);
}

@test:Config {
    groups: ["valueSet", "get_by_id_valueSet", "successful_scenario"]
}
public function getByIdValueSet2() returns error? {
    http:Response response = check vsClient->get("/account-status|4.0.1");

    json expected = returnValueSetData("account-status");
    test:assertEquals(response.getJsonPayload(), expected);
}

@test:Config {
    groups: ["valueSet", "get_by_id_valueSet", "failure_scenario"]
}
public function getByIdValueSet3() returns error? {
    http:Response response = check vsClient->get("/all-loinc");
    test:assertEquals(response.statusCode, 404);
}

@test:Config {
    groups: ["valueset", "search_valueset", "successful_scenario"]
}
public function searchValueSet1() returns error? {
    http:Response response = check vsClient->get("?url=http://hl7.org/fhir/ValueSet/abstract-types");
    json actualJson = check response.getJsonPayload();
    r4:Bundle actual = check actualJson.cloneWithType(r4:Bundle);

    r4:Bundle expected = check returnValueSetData("account-status-bundle").cloneWithType(r4:Bundle);
    expected.meta.lastUpdated = actual.meta.lastUpdated;
    test:assertEquals(response.getJsonPayload(), expected.toJson());
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "successful_scenario"]
}
public function validateCodeValueSet1() returns error? {
    http:Response response = check vsClient->get("/$validate-code?system=http://hl7.org/fhir/ValueSet/account-status&code=inactive", ());
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "successful_scenario"]
}
public function validateCodeValueSet2() returns error? {
    json requestPayload = returnValueSetData("account-status-as-parameter2");
    http:Response response = check vsClient->post("/$validate-code", requestPayload, {"Content-Type": FHIR_JSON});
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "successful_scenario"]
}
public function validateCodeValueSet3() returns error? {
    http:Response response = check vsClient->get("/account-status/$validate-code?code=inactive", ());
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "successful_scenario"]
}
public function validateCodeValueSet4() returns error? {
    json requestPayload = returnValueSetData("account-status-as-parameter2");
    http:Response response = check vsClient->post("/$validate-code", requestPayload, {"Content-Type": FHIR_JSON});
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "successful_scenario"]
}
public function validateCodeValueSet5() returns error? {
    json requestPayload = returnValueSetData("account-status-as-parameter2");

    http:Response response = check vsClient->post("/$validate-code", requestPayload, {"Content-Type": FHIR_JSON});
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "failure_scenario"]
}
public function validateCodeValueSet6() returns error? {
    http:Response response = check vsClient->post("/$validate-code", (), {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid request payload");
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "failure_scenario"]
}
public function validateCodeValueSet7() returns error? {
    http:Response response = check vsClient->post("/$validate-code", {}, {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text,
            "Invalid operation payload due to Payload must be a valid FHIR Parameters or Bundle resource.");
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "failure_scenario"]
}
public function validateCodeValueSet8() returns error? {
    json requestPayload = returnValueSetData("coding-as-parameter");
    http:Response response = check vsClient->post("/$validate-code", requestPayload, {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text,
            "Invalid request payload due to Provide (coding|codeableConcept) or (system+code), and (valueSet resource) or (url).");
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "failure_scenario"]
}
public function validateCodeValueSet9() returns error? {
    http:Response response = check vsClient->get("/$validate-code");
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Can not find a ValueSet, Code value is missing");
}

@test:Config {
    dependsOn: [testAddValidValueSet2],
    groups: ["valueset", "validate_code_valueset", "successful_scenario"]
}
public function validateCodeValueSet10() returns error? {
    http:Response response = check vsClient->get("/example-valueset-include-valueset/$validate-code?code=inactive", ());
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    dependsOn: [testAddValidValueSet4],
    groups: ["valueset", "validate_code_valueset", "successful_scenario"]
}
public function validateCodeValueSet11() returns error? {
    http:Response response = check vsClient->get("/example-valueset-include-concepts/$validate-code?code=inactive", ());
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    check assertParametersJsonEqual(actual, expected);
}

@test:Config {
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandValueSet1() returns error? {
    http:Response response = check vsClient->get("/$expand?url=http://hl7.org/fhir/ValueSet/account-status", ());
    json actualJson = check response.getJsonPayload();
    r4:ValueSet actual = check actualJson.cloneWithType(r4:ValueSet);

    json expectedJson = returnValueSetData("expanded-account-status");
    r4:ValueSet expected = check expectedJson.cloneWithType(r4:ValueSet);

    expected.expansion.timestamp = (<r4:ValueSetExpansion>actual.expansion).timestamp;
    test:assertTrue(assertValueSetExpansionsEqual(expected.expansion, actual.expansion), "ValueSet expansions are not equal");
}

@test:Config {
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandValueSet2() returns error? {
    http:Response response = check vsClient->get("/account-status/$expand", ());
    json actualJson = check response.getJsonPayload();
    r4:ValueSet actual = check actualJson.cloneWithType(r4:ValueSet);

    json expectedJson = returnValueSetData("expanded-account-status");
    r4:ValueSet expected = check expectedJson.cloneWithType(r4:ValueSet);

    expected.expansion.timestamp = (<r4:ValueSetExpansion>actual.expansion).timestamp;
    test:assertTrue(assertValueSetExpansionsEqual(expected.expansion, actual.expansion), "ValueSet expansions are not equal");
}

@test:Config {
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandValueSet3() returns error? {
    json requestPayload = returnValueSetData("account-status-as-parameter");
    http:Response response = check vsClient->post("/$expand", requestPayload, {"Content-Type": FHIR_JSON});

    json actualJson = check response.getJsonPayload();
    r4:ValueSet actual = check actualJson.cloneWithType(r4:ValueSet);

    json expectedJson = returnValueSetData("expanded-account-status");
    r4:ValueSet expected = check expectedJson.cloneWithType(r4:ValueSet);

    expected.expansion.timestamp = (<r4:ValueSetExpansion>actual.expansion).timestamp;
    test:assertTrue(assertValueSetExpansionsEqual(expected.expansion, actual.expansion), "ValueSet expansions are not equal");
}

@test:Config {
    groups: ["valueset", "expand_valueset", "failure_scenario"]
}
public function expandValueSet4() returns error? {
    http:Response response = check vsClient->post("/$expand", (), {"Content-Type": FHIR_JSON});

    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedJson = returnValueSetData("expand-error");
    r4:OperationOutcome expected = check expectedJson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["valueset", "expand_valueset", "failure_scenario"]
}
public function expandValueSet5() returns error? {
    http:Response response = check vsClient->post("/$expand", {}, {"Content-Type": FHIR_JSON});

    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text,
            "Invalid operation payload due to Payload must be a valid FHIR Parameters or Bundle resource.");
}

@test:Config {
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandValueSet6() returns error? {
    http:Response response = check vsClient->get("/$expand?url=http://hl7.org/fhir/ValueSet/account-status&filter=active", ());
    json actualJson = check response.getJsonPayload();
    r4:ValueSet actual = check actualJson.cloneWithType(r4:ValueSet);

    json expectedJson = returnValueSetData("expanded-account-status-active-filter");
    r4:ValueSet expected = check expectedJson.cloneWithType(r4:ValueSet);

    expected.expansion.timestamp = (<r4:ValueSetExpansion>actual.expansion).timestamp;
    test:assertTrue(assertValueSetExpansionsEqual(expected.expansion, actual.expansion), "ValueSet expansions are not equal");
}

@test:Config {
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandValueSet7() returns error? {
    http:Response response = check vsClient->get("/account-status/$expand?filter=active", ());
    json actualJson = check response.getJsonPayload();
    r4:ValueSet actual = check actualJson.cloneWithType(r4:ValueSet);

    json expectedJson = returnValueSetData("expanded-account-status-active-filter");
    r4:ValueSet expected = check expectedJson.cloneWithType(r4:ValueSet);

    expected.expansion.timestamp = (<r4:ValueSetExpansion>actual.expansion).timestamp;
    test:assertTrue(assertValueSetExpansionsEqual(expected.expansion, actual.expansion), "ValueSet expansions are not equal");
}

@test:Config {
    dependsOn: [testAddValidValueSet5],
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandValueSet8() returns error? {
    http:Response response = check vsClient->get("/$expand?url=http://hl7.org/fhir/ValueSet/account-and-resource-status&filter=active", ());
    json actualJson = check response.getJsonPayload();
    r4:ValueSet actual = check actualJson.cloneWithType(r4:ValueSet);

    json expectedJson = returnValueSetData("expand-account-and-resource-status");
    r4:ValueSet expected = check expectedJson.cloneWithType(r4:ValueSet);

    expected.expansion.timestamp = (<r4:ValueSetExpansion>actual.expansion).timestamp;
    test:assertTrue(assertValueSetExpansionsEqual(expected.expansion, actual.expansion), "ValueSet expansions are not equal");
}

@test:Config {
    dependsOn: [testAddValidValueSet2, validateCodeValueSet11],
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandValueSet9() returns error? {
    http:Response response = check vsClient->get("/example-valueset-include-valueset/$expand", ());
    json actualJson = check response.getJsonPayload();
    r4:ValueSet actual = check actualJson.cloneWithType(r4:ValueSet);

    json expectedJson = returnValueSetData("expanded-example-valueset-include-valueset");
    r4:ValueSet expected = check expectedJson.cloneWithType(r4:ValueSet);

    expected.expansion.timestamp = (<r4:ValueSetExpansion>actual.expansion).timestamp;
    test:assertTrue(assertValueSetExpansionsEqual(expected.expansion, actual.expansion), "ValueSet expansions are not equal");
}

@test:Config {
    groups: ["valueset", "add_valueset", "successful_scenario"]
}
public function testAddValidValueSetDirectPlusNested() returns error? {
    json requestPayload = returnValueSetData("add-valid-valueset-direct-plus-nested");

    http:Response response = check vsClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});

    test:assertEquals(response.statusCode, 201);
}

// account-status is included both directly (compose.include.system) and via a
// nested ValueSet (compose.include.valueSet) that itself includes the same
// CodeSystem. $expand must de-duplicate the overlap by system+code rather
// than treating the direct and nested contributions as unrelated (which
// previously happened because nested-ValueSet entries were namespaced by the
// nested ValueSet's own id instead of by CodeSystem).
@test:Config {
    dependsOn: [testAddValidValueSetDirectPlusNested],
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandValueSetDirectPlusNestedDedup() returns error? {
    http:Response response = check vsClient->get("/$expand?url=http://example.org/fhir/ValueSet/direct-plus-nested-account-status", ());
    json actualJson = check response.getJsonPayload();
    r4:ValueSet actual = check actualJson.cloneWithType(r4:ValueSet);

    r4:ValueSetExpansion expansion = <r4:ValueSetExpansion>actual.expansion;
    r4:ValueSetExpansionContains[] contains = <r4:ValueSetExpansionContains[]>expansion.contains;

    // account-status has 5 codes (active, on-hold, entered-in-error, unknown,
    // inactive) - the direct include and the nested include both cover all of
    // them, so a correctly-deduplicated expansion has exactly 5 entries, not 10.
    test:assertEquals(expansion.total, 5, "Expected the direct and nested includes of the same CodeSystem to de-duplicate to 5 entries");
    test:assertEquals(contains.length(), 5);

    map<boolean> seenCodes = {};
    foreach r4:ValueSetExpansionContains c in contains {
        test:assertEquals(c.system, "http://hl7.org/fhir/account-status", "Expected every entry to carry the account-status system");
        string code = <string>c.code;
        test:assertFalse(seenCodes.hasKey(code), string `Duplicate code in expansion: ${code}`);
        seenCodes[code] = true;
    }
}

// A client-supplied offset should be echoed back on expansion.parameter, the
// same way count already is - lets a client confirm which page it got back.
@test:Config {
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandValueSetEchoesRequestedOffset() returns error? {
    http:Response response = check vsClient->get("/$expand?url=http://hl7.org/fhir/ValueSet/account-status&offset=1&count=2", ());
    json actualJson = check response.getJsonPayload();
    r4:ValueSet actual = check actualJson.cloneWithType(r4:ValueSet);

    r4:ValueSetExpansionParameter[] expansionParams = (<r4:ValueSetExpansion>actual.expansion).'parameter ?: [];
    r4:ValueSetExpansionParameter[] offsetParams = expansionParams.filter(p => p.name == "offset");
    test:assertEquals(offsetParams.length(), 1, "Expected exactly one 'offset' entry in expansion.parameter");
    test:assertEquals(offsetParams[0].valueInteger, 1);
}

@test:Config {
    dependsOn: [testAddValidValueSet4],
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandValueSet10() returns error? {
    http:Response response = check vsClient->get("/example-valueset-include-concepts/$expand", ());
    json actualJson = check response.getJsonPayload();
    r4:ValueSet actual = check actualJson.cloneWithType(r4:ValueSet);

    json expectedJson = returnValueSetData("expanded-example-valueset-include-concepts");
    r4:ValueSet expected = check expectedJson.cloneWithType(r4:ValueSet);

    expected.expansion.timestamp = (<r4:ValueSetExpansion>actual.expansion).timestamp;
    test:assertTrue(assertValueSetExpansionsEqual(expected.expansion, actual.expansion), "ValueSet expansions are not equal");
}

@test:Config {
    groups: ["codesystem", "concepts", "successful_scenario"]
}
public function testCodeSystemConceptPropertiesAndDesignations() returns error? {
    r4:CodeSystemConcept concept = check returnCodeSystemData("designation-input").cloneWithType(r4:CodeSystemConcept);

    r4:Parameters parameters = codesystemConceptsToParameters(concept);
    json actualJson = parameters.toJson();

    json expectedJson = returnCodeSystemData("designation-expected");
    check assertParametersJsonEqual(actualJson, expectedJson);
}

@test:Config {
    groups: ["codesystem", "concepts", "successful_scenario"]
}
public function testCodeSystemConceptsArray() returns error? {
    json jsonData = returnCodeSystemData("concepts-array-input");
    r4:CodeSystemConcept[] concepts = [];

    if jsonData is json[] {
        foreach var item in jsonData {
            r4:CodeSystemConcept concept = check item.cloneWithType(r4:CodeSystemConcept);
            concepts.push(concept);
        }
    } else {
        return error("Invalid JSON data format");
    }

    r4:Parameters parameters = codesystemConceptsToParameters(concepts);
    json actualJson = parameters.toJson();

    json expectedJson = returnCodeSystemData("concepts-array-expected");
    check assertParametersJsonEqual(actualJson, expectedJson);
}

@test:Config {
    groups: ["valueset", "batch_validate_valueset", "successful_scenario"]
}
public function testBatchValidateValueSetsValid() returns error? {
    json requestPayload = returnBatchData("valid-batch-request");
    json expectedResponse = returnBatchData("valid-batch-response");

    http:Response response = check baseClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});
    check assertBatchResponseJsonEqual(check response.getJsonPayload(), expectedResponse);
}

@test:Config {
    groups: ["valueset", "batch_validate_valueset", "failure_scenario"]
}
public function testBatchValidateValueSetsInvalidJson() returns error? {
    json requestPayload = returnBatchData("invalid-json-batch-request");
    http:Response response = check baseClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});

    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedJson = returnBatchData("invalid-json-batch-response");
    r4:OperationOutcome expected = check expectedJson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["valueset", "batch_validate_valueset", "failure_scenario"]
}
public function testBatchValidateValueSetsNotBatchType() returns error? {
    json requestPayload = returnBatchData("not-batch-type-request");
    http:Response response = check baseClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});

    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedJson = returnBatchData("not-batch-type-response");
    r4:OperationOutcome expected = check expectedJson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["valueset", "batch_validate_valueset", "failure_scenario"]
}
public function testBatchValidateValueSetsNoEntries() returns error? {
    json requestPayload = returnBatchData("no-entries-batch-request");
    http:Response response = check baseClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});

    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedJson = returnBatchData("no-entries-batch-response");
    r4:OperationOutcome expected = check expectedJson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "add_codesystem", "successful_scenario"]
}
public function testAddValidCodeSystemJson() returns error? {
    json requestPayload = returnCodeSystemData("add-valid-codesystem");

    http:Response response = check csClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});

    // check the response status code is 201 or not
    test:assertEquals(response.statusCode, 201);

    // addCodeSystem returns as soon as the CodeSystem row is inserted; concept
    // and closure-row persistence happens in separate strands it doesn't wait
    // on (see extractConceptsFromCodeSystem). Tests that depend on this one
    // (subsumeCodeSystem8-12, closurePost1, ...) need that data to actually be
    // queryable, not just "the POST returned" - so poll for one of the
    // imported concepts (2133-7) before letting dependents proceed.
    check waitForConceptSystemJsonImportReady();
}

# Polls `$lookup` for a concept from the `add-valid-codesystem` fixture until it succeeds, so tests that `dependsOn` `testAddValidCodeSystemJson` don't race its background concept/closure import.
#
# + return - An `error` if the concept still isn't queryable after the retry budget is exhausted
function waitForConceptSystemJsonImportReady() returns error? {
    int attempts = 0;
    while attempts < 100 {
        http:Response|http:ClientError response = csClient->get("/$lookup?system=urn:oid:2.16.840.1.113883.6.238&code=2133-7");
        if response is http:Response && response.statusCode == 200 {
            return;
        }
        runtime:sleep(0.05);
        attempts += 1;
    }
    test:assertFail("Timed out waiting for the add-valid-codesystem import's concepts to become queryable");
}

// FHIR does not require CodeSystem.version - a CodeSystem with no version must
// still be creatable.
@test:Config {
    groups: ["codesystem", "add_codesystem", "successful_scenario"]
}
public function testAddValidCodeSystemWithoutVersion() returns error? {
    json requestPayload = returnCodeSystemData("add-valid-codesystem-noversion");

    http:Response response = check csClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});

    test:assertEquals(response.statusCode, 201);
}

// Todo: Uncomment after supporitng XML payloads: https://github.com/wso2-enterprise/open-healthcare/issues/2181
// @test:Config {
//     groups: ["codesystem", "add_codesystem", "successful_scenario"]
// }
// public function testAddValidCodeSystemXml() returns error? {
//     xml requestPayload = returnCodeSystemDataXml("add-valid-codesystem");

//     http:Response response = check csClient->post("/", requestPayload);

//     // check the response status code is 201 or not
//     test:assertEquals(response.statusCode, 201);
// }

@test:Config {
    groups: ["codesystem", "add_codesystem", "failure_scenario"]
}
public function testAddInvalidCodeSystemJson() returns error? {
    json codingJson = returnCodeSystemData("add-invalid-codesystem");
    http:Response response = check csClient->post("/", codingJson, {"Content-Type": FHIR_JSON});

    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedjson = returnCodeSystemData("add-invalid-codesystem-response2");
    r4:OperationOutcome expected = check expectedjson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(string:trim(actual.toJsonString()), string:trim(expected.toJsonString()));
}

// Todo: Uncomment after supporitng XML payloads: https://github.com/wso2-enterprise/open-healthcare/issues/2181
// @test:Config {
//     groups: ["codesystem", "add_codesystem", "failure_scenario"]
// }
// public function testAddInvalidCodeSystemXml() returns error? {
//     xml codingJson = returnCodeSystemDataXml("add-invalid-codesystem");
//     http:Response response = check csClient->post("/", codingJson);

//     json actualJson = check response.getJsonPayload();
//     r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

//     json expectedjson = returnCodeSystemData("add-invalid-codesystem-response");
//     r4:OperationOutcome expected = check expectedjson.cloneWithType(r4:OperationOutcome);

//     expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
//     test:assertEquals(actual, expected);
// }

@test:Config {
    groups: ["codesystem", "add_codesystem", "failure_scenario"]
}
public function testAddEmptyCodeSystemPayload() returns error? {
    http:Response response = check csClient->post("/", {}, {"Content-Type": FHIR_JSON});

    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedjson = returnCodeSystemData("add-invalid-codesystem-response");
    r4:OperationOutcome expected = check expectedjson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["valueset", "add_valueset", "successful_scenario"]
}
public function testAddValidValueSet() returns error? {
    json requestPayload = returnValueSetData("add-valid-valueset");

    http:Response response = check vsClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});

    // check the response status code is 201 or not
    test:assertEquals(response.statusCode, 201);
}

// FHIR does not require ValueSet.version - a ValueSet with no version must
// still be creatable.
@test:Config {
    groups: ["valueset", "add_valueset", "successful_scenario"]
}
public function testAddValidValueSetWithoutVersion() returns error? {
    json requestPayload = returnValueSetData("add-valid-valueset-noversion");

    http:Response response = check vsClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});

    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["valueset", "add_valueset", "successful_scenario"]
}
public function testAddValidValueSet2() returns error? {
    json requestPayload = returnValueSetData("add-valid-valueset2");

    http:Response response = check vsClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});

    // check the response status code is 201 or not
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["valueset", "add_valueset", "successful_scenario"]
}
public function testAddValidValueSet3() returns error? {
    json requestPayload = returnValueSetData("add-valid-valueset3");

    http:Response response = check vsClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});

    // check the response status code is 201 or not
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["valueset", "add_valueset", "successful_scenario"]
}
public function testAddValidValueSet4() returns error? {
    json requestPayload = returnValueSetData("add-valid-valueset4");

    http:Response response = check vsClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});

    // check the response status code is 201 or not
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["valueset", "add_valueset", "successful_scenario"]
}
public function testAddValidValueSet5() returns error? {
    json requestPayload = returnValueSetData("add-valid-valueset5");

    http:Response response = check vsClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});

    // check the response status code is 201 or not
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["valueset", "add_valueset", "failure_scenario"]
}
public function testAddInvalidValueSet() returns error? {
    json valueSetJson = returnValueSetData("add-invalid-valueset");
    http:Response response = check vsClient->post("/", valueSetJson, {"Content-Type": FHIR_JSON});

    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedJson = returnValueSetData("add-invalid-valueset-response");
    r4:OperationOutcome expected = check expectedJson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["valueset", "add_valueset", "failure_scenario"]
}
public function testAddEmptyValueSetPayload() returns error? {
    http:Response response = check vsClient->post("/", {}, {"Content-Type": FHIR_JSON});

    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedJson = returnValueSetData("add-invalid-valueset-response2");
    r4:OperationOutcome expected = check expectedJson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["upload", "successful_scenario"]
}
public function testUpload1() returns error? {
    byte[] zipBytes = check readZipFileAsBytes("test.zip");

    http:Request req = new;
    req.setPayload(zipBytes, contentType = "application/zip");
    req.setHeader(TYPE_HEADER, "FHIR");

    http:Response response = check baseClient->post("/%24upload?target-path=hl7.terminology.r4/package", req);
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["upload", "failure_scenario"]
}
public function testUpload2() returns error? {
    http:Request req = new;
    req.setPayload({}, contentType = "application/json");
    req.setHeader(TYPE_HEADER, "FHIR");

    http:Response response = check baseClient->post("/%24upload?target-path=hl7.terminology.r4/package", req);
    test:assertEquals(response.statusCode, 400);
}

@test:Config {
    groups: ["upload", "failure_scenario"]
}
public function testUpload3() returns error? {
    http:Request req = new;
    req.setPayload({}, contentType = "application/zip");

    // send without the header
    http:Response response1 = check baseClient->post("/%24upload", req);
    test:assertEquals(response1.statusCode, 400);

    // send with invalid header
    req.setHeader(TYPE_HEADER, "invalid");
    http:Response response2 = check baseClient->post("/%24upload", req);
    test:assertEquals(response2.statusCode, 400);
}

@test:Config {
    groups: ["upload", "successful_scenario", "loinc"]
}
public function testUploadLoinc() returns error? {
    byte[] zipBytes = check readZipFileAsBytes("loinc.zip");

    http:Request req = new;
    req.setPayload(zipBytes, contentType = "application/zip");
    req.setHeader(TYPE_HEADER, "LOINC");

    http:Response response = check baseClient->post("/%24upload?loinc-version=2.80", req);
    test:assertEquals(response.statusCode, 201);
}

// Todo: uncomment after supporting zip uploads
// @test:Config {
//     groups: ["upload", "codesystem", "add_codesystem", "successful_scenario"]
// }
// public function testUploadCodeSystem() returns error? {
//     byte[] zipBytes = check readZipFileAsBytes("codesystem.zip");

//     http:Request req = new;
//     req.setPayload(zipBytes, contentType = "application/zip");

//     http:Response response = check csClient->post("/", req);
//     test:assertEquals(response.statusCode, 201);
// }

// Todo: uncomment after supporting zip uploads
// @test:Config {
//     groups: ["upload", "valueset", "add_valueset_zip", "successful_scenario"]
// }
// public function testUploadValueSet() returns error? {
//     byte[] zipBytes = check readZipFileAsBytes("valueset.zip");

//     http:Request req = new;
//     req.setPayload(zipBytes, contentType = "application/zip");

//     http:Response response = check vsClient->post("/", req);
//     test:assertEquals(response.statusCode, 201);
// }

@test:Config {
    groups: ["concepts", "find_code", "successful_scenario"]
}
public function searchConcept1() returns error? {
    http:Response response = check baseClient->get("/%24find-code?filter=active");

    json actualJson = check response.getJsonPayload();
    r4:Bundle actual = check actualJson.cloneWithType(r4:Bundle);
    r4:Bundle expected = check returnConceptData("bundle-search-active").cloneWithType(r4:Bundle);

    test:assertTrue(assertBundleEqual(expected, actual));
}

@test:Config {
    groups: ["concepts", "find_code", "successful_scenario"]
}
public function searchConcept2() returns error? {
    http:Response response = check baseClient->get("/%24find-code?filter=active&_count=2&_offset=1");

    json actualJson = check response.getJsonPayload();
    r4:Bundle actual = check actualJson.cloneWithType(r4:Bundle);
    r4:Bundle expected = check returnConceptData("bundle-search-active-with-pagination").cloneWithType(r4:Bundle);

    test:assertTrue(assertBundleEqual(expected, actual));
}

@test:Config {
    groups: ["concepts", "find_code", "failure_scenario"]
}
public function searchConcept3() returns error? {
    http:Response response = check baseClient->get("/%24find-code");

    test:assertEquals(response.statusCode, 400);
}

@test:Config {
    groups: ["concepts", "find_code", "failure_scenario"]
}
public function searchConcept4() returns error? {
    http:Response response = check baseClient->get("/%24find-code?filter=active&property=invalid");

    test:assertEquals(response.statusCode, 400);
}

@test:Config {
    groups: ["concepts", "find_code", "successful_scenario"]
}
public function searchConceptPost1() returns error? {
    // Valid POST request with all parameters
    r4:ParametersParameter filterParam = {name: "filter", valueString: "active"};
    r4:ParametersParameter countParam = {name: "_count", valueInteger: 2};
    r4:ParametersParameter offsetParam = {name: "_offset", valueInteger: 1};
    r4:Parameters requestPayload = {'parameter: [filterParam, countParam, offsetParam]};

    http:Response response = check baseClient->post("/%24find-code", requestPayload, {"Content-Type": FHIR_JSON});

    json actualJson = check response.getJsonPayload();
    r4:Bundle actual = check actualJson.cloneWithType(r4:Bundle);
    r4:Bundle expected = check returnConceptData("bundle-search-active-with-pagination").cloneWithType(r4:Bundle);

    test:assertTrue(assertBundleEqual(expected, actual));
}

@test:Config {
    groups: ["concepts", "find_code", "failure_scenario"]
}
public function searchConceptPost_MissingFilter() returns error? {
    // Missing 'filter' parameter
    r4:ParametersParameter propertyParam = {name: "property", valueString: "display"};
    r4:Parameters requestPayload = {'parameter: [propertyParam]};
    http:Response response = check baseClient->post("/%24find-code", requestPayload, {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Missing 'filter' parameter");
}

@test:Config {
    groups: ["concepts", "find_code", "failure_scenario"]
}
public function searchConceptPost_InvalidProperty() returns error? {
    // Invalid 'property' parameter
    r4:ParametersParameter filterParam = {name: "filter", valueString: "active"};
    r4:ParametersParameter propertyParam = {name: "property", valueString: "invalid"};
    r4:Parameters requestPayload = {'parameter: [filterParam, propertyParam]};
    http:Response response = check baseClient->post("/%24find-code", requestPayload, {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid property value. Only 'display' or 'definition' are allowed.");
}

@test:Config {
    groups: ["concepts", "find_code", "failure_scenario"]
}
public function searchConceptPost_EmptyPayload() returns error? {
    // Empty payload
    http:Response response = check baseClient->post("/%24find-code", (), {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Empty request payload");
}

@test:Config {
    groups: ["concepts", "find_code", "failure_scenario"]
}
public function searchConceptPost_InvalidPayload() returns error? {
    // Invalid payload (not a Parameters resource)
    json invalidPayload = {"foo": "bar"};
    http:Response response = check baseClient->post("/%24find-code", invalidPayload, {"Content-Type": FHIR_JSON});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid request payload");
}

@test:Config {
    groups: ["capabilitystatement", "metadata", "successful_scenario"]
}
public function getCapabilityStatementFromMetadata() returns error? {
    http:Response response = check baseClient->get("/metadata", {"Content-Type": FHIR_JSON});
    test:assertEquals(response.statusCode, 200);
    json payload = check response.getJsonPayload();
    international401:CapabilityStatement|error capabilityStatement = payload.cloneWithType(international401:CapabilityStatement);
    test:assertTrue(capabilityStatement is international401:CapabilityStatement, "CapabilityStatement should not be an error");
}

@test:Config {
    dependsOn: [testAddValidCodeSystemJson],
    groups: ["closure", "successful_scenario"]
}
public function closurePost1() returns error? {
    r4:Parameters requestPayload = {
        'parameter: [
            {name: "name", valueString: "closure-happy-path"},
            {name: "concept", valueCoding: {system: "urn:oid:2.16.840.1.113883.6.238", code: "2133-7"}},
            {name: "concept", valueCoding: {system: "urn:oid:2.16.840.1.113883.6.238", code: "2135-2"}}
        ]
    };
    http:Response response = check baseClient->post("/%24closure", requestPayload, {"Content-Type": FHIR_JSON});
    test:assertEquals(response.statusCode, 200);

    json actualJson = check response.getJsonPayload();
    r4:ConceptMap actual = check actualJson.cloneWithType(r4:ConceptMap);
    test:assertEquals(actual.resourceType, "ConceptMap");

    // 2133-7 subsumes 2135-2 (confirmed by subsumeCodeSystem8), so $closure must
    // report it as a (ancestor=2133-7, descendant=2135-2) subsumption pair.
    r4:ConceptMapGroup[]? groups = actual.group;
    test:assertTrue(groups is r4:ConceptMapGroup[] && groups.length() > 0, "Expected at least one ConceptMap group");
    r4:ConceptMapGroup[] groupArr = <r4:ConceptMapGroup[]>groups;

    boolean pairFound = false;
    foreach r4:ConceptMapGroup g in groupArr {
        foreach r4:ConceptMapGroupElement el in g.element {
            if el.code == "2135-2" {
                foreach r4:ConceptMapGroupElementTarget t in (el.target ?: []) {
                    if t.code == "2133-7" && t.equivalence == "subsumes" {
                        pairFound = true;
                    }
                }
            }
        }
    }
    test:assertTrue(pairFound, "Expected a subsumes pair from 2135-2 to its ancestor 2133-7");
}

# Verifies that a `$closure` write sequence rolls back as a unit.
#
# + return - An `error` if setup (resolving the test CodeSystem/concept) fails
@test:Config {
    groups: ["closure", "transactional"]
}
public function closureTransactionRollsBackOnFailure() returns error? {
    string tableName = "closure-rollback-test";
    ClosureTableRow tableRow = check getOrCreateClosureTable(tableName);

    store_h2:CodeSystem storeCs = check getStoreCodeSystemByURL("http://hl7.org/fhir/account-status", ());
    store_h2:Concept concept = check getStoreConceptByCode(storeCs.codeSystemId, "active");

    error? txResult = registerConceptTwiceInOneTransaction(tableRow.closureTableId, concept.conceptId);
    test:assertTrue(txResult is error, "Expected the forced duplicate insert to fail the transaction");

    // If rollback worked, the FIRST insert (which, taken on its own, would have
    // succeeded) must be gone too - not just the second, constraint-violating one.
    int[] knownConceptIds = getKnownConceptIds(tableRow.closureTableId);
    test:assertEquals(knownConceptIds.length(), 0,
            "A failed closure transaction must not leave any partial writes committed");
}

isolated function registerConceptTwiceInOneTransaction(int closureTableId, int conceptId) returns error? {
    transaction {
        check addClosureTableConcept(closureTableId, conceptId);
        // Same (closureTableId, conceptId) again - violates
        // idx_closure_table_concepts_unique, forcing the transaction to fail
        // after the first insert already succeeded on its own.
        check addClosureTableConcept(closureTableId, conceptId);
        error? commitResult = commit;
        if commitResult is error {
            return commitResult;
        }
    }
}


// The windowed SQL path (expandWindowedInclude) and the in-memory path
// (closureMembers) must select the same concepts for an `is-a` filter. They
// can't be compared page-for-page, since only the windowed path has a defined
// row order - so this asserts the properties that actually matter: the same
// total, the same set of codes once every page has been walked, and no code
// served on two pages.
@test:Config {
    dependsOn: [testAddValidCodeSystemJson],
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function closureWindowMatchesInMemoryExpansion() returns error? {
    store_h2:CodeSystem codeSystem = check getStoreCodeSystemByURL("urn:oid:2.16.840.1.113883.6.238");
    WindowedInclude fastPath = {
        codeSystemId: codeSystem.codeSystemId,
        codeSystemUrl: codeSystem.url,
        anchorCode: "2133-7",
        includeSelf: true
    };

    r4:ValueSetExpansionContains[] inMemoryMembers = closureMembers(fastPath.codeSystemId, "2133-7", true, ());
    test:assertTrue(inMemoryMembers.length() > 1,
            "Fixture must resolve the anchor plus at least one descendant for this comparison to prove anything");

    string[] expectedCodes = [];
    foreach r4:ValueSetExpansionContains entry in inMemoryMembers {
        expectedCodes.push(entry.code ?: "");
    }

    // A page size of 1 forces every boundary to be exercised.
    int pageSize = 1;
    int offset = 0;
    int reportedTotal = -1;
    map<boolean> seenCodes = {};
    while true {
        [r4:ValueSetExpansionContains[], int] window = check expandWindowedInclude(fastPath, (), offset, pageSize);
        if reportedTotal == -1 {
            reportedTotal = window[1];
        } else {
            test:assertEquals(window[1], reportedTotal, "expansion.total must not drift between pages");
        }
        if window[0].length() == 0 {
            break;
        }
        foreach r4:ValueSetExpansionContains entry in window[0] {
            string code = entry.code ?: "";
            test:assertFalse(seenCodes.hasKey(code), string `Code ${code} was served on more than one page`);
            seenCodes[code] = true;
            test:assertEquals(entry.system, codeSystem.url, "Windowed entries must carry their CodeSystem URL");
        }
        offset += pageSize;
    }

    test:assertEquals(reportedTotal, inMemoryMembers.length(),
            "Windowed total must match the number of members the in-memory path finds");
    test:assertEquals(seenCodes.keys().sort(), expectedCodes.sort(),
            "Paging through the window must yield exactly the in-memory member set");
}

// The fast path is only ever an optimization, so the guard has to refuse every
// compose it can't reproduce exactly. Each shape here would need work the
// single windowed query can't do - intersecting two filters, de-duplicating
// against a second include, or applying a regex the page query has no
// equivalent for - and must fall through to the in-memory path instead.
@test:Config {
    groups: ["valueset", "expand_valueset", "failure_scenario"]
}
public function windowedIncludeFastPathRejectsUnsupportedShapes() {
    r4:ValueSetComposeIncludeFilter isaFilter = {property: "concept", op: "is-a", value: "2133-7"};
    string testSystem = "urn:oid:2.16.840.1.113883.6.238";

    r4:ValueSet twoFilters = {
        resourceType: "ValueSet",
        status: "active",
        compose: {
            include: [
                {
                    system: testSystem,
                    filter: [isaFilter, {property: "concept", op: "descendent-of", value: "2135-2"}]
                }
            ]
        }
    };
    test:assertTrue(windowedIncludeFastPath(twoFilters, [], ()) is (),
            "Two filters on one include have to be intersected, which the windowed query can't do");

    r4:ValueSet twoIncludes = {
        resourceType: "ValueSet",
        status: "active",
        compose: {
            include: [
                {system: testSystem, filter: [isaFilter]},
                {system: testSystem, filter: [{property: "concept", op: "is-a", value: "2135-2"}]}
            ]
        }
    };
    test:assertTrue(windowedIncludeFastPath(twoIncludes, [], ()) is (),
            "Two includes have to be de-duplicated against each other before paging");

    r4:ValueSet unsupportedOp = {
        resourceType: "ValueSet",
        status: "active",
        compose: {include: [{system: testSystem, filter: [{property: "status", op: "=", value: "active"}]}]}
    };
    test:assertTrue(windowedIncludeFastPath(unsupportedOp, [], ()) is (),
            "A property filter isn't resolvable in SQL - properties live inside the concept blob");

    r4:ValueSet withConceptList = {
        resourceType: "ValueSet",
        status: "active",
        compose: {include: [{system: testSystem, concept: [{code: "2133-7"}], filter: [isaFilter]}]}
    };
    test:assertTrue(windowedIncludeFastPath(withConceptList, [], ()) is (),
            "An explicit concept list contributes members the closure join doesn't cover");

    r4:ValueSet singleFilter = {
        resourceType: "ValueSet",
        status: "active",
        compose: {include: [{system: testSystem, filter: [isaFilter]}]}
    };
    test:assertTrue(windowedIncludeFastPath(singleFilter, [], "a.*b") is (),
            "A regex filter has no LIKE equivalent, so the page query couldn't apply it");
}

// The windowed path is worthless if the guard never actually recognizes a real
// stored ValueSet, and every other test here would still pass in that case -
// they'd just silently run the in-memory path. So: store the ordinary
// "descendants of X" compose, prove windowedIncludeFastPath claims it, and prove
// $expand over HTTP pages it correctly.
@test:Config {
    dependsOn: [testAddValidCodeSystemJson],
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandSingleIsaFilterTakesWindowedPath() returns error? {
    json requestPayload = returnValueSetData("add-valid-valueset-isa-filter");
    http:Response createResponse = check vsClient->post("/", requestPayload, {"Content-Type": FHIR_JSON});
    test:assertEquals(createResponse.statusCode, 201);

    // The guard reads the stored resource plus its persisted compose-include
    // rows - a filtered include must persist none, which is what lets the
    // windowed query stand in for the whole compose.
    store_h2:ValueSet storedRow = check getStoreValueSetByURL("http://example.org/fhir/ValueSet/race-descendants-isa", "1.0.0");
    r4:ValueSet storedVs = check byteToValueSet(storedRow.valueSet);
    store_h2:ValueSetComposeInclude[] includeRows = check getValueSetComposeIncludesForTest(storedRow.valueSetId);
    test:assertEquals(includeRows.length(), 0, "A filtered include must not persist a compose-include row");

    WindowedInclude? recognized = windowedIncludeFastPath(storedVs, includeRows, ());
    test:assertTrue(recognized is WindowedInclude,
            "The single is-a compose must be recognized, otherwise $expand silently keeps materializing the full closure");
    WindowedInclude fastPath = <WindowedInclude>recognized;
    test:assertEquals(fastPath.anchorCode, "2133-7");
    test:assertTrue(fastPath.includeSelf, "is-a includes the anchor itself");

    int expectedTotal = closureMembers(fastPath.codeSystemId, "2133-7", true, ()).length();
    test:assertTrue(expectedTotal > 1, "Fixture must resolve more than one member for paging to mean anything");

    // Same ValueSet through the actual HTTP surface, one member per page.
    http:Response firstPage = check vsClient->get("/$expand?url=http://example.org/fhir/ValueSet/race-descendants-isa&count=1&offset=0", ());
    test:assertEquals(firstPage.statusCode, 200);
    r4:ValueSet firstPageVs = check (check firstPage.getJsonPayload()).cloneWithType(r4:ValueSet);
    r4:ValueSetExpansion firstExpansion = <r4:ValueSetExpansion>firstPageVs.expansion;
    test:assertEquals(firstExpansion.total, expectedTotal, "Windowed expansion.total must count the whole closure, not the page");
    test:assertEquals((firstExpansion.contains ?: []).length(), 1, "count=1 must return exactly one member");

    http:Response secondPage = check vsClient->get("/$expand?url=http://example.org/fhir/ValueSet/race-descendants-isa&count=1&offset=1", ());
    r4:ValueSet secondPageVs = check (check secondPage.getJsonPayload()).cloneWithType(r4:ValueSet);
    r4:ValueSetExpansion secondExpansion = <r4:ValueSetExpansion>secondPageVs.expansion;
    test:assertEquals(secondExpansion.total, expectedTotal, "total must not drift between pages");

    string firstCode = (firstExpansion.contains ?: [])[0].code ?: "";
    string secondCode = (secondExpansion.contains ?: [])[0].code ?: "";
    test:assertNotEquals(firstCode, secondCode, "Consecutive offsets must return different members");
}

# Reads a ValueSet's persisted compose-include rows, so a test can check the
# input `windowedIncludeFastPath` actually sees.
#
# + valueSetId - Internal id of the stored ValueSet
# + return - The persisted compose-include rows, or an `error` if the query fails
isolated function getValueSetComposeIncludesForTest(int valueSetId) returns store_h2:ValueSetComposeInclude[]|error {
    sql:ParameterizedQuery includeQuery = sql:queryConcat(escapeToQuery("valuesetValueSetId"), ` = ${valueSetId}`);
    stream<store_h2:ValueSetComposeInclude, persist:Error?> includeStream =
        sClient->/valuesetcomposeincludes(store_h2:ValueSetComposeInclude, whereClause = includeQuery);
    return from store_h2:ValueSetComposeInclude include in includeStream
        select include;
}

// Same argument as expandSingleIsaFilterTakesWindowedPath, for the other shape
// the windowed query covers: an unfiltered whole-CodeSystem include, which
// otherwise reads and de-serializes every concept in the CodeSystem to build
// one page.
@test:Config {
    dependsOn: [testAddValidValueSet, testAddValidCodeSystemJson],
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandWholeSystemIncludeTakesWindowedPath() returns error? {
    store_h2:ValueSet storedRow = check getStoreValueSetByURL("http://example.org/fhir/ValueSet/cdcrec-all", "1.0.0");
    r4:ValueSet storedVs = check byteToValueSet(storedRow.valueSet);

    // saveValueSetCodeSystem runs in a strand the POST doesn't wait on, so the
    // systemFlag row the guard needs may not be written yet.
    store_h2:ValueSetComposeInclude[] includeRows = [];
    int attempts = 0;
    while attempts < 100 {
        includeRows = check getValueSetComposeIncludesForTest(storedRow.valueSetId);
        if includeRows.length() > 0 {
            break;
        }
        runtime:sleep(0.05);
        attempts += 1;
    }
    test:assertEquals(includeRows.length(), 1, "A whole-CodeSystem include persists exactly one compose-include row");
    test:assertTrue(includeRows[0].systemFlag, "That row must be the systemFlag one");

    WindowedInclude? recognized = windowedIncludeFastPath(storedVs, includeRows, ());
    test:assertTrue(recognized is WindowedInclude,
            "An unfiltered single-system compose must be recognized, otherwise $expand keeps reading the whole CodeSystem");
    WindowedInclude window = <WindowedInclude>recognized;
    test:assertTrue(window.anchorCode is (), "A whole-CodeSystem include has no closure anchor");

    // Windowed result must agree with what the whole-system include would have
    // produced in memory: every concept in the CodeSystem.
    [r4:ValueSetExpansionContains[], int] firstMember = check expandWindowedInclude(window, (), 0, 1);
    test:assertEquals(firstMember[0].length(), 1);
    test:assertTrue(firstMember[1] > 1, "Fixture CodeSystem must hold more than one concept");

    http:Response response = check vsClient->get("/$expand?url=http://example.org/fhir/ValueSet/cdcrec-all&count=1&offset=0", ());
    test:assertEquals(response.statusCode, 200);
    r4:ValueSet expanded = check (check response.getJsonPayload()).cloneWithType(r4:ValueSet);
    r4:ValueSetExpansion expansion = <r4:ValueSetExpansion>expanded.expansion;
    test:assertEquals(expansion.total, firstMember[1], "expansion.total must count the whole CodeSystem, not the page");
    test:assertEquals((expansion.contains ?: []).length(), 1, "count=1 must return exactly one member");
}

// A text filter must select the same concepts whether it was pushed into SQL as
// a LIKE predicate or applied in memory. The two disagreed on displays holding a
// line terminator: LIKE's % crosses one, but the in-memory check used to wrap
// the filter in `.*`, and `.` does not match a line terminator - so "active"
// found a match in "Prefix Active" but not in "Prefix\nActive", and a concept
// was kept or dropped depending on which path its expansion happened to take.
@test:Config {
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function displayFilterMatchesAcrossLineTerminators() {
    // The case that regressed: the match sits after a newline, so the in-memory
    // check has to reach across it exactly as LIKE '%ACTIVE%' does.
    test:assertTrue(displayMatchesTextFilter("Prefix\nActive", "active"),
            "A filter must match a display whose matching text follows a line terminator");
    test:assertTrue(displayMatchesTextFilter("Prefix\r\nActive", "active"),
            "The same must hold for a CRLF display");
    test:assertTrue(displayMatchesTextFilter("Prefix Active", "active"),
            "The ordinary single-line case must keep working");

    // A filter that itself spans lines still has to match literally, and still
    // has to be rejected when the display doesn't contain it.
    test:assertTrue(displayMatchesTextFilter("Alpha\nBeta", "alpha\nbeta"),
            "A filter containing a line terminator must match a display containing it");
    test:assertFalse(displayMatchesTextFilter("Alpha Beta", "alpha\nbeta"),
            "A filter containing a line terminator must not match a display without one");

    // Non-matches must stay non-matches - `find` is a search, not a match-all.
    test:assertFalse(displayMatchesTextFilter("Prefix\nRetired", "active"),
            "A display that doesn't contain the filter must still be dropped");

    // A concept with no display passes, unchanged by the switch to `find`.
    test:assertTrue(displayMatchesTextFilter((), "active"),
            "A concept with no display is kept, matching displayContainsFragment's IS NULL arm");

    // isPlainTextFilter admits CR/LF, so such a filter is pushed into SQL. That
    // is only sound while the in-memory form agrees with LIKE, which is what the
    // assertions above pin down.
    test:assertTrue(isPlainTextFilter("alpha\nbeta"),
            "A filter containing only a line terminator holds no regex syntax");
}


