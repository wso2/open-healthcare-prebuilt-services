// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.

// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein is strictly forbidden, unless permitted by WSO2 in accordance with
// the WSO2 Software License available at: https://wso2.com/licenses/eula/3.2
// For specific language governing the permissions and limitations under
// this license, please see the license as well as any agreement you’ve
// entered into with WSO2 governing the purchase of this software and any
// associated services.
//
//
// AUTO-GENERATED FILE. DO NOT MODIFY.
//
// This file is auto-generated by WSO2 Healthcare Team for managing utility functions.
// Developers are allowed modify this file as per the requirement.

import ballerina/http;
import ballerina/log;
import ballerina/os;
import ballerinax/health.fhirr4 as fhir;
import ballerinax/health.fhir.r4 as r4;
import ballerinax/health.fhir.r4.aubase410 as aubase;

# Generic type to wrap all implemented profiles.
# Add required profile types here.
# public type Patient aubase:AUBasePatient|<other_Patient_Profile>;
public type Patient aubase:AUBasePatient;

# source system endpoint
configurable string sourceSystem = os:getEnv("SOURCE_SYSTEM_URL");
final http:Client sourceEp = check new (sourceSystem);

service / on new fhir:Listener(9090, apiConfig) {

    // Read the current state of the resource represented by the given id.
    isolated resource function get fhir/r4/Patient/[string id](r4:FHIRContext fhirContext)
    returns @http:Payload {mediaType: ["application/fhir+json", "application/fhir+xml"]}
    Patient|r4:FHIRError {
        // call the source system apis
        Patient|http:ClientError res = sourceEp->/Patient/[id];

        if (res is http:ClientError) {
            log:printError("Error occurred while calling the source system apis.", 'error = res);
            return r4:clientErrorToFhirError(res);
        }
        else {
            return res;
        }
    }

    // Search the resource type based on some filter criteria
    isolated resource function get fhir/r4/Patient(r4:FHIRContext fhirContext)
    returns @http:Payload {mediaType: ["application/fhir+json", "application/fhir+xml"]}
    r4:Bundle|r4:FHIRError {
        // url encode the search parameters
        string|r4:FHIRError encodedParams = r4:urlEncodeFhirSearchParameters(fhirContext.getRequestSearchParameters());
        if encodedParams is r4:FHIRError {
            return encodedParams;
        }
        // call the source system apis
        Patient[]|http:ClientError res = sourceEp->/Patient(searchParams = encodedParams);
        if (res is http:ClientError) {
            log:printError("Error occurred while calling the source system apis.", 'error = res);
            return r4:clientErrorToFhirError(res);
        } else {
            return r4:createFhirBundle(r4:BUNDLE_TYPE_SEARCHSET, res);
        }
    }
    // Create a new resource with a server assigned id
    isolated resource function post fhir/r4/Patient(r4:FHIRContext fhirContext,
            aubase:AUBasePatient payload)
    returns @http:Payload {mediaType: ["application/fhir+json", "application/fhir+xml"]}
    Patient|r4:FHIRError {

        // Passing the Interaction processing to the r4 package with current context.
        Patient|http:ClientError res = sourceEp->/Patient.post(payload);

        if (res is http:ClientError) {
            log:printError("Error occurred while calling the source system apis.", 'error = res);
            return r4:clientErrorToFhirError(res);
        } else {
            return res;
        }
    }

}
