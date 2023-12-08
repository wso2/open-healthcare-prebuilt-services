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

import ballerina/io;
import ballerina/log;
import ballerina/time;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;

# # metadata of server and rest components as configurables
configurable ConfigFHIRServer configFHIRServer = ?;
configurable ConfigRest configRest = {};

// TODO: uncomment below line when Choreo supports object arrays in configurable editor. 
// configurable config:Resource[] resources = ?;
string resourcePath = "";

# Generate capability statement from configurables.
# 
# + return - capabilitity statement object
isolated function generateCapabilityStatement() returns international401:CapabilityStatement|error {
    log:printDebug("Generating capability statement started");

    international401:CapabilityStatementStatus capabilityStatementStatus = check configFHIRServer.status.ensureType(international401:CapabilityStatementStatus);
    international401:CapabilityStatementKind capabilityStatementKind = check configFHIRServer.kind.ensureType(international401:CapabilityStatementKind);

    international401:CapabilityStatementFormat[] capabilityStatementFormat = [];
    foreach string configFormat in configFHIRServer.format {
        international401:CapabilityStatementFormat format = check configFormat.ensureType(international401:CapabilityStatementFormat);
        capabilityStatementFormat.push(format);
    }

    string capabilityStatementDate;
    string? date = configFHIRServer.date;
    if date is string {
        capabilityStatementDate = date;
    } else {
        time:Civil dateTimeCivil =  time:utcToCivil(time:utcNow());
        capabilityStatementDate = string `${dateTimeCivil.year}-${dateTimeCivil.month}-${dateTimeCivil.day}`;
    }

    international401:CapabilityStatement capabilityStatement = {
        status: capabilityStatementStatus,
        date: capabilityStatementDate,
        kind: capabilityStatementKind,
        fhirVersion: configFHIRServer.fhirVersion,
        format: capabilityStatementFormat
    };

    international401:CapabilityStatementImplementation capabilityStatementImplementation = {
        description: configFHIRServer.implementationDescription,
        url: configFHIRServer.implementationUrl
    };
    capabilityStatement.implementation = capabilityStatementImplementation;

    string[]? configPatchFormat = configFHIRServer.patchFormat;
    if configPatchFormat is string[] {
        r4:code[] patchFormat = [];
        foreach string configPatchFormatItem in configPatchFormat {
            r4:code patchFormatItem = check configPatchFormatItem.ensureType(r4:code);
            patchFormat.push(patchFormatItem);
        }
        capabilityStatement.patchFormat = patchFormat;
    }

    international401:CapabilityStatementRest? capabilityStatementRest = check populateCapabilityStatementRest();
    if capabilityStatementRest is international401:CapabilityStatementRest {
        capabilityStatement.rest = [capabilityStatementRest];
    } else {
        log:printDebug(string `${VALUE_NOT_FOUND}: capabilityStatementRest`);
    }

    log:printDebug("Generating capability statement ended");
    return capabilityStatement;
}

# populate capability statement rest component from configurables.
# 
# + return - capability statement rest object
isolated function populateCapabilityStatementRest() returns international401:CapabilityStatementRest?|error {
    international401:CapabilityStatementRest rest = {
        mode: REST_MODE_SERVER
    };

    international401:CapabilityStatementRestSecurity? restSecurity = check populateCapabilityStatementRestSecurity();
    if restSecurity is international401:CapabilityStatementRestSecurity {
        rest.security = restSecurity;
    } else {
        log:printDebug(string `${VALUE_NOT_FOUND}: restSecurity`);
    }

    string[]? configRestInteraction = configRest.interaction;
    if configRestInteraction is string[] {
        international401:CapabilityStatementRestInteraction[] restInteraction = [];
        foreach string configInteractionCode in configRestInteraction {
            international401:CapabilityStatementRestInteractionCode interactionCode = check configInteractionCode.ensureType(international401:CapabilityStatementRestInteractionCode);
            international401:CapabilityStatementRestInteraction interaction = {
                code: interactionCode
            };
            restInteraction.push(interaction);           
        }
        rest.interaction = restInteraction;
    } else {
        log:printDebug(VALUE_NOT_FOUND);
    }

    international401:CapabilityStatementRestResource[]? restResources = check populateCapabilityStatementRestResources(configRest.resourceFilePath);
    if restResources is international401:CapabilityStatementRestResource[] {
        rest.'resource = restResources;
    } else {
        log:printDebug(string `${VALUE_NOT_FOUND}: restResources`);
    }
    return rest;
}

