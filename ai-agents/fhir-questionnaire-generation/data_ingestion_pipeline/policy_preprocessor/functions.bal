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

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/time;

function chunk_document(string fileName, string jobId) returns error? {
    log:printInfo("Starting document chunking for file: " + fileName + " with jobID: " + jobId);
    string fileContent = check readFileContent(fileName);
    log:printInfo("Processing file: " + fileName + " with content length: " + fileContent.length().toString());
    string[] sectionTitles = SECTION_TITLES;
    if SECTION_TITLES.length() > 0 {
        log:printInfo("Using predefined section titles for document splitting.");
    } else {
        // Get the first 3000 characters of the document to extract the table of contents.
        string tocExtractionContent = fileContent.length() > 3000 ? fileContent.substring(0, 3000) : fileContent;
        log:printDebug("Extracted text: >>>> " + tocExtractionContent);
        string[]|error res = readTableofContent(tocExtractionContent);
        if res is error {
            log:printError("Error extracting table of contents: " + res.message());
            return error("Failed to extract table of contents: " + res.message());
        }
        sectionTitles = res;
        log:printInfo("No predefined section titles found. Extracting table of contents using LLM.");
    }
    map<string> sections = check splitDocument(fileContent, sectionTitles);
    log:printInfo("Document split into sections successfully for file: " + fileName);
    ClassificationResponse classificationResult = SECTION_CLASSIFICATIONS;
    _ = check writeChunksToMemory(sections, classificationResult, fileName, jobId);
    log:printInfo("Chunks written to storage for jobID: " + jobId);
    log:printInfo("Template Generator Service Completed for file: " + fileName);
}

function readFileContent(string fileName) returns string|error {
    stream<byte[] & readonly, io:Error?> fileBytes = check storageGet(string `/md/${fileName}.md`);
    string mdFileContent = "";
    byte[][] & readonly chunks = check from byte[] & readonly chunk in fileBytes
        select chunk;
    foreach byte[] & readonly chunk in chunks {
        mdFileContent += check string:fromBytes(chunk);
    }
    return mdFileContent;
}

function readTableofContent(string fileContent) returns string[]|error {
    string llmResponse = check anthropicModelprovider->generate(
        `Extract the table of contents from the following segment of the document:
        ${fileContent}
        Provide the response in this json format:
        {
            "response": [<"Section Title 1">, <"Section Title 2">, ...]
        }
        Make sure to only include the section titles and nothing else. Do Not include any page numbers. or traling punctuation in the titles.
        `
    );
    log:printInfo("LLM Response received.");
    log:printDebug("LLM Response: " + llmResponse);
    json resp = check llmResponse.fromJsonString();
    ToCResponse titles = check resp.cloneWithType();
    string[] sectionTitles = titles.response;
    return sectionTitles;
}

function splitDocument(string documentContent, string[] sectionTitles) returns map<string>|error {
    log:printInfo("Splitting document into sections based on titles.");
    map<string> sections = {};
    map<int> titleIndices = {};
    int searchStartIndex = 0;
    
    foreach string title in sectionTitles {
        int? index = documentContent.indexOf(title, searchStartIndex);
        if index is () {
            log:printError("Title not found in document: " + title + " after index: " + searchStartIndex.toString());
            return error("Title not found in document: " + title);
        }
        int cur_index = index;
        while !isValidTitle(documentContent, title, cur_index) {
            int? new_index = documentContent.indexOf(title, cur_index + 1);
            if new_index is () {
                log:printWarn("No valid title found for: " + title + ". Using last occurrence at index: " + cur_index.toString());
                break;
            }
            cur_index = new_index;
        }
        log:printDebug("Title found at index: " + cur_index.toString() + " for title: " + title);
        titleIndices[title] = cur_index;
        searchStartIndex = cur_index + title.length();
    }
    
    int titleCount = sectionTitles.length();
    foreach int i in 0 ..< titleCount {
        string title = sectionTitles[i];
        int startIndex = <int>titleIndices[title];
        int endIndex = documentContent.length();
        if i < titleCount - 1 {
            string nextTitle = sectionTitles[i + 1];
            endIndex = <int>titleIndices[nextTitle];
        }
        string sectionContent = documentContent.substring(startIndex, endIndex).trim();
        sections[title] = sectionContent;
        log:printDebug("Section extracted for title: " + title + " with length: " + sectionContent.length().toString());
    }
    log:printInfo("Document successfully split into sections.");
    return sections;
}

