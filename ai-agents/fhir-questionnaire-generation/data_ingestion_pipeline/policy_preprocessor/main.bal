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

import ballerina/io;
import ballerina/log;
import ballerina/http;
import ballerina/mime;
import ballerina/regex;
import ballerina/time;

isolated map<json> QUESITONNAIRE_STORE = {};
isolated map<map<json>> FAILED_SCENARIOS_STORE = {};
isolated map<JobMetadata> JOB_METADATA_STORE = {};

service / on new http:Listener(SERVICE_PORT) {
    resource function get health() returns string {
        log:printDebug("Health check endpoint accessed");
        return "Service is healthy";
    }

    resource function post convert(http:Request request) returns ConvertResponse[]|http:BadRequest|error {
        mime:Entity[] bodyParts = check request.getBodyParts();
        if (bodyParts.length() == 0) {
            return <http:BadRequest>{body: {"error": "No files uploaded"}};
        }

        // Phase 1: Store all files to storage
        StoredFileInfo[] storedFiles = [];
        foreach mime:Entity part in bodyParts {
            if (part.getContentDisposition().name == "file") {
                StoredFileInfo|http:BadRequest|error result = storeFile(part);
                if result is error {
                    log:printError("Error storing file: " + result.message());
                    return result;
                } else if result is http:BadRequest {
                    return result;
                } else if result is StoredFileInfo {
                    storedFiles.push(result);
                }
            }
        }

        if storedFiles.length() == 0 {
            return <http:BadRequest>{body: {"error": "No valid files found"}};
        }

        // Phase 2: Send a single batch notification to the PDF-to-MD service
        string[] fileNames = from StoredFileInfo f in storedFiles select f.file_name;
        log:printInfo(string `All ${storedFiles.length()} file(s) stored successfully: ${fileNames.toString()}. Sending batch conversion request...`);

        json[] fileRequests = from StoredFileInfo f in storedFiles
            select <json>{job_id: f.job_id, file_name: f.file_name};
        json convertPayload = {requests: fileRequests};

        http:Response batchResponse = check PDF_TO_MD_CLIENT->post("/convert/batch", convertPayload, {"Content-Type": "application/json"});
        if batchResponse.statusCode != 200 {
            log:printError("Failed to initiate batch PDF to MD conversion. Status code: " + batchResponse.statusCode.toString());
            foreach StoredFileInfo f in storedFiles {
                string jobKey = f.file_name + "_" + f.job_id;
                lock {
                    JobMetadata? metadata = JOB_METADATA_STORE[jobKey];
                    if metadata is JobMetadata {
                        metadata.status = "failed";
                        metadata.error_message = "Failed to initiate batch PDF conversion";
                        JOB_METADATA_STORE[jobKey] = metadata;
                    }
                }
            }
            return <http:BadRequest>{body: {"error": "Failed to initiate batch PDF conversion"}};
        }

        foreach StoredFileInfo f in storedFiles {
            string jobKey = f.file_name + "_" + f.job_id;
            lock {
                JobMetadata? metadata = JOB_METADATA_STORE[jobKey];
                if metadata is JobMetadata {
                    metadata.status = STATUS_PDF_TO_MD_CONVERSION_STARTED;
                    metadata.error_message = ();
                    JOB_METADATA_STORE[jobKey] = metadata;
                }
            }
        }

        ConvertResponse[] responses = [];
        foreach StoredFileInfo f in storedFiles {
            responses.push({
                job_id: f.job_id,
                file_name: f.file_name,
                status: STATUS_PDF_TO_MD_CONVERSION_STARTED,
                message: "File uploaded and processing initiated"
            });
        }

        return responses;
    }

    resource function post notification(NotificationPayload payload) returns http:Ok|error {
        log:printInfo(string `Received notification: ${payload.message} for job: ${payload.job_id}`);
        error? res = sendNotification(payload);
        if (res is error) {
            log:printError("Failed to process notification: " + res.message());
            return res;
        }
        return http:OK;
    }

    resource function post reTrigger(ReTriggerRequest payload) returns ConvertResponse|http:NotFound|error {
        string jobKey = payload.file_name + "_" + payload.job_id;
        
        lock {
            JobMetadata? metadata = JOB_METADATA_STORE[jobKey];
            if metadata is () {
                return <http:NotFound>{body: {"error": "Job not found: " + payload.job_id}};
            }
        }

        boolean fileExists = check storageExists(string `/md/${payload.file_name}.md`);
        if !fileExists {
            return <http:NotFound>{body: {"error": "Source file not found: " + payload.file_name}};
        }

        _ = start chunk_document(payload.file_name, payload.job_id);
        
        lock {
            JobMetadata metadata = {
                job_id: payload.job_id,
                file_name: payload.file_name,
                status: STATUS_PREPROCESSING_STARTED,
                created_at: time:utcToString(time:utcNow()),
                error_message: ()
            };
            JOB_METADATA_STORE[jobKey] = metadata;
        }

        return {
            job_id: payload.job_id,
            file_name: payload.file_name,
            status: STATUS_PREPROCESSING_STARTED,
            message: "Processing re-triggered successfully"
        };
    }

    resource function post questionnaires(QuestionnaireUploadPayload payload) returns string|http:BadRequest|http:NotFound {
        log:printInfo(string `Received questionnaire bundle for file: ${payload.file_name}, job: ${payload.job_id}`);
        string jobKey = payload.file_name + "_" + payload.job_id;

        // Reject unknown jobs before mutating any state
        lock {
            if JOB_METADATA_STORE[jobKey] is () {
                return <http:NotFound>{body: {"error": string `Job ${jobKey} not found`}};
            }
        }

        // Validate bundle structure before mutating metadata
        json bundle = payload.bundle;
        json|error bundleType = bundle.'type;
        if bundleType is error || bundleType != "collection" {
            return <http:BadRequest>{body: {"error": "Bundle must be of type 'collection'"}};
        }

        lock {
            JobMetadata? metadata = JOB_METADATA_STORE[jobKey];
            if metadata is JobMetadata {
                metadata.status = STATUS_FHIR_QUESTIONNAIRE_GEN_ENDED;
                metadata.error_message = ();
                JOB_METADATA_STORE[jobKey] = metadata;
            }
        }

        lock {
            JobMetadata? metadata = JOB_METADATA_STORE[jobKey];
            if metadata is JobMetadata {
                metadata.status = STATUS_ENRICHING_AND_STORING;
                JOB_METADATA_STORE[jobKey] = metadata;
            }
        }
        
        // Replace http://example.org URLs with FHIR server URL in the bundle
        json processedBundle = bundle;
        if FHIR_SERVER_URL != "" {
            processedBundle = replaceExampleUrls(bundle);
        }
        
        lock {
            QUESITONNAIRE_STORE[jobKey] = processedBundle.cloneReadOnly();
        }
        lock {
            FAILED_SCENARIOS_STORE[jobKey] = payload.cloneReadOnly().failed_scenarios;
        }
        
        // Count entries for logging
        json|error entries = processedBundle.entry;
        int entryCount = 0;
        if entries is json[] {
            entryCount = entries.length();
        }
        
        // Update job metadata to completed
        lock {
            JobMetadata? metadata = JOB_METADATA_STORE[jobKey];
            if metadata is JobMetadata {
                metadata.status = STATUS_COMPLETED;
                JOB_METADATA_STORE[jobKey] = metadata;
                log:printInfo(string `Job ${payload.job_id} completed successfully with ${entryCount} bundle entries`);
            }
        }
        
        // Post resources to FHIR server in background (order: ValueSet → Library → Questionnaire)
        // Deletes md and chunks files after posting
        if FHIR_SERVER_URL != "" {
            json & readonly bundleToPost = processedBundle.cloneReadOnly();
            _ = start postBundleToFhirServer(payload.file_name, bundleToPost);
        } else {
            _ = start deleteProcessedFiles(payload.file_name);
        }
        
        return "Questionnaire bundle received";
    }

    resource function get questionnaires(string? file_name = (), string? job_id = ()) returns json {
        if file_name is string && job_id is string {
            lock {
                json? bundle = QUESITONNAIRE_STORE[file_name + "_" + job_id];
                if bundle is () {
                    return {"error": "Questionnaire bundle not found for file: " + file_name};
                }
                return bundle.cloneReadOnly();
            }
        }
        // Return all bundles in memory
        lock {
            return QUESITONNAIRE_STORE.cloneReadOnly().toJson();
        }
    }

    resource function get failedScenarios(string file_name, string job_id) returns map<json>|http:NotFound {
        lock {
            map<json>? failedScenarios = FAILED_SCENARIOS_STORE[file_name + "_" + job_id];
            if (failedScenarios is ()) {
                return <http:NotFound>{body: {"error": "Failed scenarios not found for file: " + file_name}};
            }
            return failedScenarios.cloneReadOnly();
        }
    }

    resource function get jobStatus(string file_name, string job_id) returns JobMetadata|http:NotFound {
        string jobKey = file_name + "_" + job_id;
        lock {
            JobMetadata? metadata = JOB_METADATA_STORE[jobKey];
            if (metadata is ()) {
                return <http:NotFound>{body: {"error": "Job not found: " + job_id}};
            }
            return metadata.cloneReadOnly();
        }
    }
}