# populate capability statement rest security component from configurables.
# 
# + return - capability statement rest security object
isolated function populateCapabilityStatementRestSecurity() returns international401:CapabilityStatementRestSecurity?|error {
    international401:CapabilityStatementRestSecurity restSecurity = {};

    boolean? cors = configRest.security["cors"];
    if cors is boolean {
        restSecurity.cors = cors;
    } else {
        log:printDebug(string `${VALUE_NOT_FOUND}: cors`);
    }

    r4:Coding seviceCoding = {
        system: SERVICE_SYSTEM,
        code: SERVICE_CODE,
        display: SERVICE_DISPLAY
    };

    r4:CodeableConcept securityService = {
        coding: [seviceCoding]
    };

    restSecurity.'service = [securityService];

    r4:ExtensionExtension securityExtension = {
        url: SECURITY_EXT_URL
    };
    r4:Extension[] nestedExtensions = [];

    OpenIDConfiguration openIdConfigurations = {};
    string? discoveryEndpoint = configRest.security?.discoveryEndpoint;
    if discoveryEndpoint is string && discoveryEndpoint != "" {
        openIdConfigurations = check getOpenidConfigurations(discoveryEndpoint).cloneReadOnly();
    } else {
        log:printDebug(string `${VALUE_NOT_FOUND}: discoveryEndpoint`);
    }

    string? configTokenEndpoint = configRest.security?.tokenEndpoint;
    populateSecurityExtensions(nestedExtensions, SECURITY_TOKEN, openIdConfigurations.token_endpoint, configTokenEndpoint);

    string? configAuthorizeEndpoint = configRest.security?.authorizeEndpoint;
    populateSecurityExtensions(nestedExtensions, SECURITY_AUTHORIZE, openIdConfigurations.authorization_endpoint, configAuthorizeEndpoint);

    string? configIntrospectEndpoint = configRest.security?.introspectEndpoint;
    populateSecurityExtensions(nestedExtensions, SECURITY_INTROSPECT, openIdConfigurations.introspection_endpoint, configIntrospectEndpoint);

    string? configRevokeEndpoint = configRest.security?.revocationEndpoint;
    populateSecurityExtensions(nestedExtensions, SECURITY_REVOKE, openIdConfigurations.revocation_endpoint, configRevokeEndpoint);

    string? configRegistrationEndpoint = configRest.security?.registrationEndpoint;
    populateSecurityExtensions(nestedExtensions, SECURITY_REGISTER, openIdConfigurations.registration_endpoint, configRegistrationEndpoint);

    string? confingManagementEndpoint = configRest.security?.managementEndpoint;
    populateSecurityExtensions(nestedExtensions, SECURITY_MANAGE, openIdConfigurations.management_endpoint, confingManagementEndpoint);

    if nestedExtensions.length() > 0 {
        securityExtension.extension = nestedExtensions;
        restSecurity.extension = [securityExtension];
    }
    return restSecurity;
}

isolated function populateSecurityExtensions(r4:Extension[] extensions, string extensionUrl, string? endpointOpenid, string? configEndpoint) {
    string? endpoint = ();
    if endpointOpenid is string {
        endpoint = endpointOpenid;
    } else {
        log:printDebug(string `${VALUE_NOT_FOUND}: ${extensionUrl} in Openid configuration`);
        if configEndpoint is string {
            endpoint = configEndpoint;
        } else {
            log:printDebug(string `${VALUE_NOT_FOUND}: ${extensionUrl}`);
        }
    }

    if endpoint is string {
        r4:Extension securityExtension = {
            url: extensionUrl,
            valueUrl: endpoint.toString()
        };
        extensions.push(securityExtension);
    }
}

