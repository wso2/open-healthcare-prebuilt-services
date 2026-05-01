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

import ballerina/test;

// Test the Token limit guardrail functionality
@test:Config {}
function testIsWithinTokenLimit_WithinLimit() {
    string sampleText = "This is a sample text within the token limit.";
    string sessionId = "test-session-1";
    string|error response = _ReviewerAgent.run(sampleText, sessionId);
    test:assertFalse(response is error, "The response should be within the token limit.");
}

// Test the Token limit guardrail functionality exceeding limit
@test:Config {}
function testIsWithinTokenLimit_ExceedLimit() {
    string longText = "This is a very long text ";
    foreach int i in 1 ... 100000 {
        longText += "that will exceed the token limit. ";
    }
    string sessionId = "test-session-2";
    string|error response = _ReviewerAgent.run(longText, sessionId);
    test:assertTrue(response is error, "The response should exceed the token limit.");
    if (response is error) {
        test:assertEquals(response.message(), "Input exceeds the token limit.");
    }
}
