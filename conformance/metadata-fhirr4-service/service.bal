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
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhirr4;

// Represents the subtype of http:InternalServerError status code record.
type MetatataInternalServerError record {|
    *http:InternalServerError;
    r4:OperationOutcome body;
|};

final r4:ResourceAPIConfig apiConfig = {
    resourceType: "OperationOutcome",
    profiles: [
        "http://hl7.org/fhir/StructureDefinition/OperationOutcome"        
    ],
    defaultProfile: (),
    searchParameters: [],
    operations: [],
    serverConfig: (),
    authzConfig: ()
};

# # The service representing capability statement API
final readonly & international401:CapabilityStatement capabilityStatement = check generateCapabilityStatement().cloneReadOnly();

# The service representing well known API
# Bound to port defined by configs
service / on new fhirr4:Listener(9090, apiConfig) {

    # The capability statement is a key part of the overall conformance framework in FHIR. It is used as a statement of the
    # features of actual software, or of a set of rules for an application to provide. This statement connects to all the
    # detailed statements of functionality, such as StructureDefinitions and ValueSets. This composite statement of application
    # capability may be used for system compatibility testing, code generation, or as the basis for a conformance assessment.
    # For further information https://hl7.org/fhir/capabilitystatement.html
    # + return - capability statement as a json
    isolated resource function get fhir/r4/metadata(r4:FHIRContext fhirContext) returns international401:CapabilityStatement|r4:OperationOutcome {
        international401:CapabilityStatement|error response = capabilityStatement;
        if response is international401:CapabilityStatement {
            log:printDebug("Capability statement served successfully.");
            return response;
        }
        return r4:handleErrorResponse(response);
    }
}
