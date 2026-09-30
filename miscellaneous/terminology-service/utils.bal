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
import ballerina/file;
import ballerina/io;
import ballerina/jballerina.java;
import ballerina/lang.runtime;
import ballerina/regex;
import ballerina/time;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;

import ballerinacentral/zip;

// Module-level counter for unique file naming
isolated int fileCount = 0;

# Generates a new unique temporary directory path by incrementing a module-level counter.
#
# + return - The generated temporary directory path
isolated function createNewTempDirectory() returns string {
    lock {
        fileCount = fileCount + 1;
        return TEMPORARY_FILES_DIRECTORY_NAME + "/payload_" + fileCount.toString();
    }
}

# Converts a validate-code result into the standard `$validate-code` response `Parameters`.
#
# + concept - The `Parameters` returned by a successful lookup, or the `FHIRError` raised when validation fails
# + return - A `Parameters` resource with `result`, `system`, `code`, `version`, `display`, and `definition` populated, or the original `FHIRError` if it does not represent a "concept not found" failure
isolated function validationResultToParameters(r4:Parameters|r4:FHIRError concept) returns r4:Parameters|r4:FHIRError {
    r4:ParametersParameter[] params = [];
    if concept is r4:FHIRError {
        // "Can not find any valid concepts for the code:.*" covers this file's
        // own not-found paths (inline lookup, CodeableConcept with no coding,
        // a coding with no system). "Concept not found" is what
        // terminology_source.bal's findConcept raises for a code that's
        // genuinely absent from an already-resolved (persisted) CodeSystem or
        // ValueSet - per the FHIR spec, $validate-code must report that as a
        // normal result:false response, not propagate it as an error.
        if concept.message().matches(re `Can not find any valid concepts for the code:.*|Concept not found`) {
            params.push({name: "result", valueBoolean: false});
        } else {
            return concept;
        }
    } else {
        if (<r4:ParametersParameter[]>concept.'parameter).length() > 0 {
            r4:ParametersParameter? systemPart = ();
            r4:ParametersParameter? codePart = ();
            r4:ParametersParameter? versionPart = ();
            r4:ParametersParameter? displayPart = ();
            r4:ParametersParameter? definitionPart = ();
            foreach var c in <r4:ParametersParameter[]>concept.'parameter {
                _ = c.name == "name" ? params.push({name: "result", valueBoolean: true}) : "";
                if c.name == "system" {
                    systemPart = c;
                } else if c.name == "code" {
                    codePart = c;
                } else if c.name == "version" {
                    versionPart = c;
                } else if c.name == "display" {
                    displayPart = c;
                } else if c.name == "definition" {
                    definitionPart = c;
                }
            }
            // Echo system/code/version/display/definition in the conventional
            // $validate-code response order (result, system, code, version,
            // display, definition), matching what most FHIR terminology
            // servers (e.g. tx.fhir.org) return.
            _ = systemPart is r4:ParametersParameter ? params.push(systemPart) : ();
            _ = codePart is r4:ParametersParameter ? params.push(codePart) : ();
            _ = versionPart is r4:ParametersParameter ? params.push(versionPart) : ();
            _ = displayPart is r4:ParametersParameter ? params.push(displayPart) : ();
            _ = definitionPart is r4:ParametersParameter ? params.push(definitionPart) : ();
        } else {
            params.push({name: "result", valueBoolean: false});
        }
    }

    return {
        'parameter: params
    };
}

