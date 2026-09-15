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
import ballerina/log;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhirr4;
import ballerinax/health.fhir.r4.international401;

listener http:Listener baseListener = check http:getDefaultListener();

service /fhir/r4/ValueSet on new fhirr4:Listener(config = valueSetApiConfig) {

    public function createInterceptors() returns FHIRResponseErrorInterceptor {
        return new FHIRResponseErrorInterceptor();
    }

    isolated resource function get \$expand(r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: ValueSet Expand");

        r4:ValueSet valueSet = check valueSetExpansionGet(ctx);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(valueSet, FHIR_JSON);
        return response;
    }

    isolated resource function post \$expand(r4:FHIRContext ctx, r4:Parameters parameters) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: ValueSet Expand");

        r4:ValueSet valueSet = check valueSetExpansionPost(ctx, parameters);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(valueSet, FHIR_JSON);
        return response;
    }

    isolated resource function get \$validate\-code(r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: ValueSet Validate Code");

        r4:Parameters parameters = check valueSetValidateCodeGet(ctx);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(parameters, FHIR_JSON);
        return response;
    }

    isolated resource function post \$validate\-code(r4:FHIRContext ctx, r4:Parameters parameters) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: ValueSet Validate Code");

        r4:Parameters result = check valueSetValidateCodePost(ctx, parameters);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }

    isolated resource function get [string id]/\$expand(r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug(string `FHIR Terminology request is received. Interaction: ValueSet Expand with ValueSet Id: ${id}`);

        r4:ValueSet valueSet = check valueSetExpansionGet(ctx, id);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(valueSet, FHIR_JSON);
        return response;
    }

    isolated resource function get [string id]/\$validate\-code(r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug(string `FHIR Terminology request is received. Interaction: ValueSet Validate Code with ValueSet Id: ${id}`);

        r4:Parameters parameters = check valueSetValidateCodeGet(ctx, id);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(parameters, FHIR_JSON);
        return response;
    }

    isolated resource function get [string id](r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug(string `FHIR Terminology request is received. Interaction: ValueSet Get with ValueSet Id: ${id}`);

        r4:ValueSet valueSet = check readValueSetById(id);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(valueSet, FHIR_JSON);
        return response;
    }

    isolated resource function get .(r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: ValueSet Search");

        r4:Bundle valueSet = check searchValueSet(ctx);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(valueSet, FHIR_JSON);
        return response;
    }

    isolated resource function post .(r4:FHIRContext ctx, r4:ValueSet valueSet) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Add new ValueSet");

        _ = check addValueSet(ctx, valueSet);

        http:Response successResponse = new;
        successResponse.statusCode = http:STATUS_CREATED;
        return successResponse;
    }
}

service /fhir/r4/CodeSystem on new fhirr4:Listener(config = codeSystemApiConfig) {

    public function createInterceptors() returns [FHIRResponseErrorInterceptor] {
        return [new FHIRResponseErrorInterceptor()];
    }

    isolated resource function get \$lookup(r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: CodeSystem Lookup");

        r4:Parameters codeSystemLookUpResult = check codeSystemLookUpGet(ctx);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(codeSystemLookUpResult, FHIR_JSON);
        return response;
    }

    isolated resource function post \$lookup(r4:FHIRContext ctx, r4:Parameters parameters) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: CodeSystem Lookup");

        r4:Parameters result = check codeSystemLookUpPost(ctx, parameters);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }

    isolated resource function get \$validate\-code(r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: CodeSystem Validate Code");

        r4:Parameters parameters = check codeSystemValidateCodeGet(ctx);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(parameters, FHIR_JSON);
        return response;
    }

    isolated resource function post \$validate\-code(r4:FHIRContext ctx, r4:Parameters parameters) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: CodeSystem Validate Code");

        r4:Parameters result = check codeSystemValidateCodePost(ctx, parameters);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }

    isolated resource function get [string id]/\$validate\-code(r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug(string `FHIR Terminology request is received. Interaction: CodeSystem Validate Code with Id: ${id}`);

        r4:Parameters parameters = check codeSystemValidateCodeGet(ctx, id);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(parameters, FHIR_JSON);
        return response;
    }

    isolated resource function get \$subsumes(r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: CodeSystem Subsume");

        r4:Parameters subsumesResult = check subsumesGet(ctx);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(subsumesResult, FHIR_JSON);
        return response;
    }

    isolated resource function post \$subsumes(r4:FHIRContext ctx, r4:Parameters parameters) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: CodeSystem Subsume");

        r4:Parameters result = check subsumesPost(ctx, parameters);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }

    isolated resource function get [string id](r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug(string `FHIR Terminology request is received. Interaction: CodeSystem Get with Id: ${id}`);

        r4:CodeSystem codeSystem = check readCodeSystemById(id);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(codeSystem, FHIR_JSON);
        return response;
    }

    isolated resource function get .(r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: CodeSystem Search");

        r4:Bundle codeSystem = check searchCodeSystem(ctx);

        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(codeSystem, FHIR_JSON);
        return response;
    }

    isolated resource function post .(r4:FHIRContext ctx, r4:CodeSystem codeSystem) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Add new CodeSystem");

        _ = check addCodeSystem(ctx, codeSystem);

        http:Response successResponse = new;
        successResponse.statusCode = http:STATUS_CREATED;
        return successResponse;
    }
}

