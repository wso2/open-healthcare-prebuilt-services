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
import ballerinax/health.fhir.r4utils.fhirpath as fhirpath;

# A service representing a network-accessible API for the fhirpath evaluation.
# Bound to port `9090`.
service / on new http:Listener(9090) {

    # API to evaluate Fhirpath expressions and retrieve values from a FHIR resource.
    #
    # + fhirPathRequest - Request containing the FHIR resource and FHIRPath expression(s)
    # + return - Result map of FHIRPath evaluations or an error response
    isolated resource function post fhirpath/get(@http:Payload FhirPathGetRequest fhirPathRequest) returns http:Response {
        log:printInfo("Received FHIRPath get request");
        map<json> outcome = {};
        json fhirResource = fhirPathRequest.fhirResource;
        string[]|string fhirPath = fhirPathRequest.fhirPath;
        boolean validateInputFHIRResource = fhirPathRequest.validateInputFHIRResource ?: false;

        if fhirPath is string[] {
            foreach string individualFhirPath in fhirPath {
                json|error result = fhirpath:getValuesFromFhirPath(fhirResource, individualFhirPath,
                        validateInputFHIRResource = validateInputFHIRResource);
                if result is error {
                    outcome[individualFhirPath] = {"error": result.message()};
                } else {
                    outcome[individualFhirPath] = result;
                }
            }
        } else {
            json|error result = fhirpath:getValuesFromFhirPath(fhirResource, fhirPath,
                    validateInputFHIRResource = validateInputFHIRResource);
            if result is error {
                outcome[fhirPath] = {"error": result.message()};
            } else {
                outcome[fhirPath] = result;
            }
        }

        http:Response response = new;
        response.setJsonPayload(outcome.toJson());
        return response;
    }

    # API to set values in a FHIR resource at specified FHIRPath locations.
    #
    # + fhirPathRequest - Request containing the FHIR resource, FHIRPath expression, and value to set
    # + return - Updated FHIR resource or an error response
    isolated resource function post fhirpath/'set(@http:Payload FhirPathSetRequest fhirPathRequest) returns http:Response {
        log:printInfo("Received FHIRPath set request");
        json fhirResource = fhirPathRequest.fhirResource;
        string fhirPath = fhirPathRequest.fhirPath;
        json value = fhirPathRequest.value;
        boolean validateInputFHIRResource = fhirPathRequest.validateInputFHIRResource ?: false;
        boolean validateOutputFHIRResource = fhirPathRequest.validateOutputFHIRResource ?: false;

        json|error result = fhirpath:setValuesToFhirPath(fhirResource, fhirPath, value,
                validateInputFHIRResource = validateInputFHIRResource,
                validateOutputFHIRResource = validateOutputFHIRResource);
        http:Response response = new;
        if result is error {
            response.statusCode = http:STATUS_BAD_REQUEST;
            response.setJsonPayload({"error": result.message()});
        } else {
            response.setJsonPayload(result);
        }
        return response;
    }
}

# Record to hold FhirPath GET request parameters.
#
# + fhirResource - FHIR Resource as JSON
# + fhirPath - FHIRPath expression(s) to evaluate
# + validateInputFHIRResource - Optional flag to validate the input FHIR resource (defaults to false)
public type FhirPathGetRequest record {|
    json fhirResource;
    string[]|string fhirPath;
    boolean validateInputFHIRResource?;
|};

# Record to hold FhirPath SET request parameters.
#
# + fhirResource - FHIR Resource as JSON
# + fhirPath - FHIRPath expression indicating where to set the value
# + value - The value to set at the specified path
# + validateInputFHIRResource - Optional flag to validate the input FHIR resource (defaults to false)
# + validateOutputFHIRResource - Optional flag to validate the output FHIR resource after modification (defaults to false)
public type FhirPathSetRequest record {|
    json fhirResource;
    string fhirPath;
    json value;
    boolean validateInputFHIRResource?;
    boolean validateOutputFHIRResource?;
|};