# Converts a map of raw query parameter values into FHIR `RequestSearchParameter`s recognized by the CodeSystem/ValueSet search operations.
#
# + params - The raw query parameters, keyed by parameter name, each with one or more string values
# + return - The search parameters, keyed by the same recognized parameter names
isolated function prepareRequestSearchParameter(map<string[]> params) returns map<r4:RequestSearchParameter[]> {
    map<r4:RequestSearchParameter[]> searchParams = {};
    foreach var 'key in params.keys() {
        match 'key {
            "_id" => {
                searchParams["_id"] = [createRequestSearchParameter("_id", params.get("_id")[0])];
            }

            "name" => {
                searchParams["name"] = [createRequestSearchParameter("name", params.get("name")[0])];
            }

            "title" => {
                searchParams["title"] = [createRequestSearchParameter("title", params.get("title")[0])];
            }

            "url" => {
                searchParams["url"] = [createRequestSearchParameter("url", params.get("url")[0])];
            }

            "version" => {
                r4:RequestSearchParameter[] tempList = [];
                foreach var value in params.get("version") {
                    tempList.push(createRequestSearchParameter("version", value, 'type = r4:STRING));
                }
                searchParams["version"] = tempList;
            }

            "description" => {
                searchParams["description"] = [createRequestSearchParameter("description", params.get("description")[0])];
            }

            "publisher" => {
                searchParams["publisher"] = [createRequestSearchParameter("publisher", params.get("publisher")[0])];
            }

            "status" => {
                r4:RequestSearchParameter[] tempList = [];
                foreach var value in params.get("status") {
                    tempList.push(createRequestSearchParameter("status", value, 'type = r4:REFERENCE));
                }
                searchParams["status"] = tempList;
            }

            "valueSetVersion" => {
                searchParams["valueSetVersion"] = [createRequestSearchParameter("valueSetVersion", params.get("valueSetVersion")[0])];
            }

            "filter" => {
                searchParams["filter"] = [createRequestSearchParameter("filter", params.get("filter")[0])];
            }

            "_count" => {
                searchParams["_count"] = [createRequestSearchParameter("_count", params.get("_count")[0], 'type = r4:NUMBER)];
            }

            "_offset" => {
                searchParams["_offset"] = [createRequestSearchParameter("_offset", params.get("_offset")[0], 'type = r4:NUMBER)];
            }
        }
    }
    return searchParams;
}

# Builds a single FHIR `RequestSearchParameter` from a name/value pair.
#
# + name - The search parameter name
# + value - The search parameter value
# + 'type - The FHIR search parameter type
# + modifier - The search parameter modifier
# + return - The constructed `RequestSearchParameter`
isolated function createRequestSearchParameter(string name, string value, r4:FHIRSearchParameterType? 'type = r4:STRING, r4:FHIRSearchParameterModifier? modifier = r4:MODIFIER_EXACT) returns r4:RequestSearchParameter {
    return {name: name, value: value, 'type: 'type ?: r4:STRING, typedValue: {modifier: modifier}};
}

# Converts a `CodeSystemConceptProperty` into a `$lookup`/`$validate-code` response `property` parameter, adding a human-readable description sub-part for known SNOMED module and LOINC CLASSTYPE codes.
#
# + property - The concept property to convert
# + return - The `property` `ParametersParameter`, with a `code`/`value` part for the property and an optional `description` part
isolated function codeSystemConceptPropertyToParameter(r4:CodeSystemConceptProperty property) returns r4:ParametersParameter {
    r4:ParametersParameter param = {name: "property"};
    r4:ParametersParameter[] part = [];

    if property.valueString is string {
        part.push(
            {name: "code", valueCode: property.code},
            {name: "value", valueString: property.valueString}
        );
    } else if property.valueCoding is r4:Coding {
        part.push(
            {name: "code", valueCode: property.code},
            {name: "value", valueCoding: property.valueCoding}
        );
    } else if property.valueCode is r4:code {
        part.push(
            {name: "code", valueCode: property.code},
            {name: "value", valueCode: property.valueCode}
        );
    } else if property.valueBoolean is boolean {
        part.push(
            {name: "code", valueCode: property.code},
            {name: "value", valueBoolean: property.valueBoolean}
        );
    } else if property.valueInteger is int {
        part.push(
            {name: "code", valueCode: property.code},
            {name: "value", valueInteger: property.valueInteger}
        );
    } else if property.valueDecimal is decimal {
        part.push(
            {name: "code", valueCode: property.code},
            {name: "value", valueDecimal: property.valueDecimal}
        );
    } else if property.valueDateTime is string {
        part.push(
            {name: "code", valueCode: property.code},
            {name: "value", valueDateTime: property.valueDateTime}
        );
    }

    if property.code == "module" && property.valueCode is r4:code {
        string? moduleDesc = snomedModuleDisplay(<string>property.valueCode);
        if moduleDesc is string {
            part.push({name: "description", valueString: moduleDesc});
        }
    }

    if property.code == "CLASSTYPE" && property.valueString is string {
        string? classTypeDesc = loincClassTypeDisplay(<string>property.valueString);
        if classTypeDesc is string {
            part.push({name: "description", valueString: classTypeDesc});
        }
    }

    if part.length() > 0 {
        param.part = part;
    }

    return param;
}

# Returns the display name for the handful of SNOMED module SCTIDs seen in practice. Unknown modules (extension-specific ones especially) are left without a description sub-part rather than guessed at.
#
# + moduleId - The SNOMED module SCTID
# + return - The display name for the module, or `()` if it is not one of the known modules
isolated function snomedModuleDisplay(string moduleId) returns string? {
    map<string> moduleDisplays = {
        "900000000000207008": "SNOMED CT core module",
        "900000000000012004": "SNOMED CT model component module"
    };
    return moduleDisplays[moduleId];
}

# Returns the display name for a LOINC CLASSTYPE code. LOINC's CLASSTYPE is a small fixed enum (LOINC Users' Guide Section 2.11).
#
# + classType - The LOINC CLASSTYPE code
# + return - The display name for the class type, or `()` if it is not one of the known codes
isolated function loincClassTypeDisplay(string classType) returns string? {
    map<string> classTypeDisplays = {
        "1": "Laboratory class",
        "2": "Clinical class",
        "3": "Claims attachments",
        "4": "Surveys"
    };
    return classTypeDisplays[classType];
}

# Extracts the downloaded package zip file within the given directory.
#
# + dirPath - The directory containing the zip file, used as the base for both the zip file path and the extraction path
# + return - An `error` if extraction fails, `()` otherwise
isolated function extractZipFile(string dirPath) returns error? {
    check zip:extract(dirPath + ZIP_FILE_NAME, dirPath + ZIP_FILE_EXTRACTION_PATH);
}

// zip:extract (ballerinacentral/zip, backed by zip4j) never closes the
// ZipFile handle it opens to read the archive, so on Windows the extracted
// zip's own file stays locked - by the JVM's own still-open handle, not by
// anything external - until that ZipFile object is garbage-collected and its
// finalizer runs. An immediate `file:remove` of the containing directory can
// therefore fail with "The process cannot access the file because it is
// being used by another process" for a lot longer than a brief race; a
// System.gc() nudge before each retry is what actually clears it. This is a
// no-op on platforms that don't lock open files.
const int REMOVE_DIRECTORY_MAX_ATTEMPTS = 8;
const decimal REMOVE_DIRECTORY_RETRY_DELAY = 0.3;

isolated function suggestGarbageCollection() = @java:Method {
    'class: "java.lang.System",
    name: "gc"
} external;

# Removes the given directory and all of its contents, if it exists.
#
# + dirPath - The path of the directory to remove
# + return - An `error` if the removal still fails after retrying, `()` otherwise
isolated function removeDirectory(string dirPath) returns error? {
    error? lastError = ();
    foreach int attempt in 1 ... REMOVE_DIRECTORY_MAX_ATTEMPTS {
        if !(check file:test(dirPath, file:EXISTS)) {
            return;
        }
        error? removeResult = file:remove(dirPath, file:RECURSIVE);
        if removeResult is () {
            return;
        }
        lastError = removeResult;
        if attempt < REMOVE_DIRECTORY_MAX_ATTEMPTS {
            suggestGarbageCollection();
            runtime:sleep(REMOVE_DIRECTORY_RETRY_DELAY);
        }
    }
    return lastError;
}

# Saves an incoming compressed payload stream to disk as a zip file, recreating the target directory first.
#
# + payloadStream - The stream of the compressed payload bytes
# + dirPath - The directory to (re)create and write the zip file into
# + return - An `error` if the directory setup or write fails, `()` otherwise
isolated function saveCompressedPayload(stream<byte[], io:Error?> payloadStream, string dirPath) returns error? {
    check removeDirectory(dirPath);
    check file:createDir(dirPath, file:RECURSIVE);

    check io:fileWriteBlocksFromStream(dirPath + ZIP_FILE_NAME, payloadStream);
}

# Reads the extracted FHIR package directory and groups its CodeSystem and ValueSet JSON files.
#
# + path - The base directory containing the extracted FHIR package
# + return - The CodeSystem and ValueSet JSON contents grouped by resource type, or an `error` if reading fails
isolated function readFilesForUpload(string path) returns CodeSystemValueSetJson|error {
    file:MetaData[] readDir = check file:readDir(path + FHIR_PACKAGE_PATH);

    CodeSystemValueSetJson jsonArrays = {
        codeSystems: [],
        valueSets: []
    };

    foreach var item in readDir {
        string[] nonEmptyParts = regex:split(item.absPath, "\\\\").filter(s => s != "");
        string lastPart = nonEmptyParts[nonEmptyParts.length() - 1];

        if lastPart.endsWith(".json") && lastPart.startsWith("CodeSystem-") {
            jsonArrays.codeSystems.push(check io:fileReadJson(item.absPath));
        } else if lastPart.endsWith(".json") && lastPart.startsWith("ValueSet-") {
            jsonArrays.valueSets.push(check io:fileReadJson(item.absPath));
        }
    }

    return jsonArrays;
}

# Reads all JSON files in the given directory and returns their parsed contents.
#
# + path - The directory to read JSON files from
# + return - The parsed JSON contents of every `.json` file found, or an `error` if reading fails
isolated function readFilesAsJsons(string path) returns json[]|error {
    file:MetaData[] readDir = check file:readDir(path);

    json[] jsonList = [];

    foreach var item in readDir {
        string[] nonEmptyParts = regex:split(item.absPath, "\\\\").filter(s => s != "");
        string lastPart = nonEmptyParts[nonEmptyParts.length() - 1];

        if lastPart.endsWith(".json") {
            jsonList.push(check io:fileReadJson(item.absPath));
        }
    }

    return jsonList;
}

# Reads a JSON file from disk and parses it into a FHIR `CodeSystem`.
#
# + path - The path of the JSON file to read
# + return - The parsed `CodeSystem`, or an `error` if reading or parsing fails
isolated function readFileJsonAndReturnCodeSystem(string path) returns r4:CodeSystem|error {
    string jsonString = check io:fileReadString(path);
    return check parser:parse(jsonString).ensureType();
}

# Module initializer that clears out any leftover temporary files directory from a previous run.
#
# + return - An `error` if the cleanup fails, `()` otherwise
function init() returns error? {
    check removeDirectory(TEMPORARY_FILES_DIRECTORY_NAME);
}

# Builds a `ValueSetExpansion` containing the given concepts, stamped with the current time.
#
# + vs - The `ValueSet` being expanded
# + concepts - The concepts to include in the expansion
# + return - The resulting `ValueSetExpansion`
isolated function createExpandedValueSet(r4:ValueSet vs, r4:ValueSetExpansionContains[] concepts) returns r4:ValueSetExpansion {
    r4:ValueSetExpansionContains[] contains = [];
    foreach r4:ValueSetExpansionContains concept in concepts {
        r4:ValueSetExpansionContains c = {
            code: concept.code,
            display: concept.display,
            id: concept.id,
            system: concept.system,
            'version: concept.'version,
            'abstract: concept.'abstract,
            inactive: concept.inactive
        };
        contains.push(c);
    }
    r4:ValueSetExpansion expansion = {timestamp: time:utcToString(time:utcNow()), contains: contains};
    return expansion;
}

# Extracts the search parameters attached to the FHIR request held by the given `FHIRContext`.
#
# + fhirContext - The FHIR context to extract search parameters from
# + return - The request's search parameters, or an empty map if the context holds no request, or an `error` if the search parameters could not be converted
public isolated function getSearchParametersFromFHIRContext(r4:FHIRContext fhirContext) returns map<r4:RequestSearchParameter[]>|error {

    map<r4:RequestSearchParameter[]>|error searchParameters = {};

    r4:FHIRRequest? fhirRequest = fhirContext.getFHIRRequest();
    if fhirRequest !is () {
        searchParameters = check fhirRequest.getSearchParameters().cloneWithType();
    }
    return searchParameters;
}

