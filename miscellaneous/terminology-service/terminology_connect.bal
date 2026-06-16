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

import terminology_service.loinc_to_fhir as loinc;
import terminology_service.snomed_to_fhir as snomed;

import ballerina/http;
import ballerina/regex;
import ballerina/time;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.terminology;
import ballerina/log;

final TerminologySource terminology_source = new TerminologySource();

public isolated function readCodeSystemById(string id) returns r4:FHIRError|r4:CodeSystem|r4:FHIRError {
    string[] split = regex:split(id, string `\|`);
    string code_system_id = split[0];
    string? code_system_id_version = split.length() > 1 ? split[1] : ();

    return terminology:readCodeSystemById(id = code_system_id, version = code_system_id_version, terminology = terminology_source);
}

public isolated function readValueSetById(string id) returns r4:ValueSet|r4:FHIRError {
    string[] split = regex:split(id, string `\|`);
    string value_set_id = split[0];
    string? value_set_id_version = split.length() > 1 ? split[1] : ();

    return terminology:readValueSetById(id = value_set_id, version = value_set_id_version, terminology = terminology_source);
}

public isolated function readCodeSystemByUrl(string url) returns r4:CodeSystem|r4:FHIRError {
    string[] split = regex:split(url, string `\|`);
    string code_system_url = split[0];
    string? code_system_url_version = split.length() > 1 ? split[1] : ();

    return terminology:readCodeSystemByUrl(url = code_system_url, version = code_system_url_version, terminology = terminology_source);
}

public isolated function readValueSetByUrl(string url) returns r4:ValueSet|r4:FHIRError {
    string[] split = regex:split(url, string `\|`);
    string value_set_url = split[0];
    string? value_set_url_version = split.length() > 1 ? split[1] : ();

    return terminology:readValueSetByUrl(url = value_set_url, version = value_set_url_version, terminology = terminology_source);
}

