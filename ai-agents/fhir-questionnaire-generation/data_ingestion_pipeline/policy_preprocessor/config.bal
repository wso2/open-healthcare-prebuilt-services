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

configurable string ANTHROPIC_API_KEY = "";

// Chunking and classification configurations
configurable int MAX_CHUNK_SIZE = 4500; // Max characters per chunk

// UI Notification url
configurable string UI_NOTIFICATION_URL = "http://localhost:3000/api/callback";
configurable string PDF_TO_MD_SERVICE_URL = "http://0.0.0.0:8000/convert";

// FTP configurations
configurable string FTP_HOST = "";
configurable int FTP_PORT = 2121;
configurable string FTP_USERNAME = "";
configurable string FTP_PASSWORD = "";
