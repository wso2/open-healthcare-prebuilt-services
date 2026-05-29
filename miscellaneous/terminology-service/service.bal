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

function init() returns r4:FHIRError?|error? {
    check removeDirectory(TEMPORARY_FILES_DIRECTORY_NAME);
    r4:FHIRImplementationGuide baseImplementationGuide = new(terminologyIgRecord);
    check r4:fhirRegistry.addImplementationGuide(baseImplementationGuide);
    log:printDebug("Terminology IG registered");
}

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

        isolated resource function get .(http:RequestContext ctx, http:Request request) returns http:Response|r4:FHIRError {
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