# populate capability statement rest resources component from configurables.
#
# + resourceFilePath - resource file path
# + return - capability statement rest resources list
isolated function populateCapabilityStatementRestResources(string? resourceFilePath = ()) returns international401:CapabilityStatementRestResource[]?|error {
    log:printDebug("Populating resources");

    international401:CapabilityStatementRestResource[] resources = [];

    // TODO - Fix line 256, when Choreo supports object arrays in configurable editor. 
    // Refer Issue: https://github.com/wso2-enterprise/open-healthcare/issues/847
    ConfigResource[] configResources = [];
    string? filePath = resourceFilePath;
    if filePath is string {
        json resourcesJSON = check io:fileReadJson(filePath);
        configResources = check resourcesJSON.cloneWithType();
        log:printDebug(string `Resource file path: ${filePath}`);
    } else {
        log:printDebug(string `${VALUE_NOT_FOUND}: resourceFilePath`);
        return;
    }

    if configResources.length() > 0 {
        foreach ConfigResource configResource in configResources {

            international401:CapabilityStatementRestResource 'resource = {
                'type: configResource.'type
            };

            string[]? supportedProfile = configResource.supportedProfiles;
            if supportedProfile is string[] {
                'resource.supportedProfile = supportedProfile;
            } else {
                log:printDebug(string `${VALUE_NOT_FOUND}: supportedProfile`);
            }

            international401:CapabilityStatementRestResourceInteraction[] resourceInteraction = [];
            string[]? configInteraction = configResource.interactions;
            if configInteraction is string[] {
                foreach string configInteractionCode in configInteraction {
                    international401:CapabilityStatementRestResourceInteractionCode interactionCode = check configInteractionCode.ensureType(international401:CapabilityStatementRestResourceInteractionCode);
                    international401:CapabilityStatementRestResourceInteraction interaction = {
                        code: interactionCode
                    };
                    resourceInteraction.push(interaction);
                }
                'resource.interaction = resourceInteraction;
            } else {
                log:printDebug(string `${VALUE_NOT_FOUND}: resourceInteraction`);
            }

            string? configVersioning = configResource.versioning;
            if configVersioning is string {
                international401:CapabilityStatementRestResourceVersioning versioning = check configVersioning.ensureType(international401:CapabilityStatementRestResourceVersioning);
                'resource.versioning = versioning;
            } else {
                log:printDebug(string `${VALUE_NOT_FOUND}: versioning`);
            }

            boolean? conditionalCreate = configResource.conditionalCreate;
            if conditionalCreate is boolean {
                'resource.conditionalCreate = conditionalCreate;
            } else {
                log:printDebug(string `${VALUE_NOT_FOUND}: conditionalCreate`);
            }

            string? configConditionalRead = configResource.conditionalRead;
            if configConditionalRead is string {
                international401:CapabilityStatementRestResourceConditionalRead conditionalRead = check configConditionalRead.ensureType(international401:CapabilityStatementRestResourceConditionalRead);
                'resource.conditionalRead = conditionalRead;
            } else {
                log:printDebug(string `${VALUE_NOT_FOUND}: conditionalRead`);
            }

            boolean? conditionalUpdate = configResource.conditionalUpdate;
            if conditionalUpdate is boolean {
                'resource.conditionalUpdate = conditionalUpdate;
            } else {
                log:printDebug(string `${VALUE_NOT_FOUND}: conditionalUpdate`);
            }

            
            string? configConditionalDelete = configResource.conditionalDelete;
            if configConditionalDelete is string {
                international401:CapabilityStatementRestResourceConditionalDelete conditionalDelete = check configConditionalDelete.ensureType(international401:CapabilityStatementRestResourceConditionalDelete);
                'resource.conditionalDelete = conditionalDelete;
            } else {
                log:printDebug(string `${VALUE_NOT_FOUND}: conditionalDelete`);
            }

            international401:CapabilityStatementRestResourceReferencePolicy[] referencePolicy = [];
            string[]? configReferencePolicy = configResource.referencePolicies;
            if configReferencePolicy is string[] {
                foreach string configReferencePolicyItem in configReferencePolicy {
                    international401:CapabilityStatementRestResourceReferencePolicy referencePolicyItem = check configReferencePolicyItem.ensureType(international401:CapabilityStatementRestResourceReferencePolicy);
                    referencePolicy.push(referencePolicyItem);
                }
                'resource.referencePolicy = referencePolicy;
            } else {
                log:printDebug(string `${VALUE_NOT_FOUND}: referencePolicy`);
            }

            string[] searchRevInclude = [];
            string[]? configSearchRevIncludes = configResource.searchRevIncludes;
            if configSearchRevIncludes is string[] {
                foreach string configSearchRevIncludeItem in configSearchRevIncludes {
                    searchRevInclude.push(configSearchRevIncludeItem);
                }
                'resource.searchRevInclude = searchRevInclude;
            } else {
                log:printDebug(string `${VALUE_NOT_FOUND}: searchRevInclude`);
            }

            international401:CapabilityStatementRestResourceSearchParam[] resourceSearchParams = [];
            do {
                string[]? configStringParams = configResource.stringSearchParams;
                international401:CapabilityStatementRestResourceSearchParam[] stringSearchParams = check populateSearchParams(configStringParams, r4:CODE_TYPE_STRING);
                resourceSearchParams.push(...stringSearchParams);

                string[]? configNumberParams = configResource.numberSearchParams;
                international401:CapabilityStatementRestResourceSearchParam[] numberSearchParams = check populateSearchParams(configNumberParams, international401:CODE_TYPE_NUMBER);
                resourceSearchParams.push(...numberSearchParams);

                string[]? configDateParams = configResource.dateSearchParams;
                international401:CapabilityStatementRestResourceSearchParam[] dateSearchParams = check populateSearchParams(configDateParams, international401:CODE_TYPE_DATE);
                resourceSearchParams.push(...dateSearchParams);

                string[]? configTokenParams = configResource.tokenSearchParams;
                international401:CapabilityStatementRestResourceSearchParam[] tokenSearchParams = check populateSearchParams(configTokenParams, international401:CODE_TYPE_TOKEN);
                resourceSearchParams.push(...tokenSearchParams);

                string[]? configReferenceParams = configResource.referenceSearchParams;
                international401:CapabilityStatementRestResourceSearchParam[] referenceSearchParams = check populateSearchParams(configReferenceParams, international401:CODE_TYPE_REFERENCE);
                resourceSearchParams.push(...referenceSearchParams);

                string[]? configCompositeParams = configResource.compositeSearchParams;
                international401:CapabilityStatementRestResourceSearchParam[] compositeSearchParams = check populateSearchParams(configCompositeParams, international401:CODE_TYPE_COMPOSITE);
                resourceSearchParams.push(...compositeSearchParams);

                string[]? configQuantityParams = configResource.quantitySearchParams;
                international401:CapabilityStatementRestResourceSearchParam[] quantitySearchParams = check populateSearchParams(configQuantityParams, international401:CODE_TYPE_QUANTITY);
                resourceSearchParams.push(...quantitySearchParams);

                string[]? configUriParams = configResource.uriSearchParams;
                international401:CapabilityStatementRestResourceSearchParam[] uriSearchParams = check populateSearchParams(configUriParams, international401:CODE_TYPE_URI);
                resourceSearchParams.push(...uriSearchParams);

                string[]? configSpecialParams = configResource.specialSearchParams;
                international401:CapabilityStatementRestResourceSearchParam[] specialSearchParams = check populateSearchParams(configSpecialParams, international401:CODE_TYPE_SPECIAL);
                resourceSearchParams.push(...specialSearchParams);

                'resource.searchParam = resourceSearchParams;
            } on fail var err {
                return err;
            }
            resources.push('resource);
        }
    } else {
        log:printDebug(string `${VALUE_NOT_FOUND}: restResources`);
        return;
    }
    return resources;
}

