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
import ballerina/log;
import ballerina/time;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.terminology;

# Load the FHIR R4 CodeSystems and the HL7 terminology (THO) CodeSystems bundled with the terminology
# library into the database at startup. Ones already stored (same url and version) are left as they are.
configurable boolean load_default_code_systems = true;

# Stores every bundled FHIR CodeSystem that is not yet in the database. Idempotent, so it runs on every
# startup and only does work the first time (or after a new library version adds CodeSystems).
function loadDefaultCodeSystems() {
    json[] codeSystems = [];
    foreach string bundled in [terminology:DEFAULT_FHIR_CODE_SYSTEMS, terminology:EXTERNAL_FHIR_CODE_SYSTEMS] {
        json|error parsed = bundled.fromJsonString();
        if parsed is json[] {
            codeSystems.push(...parsed);
        } else {
            log:printError("Could not read the bundled FHIR CodeSystems", 'error = parsed is error ? parsed : ());
        }
    }

    decimal started = time:monotonicNow();
    int added = 0;
    int present = 0;
    string[] rejected = [];
    foreach json item in codeSystems {
        // Check for an existing copy from the raw JSON first: converting all of them to records on every
        // startup, only to find they are already stored, would dominate startup time.
        json|error rawUrl = item.url;
        json|error rawVersion = item.'version;
        if rawUrl is string && rawVersion is string && terminology_source.isCodeSystemExist(rawUrl, rawVersion) {
            present += 1;
            continue;
        }
        r4:CodeSystem|error codeSystem = item.cloneWithType();
        if codeSystem is error {
            rejected.push(rawUrl is string ? rawUrl : string `(unparseable: ${codeSystem.message()})`);
            continue;
        }
        string? url = codeSystem.url;
        r4:FHIRError? result = terminology:addCodeSystem(codeSystem, terminology = terminology_source);
        if result is r4:FHIRError {
            rejected.push(url ?: "(no url)");
            log:printDebug(string `Bundled CodeSystem ${url ?: "(no url)"} not loaded: ${result.message()}`);
        } else {
            added += 1;
        }
    }

    decimal seconds = time:monotonicNow() - started;
    log:printInfo(string `Default FHIR CodeSystems: ${added} loaded, ${present} already present, ${rejected.length()} rejected (${seconds.round(1)}s)`);
    if rejected.length() > 0 {
        log:printWarn(string `Bundled CodeSystems rejected by validation: ${string:'join(", ", ...rejected)}`);
    }
}
