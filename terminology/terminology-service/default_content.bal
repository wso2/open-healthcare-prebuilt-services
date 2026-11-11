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

# Outcome of loading a set of CodeSystems.
type CodeSystemLoadSummary record {|
    # Number of CodeSystems stored
    int added = 0;
    # Number already stored with the same url and version
    int present = 0;
    # Urls of entries that are invalid (unparseable, or refused by validation with a 4xx); never retried
    string[] rejected = [];
    # Urls of entries that could not be stored (5xx). The partial load is removed, so they are retried
    # on the next startup.
    string[] failed = [];
|};

# Stores every bundled FHIR CodeSystem that is not yet in the database. Idempotent, so it runs on every
# startup and only does work the first time (or after a new library version adds CodeSystems, or after
# an earlier start failed to store some).
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
    CodeSystemLoadSummary summary = loadCodeSystems(codeSystems);
    decimal seconds = time:monotonicNow() - started;

    log:printInfo(string `Default FHIR CodeSystems: ${summary.added} loaded, ${summary.present} already present, ${
        summary.rejected.length()} rejected as invalid, ${summary.failed.length()} failed to store (${seconds.round(1)}s)`);
    if summary.rejected.length() > 0 {
        log:printWarn(string `Bundled CodeSystems rejected as invalid: ${string:'join(", ", ...summary.rejected)}`);
    }
    if summary.failed.length() > 0 {
        log:printError(string `Bundled CodeSystems that could not be stored, to be retried on the next startup: ${
            string:'join(", ", ...summary.failed)}`);
    }
}

# Stores each CodeSystem that is not yet in the database, classifying the ones that are not stored.
#
# + codeSystems - The CodeSystems to load, as FHIR JSON
# + return - What was stored, skipped, rejected and failed
function loadCodeSystems(json[] codeSystems) returns CodeSystemLoadSummary {
    CodeSystemLoadSummary summary = {};
    foreach json item in codeSystems {
        // Check for an existing copy from the raw JSON first: converting all of them to records on every
        // startup, only to find they are already stored, would dominate startup time.
        json|error rawUrl = item.url;
        json|error rawVersion = item.'version;
        if rawUrl is string && rawVersion is string && terminology_source.isCodeSystemExist(rawUrl, rawVersion) {
            summary.present += 1;
            continue;
        }
        r4:CodeSystem|error codeSystem = item.cloneWithType();
        if codeSystem is error {
            summary.rejected.push(rawUrl is string ? rawUrl : string `(unparseable: ${codeSystem.message()})`);
            continue;
        }
        string url = codeSystem.url ?: "(no url)";
        r4:FHIRError? result = terminology:addCodeSystem(codeSystem, terminology = terminology_source);
        if result is () {
            summary.added += 1;
        } else if result.detail().httpStatusCode < 500 {
            // The library's own checks (missing url/version, validation, duplicate) report 4xx.
            summary.rejected.push(url);
            log:printDebug(string `Bundled CodeSystem ${url} rejected: ${result.message()}`);
        } else {
            // The service's database writes report 5xx; addCodeSystem has already removed the partial load.
            summary.failed.push(url);
            log:printError(string `Bundled CodeSystem ${url} could not be stored: ${result.message()}`);
        }
    }
    return summary;
}
