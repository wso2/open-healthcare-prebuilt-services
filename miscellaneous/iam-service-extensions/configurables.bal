// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

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

configurable string ehrContextResolveUrl = "";
configurable string hostname = "localhost";
configurable int port = 9090;
configurable string consentContextApiBaseUrl = "";
configurable string consentContextApiOrganization = "";
configurable string consentContextApiToken = "";
configurable string consentAuthorizeRedirectUrl = "";
configurable string approvedScopesApiBaseUrl = "http://localhost:9091/approved-scopes";
configurable string scimApiBaseUrl = "";
configurable string scimApiPath = "/scim2/Users";
configurable string scimApiUsername = "";
configurable string scimApiPassword = "";
configurable string scimApiTrustStorePath = "";
configurable string scimApiTrustStorePassword = "";
configurable string scimPatientGroupName = "patient";
configurable string fhirUserAttributeName = "fhirUser";
configurable string[] alwaysAllowedScopes = ["openid"];