function writeChunksToMemory(map<string> sections, ClassificationResponse classification, string fileName, string jobID) returns ChunkStore|error {
    string[] coverageTitles = [];
    string[] supplementaryTitles = [];
    PolicyChunk[] supplementaryChunks = [];
    PolicyChunk[] coreChunks = [];
    foreach SectionClassfication section in classification.response {
        if section.category == "Coverage Details" {
            coverageTitles.push(...section.titles);
        } else if section.category == "Supplementary Information" {
            supplementaryTitles.push(...section.titles);
        }
    }
    foreach string coverageTitle in coverageTitles {
        if sections.hasKey(coverageTitle) {
            string[] coverageContent = [<string>sections[coverageTitle]];
            string[] chunks = recursive_splitter(coverageContent);
            int chunkCount = chunks.length();
            foreach int i in 0 ..< chunkCount {
                string chunk = chunks[i];
                PolicyChunk policyChunk = {
                    file_name: fileName,
                    section_title: coverageTitle,
                    chunk_id: i + 1,
                    chunk_content: chunk
                };
                coreChunks.push(policyChunk);
            }
        } else {
            log:printWarn("Coverage Details title not found in sections: " + coverageTitle);
        }
    }
    foreach string title in supplementaryTitles {
        if sections.hasKey(title) {
            string suppContent = <string>sections[title];
            PolicyChunk policyChunk = {
                file_name: fileName,
                section_title: title,
                chunk_id: 1,
                chunk_content: suppContent
            };
            supplementaryChunks.push(policyChunk);
        } else {
            log:printWarn("Supplementary Information title not found in sections: " + title);
        }
    }
    string targetFileName = string `${fileName}.json`;
    ChunkStore chunkStore = {
        supplementary: supplementaryChunks,
        core: coreChunks
    };
    check storagePut("/chunks/" + targetFileName, chunkStore.toJson());
    log:printInfo("Chunks stored successfully at /chunks/" + targetFileName);
    return chunkStore;
}

function sendNotification(NotificationPayload payload) returns error? {
    if (payload.message == "pdf_to_md_done" && payload.status == "completed") {
        log:printInfo(string `PDF to MD conversion completed for file: ${payload.file_name}, job: ${payload.job_id}`);
        log:printInfo("Starting data preprocessing and questionnaire generation flow...");

        // Update job metadata
        string jobKey = payload.file_name + "_" + payload.job_id;
        lock {
            JobMetadata? metadata = JOB_METADATA_STORE[jobKey];
            if metadata is JobMetadata {
                metadata.status = STATUS_PDF_TO_MD_CONVERSION_ENDED;
                metadata.error_message = ();
                JOB_METADATA_STORE[jobKey] = metadata;
            } else {
                JobMetadata newMetadata = {
                    job_id: payload.job_id,
                    file_name: payload.file_name,
                    status: STATUS_PDF_TO_MD_CONVERSION_ENDED,
                    created_at: time:utcToString(time:utcNow()),
                    error_message: ()
                };
                JOB_METADATA_STORE[jobKey] = newMetadata;
            }
        }

        // Start preprocessing and questionnaire generation in background
        _ = start processDocumentFlow(payload.file_name, payload.job_id);
    } else if (payload.status == "failed") {
        log:printError(string `PDF to MD conversion failed for file: ${payload.file_name}, job: ${payload.job_id}, message: ${payload.message}`);

        // Update job metadata with error
        string jobKey = payload.file_name + "_" + payload.job_id;
        lock {
            JobMetadata metadata = {
                job_id: payload.job_id,
                file_name: payload.file_name,
                status: "failed",
                created_at: time:utcToString(time:utcNow()),
                error_message: payload.message
            };
            JOB_METADATA_STORE[jobKey] = metadata;
        }
    }
}

function processDocumentFlow(string fileName, string jobId) returns error? {
    string jobKey = fileName + "_" + jobId;

    lock {
        JobMetadata? metadata = JOB_METADATA_STORE[jobKey];
        if metadata is JobMetadata {
            metadata.status = STATUS_PREPROCESSING_STARTED;
            metadata.error_message = ();
            JOB_METADATA_STORE[jobKey] = metadata;
        }
    }

    // Step 1: Chunk document and generate prompt templates
    error? chunkResult = chunk_document(fileName, jobId);
    if chunkResult is error {
        log:printError(string `Document chunking failed for file: ${fileName}, error: ${chunkResult.message()}`);
        lock {
            JobMetadata? metadata = JOB_METADATA_STORE[jobKey];
            if metadata is JobMetadata {
                metadata.status = "failed";
                metadata.error_message = "Document chunking failed: " + chunkResult.message();
                JOB_METADATA_STORE[jobKey] = metadata;
            }
        }
        return chunkResult;
    }

    log:printInfo(string `Document preprocessing completed for file: ${fileName}`);

    // Update job status
    lock {
        JobMetadata? metadata = JOB_METADATA_STORE[jobKey];
        if metadata is JobMetadata {
            metadata.status = STATUS_PREPROCESSING_ENDED;
            JOB_METADATA_STORE[jobKey] = metadata;
        }
    }

    // Step 2: Trigger FHIR questionnaire generation via orchestration service
    lock {
        JobMetadata? metadata = JOB_METADATA_STORE[jobKey];
        if metadata is JobMetadata {
            metadata.status = STATUS_FHIR_QUESTIONNAIRE_GEN_STARTED;
            JOB_METADATA_STORE[jobKey] = metadata;
        }
    }

    log:printInfo(string `Triggering questionnaire generation for file: ${fileName}, job: ${jobId}`);
    json generatePayload = {
        "file_name": fileName,
        "job_id": jobId
    };
    http:Response|error genResponse = FHIR_QUESTIONNAIRE_CLIENT->post("", generatePayload, {"Content-Type": "application/json"});
    if genResponse is error {
        log:printError(string `Failed to trigger questionnaire generation for file: ${fileName}, error: ${genResponse.message()}`);
        lock {
            JobMetadata? metadata = JOB_METADATA_STORE[jobKey];
            if metadata is JobMetadata {
                metadata.status = "failed";
                metadata.error_message = "Failed to trigger questionnaire generation: " + genResponse.message();
                JOB_METADATA_STORE[jobKey] = metadata;
            }
        }
        return genResponse;
    }
    log:printInfo(string `Questionnaire generation triggered for file: ${fileName}. Waiting for callback...`);
}

