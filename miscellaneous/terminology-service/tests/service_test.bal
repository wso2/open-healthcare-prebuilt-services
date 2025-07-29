import terminology_service_api.store;

import ballerina/http;
import ballerina/test;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.terminology;

http:Client baseClient = check new ("http://localhost:9089/fhir/r4");
http:Client csClient = check new ("http://localhost:9089/fhir/r4/CodeSystem");
http:Client vsClient = check new ("http://localhost:9089/fhir/r4/ValueSet");

@test:BeforeSuite
isolated function beforeSuite() returns error? {
    check store:setupTestDB();
    check addExampleDataToTestDB();
}

@test:AfterSuite
function afterSuite() returns error? {
    check store:cleanupTestDB();
}

@test:Mock {functionName: "initializeClient"}
isolated function getMockClient() returns store:Client|error {
    return test:mock(store:Client, check new store:H2Client("jdbc:h2:./tests/test", "sa", ""));
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
    http:Response response = check csClient->get("/account-status%7C4.0.1");

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
    http:Response response = check csClient->get("?url=http://hl7.org/fhir/account-status&version=4.0.1&title=AccountStatus&status=draft&count=10&offset=0&name=AccountStatus&publisher=HL7%20%28FHIR%20Project%29");

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
    http:Response response = check csClient->get("/%24lookup?system=http://hl7.org/fhir/account-status&code=inactive");
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("account-status-inactive");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "successful_scenario"]
}
public function lookupCodeSystem2() returns error? {
    http:Response response = check csClient->get("/account-status/%24lookup?code=inactive", ());
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("account-status-inactive");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "successful_scenario"]
}
public function lookupCodeSystem3() returns error? {
    r4:Coding|r4:FHIRError coding = terminology:createCoding("http://hl7.org/fhir/account-status", "inactive", terminology = terminology_source);
    international401:Parameters p = {'parameter: [{name: "coding", valueCoding: check coding}]};
    http:Response response = check csClient->post("/%24lookup", p);
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("account-status-inactive");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "failure_scenario"]
}
public function lookupCodeSystem4() returns error? {
    http:Response response = check csClient->post("/%24lookup", ());
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Empty request payload");
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "failure_scenario"]
}
public function lookupCodeSystem5() returns error? {
    http:Response response = check csClient->get("/%24lookup?code=inactive", ());
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
    http:Response response = check csClient->post("/%24lookup", codingJson);
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
    http:Response response = check csClient->post("/%24lookup", ());
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Empty request payload");
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "failure_scenario"]
}
public function lookupCodeSystem8() returns error? {
    http:Response response = check csClient->post("/%24lookup", {});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid Coding value");
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "failure_scenario"]
}
public function lookupCodeSystem9() returns error? {
    international401:Parameters parameters = {'parameter: [{name: "sample"}]};
    http:Response response = check csClient->post("/%24lookup", parameters);
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid request payload");
}

@test:Config {
    groups: ["codesystem", "lookup_codesystem", "failure_scenario"]
}
public function lookupCodeSystem10() returns error? {
    r4:Coding coding = check terminology:createCoding("http://hl7.org/fhir/account-status", "inactive", terminology = terminology_source);
    coding.system = ();
    international401:Parameters parameters = {'parameter: [{name: "coding", valueCoding: coding}]};
    http:Response response = check csClient->post("/%24lookup", parameters);
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Can not find a CodeSystem");
}

@test:Config {
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem1() returns error? {
    http:Response response = check csClient->get("/%24subsumes?codeA=Type&codeB=Any&system=http://hl7.org/fhir/abstract-types", ());
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("subsume-notequal");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem2() returns error? {
    http:Response response = check csClient->get("/%24subsumes?codeA=Type&codeB=Type&system=http://hl7.org/fhir/abstract-types", ());
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

    international401:ParametersParameter cA = {name: "codingA", valueCoding: codingA};
    international401:ParametersParameter cB = {name: "codingB", valueCoding: codingB};
    international401:ParametersParameter system = {name: "system", valueUri: "http://hl7.org/fhir/account-status"};
    international401:Parameters requestPayload = {'parameter: [cA, cB, system]};

    http:Response response = check csClient->post("/%24subsumes", requestPayload);
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("subsume-equal");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "subsume_codesystem", "failure_scenario"]
}
public function subsumeCodeSystem5() returns error? {

    http:Response response = check csClient->get("/%24subsumes?codeA=Type&codeB=Type", ());
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
    http:Response response = check csClient->post("/%24subsumes", requestJson);
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
    http:Response response = check csClient->post("/%24subsumes", ());
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Empty request payload or invalid json format");
}

@test:Config {
    dependsOn: [testAddValidCodeSystemJson],
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem8() returns error? {
    http:Response response = check csClient->get("/%24subsumes?codeA=2133-7&codeB=2135-2&system=urn:oid:2.16.840.1.113883.6.238");
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("subsumed");
    test:assertEquals(actual, expected);
}

@test:Config {
    dependsOn: [testAddValidCodeSystemJson],
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem9() returns error? {
    http:Response response = check csClient->get("/%24subsumes?codeA=2186-5&codeB=2133-7&system=urn:oid:2.16.840.1.113883.6.238");
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("subsumed-by");
    test:assertEquals(actual, expected);
}

@test:Config {
    dependsOn: [testAddValidCodeSystemJson],
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem10() returns error? {
    http:Response response = check csClient->get("/%24subsumes?codeA=2155-0&codeB=2133-7&system=urn:oid:2.16.840.1.113883.6.238");
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("subsumed-by");
    test:assertEquals(actual, expected);
}

@test:Config {
    dependsOn: [testAddValidCodeSystemJson],
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem11() returns error? {
    http:Response response = check csClient->get("/%24subsumes?codeA=2155-0&codeB=1000-9&system=urn:oid:2.16.840.1.113883.6.238");
    json actual = check response.getJsonPayload();

    json expected = returnCodeSystemData("subsume-notequal");
    test:assertEquals(actual, expected);
}

@test:Config {
    dependsOn: [testAddValidCodeSystemJson],
    groups: ["codesystem", "subsume_codesystem", "successful_scenario"]
}
public function subsumeCodeSystem12() returns error? {
    r4:Coding codingA = check terminology:createCoding("urn:oid:2.16.840.1.113883.6.238", "2133-7", terminology = terminology_source);
    r4:Coding codingB = check terminology:createCoding("urn:oid:2.16.840.1.113883.6.238", "2135-2", terminology = terminology_source);

    international401:ParametersParameter cA = {name: "codingA", valueCoding: codingA};
    international401:ParametersParameter cB = {name: "codingB", valueCoding: codingB};
    international401:ParametersParameter system = {name: "system", valueUri: "urn:oid:2.16.840.1.113883.6.238"};
    international401:Parameters requestPayload = {'parameter: [cA, cB, system]};

    http:Response response = check csClient->post("/%24subsumes", requestPayload);
    json actual = check response.getJsonPayload();

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
    http:Response response = check vsClient->get("/account-status%7C4.0.1");

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
    http:Response response = check vsClient->get("/%24validate-code?system=http://hl7.org/fhir/ValueSet/account-status&code=inactive", ());
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "successful_scenario"]
}
public function validateCodeValueSet2() returns error? {
    json requestPayload = returnValueSetData("account-status-as-parameter");
    http:Response response = check vsClient->post("/%24validate-code", requestPayload);
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "successful_scenario"]
}
public function validateCodeValueSet3() returns error? {
    http:Response response = check vsClient->get("/account-status/%24validate-code?code=inactive", ());
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "successful_scenario"]
}
public function validateCodeValueSet4() returns error? {
    json requestPayload = returnValueSetData("account-status-as-parameter");
    http:Response response = check vsClient->post("/%24validate-code", requestPayload);
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "successful_scenario"]
}
public function validateCodeValueSet5() returns error? {
    json requestPayload = returnValueSetData("account-status-as-parameter2");

    http:Response response = check vsClient->post("/%24validate-code", requestPayload);
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "failure_scenario"]
}
public function validateCodeValueSet6() returns error? {
    http:Response response = check vsClient->post("/%24validate-code", ());
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Empty request payload");
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "failure_scenario"]
}
public function validateCodeValueSet7() returns error? {
    http:Response response = check vsClient->post("/%24validate-code", {});
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid request payload");
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "failure_scenario"]
}
public function validateCodeValueSet8() returns error? {
    json requestPayload = returnValueSetData("coding-as-parameter");
    http:Response response = check vsClient->post("/%24validate-code", requestPayload);
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid request payload");
}

@test:Config {
    groups: ["valueset", "validate_code_valueset", "failure_scenario"]
}
public function validateCodeValueSet9() returns error? {
    http:Response response = check vsClient->get("/%24validate-code");
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Can not find a ValueSet, Code value is missing");
}

@test:Config {
    dependsOn: [testAddValidValueSet2],
    groups: ["valueset", "validate_code_valueset", "successful_scenario"]
}
public function validateCodeValueSet10() returns error? {
    http:Response response = check vsClient->get("/example-valueset-include-valueset/%24validate-code?code=inactive", ());
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    test:assertEquals(actual, expected);
}

@test:Config {
    dependsOn: [testAddValidValueSet4],
    groups: ["valueset", "validate_code_valueset", "successful_scenario"]
}
public function validateCodeValueSet11() returns error? {
    http:Response response = check vsClient->get("/example-valueset-include-concepts/%24validate-code?code=inactive", ());
    json actual = check response.getJsonPayload();

    json expected = returnValueSetData("validate-code");
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandValueSet1() returns error? {
    http:Response response = check vsClient->get("/%24expand?url=http://hl7.org/fhir/ValueSet/account-status", ());
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
    http:Response response = check vsClient->get("/account-status/%24expand", ());
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
    http:Response response = check vsClient->post("/%24expand", requestPayload);

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
    http:Response response = check vsClient->post("/%24expand", ());

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
    http:Response response = check vsClient->post("/%24expand", {});

    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid request payload");
}

@test:Config {
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandValueSet6() returns error? {
    http:Response response = check vsClient->get("/%24expand?url=http://hl7.org/fhir/ValueSet/account-status&filter=active", ());
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
    http:Response response = check vsClient->get("/account-status/%24expand?filter=active", ());
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
    http:Response response = check vsClient->get("/%24expand?url=http://hl7.org/fhir/ValueSet/account-and-resource-status&filter=active", ());
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
    http:Response response = check vsClient->get("/example-valueset-include-valueset/%24expand", ());
    json actualJson = check response.getJsonPayload();
    r4:ValueSet actual = check actualJson.cloneWithType(r4:ValueSet);

    json expectedJson = returnValueSetData("expanded-example-valueset-include-valueset");
    r4:ValueSet expected = check expectedJson.cloneWithType(r4:ValueSet);

    expected.expansion.timestamp = (<r4:ValueSetExpansion>actual.expansion).timestamp;
    test:assertTrue(assertValueSetExpansionsEqual(expected.expansion, actual.expansion), "ValueSet expansions are not equal");
}

@test:Config {
    dependsOn: [testAddValidValueSet4],
    groups: ["valueset", "expand_valueset", "successful_scenario"]
}
public function expandValueSet10() returns error? {
    http:Response response = check vsClient->get("/example-valueset-include-concepts/%24expand", ());
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

    international401:Parameters parameters = codesystemConceptsToParameters(concept);
    json actualJson = parameters.toJson();

    json expectedJson = returnCodeSystemData("designation-expected");
    test:assertEquals(actualJson, expectedJson);
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

    international401:Parameters parameters = codesystemConceptsToParameters(concepts);
    json actualJson = parameters.toJson();

    json expectedJson = returnCodeSystemData("concepts-array-expected");
    test:assertEquals(actualJson, expectedJson);
}

@test:Config {
    groups: ["valueset", "batch_validate_valueset", "successful_scenario"]
}
public function testBatchValidateValueSetsValid() returns error? {
    json requestPayload = returnBatchData("valid-batch-request");
    json expectedResponse = returnBatchData("valid-batch-response");

    http:Response response = check baseClient->post("/", requestPayload);
    test:assertEquals(response.getJsonPayload(), expectedResponse);
}

@test:Config {
    groups: ["valueset", "batch_validate_valueset", "failure_scenario"]
}
public function testBatchValidateValueSetsInvalidJson() returns error? {
    json requestPayload = returnBatchData("invalid-json-batch-request");
    http:Response response = check baseClient->post("/", requestPayload);

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
    http:Response response = check baseClient->post("/", requestPayload);

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
    http:Response response = check baseClient->post("/", requestPayload);

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

    http:Response response = check csClient->post("/", requestPayload);

    // check the response status code is 201 or not
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["codesystem", "add_codesystem", "successful_scenario"]
}
public function testAddValidCodeSystemXml() returns error? {
    xml requestPayload = returnCodeSystemDataXml("add-valid-codesystem");

    http:Response response = check csClient->post("/", requestPayload);

    // check the response status code is 201 or not
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["codesystem", "add_codesystem", "failure_scenario"]
}
public function testAddInvalidCodeSystemJson() returns error? {
    json codingJson = returnCodeSystemData("add-invalid-codesystem");
    http:Response response = check csClient->post("/", codingJson);

    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedjson = returnCodeSystemData("add-invalid-codesystem-response");
    r4:OperationOutcome expected = check expectedjson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "add_codesystem", "failure_scenario"]
}
public function testAddInvalidCodeSystemXml() returns error? {
    xml codingJson = returnCodeSystemDataXml("add-invalid-codesystem");
    http:Response response = check csClient->post("/", codingJson);

    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedjson = returnCodeSystemData("add-invalid-codesystem-response");
    r4:OperationOutcome expected = check expectedjson.cloneWithType(r4:OperationOutcome);

    expected.issue[0].diagnostics = (<r4:OperationOutcomeIssue[]>actual.issue)[0].diagnostics;
    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["codesystem", "add_codesystem", "failure_scenario"]
}
public function testAddEmptyCodeSystemPayload() returns error? {
    http:Response response = check csClient->post("/", {});

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

    http:Response response = check vsClient->post("/", requestPayload);

    // check the response status code is 201 or not
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["valueset", "add_valueset", "successful_scenario"]
}
public function testAddValidValueSet2() returns error? {
    json requestPayload = returnValueSetData("add-valid-valueset2");

    http:Response response = check vsClient->post("/", requestPayload);

    // check the response status code is 201 or not
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["valueset", "add_valueset", "successful_scenario"]
}
public function testAddValidValueSet3() returns error? {
    json requestPayload = returnValueSetData("add-valid-valueset3");

    http:Response response = check vsClient->post("/", requestPayload);

    // check the response status code is 201 or not
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["valueset", "add_valueset", "successful_scenario"]
}
public function testAddValidValueSet4() returns error? {
    json requestPayload = returnValueSetData("add-valid-valueset4");

    http:Response response = check vsClient->post("/", requestPayload);

    // check the response status code is 201 or not
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["valueset", "add_valueset", "successful_scenario"]
}
public function testAddValidValueSet5() returns error? {
    json requestPayload = returnValueSetData("add-valid-valueset5");

    http:Response response = check vsClient->post("/", requestPayload);

    // check the response status code is 201 or not
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["valueset", "add_valueset", "failure_scenario"]
}
public function testAddInvalidValueSet() returns error? {
    json valueSetJson = returnValueSetData("add-invalid-valueset");
    http:Response response = check vsClient->post("/", valueSetJson);

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
    http:Response response = check vsClient->post("/", {});

    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);

    json expectedJson = returnValueSetData("add-invalid-valueset-response");
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

@test:Config {
    groups: ["upload", "codesystem", "add_codesystem", "successful_scenario"]
}
public function testUploadCodeSystem() returns error? {
    byte[] zipBytes = check readZipFileAsBytes("codesystem.zip");

    http:Request req = new;
    req.setPayload(zipBytes, contentType = "application/zip");

    http:Response response = check csClient->post("/", req);
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["upload", "valueset", "add_valueset_zip", "successful_scenario"]
}
public function testUploadValueSet() returns error? {
    byte[] zipBytes = check readZipFileAsBytes("valueset.zip");

    http:Request req = new;
    req.setPayload(zipBytes, contentType = "application/zip");

    http:Response response = check vsClient->post("/", req);
    test:assertEquals(response.statusCode, 201);
}

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
    international401:ParametersParameter filterParam = {name: "filter", valueString: "active"};
    international401:ParametersParameter countParam = {name: "_count", valueInteger: 2};
    international401:ParametersParameter offsetParam = {name: "_offset", valueInteger: 1};
    international401:Parameters requestPayload = {'parameter: [filterParam, countParam, offsetParam]};

    http:Response response = check baseClient->post("/%24find-code", requestPayload);

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
    international401:ParametersParameter propertyParam = {name: "property", valueString: "display"};
    international401:Parameters requestPayload = {'parameter: [propertyParam]};
    http:Response response = check baseClient->post("/%24find-code", requestPayload);
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Missing 'filter' parameter");
}

@test:Config {
    groups: ["concepts", "find_code", "failure_scenario"]
}
public function searchConceptPost_InvalidProperty() returns error? {
    // Invalid 'property' parameter
    international401:ParametersParameter filterParam = {name: "filter", valueString: "active"};
    international401:ParametersParameter propertyParam = {name: "property", valueString: "invalid"};
    international401:Parameters requestPayload = {'parameter: [filterParam, propertyParam]};
    http:Response response = check baseClient->post("/%24find-code", requestPayload);
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid property value. Only 'display' or 'definition' are allowed.");
}

@test:Config {
    groups: ["concepts", "find_code", "failure_scenario"]
}
public function searchConceptPost_EmptyPayload() returns error? {
    // Empty payload
    http:Response response = check baseClient->post("/%24find-code", ());
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
    http:Response response = check baseClient->post("/%24find-code", invalidPayload);
    json actualJson = check response.getJsonPayload();
    r4:OperationOutcome actual = check actualJson.cloneWithType(r4:OperationOutcome);
    test:assertEquals((<r4:CodeableConcept>actual.issue[0].details).text, "Invalid request payload");
}

@test:Config {
    groups: ["capabilitystatement", "metadata", "successful_scenario"]
}
public function getCapabilityStatementFromMetadata() returns error? {
    http:Response response = check baseClient->get("/metadata");
    test:assertEquals(response.statusCode, 200);
    json payload = check response.getJsonPayload();
    international401:CapabilityStatement|error capabilityStatement = payload.cloneWithType(international401:CapabilityStatement);
    test:assertTrue(capabilityStatement is international401:CapabilityStatement, "CapabilityStatement should not be an error");
}