function storeFile(mime:Entity filePart) returns StoredFileInfo|http:BadRequest|error {
    mime:ContentDisposition contentDisposition = filePart.getContentDisposition();
    string? filename = contentDisposition.fileName;
    
    if (filename is ()) {
        return <http:BadRequest>{body: {"error": "No filename provided"}};
    }
    if (!filename.toLowerAscii().endsWith(".pdf")) {
        return <http:BadRequest>{body: {"error": "Only PDF files are allowed: " + filename}};
    }

    stream<byte[], io:Error?> fileStream = check filePart.getByteStream();
    string storageFilePath = string `/pdf/${filename}`;
    stream<byte[] & readonly, io:Error?> readonlyStream = fileStream.map(
        function(byte[] chunk) returns byte[] & readonly => chunk.cloneReadOnly()
    );
    
    check storagePut(storageFilePath, readonlyStream);
    log:printInfo(string `File ${filename} uploaded successfully to storage`);

    string fileNameWithoutExt = regex:split(filename, "\\.")[0];
    string jobId = "job-" + fileNameWithoutExt;

    lock {
        JobMetadata metadata = {
            job_id: jobId,
            file_name: fileNameWithoutExt,
            status: STATUS_PDF_TO_MD_CONVERSION_STARTED,
            created_at: time:utcToString(time:utcNow()),
            error_message: ()
        };
        JOB_METADATA_STORE[fileNameWithoutExt + "_" + jobId] = metadata;
    }

    return {
        job_id: jobId,
        file_name: fileNameWithoutExt,
        file_name_with_ext: filename
    };
}


