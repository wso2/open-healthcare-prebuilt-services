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

public final r4:ResourceAPIConfig valuesetApiConfig = {
    resourceType: "ValueSet",
    profiles: [
        "http://hl7.org/fhir/StructureDefinition/ValueSet"
    ],
    defaultProfile: (),
    searchParameters: [
        {
            name: "status",
            active: true,
            information: {
                description: "[ValueSet](valueset.html): The current status of the value set",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-status"
            }
        },
        {
            name: "url",
            active: true,
            information: {
                description: "[ValueSet](valueset.html): The uri that identifies the value set",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-url"
            }
        },
        {
            name: "name",
            active: true,
            information: {
                description: "[ValueSet](valueset.html): Computationally friendly name of the value set",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-name"
            }
        },
        {
            name: "version",
            active: true,
            information: {
                description: "[ValueSet](valueset.html): The business version of the value set",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-version"
            }
        },
        {
            name: "date",
            active: true,
            information: {
                description: "[ValueSet](valueset.html): The value set publication date",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-date"
            }
        },
        {
            name: "publisher",
            active: true,
            information: {
                description: "[ValueSet](valueset.html): Name of the publisher of the value set",
                builtin: false,
               documentation: "http://hl7.org/fhir/SearchParameter/conformance-publisher"
            }
        },
        {
            name: "jurisdiction",
            active: true,
            information: {
                description: "[ValueSet](valueset.html): Intended jurisdiction for the value set",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-jurisdiction"
            }
        },
        {
            name: "title",
            active: true,
            information: {
                description: "[ValueSet](valueset.html): The human-friendly name of the value set",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-title"
            }
        },
        {
            name: "description",
            active: true,
            information: {
                description: "[ValueSet](valueset.html): The description of the value set",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-description"
            }
        },
        {
            name: "identifier",
            active: true,
            information: {
                description: "[ValueSet](valueset.html): External identifier for the value set",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/conformance-identifier"
            }
        },
        {
            name: "reference",
            active: true,
            information: {
                description: "A code system included or excluded in the value set",
                builtin: false,
                documentation: "http://hl7.org/fhir/SearchParameter/ValueSet-reference"
            }
        }
    ],
    operations: [
        {
            name: "expand",
            active: true,
            information: {
                description: "Expand a value set to return the list of codes",
                builtin: false,
                documentation: "http://hl7.org/fhir/OperationDefinition/ValueSet-expand"
            }
        },
        {
            name: "validate-code",
            active: true,
            information: {
                description: "Validate that a code is in the value set",
                builtin: false,
                documentation: "http://hl7.org/fhir/OperationDefinition/ValueSet-validate-code"
            },
            parameters: [
                { name: "url", active: true },
                { name: "valueSet", active: true },
                { name: "code", active: true },
                { name: "system", active: true },
                { name: "display", active: true },
                { name: "coding", active: true },
                { name: "codeableConcept", active: true }
            ]
        }
    ],
    serverConfig: (),
    authzConfig: ()
};

