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

import ballerina/log;
import ballerina/http;

service / on new http:Listener(SERVICE_PORT) {
    resource function get health() returns string {
        log:printDebug("Health check endpoint accessed");
        return "Service is healthy";
    }

    resource function post generate(GenerateRequest payload) returns http:Accepted|error {
        log:printInfo("Received generate request for file: " + payload.file_name);
        _ = start processGeneration(payload);
        return http:ACCEPTED;
    }
}

function processGeneration(GenerateRequest payload) {
    string jobId = payload.job_id ?: ("job-" + payload.file_name);
    error? result = orchestrateGeneration(payload.file_name, jobId);
    if result is error {
        log:printError("Error processing generation for file: " + payload.file_name + " - " + result.message());
        log:printDebug("Trace: " + result.stackTrace().toString());
    }
}
