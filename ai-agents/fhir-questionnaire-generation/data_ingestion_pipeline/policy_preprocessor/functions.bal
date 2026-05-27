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
import ballerina/log;
import ballerina/ftp;
import ballerina/http;

function chunk_document(string fileName) returns error? {
    string jobID = "job-" + fileName;
    log:printInfo("Starting document chunking for file: " + fileName + " with jobID: " + jobID);
    string fileContent = check readFileContent(fileName);
    log:printInfo("Processing file: " + fileName + " with content length: " + fileContent.length().toString());
    string truncatedContent = fileContent;
    if truncatedContent.length() > 3000 {
        truncatedContent = fileContent.substring(0, 3000);
    }
    log:printDebug("File content (truncated to 3000 chars): " + truncatedContent);
    string[] sectionTitles = check readTableofContent(truncatedContent);
    log:printInfo("Section titles extracted: " + sectionTitles.toString());
    if sectionTitles.length() == 0 {
        sectionTitles = check fallbackToCExtraction(fileContent);
        log:printInfo("Fallback section titles extracted: " + sectionTitles.toString());
    }
    map<string> sections = check splitDocument(fileContent, sectionTitles);
    log:printInfo("Document split into sections successfully for file: " + fileName);
    ClassificationResponse classificationResult = check classifySections(sections);
    log:printInfo("Sections classified successfully for file: " + fileName);
    check writeToMemory(sections, classificationResult, fileName, jobID);
    NotificationPayload payload = {
        job_id: jobID,
        message: "chunking_done",
        status: "completed",
        file_name: fileName
    };
    log:printInfo("Sending chunking completion notification for jobID: " + jobID);
    check sendNotification(payload);
    log:printInfo("Classification results stored in memory successfully for file: " + fileName);
}

function readTableofContent(string fileContent) returns string[]|error{
    string llmResponse = check anthropicModelprovider->generate(
        `Extract the table of contents from the following segment of the document:
        ${fileContent}
        Provide the response in this json format:
        {
            "response": [<"Section Title 1">, <"Section Title 2">, ...]
        }
        Make sure to only include the section titles and nothing else. Do Not include any page numbers. or traling punctuation in the titles.
        
        If there is a table of content it should contain the relevant page numbers associated with each title as well. If no clear section titles are found with the page numbers, respond with an empty list: {"response": []}. 
        The following titles are manditory in the table of contents if they are not present the response should be empty list:
        1. Overview
        2. Coverage Details (Or equivalent title)
        3. References
        `
    );
    log:printInfo("LLM Response received.");
    log:printDebug("LLM Response: " + llmResponse);
    json resp = check llmResponse.fromJsonString();
    ToCResponse titles = check resp.cloneWithType();
    string[] sectionTitles = titles.response;
    return sectionTitles;
}

function readFileContent(string fileName) returns string|error {
    stream<byte[] & readonly, io:Error?>|ftp:Error fileBytes = fileClient->get(string `/md/${fileName}.md`);
    if fileBytes is ftp:Error {
        log:printError("Error fetching file from FTP: " + fileBytes.message());
        return fileBytes;
    }
    string mdFileContent = "";
    byte[][] & readonly chunks = check from byte[] & readonly chunk in fileBytes
                select chunk;
    foreach byte[] & readonly chunk in chunks {
        mdFileContent += check string:fromBytes(chunk);
    }
    return mdFileContent;
}

function fallbackToCExtraction(string fileContent) returns string[]|error {
    string[] commonHeaders = ["# ", "## ", "### ", "#### ", "##### ", "###### "];
    string[] extractedTitles = [];
    foreach string header in commonHeaders {
        int startIndex = 0;
        while true {
            int? index = fileContent.indexOf(header, startIndex);
            if index is null {
                break;
            }
            int titleStart = <int>index + header.length();
            int? titleEnd = fileContent.indexOf("\n", titleStart);
            if titleEnd is null {
                titleEnd = fileContent.length();
            }
            string title = fileContent.substring(titleStart, <int>titleEnd).trim();
            if title != "" && (extractedTitles.indexOf(title) == ()) {
                extractedTitles.push(title);
            }
            startIndex = <int>titleEnd + 1;
        }
        if extractedTitles.length() > 0 {
            log:printInfo("Extracted section titles using header: " + header);
            return extractedTitles;
        }
    }
    string llmResponse = check anthropicModelprovider->generate(
        `You have been given a set of title candidates extracted from a document:
        ${extractedTitles.toString()}

        From these candidates, identify the most relevant section titles that would typically appear in a table of contents. 
        These titles can be headings or subheadings that indicate the structure of the document. Only include the titles that are likely to be the main sections of the document.
        Provide the response in this json format:
        {
            "response": [<"Section Title 1">, <"Section Title 2">, ...]
        }
        Make sure to only include the main section titles and nothing else.
        `
    );
    log:printDebug("LLM Response fallback: " + llmResponse);
    json resp = check llmResponse.fromJsonString();
    ToCResponse titles = check resp.cloneWithType();
    string[] sectionTitles = titles.response;
    return sectionTitles;
}

