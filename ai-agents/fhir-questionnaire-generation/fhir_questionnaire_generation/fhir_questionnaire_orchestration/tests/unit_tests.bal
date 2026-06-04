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

import ballerina/test;

// ---------------------------------------------------------------------------
// FHIR validation tests
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// isValidGeneratorResponse tests (backward-compatible wrapper)
// ---------------------------------------------------------------------------

@test:Config {}
function testInvalidGeneratorResponse() {
    string invalidResponse = "This is not a valid FHIR Questionnaire.";
    boolean isValid = isValidGeneratorResponse(invalidResponse);
    test:assertFalse(isValid, "Plain text should be identified as invalid.");
}

@test:Config {}
function testInvalidGeneratorResponseFormat() {
    string invalidResponse = "Hi there this is the generated questionnaire: { \"resourceType\": \"Questionnaire\", \"id\": \"test-questionnaire\", \"url\": \"http://example.org/questionnaire/test-questionnaire\", \"status\": \"active\", \"subjectType\": [\"Patient\"], \"text\": { \"status\": \"generated\", \"div\": \"<div xmlns=\\\"http://www.w3.org/1999/xhtml\\\">Test Questionnaire</div>\" } } Thank you!";
    boolean isValid = isValidGeneratorResponse(invalidResponse);
    test:assertTrue(isValid, "Valid JSON wrapped in text should be identified as valid.");
}

@test:Config {}
function testValidGeneratorResponseFunction() {
    string validResponse = "{ \"resourceType\": \"Questionnaire\", \"id\": \"test-questionnaire\", \"url\": \"http://example.org/questionnaire/test-questionnaire\", \"status\": \"active\", \"subjectType\": [\"Patient\"], \"text\": { \"status\": \"generated\", \"div\": \"<div xmlns=\\\"http://www.w3.org/1999/xhtml\\\">Test Questionnaire</div>\" } }";
    boolean isValid = isValidGeneratorResponse(validResponse);
    test:assertTrue(isValid, "Pure valid JSON should be identified as valid.");
}

// ---------------------------------------------------------------------------
// extractQuestionnaireJson tests
// ---------------------------------------------------------------------------

@test:Config {}
function testExtractQuestionnaireJson_PureJson() {
    string raw = "{\"resourceType\": \"Questionnaire\", \"id\": \"q1\", \"status\": \"draft\"}";
    string? result = extractQuestionnaireJson(raw);
    test:assertTrue(result is string, "Should extract valid pure JSON.");
}

@test:Config {}
function testExtractQuestionnaireJson_WrappedInText() {
    string raw = "Here is your questionnaire: {\"resourceType\": \"Questionnaire\", \"id\": \"q1\", \"status\": \"draft\"} Hope this helps!";
    string? result = extractQuestionnaireJson(raw);
    test:assertTrue(result is string, "Should extract JSON embedded in surrounding text.");
}

@test:Config {}
function testExtractQuestionnaireJson_NoJson() {
    string raw = "I cannot generate a questionnaire for that request.";
    string? result = extractQuestionnaireJson(raw);
    test:assertTrue(result is (), "Should return () for text with no JSON.");
}

@test:Config {}
function testExtractQuestionnaireJson_WrongResourceType() {
    string raw = "{\"resourceType\": \"Patient\", \"id\": \"p1\"}";
    string? result = extractQuestionnaireJson(raw);
    test:assertTrue(result is (), "Should return () for non-Questionnaire resource types.");
}

@test:Config {}
function testExtractQuestionnaireJson_EmptyString() {
    string? result = extractQuestionnaireJson("");
    test:assertTrue(result is (), "Should return () for empty input.");
}

// ---------------------------------------------------------------------------
// parseReviewSeverity tests
// ---------------------------------------------------------------------------

@test:Config {}
function testParseReviewSeverity_Approved() {
    ReviewSeverity severity = parseReviewSeverity("APPROVED");
    test:assertEquals(severity.critical, 0);
    test:assertEquals(severity.errors, 0);
    test:assertEquals(severity.warnings, 0);
}

@test:Config {}
function testParseReviewSeverity_ApprovedLowercase() {
    ReviewSeverity severity = parseReviewSeverity("approved");
    test:assertEquals(severity.critical, 0);
    test:assertEquals(severity.errors, 0);
    test:assertEquals(severity.warnings, 0);
}

@test:Config {}
function testParseReviewSeverity_MixedFindings() {
    string feedback = "## FHIR Questionnaire Review\n"
        + "**Overall Assessment**: FAILS\n\n"
        + "### Findings\n"
        + "1. **[CRITICAL]** linkId \"1.1\": Missing enableWhen reference.\n"
        + "2. **[ERROR]** linkId \"2\": Wrong type for question.\n"
        + "3. **[ERROR]** linkId \"3\": Missing enableBehavior.\n"
        + "4. **[WARNING]** linkId \"4\": Missing required field.\n";
    ReviewSeverity severity = parseReviewSeverity(feedback);
    test:assertEquals(severity.critical, 1);
    test:assertEquals(severity.errors, 2);
    test:assertEquals(severity.warnings, 1);
}

@test:Config {}
function testParseReviewSeverity_WarningsOnly() {
    string feedback = "## FHIR Questionnaire Review\n"
        + "**Overall Assessment**: FAILS\n\n"
        + "### Findings\n"
        + "1. **[WARNING]** linkId \"1\": Consider adding required field.\n"
        + "2. **[WARNING]** linkId \"2\": Question text could be clearer.\n";
    ReviewSeverity severity = parseReviewSeverity(feedback);
    test:assertEquals(severity.critical, 0);
    test:assertEquals(severity.errors, 0);
    test:assertEquals(severity.warnings, 2);
}

