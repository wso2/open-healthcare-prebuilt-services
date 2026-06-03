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

import ballerina/ai;
import ballerina/log;
import ballerina/http;
import ballerina/io;
import ballerina/uuid;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.validator;
import ballerinax/health.fhir.r4.international401;

map<json> FHIR_QUESTIONNAIRE_STORE = {};
map<json> FAILED_SCENARIOS = {};
map<json> CQL_ENRICHED_BUNDLE_STORE = {};
const int GENERATOR_RETRY_LIMIT = 3;

// ---------------------------------------------------------------------------
// Main orchestration — reads chunks, generates one questionnaire from
// Coverage Rationale, then appends Applicable Codes as a dropdown.
// ---------------------------------------------------------------------------

function orchestrateGeneration(string fileName, string jobId) returns error? {
    check sendNotification("agent_conversation", "init", "orchestrator", 0, "", jobId, fileName);

    // 1. Read chunk store from storage
    ChunkStore chunkStore = check readChunkStore(fileName);
    log:printInfo("Loaded chunk store for: " + fileName);

    // 2. Extract coverage rationale and applicable codes from core chunks
    string coverageContent = getCoverageRationaleContent(chunkStore);
    string applicableCodesContent = getApplicableCodesContent(chunkStore);

    if coverageContent.length() == 0 {
        log:printError("No Coverage Rationale content found in chunks for: " + fileName);
        FAILED_SCENARIOS[fileName] = {"file_name": fileName, "reason": "No Coverage Rationale content found"};
        check sendNotification("agent_conversation", "end", "orchestrator", 0,
                "FAILED - No coverage rationale", jobId, fileName);
        check saveFHIRTemplates(fileName, jobId);
        return error("No Coverage Rationale content found in chunks for: " + fileName);
    }

    // 3. Build prompt from coverage rationale
    string prompt = buildCoveragePrompt(coverageContent, fileName);

    check sendNotification("agent_conversation", "started", "orchestrator", 0,
            "Starting questionnaire generation for: " + fileName, jobId, fileName);

    // 4. Run generator → reviewer loop (single questionnaire)
    string sessionId = uuid:createRandomUuid();
    string cleanJson = "";
    string lastFeedback = "";
    string lastValidation = "";
    boolean isApproved = false;

    foreach int iteration in 0 ..< AGENT_CONV_LIMIT {
        // --- Phase 1: Generator ---
        int genRetryCnt = 0;
        string? extracted = ();
        while genRetryCnt < GENERATOR_RETRY_LIMIT {
            string rawResponse;
            if iteration == 0 && genRetryCnt == 0 {
                rawResponse = check queryAgent(_QuestionnaireGeneratorAgent, prompt, sessionId);
            } else if iteration == 0 {
                rawResponse = check queryAgent(_QuestionnaireGeneratorAgent,
                        "Your previous response was not valid FHIR Questionnaire JSON. "
                        + "Please re-generate the questionnaire for the original request as a single raw JSON object.",
                        sessionId);
            } else {
                string revisionPrompt = buildRevisionPrompt(lastFeedback, lastValidation, iteration);
                rawResponse = check queryAgent(_QuestionnaireGeneratorAgent, revisionPrompt, sessionId);
            }
            genRetryCnt += 1;

            extracted = extractQuestionnaireJson(rawResponse);
            if extracted is string {
                cleanJson = extracted;
                break;
            }
            log:printWarn(string `Generator attempt ${genRetryCnt}/${GENERATOR_RETRY_LIMIT} did not produce valid JSON for "${fileName}".`);
        }

        if extracted is () {
            log:printError(string `Generator failed after ${genRetryCnt} attempts for "${fileName}".`);
            break;
        }

        error? resGen = sendNotification("agent_conversation", "in-progress", "generator",
                iteration, cleanJson, jobId, fileName);
        if resGen is error {
            log:printError("Error sending generator notification: " + resGen.message());
        }

        // --- Phase 2: FHIR Structural Validation ---
        json parsedJson = check cleanJson.fromJsonString();
        lastValidation = validateFHIRTemplate(parsedJson);
        log:printDebug(string `FHIR Validation [iteration ${iteration}]: ${lastValidation}`);

        // --- Phase 3: Reviewer (coverage rationale only — applicable codes excluded) ---
        string reviewerInput = buildReviewerInput(cleanJson, lastValidation);
        lastFeedback = check queryAgent(_ReviewerAgent, reviewerInput, sessionId);

        // --- Phase 4: Evaluate Reviewer Verdict ---
        ReviewSeverity severity = parseReviewSeverity(lastFeedback);

        if severity.critical == 0 && severity.errors == 0 {
            string endStatus = severity.warnings > 0 ? "approved-with-warnings" : "approved";
            log:printInfo(string `Reviewer ${endStatus} questionnaire "${fileName}" at iteration ${iteration}.`);

            error? resRevEnd = sendNotification("agent_conversation", "end", "reviewer",
                    iteration, lastFeedback, jobId, fileName);
            if resRevEnd is error {
                log:printError("Error sending reviewer notification: " + resRevEnd.message());
            }
            isApproved = true;
            break;
        }

        log:printInfo(string `Reviewer iteration ${iteration} for "${fileName}": ${severity.critical} critical, ${severity.errors} errors, ${severity.warnings} warnings.`);
        error? resRev = sendNotification("agent_conversation", "in-progress", "reviewer",
                iteration, lastFeedback, jobId, fileName);
        if resRev is error {
            log:printError("Error sending reviewer notification: " + resRev.message());
        }
    }

    if !isApproved {
        log:printError("Failed to get approval for questionnaire: " + fileName);
        FAILED_SCENARIOS[fileName] = {"file_name": fileName, "reason": "Failed to get reviewer approval"};
        check sendNotification("agent_conversation", "end", "orchestrator", 0, "FAILED", jobId, fileName);
        check saveFHIRTemplates(fileName, jobId);
        return;
    }

    // 5. After approval, append applicable codes as a single dropdown question via one LLM call
    if applicableCodesContent.length() > 0 {
        log:printInfo("Appending applicable codes question to finalized questionnaire for: " + fileName);
        string|error codesResult = appendApplicableCodesQuestion(cleanJson, applicableCodesContent);
        if codesResult is error {
            log:printWarn("Failed to append applicable codes, saving questionnaire without them: " + codesResult.message());
        } else {
            cleanJson = codesResult;
            log:printInfo("Applicable codes question appended successfully for: " + fileName);
        }
    }

    // 6. Store final questionnaire
    FHIR_QUESTIONNAIRE_STORE[fileName] = check cleanJson.fromJsonString();

    // 7. Enrich questionnaire with CQL via the CQL Enrichment API
    log:printInfo("Enriching questionnaire with CQL for: " + fileName);
    json|error enrichedBundle = enrichWithCQL(check cleanJson.fromJsonString());
    if enrichedBundle is error {
        log:printWarn("CQL enrichment failed, saving unenriched questionnaire: " + enrichedBundle.message());
    } else {
        CQL_ENRICHED_BUNDLE_STORE[fileName] = enrichedBundle;
        log:printInfo("CQL enrichment completed for: " + fileName);
    }

    check sendNotification("agent_conversation", "end", "orchestrator", 0, "", jobId, fileName);
    check saveFHIRTemplates(fileName, jobId);
    log:printInfo("Questionnaire generation completed for: " + fileName);
}

