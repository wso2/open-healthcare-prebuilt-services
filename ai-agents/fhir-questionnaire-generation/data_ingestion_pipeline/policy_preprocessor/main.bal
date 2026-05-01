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
import ballerina/http;
import ballerina/mime;
import ballerina/regex;

isolated map<map<json>> QUESITONNAIRE_STORE = {};
isolated map<map<PromptTemplate>> FAILED_SCENARIOS_STORE = {};

service / on new http:Listener(6080) {
    resource function get health() returns string {
        log:printDebug("Health check endpoint accessed");
        return "Service is healthy";
    }

    resource function post notification (NotificationPayload payload) returns http:STATUS_OK|error {
        error? res = sendNotification(payload);
        if (res is error) {
            log:printError("Failed to send notification: " + res.message());
            return res;
        }
        return http:STATUS_OK;
    }

    resource function post uploadPolicy(http:Request request) returns UploadResponse|http:BadRequest|error {
        mime:Entity[] bodyParts = check request.getBodyParts();
        if (bodyParts.length() == 0) {
            http:BadRequest badRequest = {
                body: {"error": "No file uploaded"}
            };
            return badRequest;
        }
        mime:Entity? filePart = ();
        foreach mime:Entity part in bodyParts {
            if (part.getContentDisposition().name == "file") {
                filePart = part;
                break;
            }
        }
        if (filePart is ()) {
            http:BadRequest badRequest = {
                body: {"error": "No file part found"}
            };
            return badRequest;
        }
        mime:ContentDisposition contentDisposition = filePart.getContentDisposition();
        string? filename = contentDisposition.fileName;
        
        if (filename is ()) {
            http:BadRequest badRequest = {
                body: {"error": "No filename provided"}
            };
            return badRequest;
        }
        if (!filename.toLowerAscii().endsWith(".pdf")) {
            http:BadRequest badRequest = {
                body: {"error": "Only PDF files are allowed"}
            };
            return badRequest;
        }
        stream<byte[], io:Error?> fileStream = check filePart.getByteStream();
        string ftpFilePath = string `/pdf/${filename}`;
        stream<byte[] & readonly, io:Error?> readonlyStream = fileStream.map(function(byte[] chunk) returns byte[] & readonly => chunk.cloneReadOnly());
        error? uploadResult = fileClient->put(ftpFilePath, readonlyStream);
        if (uploadResult is error) {
            log:printError("Failed to upload file to FTP: " + uploadResult.message());
            return uploadResult;
        }
        string fileNameWithoutExt = regex:split(filename, "\\.")[0];
        string jobId = "job-" + fileNameWithoutExt;
        log:printInfo(string `File ${fileNameWithoutExt} uploaded successfully with job ID: ${jobId}`);

        http:Response response = check PDF_TO_MD_CLIENT->post("", {
            job_id: jobId,
            file_name: fileNameWithoutExt
        }, {"Content-Type": "application/json"});

        if response.statusCode != 200 {
            log:printError("Failed to initiate PDF to MD conversion. Status code: " + response.statusCode.toString());
            http:BadRequest badRequest = {
                body: {"error": "Only PDF files are allowed"}
            };
            return badRequest;
        }

        return {
            job_id: jobId,
            message: "File uploaded successfully",
            file_name: fileNameWithoutExt,
            status: "uploaded"
        };
    }

    isolated resource function post questionnaires(QuestionnaireUploadPayload payload) returns string {
        log:printInfo(string `Received questionnaire for file: ${payload.file_name}, job: ${payload.job_id}`);
        lock {
	        QUESITONNAIRE_STORE[payload.file_name + "_" + payload.job_id] = payload.cloneReadOnly().questionnaires;
        }
        lock {
            FAILED_SCENARIOS_STORE[payload.file_name + "_" + payload.job_id] = payload.cloneReadOnly().failed_scenarios;
        }
        return "Questionnaire received";
    }

    resource function get questionnaires(string file_name, string job_id) returns map<json>|http:NotFound {
        lock {
            map<json>? questionnaires = QUESITONNAIRE_STORE[file_name + "_" + job_id];
            if (questionnaires is ()) {
                http:NotFound notFound = {
                    body: {"error": "Questionnaires not found for file: " + file_name}
                };
                return notFound.clone();
            }
            return questionnaires.cloneReadOnly();
        }
    }

    resource function get failedScenarios(string file_name, string job_id) returns map<PromptTemplate>|http:NotFound {
        lock {
            map<PromptTemplate>? failedScenarios = FAILED_SCENARIOS_STORE[file_name + "_" + job_id];
            if (failedScenarios is ()) {
                http:NotFound notFound = {
                    body: {"error": "Failed scenarios not found for file: " + file_name}
                };
                return notFound.clone();
            }
            return failedScenarios.cloneReadOnly();
        }
    }
}
