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
import ballerinax/health.fhir.r4.terminology;

//Constants
const TYPE_HEADER = "x-terminology-type";
const ZIP_FILE_NAME = "/terminology.zip";
const ZIP_FILE_EXTRACTION_PATH = "/extracted";
const FHIR_PACKAGE_PATH = "/hl7.terminology.r4/package";
const TEMPORARY_FILES_DIRECTORY_NAME = "temp_files";

// enums
enum SearchCodeProperties {
    DISPLAY = terminology:DISPLAY,
    DEFINITION = terminology:DEFINITION
};

enum ContentType {
    FHIR_JSON = "application/fhir+json",
    FHIR_XML = "application/fhir+xml",
    JSON = "application/json",
    XML = "application/xml",
    ZIP = "application/zip"
}

enum TerminologyType {
    SNOMED = "SNOMED",
    LOINC = "LOINC",
    ICD10 = "ICD10",
    RXNORM = "RXNORM",
    FHIR = "FHIR"
}

// Configurable Parameters
configurable string db_type = "postgresql";
