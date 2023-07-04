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
import ballerinax/health.fhir.r4;
import ballerinax/health.hl7v2;
import ballerinax/health.hl7v2.utils.v2tofhirr4;

service / on new http:Listener(9090) {

    resource function post transform(http:Request request) returns http:Response|http:ClientError|error {
        string textPayload = check request.getTextPayload();
        json|error v2tofhirResult = v2tofhirr4:v2ToFhir(textPayload);
        http:Response response = new;
        if v2tofhirResult is json {
            response.setJsonPayload(v2tofhirResult);
            response.statusCode = http:STATUS_OK;
            _ = check response.setContentType(r4:FHIR_MIME_TYPE_JSON);
        } else if v2tofhirResult is hl7v2:HL7Error {
            string msg = v2tofhirResult.detail().message ?: v2tofhirResult.message();
            response.setPayload(string `Unable to convert HL7 message to FHIR. Error: ${msg}.`);
            response.statusCode = http:STATUS_BAD_REQUEST;
        } else {
            response.setPayload("Unable to Convert HL7 Message to FHIR");
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
        }
        return response;
    }
}
