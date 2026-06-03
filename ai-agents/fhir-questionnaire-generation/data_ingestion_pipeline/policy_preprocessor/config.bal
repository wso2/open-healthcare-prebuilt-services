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

import ballerina/os;

// Environment variable helpers
function getEnvOrDefault(string key, string defaultVal) returns string {
    string val = os:getEnv(key);
    return val == "" ? defaultVal : val;
}

function getEnvAsIntOrDefault(string key, int defaultVal) returns int {
    string val = os:getEnv(key);
    if val == "" {
        return defaultVal;
    }
    int|error intVal = int:fromString(val);
    return intVal is int ? intVal : defaultVal;
}

final string ANTHROPIC_API_KEY = os:getEnv("ANTHROPIC_API_KEY");

// Service port
final int SERVICE_PORT = getEnvAsIntOrDefault("SERVICE_PORT", 6080);

// Chunking and classification configurations
final int MAX_CHUNK_SIZE = getEnvAsIntOrDefault("MAX_CHUNK_SIZE", 4500);

// PDF to MD Service URL
final string PDF_TO_MD_SERVICE_URL = getEnvOrDefault("PDF_TO_MD_SERVICE_URL", "http://localhost:8000");

// FHIR Questionnaire Generation Service URL
final string FHIR_QUESTIONNAIRE_SERVICE_URL = getEnvOrDefault("FHIR_QUESTIONNAIRE_SERVICE_URL", "http://localhost:6060/generate");

// FHIR Server URL (for posting questionnaires and replacing example.org URLs)
final string FHIR_SERVER_URL = getEnvOrDefault("FHIR_SERVER_URL", "");

// Storage configurations
final string STORAGE_TYPE = getEnvOrDefault("STORAGE_TYPE", "local");
final string LOCAL_STORAGE_PATH = getEnvOrDefault("LOCAL_STORAGE_PATH", "../../data");

// FTP configurations (used when STORAGE_TYPE = "ftp")
final string FTP_HOST = getEnvOrDefault("FTP_HOST", "");
final int FTP_PORT = getEnvAsIntOrDefault("FTP_PORT", 2121);
final string FTP_USERNAME = getEnvOrDefault("FTP_USERNAME", "");
final string FTP_PASSWORD = getEnvOrDefault("FTP_PASSWORD", "");

// Document configurations
final string[] SECTION_TITLES = [];
final ClassificationResponse SECTION_CLASSIFICATIONS = {
    response: [{
        category: "Coverage Details",
        titles: ["Coverage Rationale", "Applicable Codes"]
    }, {
        category: "Supplementary Information",
        titles: ["Benefit Considerations", "Clinical Evidence", "U.S. Food and Drug Administration (FDA)"]
    }]
};