function splitDocument(string documentContent, string[] sectionTitles) returns map<string>|error {
    log:printInfo("Splitting document into sections based on titles.");
    map<string> sections = {};
    map<int> titleIndices = {};
    foreach string title in sectionTitles {
        int? index = documentContent.indexOf(title);
        if index is null {
            log:printError("Title not found in document: " + title);
            return error("Title not found in document: " + title);
        }
        int cur_index = index;
        while !isValidTitle(documentContent, title, cur_index) {
            int? new_index = documentContent.indexOf(title, cur_index + 1);
            if new_index is null {
                log:printWarn("No valid title found for: " + title + ". Using last occurrence at index: " + cur_index.toString());
                break;
            }
            cur_index = new_index;
        } 
        log:printDebug("Title found at index: " + cur_index.toString() + " for title: " + title);
        titleIndices[title] = cur_index;
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

function isValidTitle(string documentContent, string title, int index) returns boolean {
    if index == 0 {
        log:printDebug("Title is at the start of the document. Title: " + title);
        return false;
    }
    foreach int i in 1...5{
        if documentContent[index - i] == "#" {
            return true;
        }
    }
    log:printDebug("Title:  " + title + "at index" + index.toString() + " does not have # before it.");
    return false;
}

function classifySections(map<string> sections) returns ClassificationResponse|error{
    string[] categories = sections.keys();
    string sectionTitles = "";
    foreach string title in categories {
        sectionTitles += "- " + title + "\n";
    }
    string llmResponse = check anthropicModelprovider->generate(
        `You are given a set of section titles from a document:
        ${sectionTitles}
        Classify each section title into one of the following categories:
        1. Coverage Details (The core part of the document which describes the covered scenarios)
        2. Supplementary Information (This should not include the details the scenarios which are not covered)
        3. Non-Essential Information
        You have to strictly classify each section title into one of the above categories. The Non-Essential Information should contain the ones like reference, glossary, index etc. Coverage Details should only contain only one section title.
        Provide the response in this json format:
        {
            "response": [
                {
                    "category": "<category name>",
                    "titles": ["<title1>", "<title2>", ...]
                },
                ...
            ]
        }
        `
    );
    log:printInfo("LLM Response for classification received.");
    log:printDebug("LLM Response: " + llmResponse);
    json resp = check llmResponse.fromJsonString();
    ClassificationResponse classification = check resp.cloneWithType();
    string coverageTitle = "";
    foreach SectionClassfication section in classification.response {
        if section.category == "Coverage Details" {
            if coverageTitle != "" {
                log:printError("Multiple sections classified as Coverage Details.");
                return error("Multiple sections classified as Coverage Details.");
            }
            if section.titles.length() != 1 {
                log:printError("Coverage Details should have exactly one section.");
                return error("Coverage Details should have exactly one section.");
            }
            coverageTitle = section.titles[0];
        } else if section.category == "Supplementary Information" {
            log:printInfo("Supplementary Information sections: " + section.titles.toString());
        } else {
            log:printInfo("Ignoring Non-Essential Information category.");
        }
    }
    return classification;
}

function recursive_splitter(string[] sectionContent) returns string[]{
    int contentLength = sectionContent[0].length();
    if contentLength <= MAX_CHUNK_SIZE {
        return sectionContent;
    }
    string[] chunks = [];
    while contentLength > MAX_CHUNK_SIZE {
        int? splitIndex = sectionContent[0].lastIndexOf("\n", MAX_CHUNK_SIZE);
        if splitIndex is null{
            splitIndex = MAX_CHUNK_SIZE;
        }
        string chunk = sectionContent[0].substring(0, <int>splitIndex);
        chunks.push(chunk.trim());
        sectionContent[0] = sectionContent[0].substring(<int>splitIndex).trim();
        contentLength = sectionContent[0].length();
    }
    if sectionContent[0] != "" {
        chunks.push(sectionContent[0].trim());
    }
    return chunks;
}

function writeToMemory(map<string> sections, ClassificationResponse classification, string fileName, string jobID) returns error? {
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
        if sections.hasKey(coverageTitle){
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
    string targetFileName = string`${fileName}.json`;
    ChunkStore chunkStore = {
        supplementary: supplementaryChunks,
        core: coreChunks
    };
    error? res = fileClient->put("/chunks/" + targetFileName, chunkStore.toJson());
    if res is error {
        log:printError("Error storing chunks to FTP server: " + res.message());
        return res;
    }
    log:printInfo("Chunks stored successfully to FTP server at /chunks/" + targetFileName);
}

function sendNotification(NotificationPayload payload) returns error? {
    if (payload.message == "pdf_to_md_done" && payload.status == "completed") {
        _ = start chunk_document(payload.file_name);
    }
    map<string> headers = {
        "Content-Type": "application/json"
    };
    http:Response response = check UI_CLIENT->post("", payload, headers);
    json responseBody = check response.getJsonPayload();
    log:printInfo("UI notified successfully with response: " + responseBody.toJsonString());
}