// ---------------------------------------------------------------------------
// countOccurrences tests
// ---------------------------------------------------------------------------

@test:Config {}
function testCountOccurrences_MultipleHits() {
    int count = countOccurrences("abc abc abc", "abc");
    test:assertEquals(count, 3);
}

@test:Config {}
function testCountOccurrences_NoHits() {
    int count = countOccurrences("hello world", "xyz");
    test:assertEquals(count, 0);
}

// ---------------------------------------------------------------------------
// buildRevisionPrompt tests
// ---------------------------------------------------------------------------

@test:Config {}
function testBuildRevisionPrompt_WithValidationErrors() {
    string prompt = buildRevisionPrompt("Some feedback", "FHIR Validation Errors: missing url", 1);
    test:assertTrue(prompt.includes("Reviewer Feedback (Iteration 1)"));
    test:assertTrue(prompt.includes("Some feedback"));
    test:assertTrue(prompt.includes("FHIR Structural Validation Result"));
    test:assertTrue(prompt.includes("FHIR Validation Errors: missing url"));
}

@test:Config {}
function testBuildRevisionPrompt_WithoutValidationErrors() {
    string prompt = buildRevisionPrompt("Some feedback", "This is a valid FHIR Resource.", 2);
    test:assertTrue(prompt.includes("Reviewer Feedback (Iteration 2)"));
    test:assertFalse(prompt.includes("FHIR Structural Validation Result"));
}

// ---------------------------------------------------------------------------
// buildReviewerInput tests
// ---------------------------------------------------------------------------

@test:Config {}
function testBuildReviewerInput_WithErrors() {
    string input = buildReviewerInput("{\"resourceType\":\"Questionnaire\"}", "FHIR Validation Errors: bad field");
    test:assertTrue(input.includes("FHIR Questionnaire JSON"));
    test:assertTrue(input.includes("FHIR Validation Errors: bad field"));
}

@test:Config {}
function testBuildReviewerInput_NoErrors() {
    string input = buildReviewerInput("{\"resourceType\":\"Questionnaire\"}", "This is a valid FHIR Resource.");
    test:assertTrue(input.includes("Passed"));
}

// ---------------------------------------------------------------------------
// Chunk content extraction tests
// ---------------------------------------------------------------------------

@test:Config {}
function testGetCoverageRationaleContent_Found() {
    ChunkStore store = {
        supplementary: [],
        core: [
            {file_name: "test", section_title: "Coverage Rationale", chunk_id: 1, chunk_content: "Coverage content here"},
            {file_name: "test", section_title: "Applicable Codes", chunk_id: 1, chunk_content: "Code content here"}
        ]
    };
    string result = getCoverageRationaleContent(store);
    test:assertEquals(result, "Coverage content here");
}

@test:Config {}
function testGetCoverageRationaleContent_MultipleChunks() {
    ChunkStore store = {
        supplementary: [],
        core: [
            {file_name: "test", section_title: "Coverage Rationale", chunk_id: 1, chunk_content: "Part 1"},
            {file_name: "test", section_title: "Coverage Rationale", chunk_id: 2, chunk_content: "Part 2"},
            {file_name: "test", section_title: "Applicable Codes", chunk_id: 1, chunk_content: "Codes"}
        ]
    };
    string result = getCoverageRationaleContent(store);
    test:assertTrue(result.includes("Part 1"));
    test:assertTrue(result.includes("Part 2"));
}

@test:Config {}
function testGetCoverageRationaleContent_NotFound() {
    ChunkStore store = {
        supplementary: [],
        core: [
            {file_name: "test", section_title: "Applicable Codes", chunk_id: 1, chunk_content: "Codes only"}
        ]
    };
    string result = getCoverageRationaleContent(store);
    test:assertEquals(result, "");
}

@test:Config {}
function testGetApplicableCodesContent_Found() {
    ChunkStore store = {
        supplementary: [],
        core: [
            {file_name: "test", section_title: "Coverage Rationale", chunk_id: 1, chunk_content: "Coverage"},
            {file_name: "test", section_title: "Applicable Codes", chunk_id: 1, chunk_content: "HCPCS J3032"},
            {file_name: "test", section_title: "Applicable Codes", chunk_id: 2, chunk_content: "G43.001 Migraine"}
        ]
    };
    string result = getApplicableCodesContent(store);
    test:assertTrue(result.includes("HCPCS J3032"));
    test:assertTrue(result.includes("G43.001 Migraine"));
}

@test:Config {}
function testGetApplicableCodesContent_NotFound() {
    ChunkStore store = {
        supplementary: [],
        core: [
            {file_name: "test", section_title: "Coverage Rationale", chunk_id: 1, chunk_content: "Coverage only"}
        ]
    };
    string result = getApplicableCodesContent(store);
    test:assertEquals(result, "");
}

// ---------------------------------------------------------------------------
// buildCoveragePrompt tests
// ---------------------------------------------------------------------------

@test:Config {}
function testBuildCoveragePrompt_ContainsContent() {
    string prompt = buildCoveragePrompt("Some coverage criteria", "test-policy");
    test:assertTrue(prompt.includes("Some coverage criteria"));
    test:assertTrue(prompt.includes("test-policy"));
    test:assertTrue(prompt.includes("Coverage Rationale"));
    test:assertTrue(prompt.includes("Do NOT include applicable diagnosis"));
}