// ---------------------------------------------------------------------------
// Chunk storage reading
// ---------------------------------------------------------------------------

function readChunkStore(string fileName) returns ChunkStore|error {
    string filePath = string `/chunks/${fileName}.json`;
    string content = check readFromStorage(filePath);
    json jsonContent = check content.fromJsonString();
    return check jsonContent.cloneWithType(ChunkStore);
}

function readFromStorage(string path) returns string|error {
    string fullPath = LOCAL_STORAGE_PATH + path;
    log:printDebug("Reading from local storage: " + fullPath);
    return check io:fileReadString(fullPath);
}

// ---------------------------------------------------------------------------
// Chunk content extraction
// ---------------------------------------------------------------------------

function getCoverageRationaleContent(ChunkStore chunkStore) returns string {
    string content = "";
    foreach PolicyChunk chunk in chunkStore.core {
        if chunk.section_title == "Coverage Rationale" {
            if content.length() > 0 {
                content += "\n\n";
            }
            content += chunk.chunk_content;
        }
    }
    return content.trim();
}

function getApplicableCodesContent(ChunkStore chunkStore) returns string {
    string content = "";
    foreach PolicyChunk chunk in chunkStore.core {
        if chunk.section_title == "Applicable Codes" {
            if content.length() > 0 {
                content += "\n\n";
            }
            content += chunk.chunk_content;
        }
    }
    return content.trim();
}