public isolated function searchValueSet(r4:FHIRContext ctx) returns r4:Bundle|r4:FHIRError {
    
    map<r4:RequestSearchParameter[]>|error params = getSearchParametersFromFHIRContext(ctx);

    if params is error {
        log:printError("Failed to get search parameters from FHIR context", 'error = params);
        return r4:createFHIRError(
                "Invalid search parameters",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = params,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:ValueSet[] valueSets = check terminology:searchValueSets(params, terminology = terminology_source);

    r4:BundleEntry[] entries = valueSets.'map(v => <r4:BundleEntry>{'resource: v, search: {mode: r4:MATCH}});

    return {
        'type: r4:BUNDLE_TYPE_SEARCHSET,
        meta: {
            lastUpdated: time:utcToString(time:utcNow())
        },
        total: entries.length(),
        entry: entries
    };
}

public isolated function searchCodeSystem(r4:FHIRContext ctx) returns r4:Bundle|r4:FHIRError {
    map<r4:RequestSearchParameter[] & readonly> & readonly params = ctx.getRequestSearchParameters();
    map<r4:RequestSearchParameter[]>|error clonedParams =  params.cloneWithType();

    if clonedParams is error {
        return r4:createFHIRError(
                "Invalid search parameters blah",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:CodeSystem[] codeSystems = check terminology:searchCodeSystems(clonedParams, terminology = terminology_source);

    r4:BundleEntry[] entries = codeSystems.'map(c => <r4:BundleEntry>{'resource: c.toJson(), search: {mode: r4:MATCH}});

    return {
        'type: r4:BUNDLE_TYPE_SEARCHSET,
        meta: {
            lastUpdated: time:utcToString(time:utcNow())
        },
        total: entries.length(),
        entry: entries
    };
}

public isolated function valueSetExpansionGet(r4:FHIRContext ctx, string? id = ()) returns r4:ValueSet|r4:FHIRError {
    map<r4:RequestSearchParameter[] & readonly> & readonly searchParameters = ctx.getRequestSearchParameters();
    map<r4:RequestSearchParameter[]> mutableParams = {};
    foreach var [k, v] in searchParameters.entries() {
        mutableParams[k] = v;
    }

    r4:ValueSet valueSet = {status: "unknown"};

    if id is string {
        valueSet = check terminology:valueSetExpansion(mutableParams, vs = check readValueSetById(id), terminology = terminology_source);
    } else {
        string? system = searchParameters["url"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>searchParameters["url"])[0].value : ();
        valueSet = check terminology:valueSetExpansion(mutableParams, system = system, terminology = terminology_source);
    }

    return valueSet;
}

public isolated function valueSetExpansionPost(r4:FHIRContext ctx, r4:Parameters parameters, string? id = ()) returns r4:ValueSet|r4:FHIRError {
    map<r4:RequestSearchParameter[] & readonly> & readonly searchParameters = ctx.getRequestSearchParameters();
    map<r4:RequestSearchParameter[]> mutableParams = {};
    foreach var [k, v] in searchParameters.entries() {
        mutableParams[k] = v;
    }

    r4:ValueSet valueSet = {status: "unknown"};
    if id is string {
        valueSet = check terminology:valueSetExpansion(mutableParams, vs = check readValueSetById(id), terminology = terminology_source);
    } else {
        json paramsJson = parameters.toJson();
        json parametersArray = (paramsJson is map<json>) ? (paramsJson["parameter"] ?: []) : [];
        if parametersArray is json[] && parametersArray.length() > 0 {
            foreach json paramItem in parametersArray {
                if paramItem is map<json> && paramItem["name"] == "valueSet" {
                    json? resourceJson = paramItem["resource"];
                    if resourceJson is map<json> {
                        r4:ValueSet|error vs = resourceJson.cloneWithType(r4:ValueSet);
                        valueSet = vs is r4:ValueSet ? vs : valueSet;
                    }
                }
            }
            valueSet = check terminology:valueSetExpansion(mutableParams, vs = valueSet, terminology = terminology_source);
        } else {
            string? system = searchParameters["url"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>searchParameters["url"])[0].value : ();
            valueSet = check terminology:valueSetExpansion(mutableParams, system = system, terminology = terminology_source);
        }
    }
    return valueSet;
}

public isolated function valueSetValidateCodePost(r4:FHIRContext ctx, r4:Parameters parameters) returns r4:Parameters|r4:FHIRError {
    r4:Parameters|r4:FHIRError concept = valueSetLookUpPost(ctx, parameters);
    return validationResultToParameters(concept);
}

public isolated function valueSetValidateCodeGet(r4:FHIRContext ctx, string? id = ()) returns r4:Parameters|r4:FHIRError {
    r4:Parameters|r4:FHIRError concept = valueSetLookUpGet(ctx, id);
    return validationResultToParameters(concept);
}

public isolated function codeSystemLookUpGet(r4:FHIRContext ctx, string? id = ()) returns r4:Parameters|r4:FHIRError {

    map<r4:RequestSearchParameter[] & readonly> & readonly idParam = ctx.getRequestSearchParameters();

    string? system = idParam["system"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["system"])[0].value : ();
    string? code = idParam["code"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["code"])[0].value : ();
    string? 'version = idParam["version"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["version"])[0].value : ();
    r4:code|r4:Coding? codeValue = code;

    if codeValue !is r4:code|r4:Coding {
        return r4:createFHIRError(
                "Invalid request payload, Code value is missing",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:CodeSystemConcept[]|r4:CodeSystemConcept result;

    if id is string {
        result = check terminology:codeSystemLookUp(<r4:code>codeValue, system = (check readCodeSystemById(id)).url, version = 'version, terminology = terminology_source);
    } else if system is string {
        result = check terminology:codeSystemLookUp(<r4:code>codeValue, system = system, version = 'version, terminology = terminology_source);
    } else {
        return r4:createFHIRError(
                "Can not find a CodeSystem",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    return codesystemConceptsToParameters(result);
}

public isolated function codeSystemLookUpPost(r4:FHIRContext ctx, r4:Parameters parameters) returns r4:Parameters|r4:FHIRError {
    r4:Coding? codingValue = ();
    r4:uri? system = ();

    r4:Parameters|error typedParams = parameters.toJson().cloneWithType(r4:Parameters);
    if typedParams is error {
        return r4:createFHIRError("Invalid request payload", r4:ERROR, r4:INVALID_REQUIRED, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if typedParams.'parameter is r4:ParametersParameter[] {
        foreach var item in <r4:ParametersParameter[]>typedParams.'parameter {
            match item.name {
                "coding" => {
                    codingValue = item.valueCoding;
                    if (<r4:Coding>codingValue).system is r4:uri {
                        system = (<r4:Coding>codingValue).system;
                    }
                }
            }
        }
    } else {
        return r4:createFHIRError(
                "Invalid Coding value",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:CodeSystemConcept[]|r4:CodeSystemConcept result;
    if codingValue !is r4:Coding {
        return r4:createFHIRError(
                "Invalid request payload",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    } else if system is string {
        result = check terminology:codeSystemLookUp(codingValue, system = system, terminology = terminology_source);
    } else {
        return r4:createFHIRError(
                "Can not find a CodeSystem",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    return codesystemConceptsToParameters(result);
}

public isolated function valueSetLookUpPost(r4:FHIRContext ctx, r4:Parameters parameters) returns r4:Parameters|r4:FHIRError {
    r4:Coding?|r4:CodeableConcept? codingValue = ();
    r4:ValueSet? valueSet = ();

    r4:Parameters|error parse = parameters.toJson().cloneWithType(r4:Parameters);
    if parse is r4:Parameters && parse.'parameter is r4:ParametersParameter[] {
        foreach var item in <r4:ParametersParameter[]>parse.'parameter {
            match item.name {
                "coding" => {
                    codingValue = <r4:Coding>item.valueCoding;
                }

                "codeableConcept" => {
                    codingValue = <r4:CodeableConcept>item.valueCodeableConcept;
                }

                "valueSet" => {
                    anydata temp = item.'resource is r4:Resource ? item.'resource : ();
                    r4:ValueSet|error cloneWithType = temp.cloneWithType(r4:ValueSet);
                    if cloneWithType is r4:ValueSet {
                        valueSet = cloneWithType;
                    }
                }
            }
        }
    } else {
        return r4:createFHIRError(
                "Invalid request payload",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = parse is error ? parse : (),
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if valueSet is r4:ValueSet && (codingValue is r4:Coding || codingValue is r4:CodeableConcept) {
        return codesystemConceptsToParameters(check terminology:valueSetLookUp(codingValue, vs = valueSet, terminology = terminology_source));
    } else {
        return r4:createFHIRError(
                "Invalid request payload",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }
}

public isolated function valueSetLookUpGet(r4:FHIRContext ctx, string? id = (), string? reqSystem = (), string? reqCodeValue = ()) returns r4:Parameters|r4:FHIRError {
    map<r4:RequestSearchParameter[] & readonly> & readonly searchParams = ctx.getRequestSearchParameters();
    string? system = searchParams["system"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>searchParams["system"])[0].value : reqSystem;
    r4:code? codeValue = searchParams["code"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>searchParams["code"])[0].value : reqCodeValue;

    if codeValue !is r4:code|r4:Coding|r4:CodeableConcept {
        return r4:createFHIRError(
                "Can not find a ValueSet, Code value is missing",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:CodeSystemConcept[]|r4:CodeSystemConcept|r4:FHIRError result;
    if id is string {
        result = terminology:valueSetLookUp(<r4:code>codeValue, vs = check readValueSetById(id), terminology = terminology_source);
    } else if system is string {
        result = terminology:valueSetLookUp(<r4:code>codeValue, vs = check readValueSetByUrl(system), terminology = terminology_source);
    } else {
        return r4:createFHIRError(
                "Can not find a ValueSet",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if result is r4:FHIRError {
        return result;
    }

    return codesystemConceptsToParameters(result);
}

public isolated function subsumesGet(r4:FHIRContext ctx) returns r4:Parameters|r4:FHIRError {
    map<r4:RequestSearchParameter[] & readonly> & readonly idParam = ctx.getRequestSearchParameters();

    string? 'version = idParam["version"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["version"])[0].value : ();
    r4:uri? system = idParam["system"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["system"])[0].value : ();
    r4:code? codeA = idParam["codeA"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["codeA"])[0].value : ();
    r4:code? codeB = idParam["codeB"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["codeB"])[0].value : ();

    if system is string && codeA is r4:code && codeB is r4:code {
        // NOTE: replace the subsume function in terminology library by this subsume function
        // because this implementation is more efficient than the one in terminology library
        return terminology_source.subsumes(codeA = codeA, codeB = codeB, system = system, version = 'version);
    } else {
        return r4:createFHIRError(
                "Missing required input parameters",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }
}

public isolated function subsumesPost(r4:FHIRContext ctx, r4:Parameters parameters) returns r4:Parameters|r4:FHIRError {
    string? 'version = ();
    r4:uri? system = ();
    r4:Coding? codingA = ();
    r4:Coding? codingB = ();

    r4:Parameters|error typedParams = parameters.toJson().cloneWithType(r4:Parameters);
    if typedParams is error {
        return r4:createFHIRError("Invalid request payload", r4:ERROR, r4:INVALID_REQUIRED, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    // json|http:ClientError jsonPayload = request.getJsonPayload();
    if typedParams.'parameter is r4:ParametersParameter[] {
        foreach var item in <r4:ParametersParameter[]>typedParams.'parameter {
            match item.name {
                "codingA" => {
                    codingA = item.valueCoding ?: ();
                }

                "codingB" => {
                    codingB = item.valueCoding ?: ();
                }

                "version" => {
                    'version = item.valueString ?: ();
                }

                "system" => {
                    system = item.valueUri ?: ();
                }
            }
        }
    }

    if system is string && codingA is r4:Coding && codingB is r4:Coding {
        // NOTE: replace the subsume function in terminology library by this subsume function
        // because this implementation is more efficient than the one in terminology library
        return terminology_source.subsumes(codeA = <r4:code>codingA.code, codeB = <r4:code>codingB.code, system = system, version = 'version);
    } else {
        return r4:createFHIRError(
                "Missing required input parameters",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }
}

public isolated function batchValidateValueSets(r4:Bundle bundle) returns r4:Bundle|r4:FHIRError {
    
    if bundle.'type != r4:BUNDLE_TYPE_BATCH {
        return r4:createFHIRError(
                "Not a batch type bundle",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:BundleEntry[] responseEntries = [];
    r4:BundleEntry[]? entries = bundle.entry;
    if entries != () {
        foreach r4:BundleEntry entry in entries {
            if entry.request is r4:BundleEntryRequest {
                
                r4:BundleEntryRequest? entryRequest = entry.request;
                
                if entryRequest is () {
                    return r4:createFHIRError(
                        "No entry requests found in the bundle",
                        r4:ERROR,
                        r4:INVALID_REQUIRED,
                        httpStatusCode = http:STATUS_BAD_REQUEST);
                }

                // split the url to get system and code
                map<string> urlParts = getSystemAndCode(entryRequest.url);
                string? system = urlParts["system"];
                r4:code? code = urlParts["code"];

                r4:Parameters|r4:FHIRError result;
                if code is r4:code && system is string {
                    r4:CodeSystemConcept[]|r4:CodeSystemConcept|r4:FHIRError lookupResult = terminology:valueSetLookUp(code, vs = check readValueSetByUrl(system), terminology = terminology_source);
                    result = lookupResult is r4:FHIRError ? lookupResult : codesystemConceptsToParameters(lookupResult);
                } else {
                    result = r4:createFHIRError("Missing required parameters", r4:ERROR, r4:INVALID_REQUIRED, httpStatusCode = http:STATUS_BAD_REQUEST);
                }

                if result is r4:Parameters {
                    responseEntries.push({
                        'resource: check validationResultToParameters(result)
                    });
                } else {
                    responseEntries.push({
                        'resource: <r4:Parameters>{
                            'parameter: [
                                {
                                    name: "result",
                                    valueBoolean: false
                                },
                                {
                                    name: "message",
                                    valueString: result.message()
                                }
                            ]
                        }
                    });
                }
            }
        }
    } else {
        return r4:createFHIRError(
                "No entries in the bundle",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    return {
        'type: r4:BUNDLE_TYPE_BATCH_RESPONSE,
        entry: responseEntries
    };
}

isolated function getSystemAndCode(string input) returns map<string> {
    // Split the string at '?' to separate the base URL and query parameters
    string[] parts = regex:split(input, string `\?`);

    if parts.length() < 2 {
        return {};
    }

    string queryParams = parts[1];

    // Split query parameters using '&'
    string[] params = regex:split(queryParams, string `&`);

    string system = "";
    string code = "";

    foreach var param in params {
        // Split each parameter by '='
        string[] keyValue = regex:split(param, string `=`);
        if keyValue.length() == 2 {
            if keyValue[0] == "system" {
                system = keyValue[1];
            } else if keyValue[0] == "code" {
                code = keyValue[1];
            }
        }
    }

    return {"system": system, "code": code};
}

public isolated function addCodeSystem(r4:FHIRContext ctx, r4:CodeSystem codeSystem) returns r4:FHIRError? {
    do {
        return terminology:addCodeSystem(codeSystem, terminology = terminology_source);
    } on fail var e {
        return r4:createFHIRError(
                "Invalid request payload, " + e.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = e,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
}

public isolated function addValueSet(r4:FHIRContext ctx, r4:ValueSet valueSet) returns r4:FHIRError? {
    do {
        return terminology:addValueSet(valueSet, terminology = terminology_source);
    } on fail var e {
        return r4:createFHIRError(
                "Invalid request payload, " + e.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = e,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
}

public isolated function upload(http:Request payload) returns r4:FHIRError? {
    if payload.getContentType() != ZIP {
        return r4:createFHIRError(
                "Invalid request payload, content type is not supported",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                diagnostic = "The request payload should be a zip file",
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    do {
        string|error typeHeader = payload.getHeader(TYPE_HEADER);

        if typeHeader is error {
            return r4:createFHIRError(
                    string `Missing ${TYPE_HEADER} header in the request`,
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    diagnostic = string `The request should contains ${TYPE_HEADER} header and supported values are: FHIR, LOINC and SNOMED`,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }
        else if typeHeader != FHIR && typeHeader != LOINC && typeHeader != SNOMED {
            return r4:createFHIRError(
                    string `Invalid ${TYPE_HEADER} header value`,
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    diagnostic = string `The request should contains ${TYPE_HEADER} header and supported values are: FHIR, LOINC and SNOMED`,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }

        string dirPath = createNewTempDirectory();

        check saveCompressedPayload(check payload.getByteStream(), dirPath);
        check extractZipFile(dirPath);

        r4:FHIRError? result = ();

        // standard FHIR
        if typeHeader == FHIR {
            CodeSystemValueSetJson jsonArrays = check readFilesForUpload(dirPath + ZIP_FILE_EXTRACTION_PATH);

            _ = terminology:addCodeSystemsAsJson(jsonArrays.codeSystems, terminology = terminology_source);
            _ = terminology:addValueSetsAsJson(jsonArrays.valueSets, terminology = terminology_source);
        }

        // LOINC
        else if typeHeader == LOINC {
            string? version = payload.getQueryParamValue("loinc-version");
            check loinc:convert(dirPath + ZIP_FILE_EXTRACTION_PATH, version);

            r4:CodeSystem codeSystem = check readFileJsonAndReturnCodeSystem(dirPath + ZIP_FILE_EXTRACTION_PATH + loinc:FHIR_LOINC_FILE_NAME);

            result = terminology:addCodeSystem(codeSystem, terminology = terminology_source);
        }

        // SNOMED
        else if typeHeader == SNOMED {
            string? version = payload.getQueryParamValue("snomed-version");
            check snomed:convert(dirPath + ZIP_FILE_EXTRACTION_PATH, version);

            r4:CodeSystem codeSystem = check readFileJsonAndReturnCodeSystem(dirPath + ZIP_FILE_EXTRACTION_PATH + snomed:FHIR_SNOMED_FILE_NAME);

            result = terminology:addCodeSystem(codeSystem, terminology = terminology_source);
        }

        _ = start removeDirectory(dirPath);

        return result;
    } on fail var e {
        return r4:createFHIRError(
                "Invalid request payload, " + e.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = e,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
}

public isolated function findCodeGet(http:Request request) returns r4:Bundle|r4:FHIRError {
    string property = request.getQueryParamValue("property") ?: DISPLAY;
    string? system = request.getQueryParamValue("system");
    string? filter = request.getQueryParamValue("filter");
    int count;
    int offset;

    do {
        if filter is () {
            check error("Missing 'filter' query parameter");
        }

        if !(property == DISPLAY || property == DEFINITION) {
            check error("Invalid property value. Only 'display' or 'definition' are allowed.");
        }

        string? countStr = request.getQueryParamValue("_count");
        string? offsetStr = request.getQueryParamValue("_offset");

        count = countStr is string ? check int:fromString(countStr) : terminology:TERMINOLOGY_SEARCH_DEFAULT_COUNT;
        offset = offsetStr is string ? check int:fromString(offsetStr) : 0;
    } on fail var e {
        return r4:createFHIRError(
                "Invalid request payload, " + e.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = e,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    terminology:CodeConceptDetails[]|r4:FHIRError result = terminology_source.searchConcept(<DISPLAY|DEFINITION>property, <string>filter, system, offset, count);

    if result is r4:FHIRError {
        return result;
    }

    return codeSystemDetailsIntoBundle(result);
}

public isolated function findCodePost(http:Request request) returns r4:Bundle|r4:FHIRError {
    string property = DISPLAY;
    string? system = ();
    string? filter = ();
    int count = terminology:TERMINOLOGY_SEARCH_DEFAULT_COUNT;
    int offset = 0;

    json|http:ClientError jsonPayload = request.getJsonPayload();
    if jsonPayload is json {
        r4:Parameters|error parameters = jsonPayload.cloneWithType(r4:Parameters);
        if parameters is r4:Parameters && parameters.'parameter is r4:ParametersParameter[] {
            foreach var item in <r4:ParametersParameter[]>parameters.'parameter {
                match item.name {
                    "property" => {
                        property = item.valueString ?: DISPLAY;
                    }
                    "system" => {
                        system = item.valueString ?: ();
                    }
                    "filter" => {
                        filter = item.valueString ?: ();
                    }
                    "_count" => {
                        count = item.valueInteger is int ? <int>item.valueInteger : terminology:TERMINOLOGY_SEARCH_DEFAULT_COUNT;
                    }
                    "_offset" => {
                        offset = item.valueInteger is int ? <int>item.valueInteger : 0;
                    }
                }
            }
        } else {
            return r4:createFHIRError(
                    "Invalid request payload",
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    cause = parameters is error ? parameters : (),
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }
    } else {
        return r4:createFHIRError(
                "Empty request payload",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if filter is () {
        return r4:createFHIRError(
                "Missing 'filter' parameter",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if !(property == DISPLAY || property == DEFINITION) {
        return r4:createFHIRError(
                "Invalid property value. Only 'display' or 'definition' are allowed.",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    terminology:CodeConceptDetails[]|r4:FHIRError result = terminology_source.searchConcept(<DISPLAY|DEFINITION>property, <string>filter, system, offset, count);

    if result is r4:FHIRError {
        return result;
    }

    return codeSystemDetailsIntoBundle(result);
}