service /fhir/r4/ConceptMap on new fhirr4:Listener(config = conceptMapApiConfig) {

    public function createInterceptors() returns [FHIRResponseErrorInterceptor] {
        return [new FHIRResponseErrorInterceptor()];
    }

    isolated resource function get \$translate(r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: ConceptMap Translate");

        r4:Parameters result = check translateGet(ctx);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }

    isolated resource function post \$translate(r4:FHIRContext ctx, r4:Parameters parameters) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: ConceptMap Translate");

        r4:Parameters result = check translatePost(ctx, parameters);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }

    isolated resource function get [string id](r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug(string `FHIR Terminology request is received. Interaction: ConceptMap Get with Id: ${id}`);

        r4:ConceptMap conceptMap = check readConceptMapById(id);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(conceptMap, FHIR_JSON);
        return response;
    }

    isolated resource function get .(r4:FHIRContext ctx) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: ConceptMap Search");

        r4:Bundle conceptMap = check searchConceptMap(ctx);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(conceptMap, FHIR_JSON);
        return response;
    }

    isolated resource function post .(r4:FHIRContext ctx, r4:ConceptMap conceptMap) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Add new ConceptMap");

        _ = check addConceptMap(ctx, conceptMap);

        http:Response successResponse = new;
        successResponse.statusCode = http:STATUS_CREATED;
        return successResponse;
    }
}

service /fhir/r4 on new fhirr4:Listener(config = apiConfig) {

    public function createInterceptors() returns [FHIRResponseErrorInterceptor] {
        return [new FHIRResponseErrorInterceptor()];
    }

    isolated resource function post .(r4:FHIRContext ctx, r4:Bundle bundle) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Batch");

        r4:Bundle result = check batchValidateValueSets(bundle);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }
}

service http:InterceptableService /fhir/r4/\$upload on baseListener {

    public function createInterceptors() returns [FHIRResponseErrorInterceptor] {
        return [new FHIRResponseErrorInterceptor()];
    }

    isolated resource function post .(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Create");

        r4:FHIRError? response = upload(request);

        if response is r4:FHIRError {
            log:printError(string `Upload failed: ${response.message()}`);
            return response;
        } else {
            http:Response successResponse = new;
            successResponse.statusCode = http:STATUS_CREATED;
            successResponse.setJsonPayload(response.toJson());
            return successResponse;
        }
    }
}

service http:InterceptableService /fhir/r4/\$find\-code on baseListener {

    public function createInterceptors() returns [FHIRResponseErrorInterceptor] {
        return [new FHIRResponseErrorInterceptor()];
    }

    isolated resource function get .(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Find Code");

        r4:Bundle result = check findCodeGet(request);

        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }

    isolated resource function post .(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Find Code (POST)");

        r4:Bundle result = check findCodePost(request);

        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }
}

// TEMPORARY (branch: api-conformance): the HL7 validator probes GET [base]/$versions
// on connect to discover which FHIR versions the server supports. The terminology
// service did not expose it (returned 404 "Path not found: /$versions"), which the
// validator logs as "Unable to interpret response from $versions". This endpoint
// returns the standard Parameters response declaring FHIR R4 (4.0.1) support, and
// supports both GET and POST so it can be referenced by the standard
// http://hl7.org/fhir/OperationDefinition/CapabilityStatement-versions definition.
service http:InterceptableService /fhir/r4/\$versions on baseListener {

    public function createInterceptors() returns [FHIRResponseErrorInterceptor] {
        return [new FHIRResponseErrorInterceptor()];
    }

    isolated resource function get .(http:RequestContext ctx, http:Request request) returns http:Response {
        return buildVersionsResponse();
    }

    isolated resource function post .(http:RequestContext ctx, http:Request request) returns http:Response {
        return buildVersionsResponse();
    }
}

