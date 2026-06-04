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

import ballerina/http;
import ballerinax/ai.anthropic;

// HTTP Client for Policy Preprocessor Service
final http:Client POLICY_FLOW_ORCHESTRATOR_CLIENT = check new (POLICY_FLOW_ORCHESTRATOR);

// Direct LLM model provider for lightweight calls (e.g. appending applicable codes)
final anthropic:ModelProvider _AnthropicModelProvider = check new (
        string `${ANTHROPIC_API_KEY}`,
        "claude-sonnet-4-20250514",
        serviceUrl = ANTHROPIC_AI_GATEWAY_URL,
        maxTokens = 8192
);

// HTTP Clients for Agents
final http:Client _QuestionnaireGeneratorAgent = check new (FHIR_QUESTIONNAIRE_GENERATOR_URL, {
        timeout: 30000,
        retryConfig: {
            count: 3,
            interval: 2
        }
});

final http:Client _ReviewerAgent = check new (FHIR_REVIEWER_URL, {
        timeout: 30000,
        retryConfig: {
            count: 3,
            interval: 2
        }
});

// HTTP Client for CQL Enrichment API
final http:Client CQL_ENRICHMENT_CLIENT = check new (CQL_ENRICHMENT_API_URL, {
        timeout: 30000,
        retryConfig: {
            count: 3,
            interval: 2
        }
});
