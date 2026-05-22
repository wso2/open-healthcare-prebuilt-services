// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerinax/health.fhir.r4;

public final r4:ResourceAPIConfig codesystemApiConfig = {
    resourceType: "CodeSystem",
    profiles: [
        "http://hl7.org/fhir/StructureDefinition/CodeSystem"
    ],
    defaultProfile: (),
    searchParameters: [
        {
            name: "status",
            active: true,
            information: {
                description: "[CodeSystem](codesystem.html): The current status of the code system",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-status"
            }
        },
        {
            name: "url",
            active: true,
            information: {
                description: "[CodeSystem](codesystem.html): The uri that identifies the code system",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-url"
            }
        },
        {
            name: "name",
            active: true,
            information: {
                description: "[CodeSystem](codesystem.html): Computationally friendly name of the code system",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-name"
            }
        },
        {
            name: "version",
            active: true,
            information: {
                description: "[CodeSystem](codesystem.html): The business version of the code system",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-version"
            }
        },
        {
            name: "date",
            active: true,
            information: {
                description: "[CodeSystem](codesystem.html): The code system publication date",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-date"
            }
        },
        {
            name: "publisher",
            active: true,
            information: {
                description: "[CodeSystem](codesystem.html): Name of the publisher of the code system",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-publisher"
            }
        },
        {
            name: "jurisdiction",
            active: true,
            information: {
                description: "[CodeSystem](codesystem.html): Intended jurisdiction for the code system",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-jurisdiction"
            }
        },
        {
            name: "title",
            active: true,
            information: {
                description: "[CodeSystem](codesystem.html): The human-friendly name of the code system",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-title"
            }
        },
        {
            name: "description",
            active: true,
            information: {
                description: "[CodeSystem](codesystem.html): The description of the code system",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-description"
            }
        },
        {
            name: "identifier",
            active: true,
            information: {
                description: "[CodeSystem](codesystem.html): External identifier for the code system",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-identifier"
            }
        },
        {
            name: "system",
            active: true,
            information: {
                description: "The system identifier for the code system",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/CodeSystem-system"
            }
        },
        {
            name: "content-mode",
            active: true,
            information: {
                description: "The content mode of the code system",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/CodeSystem-content-mode"
            }
        },
        {
            name: "language",
            active: true,
            information: {
                description: "The language of the resource",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/Resource-language"
            }
        }
    ],
    operations: [
        {
            name: "lookup",
            active: true,
            information: {
                description: "Look up a code in the code system",
                builtin: false,
                documentation: "http://hl7.org/fhir/OperationDefinition/CodeSystem-lookup"
            },
            parameters: [
                { name: "system", active: true },
                { name: "code", active: true },
                { name: "version", active: true },
                { name: "coding", active: true },
                { name: "date", active: true },
                { name: "displayLanguage", active: true },
                { name: "property", active: true }
            ]
        },
        {
            name: "subsumes",
            active: true,
            information: {
                description: "Test subsumption relationship between two codes",
                builtin: false,
                documentation: "http://hl7.org/fhir/OperationDefinition/CodeSystem-subsumes"
            }
        }
    ],
    serverConfig: (),
    authzConfig: ()
};