isolated function buildVersionsResponse() returns http:Response {
    log:printDebug("FHIR Terminology request is received. Interaction: $versions");

    http:Response response = new;
    response.statusCode = http:STATUS_OK;
    response.setHeader("content-type", "application/fhir+json");
    json versions = {
        "resourceType": "Parameters",
        "parameter": [
            {"name": "version", "valueCode": "4.0"},
            {"name": "default", "valueCode": "4.0"}
        ]
    };
    response.setJsonPayload(versions);
    return response;
}

// ConceptMap/$closure (https://hl7.org/fhir/R4/conceptmap-operation-closure.html)
// is a base-level operation ([base]/$closure, not resource-scoped), same as
// $upload/$find-code/$versions above - so it lives on baseListener rather than
// the fhirr4:Listener-based CodeSystem/ValueSet services, and its handler
// parses the request body itself instead of getting r4:Parameters for free.
service http:InterceptableService /fhir/r4/\$closure on baseListener {

    public function createInterceptors() returns [FHIRResponseErrorInterceptor] {
        return [new FHIRResponseErrorInterceptor()];
    }

    isolated resource function post .(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: $closure");

        r4:ConceptMap result = check closurePost(request);

        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }
}

service http:InterceptableService /fhir/r4/metadata on baseListener {

    public function createInterceptors() returns [FHIRResponseErrorInterceptor] {
        return [new FHIRResponseErrorInterceptor()];
    }

    isolated resource function get .(http:RequestContext ctx, http:Request request, string? mode) returns http:Response|r4:FHIRError {

        log:printDebug("FHIR Terminology request is received. Interaction: Metadata (CapabilityStatement)");

        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setHeader("content-type", "application/json");

        if mode == "terminology" {
            international401:TerminologyCapabilities terminologyCapabilities = {
                "resourceType": "TerminologyCapabilities",
                "id": "wso2-ballerina-terminology-service",
                "url": "http://localhost:9089/fhir/r4/terminology-capabilities",
                "version": "0.1.1",
                "name": "WSO2BallerinaTerminologyServiceCapabilities",
                "title": "WSO2 Ballerina FHIR R4 Terminology Service — TerminologyCapabilities",
                "status": "active",
                "date": "2025-06-17",
                "publisher": "WSO2 LLC.",
                "contact": [
                    {
                        "name": "WSO2 LLC.",
                        "telecom": [
                            {
                                "system": "url",
                                "value": "http://www.wso2.com"
                            }
                        ]
                    }
                ],
                "description": "TerminologyCapabilities for the WSO2 Ballerina FHIR R4 Terminology Service (wso2/terminology_service v0.1.1), powered by the ballerinax/health.fhir.r4.terminology v7.0.1 library. The service persists CodeSystem, ValueSet, and ConceptMap resources in a relational database (PostgreSQL or H2). CodeSystem concepts are extracted into a separate table at ingest with a parentConceptId hierarchy, enabling efficient $lookup and DB-native $subsumes traversal. $closure is implemented, backed by the same closure table $subsumes uses, with its own client-named-table state tracked separately from the ConceptMap resource CRUD. $translate is implemented via the library's matching logic, backed by ConceptMap resource CRUD (create/read/search) against the same database.",
                "kind": "instance",
                "software": {
                    "name": "ballerinax/health.fhir.r4.terminology",
                    "version": "7.0.1"
                },
                "implementation": {
                    "description": "WSO2 Ballerina FHIR R4 Terminology Service — database-backed (PostgreSQL or H2), running on port 9089",
                    "url": "http://localhost:9089/fhir/r4"
                },
                "lockedDate": false,
                "codeSearch": "all",
                "codeSystem": [
                    {
                        "uri": "http://loinc.org",
                        "version": [
                            {
                                "code": "*",
                                "isDefault": false,
                                "compositional": false
                            }
                        ],
                        "subsumption": false
                    },
                    {
                        "uri": "http://snomed.info/sct",
                        "version": [
                            {
                                "code": "*",

                                "isDefault": false,
                                "compositional": false
                            }
                        ],
                        "subsumption": true
                    }
                ],
                "expansion": {
                    "hierarchical": false,
                    "paging": true,
                    "incomplete": false,
                    "parameter": [
                        {
                            "name": "activeOnly",
                            "documentation": "When true, drops inactive concepts from the expansion and recomputes expansion.total. Concepts are included by default unless the ValueSet's own compose says otherwise."
                        },
                        {
                            "name": "url",
                            "documentation": "Canonical URL of the ValueSet to expand. Resolved via the database. Required when no ValueSet is provided inline and no {id} path parameter is used."
                        },
                        {
                            "name": "valueSetVersion",
                            "documentation": "Version of the ValueSet to expand when resolving by URL. Maps to the 'version' search parameter internally."
                        },
                        {
                            "name": "filter",
                            "documentation": "Case-insensitive substring match applied to concept display values during expansion. Filters allConcepts before pagination is applied."
                        },
                        {
                            "name": "_count",
                            "documentation": "Maximum number of concepts to return per page. Default: 20. Maximum enforced: 300 (returns HTTP 413 if exceeded)."
                        },
                        {
                            "name": "_offset",
                            "documentation": "Zero-based index of the first concept to return. Enables pagination of expansion results. The total field in the response always reflects the unfiltered full count."
                        }
                    ],
                    "textFilter": null
                },
                "validateCode": {
                    "translations": false
                },
                "translation": {
                    "needsMap": true
                },
                "closure": {
                    "translation": false
                }
            };
            response.setJsonPayload(terminologyCapabilities.toJson());
            return response;
        } else {
            international401:CapabilityStatement capabilityStatement = {
                status: "active",
                date: "2025-06-17",
                publisher: "Ballerina FHIR Terminology Service",
                description: "CapabilityStatement for the Ballerina FHIR Terminology Service API.",
                kind: "instance",
                fhirVersion: "4.0.1",
                format: [],
                rest: [
                    {
                        mode: "server",
                        documentation: "FHIR Terminology Service REST interface.",
                        'resource: [
                            {
                                'type: "CodeSystem",
                                interaction: [
                                    {code: "read"},
                                    {code: "search-type"},
                                    {code: "create"},
                                    {code: "update"},
                                    {code: "delete"},
                                    {code: "patch"}
                                ],
                                operation: [
                                    {name: "lookup", definition: "http://hl7.org/fhir/OperationDefinition/CodeSystem-lookup"},
                                    {name: "validate-code", definition: "http://hl7.org/fhir/OperationDefinition/CodeSystem-validate-code"},
                                    {name: "subsumes", definition: "http://hl7.org/fhir/OperationDefinition/CodeSystem-subsumes"}
                                ]
                            },
                            {
                                'type: "ValueSet",
                                interaction: [
                                    {code: "read"},
                                    {code: "search-type"},
                                    {code: "create"},
                                    {code: "update"},
                                    {code: "delete"},
                                    {code: "patch"}
                                ],
                                operation: [
                                    {name: "expand", definition: "http://hl7.org/fhir/OperationDefinition/ValueSet-expand"},
                                    {name: "validate-code", definition: "http://hl7.org/fhir/OperationDefinition/ValueSet-validate-code"}
                                ]
                            },
                            {
                                'type: "ConceptMap",
                                interaction: [
                                    {code: "read"},
                                    {code: "search-type"},
                                    {code: "create"}
                                ],
                                operation: [
                                    {name: "translate", definition: "http://hl7.org/fhir/OperationDefinition/ConceptMap-translate"}
                                ]
                            }
                        ],
                        // $versions is implemented (see the /$versions listener below) but
                        // wasn't declared here - a base-level (not resource-scoped) operation.
                        // $closure is likewise a base-level operation (see the /$closure listener below).
                        operation: [
                            {name: "versions", definition: "http://hl7.org/fhir/OperationDefinition/CapabilityStatement-versions"},
                            {name: "closure", definition: "http://hl7.org/fhir/OperationDefinition/ConceptMap-closure"}
                        ]
                    }
                ]
            };
            response.setJsonPayload(capabilityStatement.toJson());
            return response;
        }
    }

}

