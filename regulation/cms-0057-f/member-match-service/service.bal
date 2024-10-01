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
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhirr4;
import ballerinax/health.fhir.r4.davincihrex100;

// FHIR repository configs
configurable string fhirRepositoryUrl = ?;
configurable AuthConfig? fhirRepositoryAuthConfig = ();

// Consent service configs
configurable string consentServiceUrl = ?;
configurable AuthConfig? consentServiceAuthConfig = ();
configurable map<string|string[]>? consentServiceRequestHeaders = ();

// Coverage service configs
configurable string coverageServiceUrl = "";
configurable AuthConfig? coverageServiceAuthConfig = ();
configurable map<string|string[]>? coverageServiceRequestHeaders = ();

final fhir:FHIRConnectorConfig fhirClientConfig = {
    baseURL: fhirRepositoryUrl,
    mimeType: fhir:FHIR_JSON,
    authConfig: getClientAuthConfig(fhirRepositoryAuthConfig)
};

final davincihrex100:ExternalServiceConfig consentServiceConfig = {
    url: consentServiceUrl,
    requestHeaders: consentServiceRequestHeaders,
    clientConfig: {
        auth: getClientAuthConfig(consentServiceAuthConfig)
    }
};

final davincihrex100:ExternalServiceConfig coverageServiceConfig = {
    url: coverageServiceUrl,
    requestHeaders: coverageServiceRequestHeaders,
    clientConfig: {
        auth: getClientAuthConfig(coverageServiceAuthConfig)
    }
};

final davincihrex100:MatcherConfig matcherConfig = {
    fhirClientConfig: fhirClientConfig,
    consentServiceConfig: consentServiceConfig,
    coverageServiceConfig: coverageServiceConfig
};

// FHIR member matcher instance
final davincihrex100:FhirMemberMatcher fhirMemberMatcher = check new (matcherConfig, ());

## uncomment the following line to use the demo FHIR member matcher.
## Note: This will bypass the default matching flow. This is only for testing purposes.

// final DemoFHIRMemberMatcher fhirMemberMatcher = check new ();

service / on new fhirr4:Listener(9095, apiConfig) {
    isolated resource function post fhir/r4/Patient/\$member\-match(r4:FHIRContext context,
            davincihrex100:HRexMemberMatchRequestParameters parameters)
            returns davincihrex100:HRexMemberMatchResponseParameters|r4:FHIRError {
        // Validate and extract resources from the request parameters
        davincihrex100:MemberMatchResources memberMatchResources =
                check validateAndExtractMemberMatchResources(parameters);

        // Match member
        davincihrex100:MemberIdentifier memberIdentifier = check fhirMemberMatcher.matchMember(memberMatchResources);

        // Member match response profile: 
        // https://hl7.org/fhir/us/davinci-hrex/StructureDefinition-hrex-parameters-member-match-out.html
        return {
            'parameter: {
                name: "MemberIdentifier",
                valueIdentifier: {
                    'type: {
                        coding: [
                            {
                                system: "http://terminology.hl7.org/3.1.0/CodeSystem-v2-0203.html",
                                code: "MB"
                            }
                        ]
                    },
                    value: memberIdentifier
                }
            }
        };
    }
}
