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

import ballerina/test;

// Test FHIR validation functionality
@test:Config {}
function testValidateFHIRTemplate_ValidQuestionnaire() {
    json validQuestionnaire = {
        "resourceType": "Questionnaire",
        "id": "test-questionnaire",
        "url": "http://example.org/questionnaire/test-questionnaire",
        "status": "active", 
        "subjectType": ["Patient"],
        "text": {
            "status": "generated",
            "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\">Test Questionnaire</div>"
        }
    };
    
    string result = validateFHIRTemplate(validQuestionnaire);
    test:assertEquals(result, "This is a valid FHIR Resource.");
}

// Test FHIR validation with invalid questionnaire
@test:Config {}
function testValidateFHIRTemplate_InvalidQuestionnaire() {
    json invalidQuestionnaire = {
        "resourceType": "Questionnaire",
        "id": "test-questionnaire",
        "status": "active"
        // Missing required fields: url, subjectType, text, etc.
    };
    
    string result = validateFHIRTemplate(invalidQuestionnaire);
    test:assertTrue(result.includes("FHIR Validation Errors"));
}

// Test isValidGeneratorResponse function
@test:Config {}
function testInvalidGeneratorResponse(){
    string invalidResponse = "This is not a valid FHIR Questionnaire.";
    boolean isValid = isValidGeneratorResponse(invalidResponse);
    test:assertFalse(isValid, "The response should be identified as invalid.");
}

// Test isValidGeneratorResponse with extra text around valid JSON
@test:Config {}
function testInvalidGeneratorResponseFormat(){
    string invalidResponse = "Hi there this is the generated questionnaire: { \"resourceType\": \"Questionnaire\", \"id\": \"test-questionnaire\", \"url\": \"http://example.org/questionnaire/test-questionnaire\", \"status\": \"active\", \"subjectType\": [\"Patient\"], \"text\": { \"status\": \"generated\", \"div\": \"<div xmlns=\\\"http://www.w3.org/1999/xhtml\\\">Test Questionnaire</div>\" } } Thank you!";
    boolean isValid = isValidGeneratorResponse(invalidResponse);
    test:assertTrue(isValid, "The response should be identified as valid despite extra text.");
}

// Test isValidGeneratorResponse with valid JSON string
@test:Config {}
function testValidGeneratorResponseFunction(){
    string validResponse = "{ \"resourceType\": \"Questionnaire\", \"id\": \"test-questionnaire\", \"url\": \"http://example.org/questionnaire/test-questionnaire\", \"status\": \"active\", \"subjectType\": [\"Patient\"], \"text\": { \"status\": \"generated\", \"div\": \"<div xmlns=\\\"http://www.w3.org/1999/xhtml\\\">Test Questionnaire</div>\" } }";
    boolean isValid = isValidGeneratorResponse(validResponse);
    test:assertTrue(isValid, "The response should be identified as valid.");
}
