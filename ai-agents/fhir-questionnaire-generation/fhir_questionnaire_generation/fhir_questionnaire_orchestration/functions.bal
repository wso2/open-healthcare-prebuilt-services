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

import ballerina/ai;
import ballerina/log;
import ballerina/http;
import ballerina/uuid;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.validator;
import ballerinax/health.fhir.r4.davincidtr210;

map<json> FHIR_QUESTIONNAIRE_STORE = {};
map<PromptTemplate> FAILED_SCENARIOS = {};
const int GENERATOR_RETRY_LIMIT = 3;

function orchestrateConversation(PromptTemplate[] templates, string file_name) returns error? {
    string job_id = "job-" + file_name;
    int cnt = 1;
    check sendNotification("agent_conversation", "init", "orchestrator", 0, "", job_id, file_name);
    foreach PromptTemplate template in templates{
        string title = template.title;
        check sendNotification("agent_conversation", "started", "orchestrator", 0, "Starting process template: " + title, job_id, file_name);
        string session_id = uuid:createRandomUuid() + string`_${cnt}`;
        string generator_agent_res = "";
        string last_feedback = "";
        int gen_retry_cnt = 0;
        boolean isApproved = false;
        foreach int i in 0..<AGENT_CONV_LIMIT{
            while (gen_retry_cnt <= GENERATOR_RETRY_LIMIT && isValidGeneratorResponse(generator_agent_res)) {
                if i == 0 {
                    generator_agent_res = check queryAgent(_QuestionnaireGeneratorAgent, template.prompt, session_id);
                } else {
                    string message_to_generator = string `Previous reviewer feedback: ${last_feedback}\n\nPlease revise based on this feedback.`;
                    generator_agent_res = check queryAgent(_QuestionnaireGeneratorAgent, message_to_generator, session_id);
                }
                gen_retry_cnt += 1;
            }

            if (!isValidGeneratorResponse(generator_agent_res)) {
                log:printError("Generator agent failed to produce a valid FHIR Questionnaire after " + gen_retry_cnt.toString() + " attempts.");
                FAILED_SCENARIOS[title] = template;
                break;
            }

            error? res_gen = sendNotification("agent_conversation", "in-progress", "generator", i, generator_agent_res, job_id, file_name);
            if res_gen is error {
                log:printError("Error sending UI notification for generator agent: " + res_gen.message());
            }

            log:printDebug("Validating FHIR Template");
            string validation_response = validateFHIRTemplate(check generator_agent_res.fromJsonString());
            log:printDebug("FHIR Validation Response: " + validation_response);

            last_feedback = check queryAgent(_ReviewerAgent, generator_agent_res, session_id);
            if last_feedback.toLowerAscii().includes("approved"){
                error? res_rev_end = sendNotification("agent_conversation", "end", "reviewer", i, last_feedback, job_id, file_name); 
                if res_rev_end is error {
                    log:printError("Error sending UI notification for reviewer agent: " + res_rev_end.message());
                }
                isApproved = true;
                break;
            }   
            error? res_rev = sendNotification("agent_conversation", "in-progress", "reviewer", i, last_feedback, job_id, file_name);
            if res_rev is error {
                log:printError("Error sending UI notification for reviewer agent: " + res_rev.message());
            } 
            cnt += 1;
        }
        if (!isApproved) {
            log:printError("Failed to get approval from reviewer for template: " + title);
            FAILED_SCENARIOS[title] = template;
            continue;
        }
        json fhir_questionnaire = generator_agent_res.toJson();
        FHIR_QUESTIONNAIRE_STORE[title] = fhir_questionnaire;
    }
    check sendNotification("agent_conversation", "end", "orchestrator", 0, "", job_id, file_name);
    check saveFHIRTemplates(file_name, job_id);
}

function isValidGeneratorResponse(string response) returns boolean {
    do {
        json parsed = check response.fromJsonString();
        if parsed.resourceType is string && parsed.resourceType == "Questionnaire" {
            return true;
        } else {
            return false;
        }
    } on fail error e{
        log:printError("Exception occrured" + e.message());
        do {
            // Try to get find the json within the response string
            int? startIndex = response.indexOf("{");
            if startIndex == (){
                log:printError("JSON response not found!");
                return false;
            }
            int? endIndex = response.lastIndexOf("}");
            if endIndex == (){
                log:printError("JSON response not found!");
                return false;
            }
            string jsonString = response.substring(startIndex, endIndex + 1);
            json parsed = check jsonString.fromJsonString();
            if parsed.resourceType is string && parsed.resourceType == "Questionnaire" {
                return true;
            } else {
                return false;
            }
        } on fail error e2 {
            log:printError("Failed to extract JSON from the response." + e2.message());
            return false;
        }
    }
}

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

function validateFHIRTemplate(json fhirTemplate) returns string {
    string validatorResponse = "This is a valid FHIR Resource.";
    r4:FHIRValidationError? validateFHIRResourceJson = validator:validate(fhirTemplate, davincidtr210:DTRStdQuestionnaire);

    if validateFHIRResourceJson is r4:FHIRValidationError {
        log:printError(validateFHIRResourceJson.toString());
        validatorResponse = "FHIR Validation Errors: " + validateFHIRResourceJson.toString();
    }
    return validatorResponse;
}

function saveFHIRTemplates(string file_name, string job_id) returns error? {
    QuestionnaireUploadPayload payload = {
        file_name: file_name,
        job_id: job_id,
        questionnaires: FHIR_QUESTIONNAIRE_STORE,
        failed_scenarios: FAILED_SCENARIOS
    };
    map<string> headers = {
        "Content-Type": "application/json"
    }; 
    http:Response response = check POLICY_FLOW_ORCHESTRATOR_CLIENT->post("/questionnaires", payload, headers);
    json responseBody = check response.getJsonPayload();
    if response.statusCode != 200 {
        log:printError("Failed to store FHIR template in the FHIR Repository. Response: " + responseBody.toJsonString());
        return error("Failed to store FHIR template in the FHIR Repository.");
    }
}

function sendNotification(string message, string status, string agent, int cnt, string agent_response, string job_id, string file_name) returns error? {
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
    json responseBody = check response.getJsonPayload();
    log:printInfo("UI notified successfully with response: " + responseBody.toJsonString());
}
