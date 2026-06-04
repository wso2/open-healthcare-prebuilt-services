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

import ballerina/ftp;
import ballerina/http;
import ballerinax/ai.anthropic;

final anthropic:ModelProvider anthropicModelprovider = check new (string `${ANTHROPIC_API_KEY}`, "claude-sonnet-4-20250514");

// HTTP Client for PDF to MD conversion service
final http:Client PDF_TO_MD_CLIENT = check new (PDF_TO_MD_SERVICE_URL);

// HTTP Client for FHIR Questionnaire Generation Service
final http:Client FHIR_QUESTIONNAIRE_CLIENT = check new (FHIR_QUESTIONNAIRE_SERVICE_URL);

// HTTP Client for FHIR Server (only initialized if FHIR_SERVER_URL is set)
final http:Client? FHIR_SERVER_CLIENT = FHIR_SERVER_URL != "" ? check new (FHIR_SERVER_URL) : ();

// FTP Client (only initialized if STORAGE_TYPE is "ftp")
final ftp:Client? fileClient = STORAGE_TYPE == "ftp" ? check new ({
    host: FTP_HOST,
    port: FTP_PORT,
    auth: {
        credentials: {
            username: FTP_USERNAME,
            password: FTP_PASSWORD
        }
    }
}) : ();
