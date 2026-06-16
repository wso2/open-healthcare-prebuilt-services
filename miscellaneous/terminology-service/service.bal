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

import ballerina/http;
import ballerina/log;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhirr4;

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

        _ =  check addCodeSystem(ctx, codeSystem);

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
                "description": "TerminologyCapabilities for the WSO2 Ballerina FHIR R4 Terminology Service (wso2/terminology_service v0.1.1), powered by the ballerinax/health.fhir.r4.terminology v7.0.1 library. The service persists CodeSystem and ValueSet resources in a relational database (PostgreSQL or H2). CodeSystem concepts are extracted into a separate table at ingest with a parentConceptId hierarchy, enabling efficient $lookup and DB-native $subsumes traversal. ConceptMap and $translate are defined in the library but are not implemented in this service tier — all ConceptMap interface methods are stubs.",
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
                                    {name: "subsumes", definition: "http://hl7.org/fhir/OperationDefinition/CodeSystem-subsumes"}
                                ]
                            }
                        ]
                    }
                ]
            };
            response.setJsonPayload(capabilityStatement.toJson());
            return response;
        }
    }

}
