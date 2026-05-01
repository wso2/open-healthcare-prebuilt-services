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

// LLM configurations
configurable string ANTHROPIC_API_KEY = "";
configurable string OPENAI_API_KEY = "";
configurable int MAX_TOOL_CALL = 3;
configurable string ANTHROPIC_API_AI_GATEWAY_URL = "https://api.anthropic.com/v1";
configurable string OPENAI_API_AI_GATEWAY_URL = "https://api.openai.com/v1";

// PGVector configurations
configurable string PGVECTOR_HOST = "";
configurable int PGVECTOR_PORT = 12352;
configurable string PGVECTOR_USER = "";
configurable string PGVECTOR_DATABASE = "";
configurable string PGVECTOR_PASSWORD = "";
configurable string CA_CERT_PATH = "";

configurable int MAX_CHUNKS = 3;

// UI Notification url
configurable string NOTIFICATION_URL = "http://localhost:6080/notification";

// FTP configurations
configurable string FTP_HOST = "";
configurable int FTP_PORT = 2121;
configurable string FTP_USERNAME = "";
configurable string FTP_PASSWORD = "";
