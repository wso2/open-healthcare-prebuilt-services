import terminology_service_api.loinc_to_fhir as loinc;
import terminology_service_api.snomed_to_fhir as snomed;

import ballerina/data.jsondata;
import ballerina/data.xmldata;
import ballerina/http;
import ballerina/regex;
import ballerina/time;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.terminology;

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

public isolated function searchValueSet(http:Request request) returns r4:Bundle|r4:FHIRError {
    map<string[]> searchParams = request.getQueryParams();
    map<r4:RequestSearchParameter[]> params = prepareRequestSearchParameter(searchParams);

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

public isolated function searchCodeSystem(http:Request request) returns r4:Bundle|r4:FHIRError {
    map<string[]> searchParams = request.getQueryParams();
    map<r4:RequestSearchParameter[]> params = prepareRequestSearchParameter(searchParams);

    r4:CodeSystem[] codeSystems = check terminology:searchCodeSystems(params, terminology = terminology_source);

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

public isolated function valueSetExpansionGet(http:Request request, string? id = ()) returns r4:ValueSet|r4:FHIRError {
    map<string[]> searchParams = request.getQueryParams();
    map<r4:RequestSearchParameter[]> searchParameters = prepareRequestSearchParameter(searchParams);

    r4:ValueSet valueSet = {status: "unknown"};

    if id is string {
        valueSet = check terminology:valueSetExpansion(searchParameters, vs = check readValueSetById(id), terminology = terminology_source);
    } else {
        string|() system = request.getQueryParamValue("url") ?: ();
        valueSet = check terminology:valueSetExpansion(searchParameters, system = system, terminology = terminology_source);
    }

    return valueSet;
}

public isolated function valueSetExpansionPost(http:Request request, string? id = ()) returns r4:ValueSet|r4:FHIRError {
    map<string[]> searchParams = request.getQueryParams();
    map<r4:RequestSearchParameter[]> searchParameters = prepareRequestSearchParameter(searchParams);

    r4:ValueSet valueSet = {status: "unknown"};
    if id is string {
        valueSet = check terminology:valueSetExpansion(searchParameters, vs = check readValueSetById(id), terminology = terminology_source);
    } else {
        json|http:ClientError jsonPayload = request.getJsonPayload();

        if jsonPayload is json {
            international401:Parameters|error parameters = jsonPayload.cloneWithType(international401:Parameters);
            if parameters is international401:Parameters && parameters.'parameter is international401:ParametersParameter[] {
                foreach var item in <international401:ParametersParameter[]>parameters.'parameter {
                    match item.name {
                        "valueSet" => {
                            anydata temp = item.'resource is r4:Resource ? item.'resource : ();
                            r4:ValueSet|error cloneWithType = temp.cloneWithType(r4:ValueSet);
                            valueSet = cloneWithType is r4:ValueSet ? cloneWithType : valueSet;
                        }
                    }
                }

                valueSet = check terminology:valueSetExpansion(searchParameters, vs = valueSet, terminology = terminology_source);
            } else {
                return r4:createFHIRError(
                        "Invalid request payload",
                        r4:ERROR,
                        r4:INVALID_REQUIRED,
                        cause = parameters is error ? parameters : (),
                        httpStatusCode = http:STATUS_BAD_REQUEST);
            }
        } else {
            string|() system = request.getQueryParamValue("url") ?: ();

            valueSet = check terminology:valueSetExpansion(searchParameters, system = system, terminology = terminology_source);
        }
    }
    return valueSet;
}

public isolated function valueSetValidateCodePost(http:Request request) returns international401:Parameters|r4:FHIRError {
    international401:Parameters|r4:FHIRError concept = valueSetLookUpPost(request);
    return validationResultToParameters(concept);
}

public isolated function valueSetValidateCodeGet(http:Request request, string? id = ()) returns international401:Parameters|r4:FHIRError {
    international401:Parameters|r4:FHIRError concept = valueSetLookUpGet(request, id);
    return validationResultToParameters(concept);
}