// ---------------------------------------------------------------------------
// Prompt builders
// ---------------------------------------------------------------------------

function buildCoveragePrompt(string coverageContent, string fileName) returns string {
    return string `Generate a FHIR R4 Questionnaire based on the following coverage policy document.
The questionnaire should capture all clinical criteria, conditions, and requirements specified in the coverage rationale.
Convert each coverage criterion into appropriate FHIR Questionnaire items with proper types, conditional logic (enableWhen), and grouping.

Policy Document: ${fileName}

## Coverage Rationale:
${coverageContent}

Requirements:
1. Create a single comprehensive FHIR Questionnaire that covers ALL criteria in the coverage rationale
2. Use appropriate question types (boolean for yes/no criteria, choice for selection lists, string for free-text, date for date fields, integer for numeric values)
3. Implement enableWhen conditional logic where criteria depend on prior answers (e.g., initial therapy vs continuation)
4. Group related criteria into logical sections using group items (e.g., "Initial Therapy" group, "Continuation of Therapy" group)
5. Set required=true for mandatory criteria
6. The title should be derived from the policy name
7. Status should be "draft"
8. Ensure hierarchical criteria (e.g., "all of the following", "one of the following") are properly represented with nested groups and conditional logic
9. Do NOT include applicable diagnosis or procedure codes as questions — those will be added separately`;
}

// ---------------------------------------------------------------------------
// Applicable codes: lightweight LLM extraction + programmatic FHIR construction
// ---------------------------------------------------------------------------
const int APPLICABLE_CODES_RETRY_LIMIT = 3;

// Orchestrates: (1) extract codes via a small LLM call, (2) programmatically
// build FHIR choice items grouped by code type, (3) append to questionnaire JSON.
function appendApplicableCodesQuestion(string questionnaireJson, string applicableCodesContent) returns string|error {
    // Step 1: Use LLM only to extract structured codes from the ambiguous content
    // (sends only the codes text — NOT the entire questionnaire, saving tokens)
    CodeEntry[] codes = check extractCodesViaLLM(applicableCodesContent);
    if codes.length() == 0 {
        log:printWarn("No codes extracted from applicable codes content");
        return questionnaireJson;
    }
    log:printInfo(string `Extracted ${codes.length()} codes, building FHIR items programmatically.`);

    // Step 2: Programmatically build and append FHIR items to the questionnaire
    return appendCodeItemsToQuestionnaire(questionnaireJson, codes);
}

