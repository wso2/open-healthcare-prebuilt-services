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

public type PolicyChunk record {
    string file_name;
    string section_title;
    int chunk_id;
    string chunk_content;
};

type ChunkStore record{
    PolicyChunk[] supplementary;
    PolicyChunk[] core;
};

type ToCResponse record {
    string[] response;
};

type SectionClassfication record{
    string category;
    string[] titles;
};

type ClassificationResponse record {
    SectionClassfication[] response;
};

type NotificationPayload record {
    string job_id;
    string message;
    string status;
    string file_name;
    string agent?;
    int iteration_cnt?;
    string response?;
};

type PromptTemplate record {
    string title;
    string prompt;
};

type QuestionnaireUploadPayload record {
    string file_name;
    string job_id;
    map<json> questionnaires;
    map<PromptTemplate> failed_scenarios;
};

type UploadResponse record {
    string job_id;
    string message;
    string file_name;
    string status;
};

type ErrorResponse record {
    string 'error;
};
