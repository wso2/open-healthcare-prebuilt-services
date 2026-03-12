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
import ballerina/http;
import ballerina/log;

function generate_template(string file_name, ChunkStore chunkstore) returns error? {
    string jobID = "job-" + file_name;
    log:printInfo("Template Generator Service Started");
    map<string[]> supplementaryData = getData(chunkstore.supplementary);
    string[] sectionTitles = extractTitles(supplementaryData);
    log:printInfo("Starting to vectorize supplementary data");
    check vectorizeSupplementaryData(supplementaryData, file_name);
    check sendNotification(jobID, file_name, "vectorization_and_ingestion_done");
    log:printInfo("Vectorized and stored supplementary data");
    log:printInfo("Starting to retrieve coverage chunks from the database");
    map<string[]> coverageData = getData(chunkstore.core);
    log:printInfo("Successfully retrieved coverage chunks from the database");
    PromptTemplate[] promptTemplates = check generatePromptTemplates(<string[]>coverageData[coverageData.keys()[0]], file_name, sectionTitles);
    check sendNotification(jobID, file_name, "scenarios_extracted");
    log:printInfo("Generated prompt templates to the database");
    check savePromptTemplate(file_name, promptTemplates);
    check sendNotification(jobID, file_name, "all_processing_done");
    log:printInfo("Template Generator Service Completed");
}

function extractTitles(map<string[]> chunks) returns string[] {
    string[] titles = [];
    foreach string sectionTitle in chunks.keys() {
        titles.push(sectionTitle);
    }
    return titles;
}

function vectorizeSupplementaryData(map<string[]> chunks, string file_name) returns error? {
    log:printDebug("Number of sections to process: " + chunks.keys().length().toString());
    foreach string sectionTitle in chunks.keys() {
        log:printInfo("Processing sectionTitle: " + sectionTitle);
        string[] supplementartyChunks = <string[]>chunks[sectionTitle];
        string supplementartyChunk = supplementartyChunks[0];
        ai:Metadata metadata = {
            "fileName": file_name,
            "sectionTitle": sectionTitle,
            "type": "supplementarty"
        };
        ai:TextDocument document = {
            content: supplementartyChunk,
            metadata: metadata
        };
        ai:Chunk[] chunkDocumentRecursively = check ai:chunkDocumentRecursively(document);
        error? res = aiVectorknowledgebase.ingest(chunkDocumentRecursively);
        if res is error {
            log:printError("Error ingesting supplementarty chunk into the vector store: " + res.message());
            return res;
        }
        log:printInfo("Ingested supplementarty chunk for sectionTitle: " + sectionTitle);
    }
}

function generatePromptTemplates(string[] coverageChunks, string file_name, string[] sectionTitles) returns PromptTemplate[]|error {
    string carryForwardContext = "";
    PromptTemplate[] promptTemplates = [];
    int sessionID = 1;
    foreach string chunk in coverageChunks {
        string finalChunk = chunk;
        if carryForwardContext != "" {
            finalChunk = carryForwardContext + "\n" + chunk;
        }
        string agentQuery = string `
            You are currently processing file: ${file_name}.
            The section titles available in the supplementary data are: ${sectionTitles.toString()}.
            Use the following context to create the prompt template:
            """
            ${finalChunk}
            """
        `;
        string llmResponse = check PromptTemplateGeneratorAgent.run(agentQuery, sessionID.toString());
        log:printDebug("LLM Response for chunk: " + llmResponse);
        json resp = check llmResponse.fromJsonString();
        PromptTemplateResponse templateRes = check resp.cloneWithType();
        if templateRes.promptTemplates.length() > 0 {
            promptTemplates.push(...templateRes.promptTemplates);
            log:printInfo("Generated " + templateRes.promptTemplates.length().toString() + " prompt templates from chunk.");
        } else {
            log:printInfo("No prompt templates generated from chunk.");
        }
        if templateRes.carryForwardContext is string {
            if carryForwardContext != "" {
                carryForwardContext += "\n" + <string>templateRes.carryForwardContext;
            } else {
                carryForwardContext = <string>templateRes.carryForwardContext;
            }
        } else {
            carryForwardContext = "";
        }
        sessionID += 1;
    }
    return promptTemplates;
}

function getData(PolicyChunk[] chunks) returns map<string[]> {
    map<string[]> policyData = {};
    foreach PolicyChunk chunk in chunks {
        // Only process chunks that match the requested filename
        string sectionTitle = chunk.section_title;
        log:printDebug("Processing sectionTitle: " + sectionTitle);
        if policyData.hasKey(sectionTitle) {
            (<string[]>policyData[sectionTitle]).push(chunk.chunk_content);
            log:printDebug("Appended chunkContext to existing sectionTitle: " + sectionTitle);
        } else {
            policyData[sectionTitle] = [chunk.chunk_content];
            log:printDebug("Created new entry for sectionTitle: " + sectionTitle);
        }
    }
    return policyData;
}

function savePromptTemplate(string file_name, PromptTemplate[] promptTemplates) returns error? {
    log:printInfo("Saving " + promptTemplates.length().toString() + " prompt templates for file: " + file_name);
    PromptStore promptStore = {
        templates: promptTemplates
    };
    string targetFileName = string `${file_name}.json`;
    error? res = fileClient->put("/prompts/" + targetFileName, promptStore.toJson());
    if res is error {
        log:printError("Error storing prompt templates to FTP server: " + res.message());
        return res;
    }
    log:printInfo("Prompt templates stored successfully to FTP server at /prompts/" + targetFileName);
    return;
}

function sendNotification(string jobID, string file_name, string message) returns error? {
    json params = {
        "status": "completed",
        "message": message,
        "job_id": jobID,
        "file_name": file_name
    };
    map<string> headers = {
        "Content-Type": "application/json"
    };
    http:Response response = check NOTIFICATION_CLIENT->post("", params, headers);
    json responseBody = check response.getJsonPayload();
    log:printInfo("UI notified successfully with response: " + responseBody.toJsonString());
}