// Send only the applicable codes content to the LLM to extract a structured
// list of codes. This is a lightweight call — no questionnaire JSON is sent.
function extractCodesViaLLM(string applicableCodesContent) returns CodeEntry[]|error {
    string prompt = string `Extract all medical codes from the following content. Categorize each code as one of: "HCPCS", "CPT", or "ICD-10".

Rules for categorization:
- HCPCS codes start with a letter followed by digits (e.g., J3032)
- CPT codes are 5-digit numeric codes (e.g., 96413)
- ICD-10 diagnosis codes start with a letter, followed by digits, and often contain a dot (e.g., G43.001)
- Include the full description for each code

Return a JSON object in this exact format:
{"codes": [{"code": "<code>", "description": "<description>", "codeType": "<HCPCS|CPT|ICD-10>"}]}

Content:
${applicableCodesContent}

Output ONLY the raw JSON object.`;

    int attempt = 0;
    while attempt < APPLICABLE_CODES_RETRY_LIMIT {
        attempt += 1;
        do {
            string rawResponse = check _AnthropicModelProvider->generate(`${prompt}`);
            string trimmed = rawResponse.trim();
            int? startIdx = trimmed.indexOf("{");
            int? endIdx = trimmed.lastIndexOf("}");
            if startIdx is int && endIdx is int && endIdx > startIdx {
                string jsonStr = trimmed.substring(startIdx, endIdx + 1);
                json parsed = check jsonStr.fromJsonString();
                ExtractedCodes result = check parsed.cloneWithType();
                log:printInfo(string `LLM extracted ${result.codes.length()} codes on attempt ${attempt}.`);
                return result.codes;
            }
            log:printWarn(string `Code extraction attempt ${attempt}/${APPLICABLE_CODES_RETRY_LIMIT}: no valid JSON in response.`);
        } on fail error e {
            log:printWarn(string `Code extraction attempt ${attempt}/${APPLICABLE_CODES_RETRY_LIMIT} failed: ${e.message()}`);
        }
    }
    return error("Failed to extract codes after " + APPLICABLE_CODES_RETRY_LIMIT.toString() + " attempts");
}

// Programmatically parse the questionnaire JSON, build separate FHIR choice
// items for each code type (HCPCS, CPT, ICD-10), and append them.
function appendCodeItemsToQuestionnaire(string questionnaireJson, CodeEntry[] codes) returns string|error {
    json parsed = check questionnaireJson.fromJsonString();
    map<json> questionnaire = check parsed.cloneWithType();
    json[] items = check (questionnaire["item"]).cloneWithType();
    int nextLinkId = getNextRootLinkId(items);

    // Group codes by type
    CodeEntry[] hcpcsCodes = from CodeEntry c in codes where c.codeType == "HCPCS" select c;
    CodeEntry[] cptCodes = from CodeEntry c in codes where c.codeType == "CPT" select c;
    CodeEntry[] icd10Codes = from CodeEntry c in codes where c.codeType == "ICD-10" select c;

    if hcpcsCodes.length() > 0 {
        items.push(buildCodeChoiceItem(nextLinkId.toString(), "Applicable HCPCS Code",
                hcpcsCodes, "https://www.cms.gov/Medicare/Coding/HCPCSReleaseCodeSets"));
        nextLinkId += 1;
    }
    if cptCodes.length() > 0 {
        items.push(buildCodeChoiceItem(nextLinkId.toString(), "Applicable CPT Code",
                cptCodes, "http://www.ama-assn.org/go/cpt"));
        nextLinkId += 1;
    }
    if icd10Codes.length() > 0 {
        items.push(buildCodeChoiceItem(nextLinkId.toString(), "Applicable Diagnosis Code (ICD-10)",
                icd10Codes, "http://hl7.org/fhir/sid/icd-10-cm"));
    }

    questionnaire["item"] = items;
    return questionnaire.toJsonString();
}

// Build a single FHIR choice item with answerOptions from a list of codes.
function buildCodeChoiceItem(string linkId, string text, CodeEntry[] codes, string system) returns json {
    json[] answerOptions = [];
    foreach CodeEntry code in codes {
        answerOptions.push({
            "valueCoding": {
                "system": system,
                "code": code.code,
                "display": code.description
            }
        });
    }
    return {
        "linkId": linkId,
        "text": text,
        "type": "choice",
        "required": true,
        "repeats": false,
        "answerOption": answerOptions
    };
}

// Scan root-level items to find the highest numeric linkId.
function getNextRootLinkId(json[] items) returns int {
    int maxId = 0;
    foreach json item in items {
        json|error linkIdJson = item.linkId;
        if linkIdJson is string {
            int|error numId = int:fromString(linkIdJson);
            if numId is int && numId > maxId {
                maxId = numId;
            }
        }
    }
    return maxId + 1;
}

