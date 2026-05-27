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

import ballerina/ai;
import ballerina/ftp;
import ballerina/http;
import ballerinax/ai.openai;
import ballerinax/postgresql;
import ballerinax/ai.pgvector;
import ballerinax/ai.anthropic;

// FTP Client to fetch files
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

// Vector Store and Knowledge Base
final pgvector:VectorStore pgVectorstore = check new (
    host=PGVECTOR_HOST,
    user=PGVECTOR_USER,
    password=PGVECTOR_PASSWORD,
    database=PGVECTOR_DATABASE,
    port=PGVECTOR_PORT,
    configs={
        vectorDimension: 1536
    },
    options = {
        ssl: {
            mode: postgresql:REQUIRE,
            rootcert: CA_CERT_PATH
        }
    }
);
final openai:EmbeddingProvider openAIEmbeddingProvider = check new (OPENAI_API_KEY, "text-embedding-ada-002", serviceUrl = OPENAI_API_AI_GATEWAY_URL);
final ai:VectorKnowledgeBase aiVectorknowledgebase = new (pgVectorstore, <ai:EmbeddingProvider>openAIEmbeddingProvider);

// LLM Model Providers
final anthropic:ModelProvider anthropicModelprovider = check new (ANTHROPIC_API_KEY, "claude-sonnet-4-20250514", serviceUrl = ANTHROPIC_API_AI_GATEWAY_URL, maxTokens = 4096);
final openai:ModelProvider openAIModelProvider = check new (OPENAI_API_KEY, "gpt-4.1", serviceUrl = OPENAI_API_AI_GATEWAY_URL, maxTokens = 4096);

// HTTP Client for UI notifications
final http:Client NOTIFICATION_CLIENT = check new (NOTIFICATION_URL);