# Populate search params
#
# + configSearchParams - search params from config
# + 'type - search param type
# + return - search params
isolated function populateSearchParams(string[]? configSearchParams, international401:CapabilityStatementRestResourceSearchParamType 'type) returns international401:CapabilityStatementRestResourceSearchParam[]|error {
    international401:CapabilityStatementRestResourceSearchParam[] searchParams = [];
    international401:CapabilityStatementRestResourceSearchParam[]? typeSearchParams = check populateSearchParamType(configSearchParams, 'type);
    if typeSearchParams is international401:CapabilityStatementRestResourceSearchParam[] {
        searchParams.push(...typeSearchParams);
    } else {
        log:printDebug(string `${VALUE_NOT_FOUND}: searchParams: ${'type}`);
    }
    return searchParams;
}

# Populate search param type.
#
# + configTypeSearchParams - config type search params
# + configSearchParamType - config search param type
# + return - search params
isolated function populateSearchParamType(string[]? configTypeSearchParams, string configSearchParamType) returns international401:CapabilityStatementRestResourceSearchParam[]?|error {
    international401:CapabilityStatementRestResourceSearchParam[] searchParams = [];
    if configTypeSearchParams is string[] {
        foreach string configTypeSearchParam in configTypeSearchParams {
            international401:CapabilityStatementRestResourceSearchParamType searchParamType = check configSearchParamType.ensureType(international401:CapabilityStatementRestResourceSearchParamType);
            international401:CapabilityStatementRestResourceSearchParam searchParam = {
                name: configTypeSearchParam,
                'type: searchParamType
            };
            searchParams.push(searchParam);
        }
    } else {
        return;
    }
    return searchParams;
}