// Build a structured revision prompt that gives the generator the reviewer's
// severity-tagged feedback plus the FHIR validator output.
function buildRevisionPrompt(string reviewerFeedback, string fhirValidation, int iteration) returns string {
    string prompt = string `## Reviewer Feedback (Iteration ${iteration})
${reviewerFeedback}`;

    if fhirValidation != "This is a valid FHIR Resource." {
        prompt += string `

## FHIR Structural Validation Result
${fhirValidation}`;
    }

    prompt += "\n\nRevise the questionnaire to address all CRITICAL and ERROR findings above. "
            + "Preserve items that were not flagged. Respond with the full corrected JSON only.";
    return prompt;
}

// Build the input message for the reviewer, combining the questionnaire JSON
// with the FHIR validator result so the reviewer has full context.
function buildReviewerInput(string questionnaireJson, string fhirValidation) returns string {
    string input = string `## FHIR Questionnaire JSON
${questionnaireJson}`;

    if fhirValidation != "This is a valid FHIR Resource." {
        input += string `

## FHIR Structural Validation Result
${fhirValidation}`;
    } else {
        input += "\n\n## FHIR Structural Validation Result\nPassed — no structural errors detected.";
    }
    return input;
}

// ---------------------------------------------------------------------------
// JSON extraction & validation
// ---------------------------------------------------------------------------

// Attempt to extract a clean FHIR Questionnaire JSON string from a raw
// generator response. Returns the clean JSON string if successful, or ()
// if no valid Questionnaire JSON could be found.
function extractQuestionnaireJson(string response) returns string? {
    // Fast path: the entire response is valid JSON with resourceType Questionnaire
    string trimmed = response.trim();
    string? result = tryParseQuestionnaire(trimmed);
    if result is string {
        return result;
    }

    // Fallback: extract the outermost {...} block from the response
    int? startIndex = trimmed.indexOf("{");
    int? endIndex = trimmed.lastIndexOf("}");
    if startIndex is () || endIndex is () || endIndex <= startIndex {
        return ();
    }
    string jsonCandidate = trimmed.substring(startIndex, endIndex + 1);
    return tryParseQuestionnaire(jsonCandidate);
}

// Try to parse a string as JSON and verify it has resourceType "Questionnaire".
// Returns the original string if valid, () otherwise.
function tryParseQuestionnaire(string candidate) returns string? {
    do {
        json parsed = check candidate.fromJsonString();
        if parsed.resourceType is string && parsed.resourceType == "Questionnaire" {
            return candidate;
        }
        return ();
    } on fail {
        return ();
    }
}

// Backward-compatible boolean wrapper around extractQuestionnaireJson.
function isValidGeneratorResponse(string response) returns boolean {
    return extractQuestionnaireJson(response) is string;
}

// ---------------------------------------------------------------------------
// Reviewer severity parsing
// ---------------------------------------------------------------------------

// Parse the reviewer's feedback to count severity tags.
function parseReviewSeverity(string feedback) returns ReviewSeverity {
    string lower = feedback.toLowerAscii();

    // Explicit APPROVED with no findings
    if lower.trim() == "approved" {
        return {critical: 0, errors: 0, warnings: 0};
    }

    int critical = countOccurrences(lower, "[critical]");
    int errors = countOccurrences(lower, "[error]");
    int warnings = countOccurrences(lower, "[warning]");

    return {critical, errors, warnings};
}

// Count non-overlapping occurrences of a substring within a string.
function countOccurrences(string text, string substring) returns int {
    int count = 0;
    int searchFrom = 0;
    while true {
        int? idx = text.indexOf(substring, searchFrom);
        if idx is () {
            break;
        }
        count += 1;
        searchFrom = idx + substring.length();
    }
    return count;
}

// ---------------------------------------------------------------------------
// Agent communication
// ---------------------------------------------------------------------------

function queryAgent(http:Client agentClient, string message, string session_id) returns string|error {
    json payload = {
        "message": message,
        "sessionId": session_id
    };
    map<string> headers = {
        "Content-Type": "application/json"
    };
    json response = check agentClient->post("/chat", payload, headers);
    ai:ChatRespMessage res = check response.cloneWithType();
    return res.message;
}

// ---------------------------------------------------------------------------
// FHIR validation
// ---------------------------------------------------------------------------