public isolated function codeSystemLookUpGet(http:RequestContext ctx, http:Request request, string? id = ()) returns international401:Parameters|r4:FHIRError {
    string? system = request.getQueryParamValue("system");
    string? codeValue = request.getQueryParamValue("code");
    string? 'version = request.getQueryParamValue("version") ?: ();

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

public isolated function codeSystemLookUpPost(http:RequestContext ctx, http:Request request) returns international401:Parameters|r4:FHIRError {
    r4:Coding? codingValue = ();
    r4:uri? system = ();

    json|http:ClientError jsonPayload = request.getJsonPayload();
    if jsonPayload is json {
        international401:Parameters|error parse = jsonPayload.cloneWithType(international401:Parameters);
        if parse is international401:Parameters && parse.'parameter is international401:ParametersParameter[] {
            foreach var item in <international401:ParametersParameter[]>parse.'parameter {
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
                    cause = parse is error ? parse : (),
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }
    } else {
        return r4:createFHIRError(
                "Empty request payload",
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

public isolated function valueSetLookUpPost(http:Request request) returns international401:Parameters|r4:FHIRError {
    r4:Coding?|r4:CodeableConcept? codingValue = ();
    r4:ValueSet? valueSet = ();

    json|http:ClientError jsonPayload = request.getJsonPayload();
    if jsonPayload is json {
        international401:Parameters|error parse = jsonPayload.cloneWithType(international401:Parameters);
        if parse is international401:Parameters && parse.'parameter is international401:ParametersParameter[] {
            foreach var item in <international401:ParametersParameter[]>parse.'parameter {
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
    } else {
        return r4:createFHIRError(
                "Empty request payload",
                r4:ERROR,
                r4:INVALID_REQUIRED,
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

public isolated function valueSetLookUpGet(http:Request request, string? id = (), string? reqSystem = (), string? reqCodeValue = ()) returns international401:Parameters|r4:FHIRError {
    string? system = request.getQueryParamValue("system") ?: reqSystem;
    r4:code? codeValue = request.getQueryParamValue("code") ?: reqCodeValue;

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

public isolated function subsumesGet(http:RequestContext ctx, http:Request request) returns international401:Parameters|r4:FHIRError {
    string? 'version = request.getQueryParamValue("version");
    r4:uri? system = request.getQueryParamValue("system");
    r4:code? codeA = request.getQueryParamValue("codeA");
    r4:code? codeB = request.getQueryParamValue("codeB");

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

public isolated function subsumesPost(http:RequestContext ctx, http:Request request) returns international401:Parameters|r4:FHIRError {
    string? 'version = ();
    r4:uri? system = ();
    r4:Coding? codingA = ();
    r4:Coding? codingB = ();

    json|http:ClientError jsonPayload = request.getJsonPayload();
    if jsonPayload is json {
        international401:Parameters|error parameters = jsonPayload.cloneWithType(international401:Parameters);
        if parameters is international401:Parameters && parameters.'parameter is international401:ParametersParameter[] {

            foreach var item in <international401:ParametersParameter[]>parameters.'parameter {
                match item.name {
                    "codingA" => {
                        codingA = item.valueCoding ?: {};
                    }

                    "codingB" => {
                        codingB = item.valueCoding ?: {};
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
    } else {
        return r4:createFHIRError(
                "Empty request payload or invalid json format",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
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

public isolated function batchValidateValueSets(http:Request request) returns r4:Bundle|r4:FHIRError {
    json|error payload = request.getJsonPayload();
    if payload is error {
        return r4:createFHIRError(
                "Invalid or empty request payload",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:Bundle|error bundleIn = payload.cloneWithType(r4:Bundle);
    if bundleIn is error {
        return r4:createFHIRError(
                "Cannot parse request as a FHIR Bundle",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }
    if bundleIn.'type != r4:BUNDLE_TYPE_BATCH {
        return r4:createFHIRError(
                "Not a batch type bundle",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:BundleEntry[] responseEntries = [];
    if bundleIn.entry is r4:BundleEntry[] {
        foreach r4:BundleEntry entry in <r4:BundleEntry[]>bundleIn.entry {
            if entry.request is r4:BundleEntryRequest {
                // cast to http request
                r4:BundleEntryRequest entryRequest = <r4:BundleEntryRequest>entry.request;

                http:Request entryRequestHttp = new;

                // split the url to get system and code
                map<string> urlParts = getSystemAndCode(entryRequest.url);
                string? system = urlParts["system"];
                string? code = urlParts["code"];

                international401:Parameters|r4:FHIRError result = valueSetLookUpGet(entryRequestHttp, reqSystem = system, reqCodeValue = code);

                if result is international401:Parameters {
                    responseEntries.push({
                        'resource: check validationResultToParameters(result)
                    });
                } else {
                    responseEntries.push({
                        'resource: <international401:Parameters>{
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

public isolated function addCodeSystem(http:Request req) returns r4:FHIRError? {
    do {
        string contentType = req.getContentType();
        r4:CodeSystem codeSystem;

        // for JSON content
        if contentType == JSON || contentType == FHIR_JSON {
            ParseCodeSystem parsedCodeSystem = check jsondata:parseStream(check req.getByteStream());

            if parsedCodeSystem.content is () || parsedCodeSystem.status is () {
                return r4:createFHIRError(
                        "Invalid request payload",
                        r4:ERROR,
                        r4:INVALID_REQUIRED,
                        httpStatusCode = http:STATUS_BAD_REQUEST);
            }

            codeSystem = parseCodeSystemToR4CodeSystem(parsedCodeSystem);
        }

        // for XML content
        else if contentType == XML || contentType == FHIR_XML {
            XMLCodeSystem parsedCodeSystem = check xmldata:parseStream(check req.getByteStream());

            if parsedCodeSystem.content is () || parsedCodeSystem.status is () {
                return r4:createFHIRError(
                        "Invalid request payload",
                        r4:ERROR,
                        r4:INVALID_REQUIRED,
                        httpStatusCode = http:STATUS_BAD_REQUEST);
            }

            codeSystem = xmlCodeSystemToR4CodeSystem(parsedCodeSystem);
        }

        // for zip
        else if contentType == ZIP {
            string path = req.getQueryParamValue("target-path") ?: "";
            string dirPath = createNewTempDirectory();

            check saveCompressedPayload(check req.getByteStream(), dirPath);
            check extractZipFile(dirPath);

            json[] codeSystems = check readFilesAsJsons(dirPath + ZIP_FILE_EXTRACTION_PATH + (path != "" ? "/" + path : ""));

            _ = terminology:addCodeSystemsAsJson(codeSystems, terminology = terminology_source);

            _ = start removeDirectory(dirPath);
            return;
        }

        // not supported
        else {
            return r4:createFHIRError(
                    "Invalid request payload, content type is not supported",
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }

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

public isolated function addValueSet(http:Request req) returns r4:FHIRError? {
    do {
        string contentType = req.getContentType();

        // for JSON content
        if contentType == JSON || contentType == FHIR_JSON {
            stream<byte[], error?> payloadStream = check req.getByteStream();
            ParseValueSet parseValueSet = check jsondata:parseStream(s = payloadStream);
            if parseValueSet.status is () {
                return r4:createFHIRError(
                        "Invalid request payload",
                        r4:ERROR,
                        r4:INVALID_REQUIRED,
                        httpStatusCode = http:STATUS_BAD_REQUEST);
            }

            r4:ValueSet valueSet = parseValueSetToR4ValueSet(parseValueSet);

            return terminology:addValueSet(valueSet, terminology = terminology_source);
        }

        // for zip
        else if contentType == ZIP {
            string path = req.getQueryParamValue("target-path") ?: "";
            string dirPath = createNewTempDirectory();

            check saveCompressedPayload(check req.getByteStream(), dirPath);
            check extractZipFile(dirPath);

            json[] codeSystems = check readFilesAsJsons(dirPath + ZIP_FILE_EXTRACTION_PATH + (path != "" ? "/" + path : ""));

            _ = terminology:addValueSetsAsJson(codeSystems, terminology = terminology_source);

            _ = start removeDirectory(dirPath);
            return;
        }

        // not supported
        else {
            return r4:createFHIRError(
                    "Invalid request payload, content type is not supported",
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }
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
        international401:Parameters|error parameters = jsonPayload.cloneWithType(international401:Parameters);
        if parameters is international401:Parameters && parameters.'parameter is international401:ParametersParameter[] {
            foreach var item in <international401:ParametersParameter[]>parameters.'parameter {
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