isolated function replaceExampleUrls(json input) returns json {
    if input is string {
        if input.startsWith("http://example.org") {
            return FHIR_SERVER_URL + input.substring(18);
        }
        return input;
    } else if input is json[] {
        json[] result = [];
        foreach json item in input {
            result.push(replaceExampleUrls(item));
        }
        return result;
    } else if input is map<json> {
        map<json> result = {};
        foreach [string, json] [key, value] in input.entries() {
            result[key] = replaceExampleUrls(value);
        }
        return result;
    }
    return input;
}

function deleteProcessedFiles(string fileName) {
    error? mdResult = storageDelete(string `/md/${fileName}.md`);
    if mdResult is error {
        log:printError(string `Failed to delete MD file for ${fileName}: ${mdResult.message()}`);
    } else {
        log:printInfo(string `Deleted MD file for ${fileName}`);
    }
    error? chunksResult = storageDelete(string `/chunks/${fileName}.json`);
    if chunksResult is error {
        log:printError(string `Failed to delete chunks file for ${fileName}: ${chunksResult.message()}`);
    } else {
        log:printInfo(string `Deleted chunks file for ${fileName}`);
    }
}

function postBundleToFhirServer(string fileName, json & readonly bundle) returns error? {
    http:Client? fhirClient = FHIR_SERVER_CLIENT;
    if fhirClient is () {
        log:printError("FHIR server client not initialized. Skipping FHIR server post.");
        return;
    }

    json|error entriesJson = bundle.entry;
    if entriesJson is error {
        log:printError("Bundle has no entries. Skipping FHIR server post.");
        return;
    }
    json[] entries = <json[]>entriesJson;

    // Separate resources by type for ordered posting
    json[] valueSets = [];
    json[] libraries = [];
    json[] questionnaires = [];

    foreach json entry in entries {
        map<json>|error entryMap = entry.ensureType();
        if entryMap is error {
            continue;
        }
        json? entryResource = entryMap["resource"];
        if entryResource is () {
            continue;
        }
        map<json>|error resMap = entryResource.ensureType();
        if resMap is error {
            continue;
        }
        string? resType = <string?>resMap["resourceType"];
        if resType is () {
            continue;
        }
        if resType == "ValueSet" {
            valueSets.push(entryResource);
        } else if resType == "Library" {
            libraries.push(entryResource);
        } else if resType == "Questionnaire" {
            questionnaires.push(entryResource);
        }
    }

    log:printInfo(string `Posting bundle resources to FHIR server: ${valueSets.length()} ValueSets, ${libraries.length()} Libraries, ${questionnaires.length()} Questionnaires`);

    // Post in order: ValueSet → Library → Questionnaire
    foreach json vs in valueSets {
        error? result = postResourceToFhirServer(fhirClient, "ValueSet", vs);
        if result is error {
            log:printError("Failed to post ValueSet: " + result.message());
        }
    }
    foreach json lib in libraries {
        error? result = postResourceToFhirServer(fhirClient, "Library", lib);
        if result is error {
            log:printError("Failed to post Library: " + result.message());
        }
    }
    foreach json q in questionnaires {
        error? result = postResourceToFhirServer(fhirClient, "Questionnaire", q);
        if result is error {
            log:printError("Failed to post Questionnaire: " + result.message());
        }
    }

    deleteProcessedFiles(fileName);
}

function postResourceToFhirServer(http:Client fhirClient, string resourceType, json fhirResource) returns error? {
    http:Response response = check fhirClient->post(string `/${resourceType}`, fhirResource, {"Content-Type": "application/fhir+json"});
    json|error id = fhirResource.id;
    string resId = id is json ? id.toString() : "unknown";
    if response.statusCode != 200 && response.statusCode != 201 {
        log:printError(string `FHIR server returned ${response.statusCode} for ${resourceType} '${resId}'`);
    } else {
        log:printInfo(string `${resourceType} '${resId}' posted to FHIR server successfully`);
    }
}
