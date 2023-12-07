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

import ballerinax/health.fhir.r4.international401;

# Configs for server
#
# + url - Canonical identifier for this capability statement, represented as a URI (globally unique)
# + 'version - Business version of the capability statement
# + name - Name for this capability statement (computer friendly)  
# + title - Name for this capability statement (human friendly)
# + status - Code: draft | active | retired | unknown
# + experimental - For testing purposes, not real usage
# + date - Date last changed
# + kind - Code: instance | capability | requirements
# + implementationUrl - Base URL for the installation
# + implementationDescription - Describes this specific instance
# + fhirVersion - FHIR Version the system supports
# + format - formats supported (xml | json | ttl | mime type)
# + patchFormat - Patch formats supported
public type ConfigFHIRServer record {|
    string url?;
    string 'version?;
    string name?;
    string title?;
    international401:CapabilityStatementStatus status;
    boolean experimental?;
    string date?;
    international401:CapabilityStatementKind kind;
    string implementationUrl?;
    string implementationDescription;
    string fhirVersion;
    international401:CapabilityStatementFormat[] format;
    string[] patchFormat?;
|};

# If the endpoint is a RESTful one
# Rule: A given resource can only be described once per RESTful mode.
#
# + mode - Code: client | server  
# + documentation - General description of implementation  
# + security - Information about security of implementation  
# + resourceFilePath - Path to the file containing resources
# + interaction - Operations supported  
# + searchParam - Search parameters for searching all resources
public type ConfigRest record {|
    string ?mode = REST_MODE_SERVER;
    string documentation?;
    ConfigSecurity security?;
    string resourceFilePath?;
    string[] interaction?;
    string[] searchParam?;
|};

# Configs for server security
#
# + cors - Enable cors or not  
# + discoveryEndpoint - Discovery endpoint for the FHIR server  
# + tokenEndpoint - Token endpoint for the FHIR server  
# + revocationEndpoint - Revoke endpoint for the FHIR server  
# + authorizeEndpoint - Authorization endpoint for the FHIR server  
# + introspectEndpoint - Introspect endpoint for the FHIR server  
# + managementEndpoint - Manage endpoint for the FHIR server  
# + registrationEndpoint - Register endpoint for the FHIR server
public type ConfigSecurity record {
    boolean cors?;
    string discoveryEndpoint?;
    string tokenEndpoint?;
    string revocationEndpoint?;
    string authorizeEndpoint?;
    string introspectEndpoint?;
    string managementEndpoint?;
    string registrationEndpoint?;
};

# Configs for resource.
#
# + 'type - A resource type that is supported
# + versioning - no-version | versioned | versioned-update
# + conditionalCreate - If allows/uses conditional create
# + conditionalRead - not-supported | modified-since | not-match | full-support
# + conditionalUpdate - If allows/uses conditional update
# + conditionalDelete - not-supported | single | multiple - how conditional delete is supported
# + referencePolicies - literal | logical | resolves | enforced | local
# + searchIncludes - _include values supported by the server
# + searchRevIncludes - _revinclude values supported by the server
# + supportedProfiles - Use-case specific profiles
# + interactions - Operations supported
# + numberSearchParams - Numeric search parameters supported by implementation
# + dateSearchParams - Date search parameters supported by implementation
# + stringSearchParams - String search parameters supported by implementation
# + tokenSearchParams - Token search parameters supported by implementation
# + referenceSearchParams - Reference search parameters supported by implementation
# + compositeSearchParams - Composite search parameters supported by implementation
# + quantitySearchParams - Quantity search parameters supported by implementation
# + uriSearchParams - URI search parameters supported by implementation
# + specialSearchParams - Special search parameters supported by implementation
public type ConfigResource record {
    string 'type;
    string versioning?;
    boolean conditionalCreate?;
    string conditionalRead?;
    boolean conditionalUpdate?;
    string conditionalDelete?;
    string[] referencePolicies?;
    string[] searchIncludes?;
    string[] searchRevIncludes?;
    string[] supportedProfiles?;
    string[] interactions?;
    string[] numberSearchParams?;
    string[] dateSearchParams?;
    string[] stringSearchParams?;
    string[] tokenSearchParams?;
    string[] referenceSearchParams?;
    string[] compositeSearchParams?;
    string[] quantitySearchParams?;
    string[] uriSearchParams?;
    string[] specialSearchParams?;
};
