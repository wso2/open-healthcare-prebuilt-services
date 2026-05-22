// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com).

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

import ballerina/io;
import ballerina/http;
import ballerina/test;

http:Client testClient = check new ("http://localhost:9090");
map<string> documentMap = {};
json bundle = {};

@test:BeforeSuite
function beforeSuiteFunc() returns error? {
    documentMap["validCcda"] = check io:fileReadString("tests/test_valid_ccda_document.xml");
    documentMap["invalid"] = check io:fileReadString("tests/test_invalid_ccda_document.xml");
    bundle = check io:fileReadJson("tests/test_valid_fhir_bundle.json");
}

@test:Config {}
function testCcdaDocumentToFhir() returns error? {
    http:Response|error response = testClient->/transform.post(documentMap["validCcda"]);
    test:assertTrue(response is http:Response, "Error occurred while transforming CCDA document to FHIR!");
    if (response is http:Response) {
        json jsonPayload = check response.getJsonPayload();
        json entryArr = check jsonPayload.entry;
        json expectedEntryArr = check bundle.entry;
        if entryArr is json[] && expectedEntryArr is json[] {
            test:assertEquals(jsonPayload.resourceType, "Bundle", "Response should be a Bundle!");
            test:assertEquals(entryArr.length(), expectedEntryArr.length(), "Response payload length mismatched!");
        } else {
            test:assertTrue(false, "Response payload is not an array!");
        }
    }
}

@test:Config {}
function testErrorneousCcdaDocument() returns error? {
    http:Response|error response = testClient->/transform.post(documentMap["invalid"]);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400, "Response status code mismatched!");
        json jsonPayload = check response.getJsonPayload();
        test:assertEquals(jsonPayload.resourceType, "OperationOutcome", "Response should be an OperationOutcome!");
        json[] issues = <json[]>check jsonPayload.issue;
        json textElement = check issues[0].details.text;
        test:assertTrue(string:startsWith(textElement.toString(), "Invalid xml document."),
            "Incorrect error message from the invalid document conversion!");
    }
}

