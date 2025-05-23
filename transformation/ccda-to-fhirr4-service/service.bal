// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com).

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
import ballerinax/health.fhir.r4utils.ccdatofhir;

// Represents the subtype of http:Ok status code record.
type CcdaToFhirResponse record {|
    *http:Ok;
    string mediaType = r4:FHIR_MIME_TYPE_JSON;
    r4:Bundle body;
|};

// Represents the subtype of http:BadRequest status code record.
type CcdaToFhirBadRequest record {|
    *http:BadRequest;
    r4:OperationOutcome body;
|};

// Represents the subtype of http:InternalServerError status code record.
type CcdaToFhirInternalServerError record {|
    *http:InternalServerError;
    r4:OperationOutcome body;
|};

# This service supports transform CCDA documents to FHIR based on the CCDA to FHIR mapping Implementation Guide.
# Link to the IG: http://hl7.org/fhir/us/ccda/2023May/CF-index.html
# The service is exposed at `/transform` path and the service is listening to HTTP requests at port `9090`.
service / on new http:Listener(9090) {

    # CCDA to FHIR transform service
    # + return - Transformed FHIR bundle for the given CCDA document.
    resource function post transform(http:RequestContext ctx, http:Request request) returns json|error {

        xml|error xmlPayload = request.getXmlPayload();
        if xmlPayload is error {
            string diagnosticMsg = xmlPayload.message();
            error? cause = xmlPayload.cause();
            if cause is error {
                diagnosticMsg = cause.message();
            }
            r4:OperationOutcome operationOutcome = r4:errorToOperationOutcome(r4:createFHIRError(
                "Invalid xml document.", r4:CODE_SEVERITY_ERROR, r4:TRANSIENT_EXCEPTION, diagnostic = diagnosticMsg));
            log:printError(string `Invalid xml document.`, diagnosic = diagnosticMsg);
            return {body: operationOutcome}.toJson();
        }
        // Pass the xml payload to the CCDA to FHIR transform util function in the FHIR R4 utils package.
        r4:Bundle|r4:FHIRError ccdaToFhir = ccdatofhir:ccdaToFhir(xmlPayload);
        // If the success scenario, return the transformed FHIR bundle.
        if ccdaToFhir is r4:Bundle {
            log:printDebug(string`Transformed message: ${ccdaToFhir.toJsonString()}`);
            return {body: ccdaToFhir}.toJson();
        }
        log:printError("Error occurred in CCDA to FHIR transformation.", ccdaToFhir);
        return {body: r4:errorToOperationOutcome(ccdaToFhir)}.toJson();
    }
}
