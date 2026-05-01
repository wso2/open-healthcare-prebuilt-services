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

import ballerina/ftp;
import ballerina/http;
import ballerinax/ai.anthropic;

final anthropic:ModelProvider anthropicModelprovider = check new (ANTHROPIC_API_KEY, "claude-3-7-sonnet-20250219");

// HTTP Client for chunks service
final http:Client UI_CLIENT = check new (UI_NOTIFICATION_URL, {
    timeout: 30,
    retryConfig: {
        count: 3,
        interval: 2
    },
    httpVersion: "1.1",
    http1Settings: {
        keepAlive: http:KEEPALIVE_AUTO,
        chunking: http:CHUNKING_NEVER
    }
});

// HTTP Client for PDF to MD conversion service
final http:Client PDF_TO_MD_CLIENT = check new (PDF_TO_MD_SERVICE_URL);

// FTP Client to store chunks
final ftp:Client fileClient = check new ({
    host: FTP_HOST,
    port: FTP_PORT,
    auth: {
        credentials: {
            username: FTP_USERNAME,
            password: FTP_PASSWORD
        }
    }
});