function validateFHIRTemplate(json fhirTemplate) returns string {
    string validatorResponse = "This is a valid FHIR Resource.";
    r4:FHIRValidationError? validateFHIRResourceJson = validator:validate(fhirTemplate, international401:Questionnaire);

    if validateFHIRResourceJson is r4:FHIRValidationError {
        log:printError(validateFHIRResourceJson.toString());
        validatorResponse = "FHIR Validation Errors: " + validateFHIRResourceJson.toString();
    }
    return validatorResponse;
}

// ---------------------------------------------------------------------------
// CQL Enrichment — calls the CQL Enrichment API to produce an enriched bundle
// ---------------------------------------------------------------------------

function enrichWithCQL(json questionnaire) returns json|error {
    http:Response response = check CQL_ENRICHMENT_CLIENT->post("/api/enrich", questionnaire, {"Content-Type": "application/json"});
    if response.statusCode != 200 {
        string|error body = response.getTextPayload();
        string errMsg = body is string ? body : "Unknown error";
        return error(string `CQL Enrichment API returned ${response.statusCode}: ${errMsg}`);
    }

    json responseBody = check response.getJsonPayload();

    // The API returns: { success, enrichedQuestionnaire, cqlLibrary, valueSets, questionnairePackageBundle, stats }
    // Use the questionnairePackageBundle which is already a FHIR Bundle (collection) with
    // Questionnaire, Library, and ValueSet entries
    json|error packageBundle = responseBody.questionnairePackageBundle;
    if packageBundle is error {
        return error("CQL Enrichment API response missing questionnairePackageBundle");
    }

    log:printInfo("CQL Enrichment API returned bundle successfully");
    return packageBundle;
}

// ---------------------------------------------------------------------------
// Persistence & notifications
// ---------------------------------------------------------------------------

function saveFHIRTemplates(string file_name, string job_id) returns error? {
    // Use CQL-enriched bundle if available, otherwise build a basic bundle from questionnaire store
    json bundle;
    if CQL_ENRICHED_BUNDLE_STORE.hasKey(file_name) {
        bundle = CQL_ENRICHED_BUNDLE_STORE[file_name];
        log:printInfo("Using CQL-enriched bundle for: " + file_name);
    } else {
        json[] bundleEntries = [];
        json questionnaire = FHIR_QUESTIONNAIRE_STORE[file_name];
        bundleEntries.push({"resource": questionnaire});
        bundle = {
            "resourceType": "Bundle",
            "type": "collection",
            "entry": bundleEntries
        };
        log:printInfo("Using unenriched questionnaire bundle for: " + file_name);
    }

    QuestionnaireUploadPayload payload = {
        file_name: file_name,
        job_id: job_id,
        bundle: bundle,
        failed_scenarios: FAILED_SCENARIOS
    };
    map<string> headers = {
        "Content-Type": "application/json"
    };
    http:Response response = check POLICY_FLOW_ORCHESTRATOR_CLIENT->post("/questionnaires", payload, headers);
    json responseBody = check response.getJsonPayload();
    if response.statusCode != 200 {
        log:printError("Failed to store FHIR template. Response: " + responseBody.toJsonString());
        return error("Failed to store FHIR template in the FHIR Repository.");
    }
}

function sendNotification(string message, string status, string agent, int cnt,
        string agent_response, string job_id, string file_name) returns error? {
    json params = {
        "job_id": job_id,
        "message": message,
        "status": status,
        "agent": agent,
        "iteration_cnt": cnt,
        "response": agent_response,
        "file_name": file_name
    };
    map<string> headers = {
        "Content-Type": "application/json"
    };
    http:Response response = check POLICY_FLOW_ORCHESTRATOR_CLIENT->post("/notification", params, headers);
    if response.statusCode == 200 || response.statusCode == 202 || response.statusCode == 204 {
        json|error responseBody = response.getJsonPayload();
        if responseBody is json {
            log:printInfo("Policy preprocessor notified with response: " + responseBody.toJsonString());
        } else {
            log:printInfo("Policy preprocessor notified successfully. Status: " + response.statusCode.toString());
        }
    } else {
        return error("Failed to send notification. Status: " + response.statusCode.toString());
    }
}
