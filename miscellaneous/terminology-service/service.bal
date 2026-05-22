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

listener http:Listener interceptorListener = new (9089, timeout = 0);

service http:InterceptableService /fhir/r4 on interceptorListener {

    public function createInterceptors() returns FHIRResponseErrorInterceptor {
        return new FHIRResponseErrorInterceptor();
    }

    isolated resource function get ValueSet/\$expand(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: ValueSet Expand");

        r4:ValueSet valueSet = check valueSetExpansionGet(request);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(valueSet, FHIR_JSON);
        return response;
    }

    isolated resource function post ValueSet/\$expand(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: ValueSet Expand");

        r4:ValueSet valueSet = check valueSetExpansionPost(request);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(valueSet, FHIR_JSON);
        return response;
    }

    isolated resource function get ValueSet/\$validate\-code(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: ValueSet Validate Code");

        international401:Parameters parameters = check valueSetValidateCodeGet(request);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(parameters, FHIR_JSON);
        return response;
    }

    isolated resource function post ValueSet/\$validate\-code(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: ValueSet Validate Code");

        international401:Parameters parameters = check valueSetValidateCodePost(request);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(parameters, FHIR_JSON);
        return response;
    }

    isolated resource function get ValueSet/[string id]/\$expand(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug(string `FHIR Terminology request is received. Interaction: ValueSet Expand with ValueSet Id: ${id}`);

        r4:ValueSet valueSet = check valueSetExpansionGet(request, id);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(valueSet, FHIR_JSON);
        return response;
    }

    isolated resource function get ValueSet/[string id]/\$validate\-code(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug(string `FHIR Terminology request is received. Interaction: ValueSet Validate Code with ValueSet Id: ${id}`);

        international401:Parameters parameters = check valueSetValidateCodeGet(request, id);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(parameters, FHIR_JSON);
        return response;
    }

    isolated resource function get ValueSet/[string id](http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug(string `FHIR Terminology request is received. Interaction: ValueSet Get with ValueSet Id: ${id}`);

        r4:ValueSet valueSet = check readValueSetById(id);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(valueSet, FHIR_JSON);
        return response;
    }

    isolated resource function get ValueSet(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: ValueSet Search");

        r4:Bundle valueSet = check searchValueSet(request);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(valueSet, FHIR_JSON);
        return response;
    }

    isolated resource function post ValueSet(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Add new ValueSet");

        _ = check addValueSet(request);

        http:Response successResponse = new;
        successResponse.statusCode = http:STATUS_CREATED;
        return successResponse;
    }

    // ===============================================================================================================================

    isolated resource function get CodeSystem/\$lookup(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: CodeSystem Lookup");

        international401:Parameters codeSystemLookUpResult = check codeSystemLookUpGet(ctx, request);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(codeSystemLookUpResult, FHIR_JSON);
        return response;
    }

    isolated resource function post CodeSystem/\$lookup(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: CodeSystem Lookup");

        international401:Parameters result = check codeSystemLookUpPost(ctx, request);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }

    isolated resource function get CodeSystem/\$subsumes(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: CodeSystem Subsume");

        international401:Parameters subsumesResult = check subsumesGet(ctx, request);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(subsumesResult, FHIR_JSON);
        return response;
    }

    isolated resource function post CodeSystem/\$subsumes(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: CodeSystem Subsume");

        international401:Parameters result = check subsumesPost(ctx, request);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }

    isolated resource function get CodeSystem/[string id]/\$lookup(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug(string `FHIR Terminology request is received. Interaction: CodeSystem Lookup with Id: ${id}`);

        international401:Parameters codeSystemLookUpResult = check codeSystemLookUpGet(ctx, request, id);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(codeSystemLookUpResult, FHIR_JSON);
        return response;
    }

    isolated resource function get CodeSystem/[string id](http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug(string `FHIR Terminology request is received. Interaction: CodeSystem Get with Id: ${id}`);

        r4:CodeSystem codeSystem = check readCodeSystemById(id);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(codeSystem, FHIR_JSON);
        return response;
    }

    isolated resource function get CodeSystem(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: CodeSystem Search");

        r4:Bundle codeSystem = check searchCodeSystem(request);

        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(codeSystem, FHIR_JSON);
        return response;
    }

    isolated resource function post CodeSystem(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Add new CodeSystem");

        _ = check addCodeSystem(request);

        http:Response successResponse = new;
        successResponse.statusCode = http:STATUS_CREATED;
        return successResponse;
    }

    // ===============================================================================================================================

    isolated resource function post .(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Batch");

        r4:Bundle result = check batchValidateValueSets(request);
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }

    isolated resource function post \$upload(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Create");

        r4:FHIRError? response = upload(request);

        if response is r4:FHIRError {
            return response;
        } else {
            http:Response successResponse = new;
            successResponse.statusCode = http:STATUS_CREATED;
            successResponse.setJsonPayload(response.toJson());
            return successResponse;
        }
    }

    isolated resource function get \$find\-code(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Find Code");

        r4:Bundle result = check findCodeGet(request);

        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }

    isolated resource function post \$find\-code(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Find Code (POST)");

        r4:Bundle result = check findCodePost(request);

        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setPayload(result, FHIR_JSON);
        return response;
    }

    isolated resource function get metadata(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
        log:printDebug("FHIR Terminology request is received. Interaction: Metadata (CapabilityStatement)");

        international401:CapabilityStatement capabilityStatement = {
            status: "active",
            date: "2025-06-17",
            publisher: "Ballerina FHIR Terminology Service",
            description: "CapabilityStatement for the Ballerina FHIR Terminology Service API.",
            kind: "instance",
            fhirVersion: "4.0.1",
            format: ["json"],
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

        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setJsonPayload(capabilityStatement.toJson());
        response.setHeader("content-type", "application/fhir+json");
        return response;
    }
}
