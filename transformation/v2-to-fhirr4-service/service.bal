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
import ballerinax/health.hl7v2;
import ballerinax/health.hl7v2.utils.v2tofhirr4;

// Represents the subtype of http:Ok status code record.
type V2ToFhirResponse record {|
    *http:Ok;
    string mediaType = r4:FHIR_MIME_TYPE_JSON;
    json body;
|};

// Represents the subtype of http:BadRequest status code record.
type V2ToFhirBadRequest record {|
    *http:BadRequest;
    string body;
|};

// Represents the subtype of http:InternalServerError status code record.
type V2ToFhirInternalServerError record {|
    *http:InternalServerError;
    string body;
|};

service / on new http:Listener(9090) {

    resource function post transform(@http:Payload string hl7Message) returns V2ToFhirResponse|V2ToFhirBadRequest|V2ToFhirInternalServerError {
        json|error v2tofhirResult = v2tofhirr4:v2ToFhir(hl7Message);
        if v2tofhirResult is json {
            log:printDebug("Successfully transformed the HL7 message to FHIR.");
            return {body: v2tofhirResult};
        }
        else if v2tofhirResult is hl7v2:HL7Error {
            string msg = v2tofhirResult.detail().message ?: v2tofhirResult.message();
            log:printError("Failed to transform the HL7 message to FHIR. HL7 message is malformed. Error: ", 'error = v2tofhirResult);
            return <V2ToFhirBadRequest>{body: string `HL7 message is malformed. Error: ${msg} .`};
        }
        else {
            log:printError("Unable to convert HL7 message to FHIR. Error: ", 'error = v2tofhirResult);
            return <V2ToFhirInternalServerError>{body: "Unable to convert HL7 message to FHIR."};
        }
    }
}
