// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

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
import ballerina/io;
import ballerinax/health.fhir.r4;

// Function to read the LOINC CSV file
isolated function readLoincCsv(string path) returns LoincConcept[]|error {
    LoincConcept[]|io:Error content = io:fileReadCsv(path);
    return content;
}

// Function to export the combined CodeSystem resource to a JSON file
isolated function exportCodeSystem(LoincConcept[] concepts, string? 'version, string jsonFilePath) returns error? {
    r4:CodeSystem codeSystem;
    codeSystem = check createCodeSystemResource(concepts, 'version);

    check io:fileWriteString(jsonFilePath, codeSystem.toJson().toJsonString());
}

public isolated function convert(string filePath, string? version) returns error? {
    LoincConcept[] loincData = check readLoincCsv(filePath + LOINC_CSV_FILE_PATH);
    check exportCodeSystem(loincData, version, filePath + FHIR_LOINC_FILE_NAME);
}
