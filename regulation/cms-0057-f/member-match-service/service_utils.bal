// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).

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
import ballerinax/health.fhir.r4.davincihrex100;
import ballerinax/health.fhir.r4.uscore501;
import ballerinax/health.fhir.r4.validator;

# Input parameters of the member match operation.
enum MemberMatchParameter {
    MEMBER_PATIENT = "MemberPatient",
    CONSENT = "Consent",
    COVERAGE_TO_MATCH = "CoverageToMatch",
    COVERAGE_TO_LINK = "CoverageToLink"
};

# Map of `ParameterInfo` to hold information about member match parameters.
final map<ParameterInfo> & readonly MEMBER_MATCH_PARAMETERS_INFO = {
    [MEMBER_PATIENT] : {profile: "USCorePatientProfile", typeDesc: uscore501:USCorePatientProfile},
    [CONSENT] : {profile: "HRexConsent", typeDesc: davincihrex100:HRexConsent},
    [COVERAGE_TO_MATCH] : {profile: "HRexCoverage", typeDesc: davincihrex100:HRexCoverage},
    [COVERAGE_TO_LINK] : {profile: "HrexCoverage", typeDesc: davincihrex100:HRexCoverage}
};

# Validates and extracts the parameter resources from member match request parameters.
#
# + requestParams - The `HRexMemberMatchRequestParameters` containing the parameters
# + return - A `MemberMatchResources` record containing the extracted resources if validation is successful,
# or a `FHIRError` if there's an error in validating the resources
isolated function validateAndExtractMemberMatchResources(davincihrex100:HRexMemberMatchRequestParameters requestParams)
        returns davincihrex100:MemberMatchResources|r4:FHIRError {
    map<anydata> processedResources = {};

    foreach string param in MEMBER_MATCH_PARAMETERS_INFO.keys() {
        anydata? 'resource = check validateAndExtractParamResource(requestParams, param,
                MEMBER_MATCH_PARAMETERS_INFO.get(param));
        if param != COVERAGE_TO_LINK && 'resource == () { // CoverageToLink is optional
            return createMissingMandatoryParamError(param);
        }
        processedResources[param] = 'resource;
    }

    return {
        memberPatient: <uscore501:USCorePatientProfile>processedResources[MEMBER_PATIENT],
        consent: <davincihrex100:HRexConsent>processedResources[CONSENT],
        coverageToMatch: <davincihrex100:HRexCoverage>processedResources[COVERAGE_TO_MATCH],
        coverageToLink: <davincihrex100:HRexCoverage?>processedResources[COVERAGE_TO_LINK]
    };
}

# Validates and extracts a specific parameter resource from the member match request parameters.
#
# + requestParams - The `HRexMemberMatchRequestParameters` containing the parameters
# + paramName - The name of the parameter to be validated and extracted
# + paramInfo - The `ParameterInfo` of the parameter
# + return - The validated and extracted parameter as `anydata` if successful, a `FHIRError` if validation fails, or 
# `()` if the parameter is not present
isolated function validateAndExtractParamResource(davincihrex100:HRexMemberMatchRequestParameters requestParams,
        string paramName, ParameterInfo paramInfo) returns anydata|r4:FHIRError? {
    r4:Resource? paramResource = getParamResource(requestParams, paramName);
    if paramResource == () {
        return;
    }

    anydata|error 'resource = paramResource.cloneWithType(paramInfo.typeDesc);
    if 'resource is error {
        return createInvalidParamTypeError(paramName, paramInfo.profile);
    }

    // Validate the resource
    r4:FHIRValidationError? validationRes = validator:validate('resource, paramInfo.typeDesc);
    if validationRes is r4:FHIRValidationError {
        return createInvalidParamTypeError(paramName, paramInfo.profile);
    }

    return 'resource;
}

# Retrieves a specific FHIR resource associated with a parameter from the member match request parameters.
#
# + requestParams - The `HRexMemberMatchRequestParameters` containing the parameters
# + 'parameter - The name of the parameter whose resource is to be retrieved
# + return - The FHIR `r4:Resource` associated with the specified parameter if found, or `()` if not found
isolated function getParamResource(davincihrex100:HRexMemberMatchRequestParameters requestParams, string 'parameter)
        returns r4:Resource? {
    foreach davincihrex100:HRexMemberMatchRequestParametersParameter param in requestParams.'parameter {
        if param.'name == 'parameter {
            return param?.'resource;
        }
    }
    return;
}

# Constructs an HTTP client authentication configuration from a given `AuthConfig`.
#
# + authConfig - An optional `AuthConfig` containing the OAuth2 authentication details
# + return - An `http:ClientAuthConfig` if `authConfig` is provided, otherwise `()`
isolated function getClientAuthConfig(AuthConfig? authConfig) returns http:ClientAuthConfig? {
    if authConfig != () {
        return {
            tokenUrl: authConfig.tokenUrl,
            clientId: authConfig.clientId,
            clientSecret: authConfig.clientSecret
        };
    }
    return;
}

# Creates a `FHIRError` indicating an invalid parameter type error.
#
# + paramName - The name of the parameter that failed validation
# + expectedType - The expected data type of the parameter
# + return - A `FHIRError` with details about the invalid parameter type
isolated function createInvalidParamTypeError(string paramName, string expectedType) returns r4:FHIRError {
    string message = "Invalid parameter";
    string diagnostic = "Parameter \"" + paramName + "\" must be a valid \"" + expectedType + "\" type";
    return r4:createFHIRError(message, r4:ERROR, r4:INVALID_VALUE, diagnostic = diagnostic,
            httpStatusCode = http:STATUS_BAD_REQUEST);
}

# Creates a `FHIRError` for a missing mandatory parameter in FHIR operations.
#
# + paramName - The name of the missing mandatory parameter
# + return - A `FHIRError` with details about the missing mandatory parameter
isolated function createMissingMandatoryParamError(string paramName) returns r4:FHIRError {
    string message = "Missing mandatory parameter";
    string diagnostic = "Mandatory parameter \"" + paramName + "\" is missing";
    return r4:createFHIRError(message, r4:ERROR, r4:INVALID_REQUIRED, diagnostic = diagnostic,
            httpStatusCode = http:STATUS_BAD_REQUEST);
}
