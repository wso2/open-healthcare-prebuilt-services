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
import ballerina/lang.runtime;
import ballerina/test;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.hl7v2commons;

http:Client testClient = check new ("http://localhost:9090");
http:Listener customHl7ServiceListener = check new (9091);

@test:BeforeGroups {value: ["g1"]}
function setup() returns error? {
    check customHl7ServiceListener.attach(customMapperService, "v2tofhir");
    // Start the listener.
    check customHl7ServiceListener.'start();
    runtime:registerListener(customHl7ServiceListener);
}

@test:AfterGroups {value: ["g1"]}
function cleanUp() returns error? {
    check customHl7ServiceListener.gracefulStop();
    runtime:deregisterListener(customHl7ServiceListener);
}

@test:Config {}
function testTransformation() returns error? {
    string hl7Payload = string `MSH|^~\\&|ADT1|MCM|LABADT|MCM||SECURITY|QRY^A19|MSG00001|P|2.3|||||||${"\r"}QRD|20220828104856+0000|R|I|QueryID01|||5.0|1^ADAM^EVERMAN^^|VXI|SIIS|`;

    http:Response response = check testClient->/transform.post(hl7Payload);
    json fhirPayload = check response.getJsonPayload();
    json[] fhirres = <json[]>(check fhirPayload.entry);
    anydata|r4:FHIRParseError fhirResource = parser:parse(check fhirres[0].'resource);
    test:assertTrue(fhirResource is r4:DomainResource);
}

@test:Config {}
function testInvalidMsg() returns error? {
    string hl7Payload = string `MSH|^~\\&|ADT1|MCM|LABADT|MCM||SECURITY|QRY^A19|MSG00001|P|2.3|||||||${"\r"}QRD|20220828104856+0000|R|I|${"\n"}QueryID01|||5.0|1^ADAM^EVERMAN^^|VXI|SIIS|`;

    http:Response response = check testClient->/transform.post(hl7Payload);
    test:assertEquals(response.statusCode, 400);
    string msg = check response.getTextPayload();
    test:assertTrue(msg.startsWith("HL7 message is malformed."));
}

@test:Config {groups: ["g1"]}
function testCustomMapperService() returns error? {
    string hl7Payload = string `MSH|^~\\&|ADT1|MCM|LABADT|MCM||SECURITY|QRY^A19|MSG00001|P|2.3|||||||${"\r"}NK1|1|EVERMAN^ADAM^A|F|GRANDFATHER|123 FAKE ST^^SPRINGFIELD^IL^62703^USA|(217)555-5555|(217)`;
    http:Response response = check testClient->/transform.post(hl7Payload);
    json res = check response.getJsonPayload();
    anydata|r4:FHIRParseError fhirResource = parser:parse(res);
    test:assertTrue(fhirResource is r4:Bundle);
    r4:Bundle bundle = check fhirResource.ensureType(r4:Bundle);
    r4:BundleEntry[]? entry = bundle.entry;
    if entry is r4:BundleEntry[] {
        r4:BundleEntry bundleEntry = entry[1];
        map<anydata> patientResource = <map<anydata>>bundleEntry?.'resource;
        test:assertEquals(patientResource["resourceType"], "Patient");
        test:assertEquals(patientResource["id"], "example-id-1");
    } else {
        test:assertFail("Invalid response");
    }
}

http:Service customMapperService = service object {
    resource function post segment/nk1(@http:Payload hl7v2commons:Nk1 nk1) returns json|error {
        return {
            "resourceType": "Patient",
            "id": "example-id-1",
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\">\n\t\t\t<table>\n\t\t\t\t<tbody>\n\t\t\t\t\t<tr>\n\t\t\t\t\t\t<td>Name</td>\n\t\t\t\t\t\t<td>Peter James \n              <b>Chalmers</b> (&quot;Jim&quot;)\n            </td>\n\t\t\t\t\t</tr>\n\t\t\t\t\t<tr>\n\t\t\t\t\t\t<td>Address</td>\n\t\t\t\t\t\t<td>534 Erewhon, Pleasantville, Vic, 3999</td>\n\t\t\t\t\t</tr>\n\t\t\t\t\t<tr>\n\t\t\t\t\t\t<td>Contacts</td>\n\t\t\t\t\t\t<td>Home: unknown. Work: (03) 5555 6473</td>\n\t\t\t\t\t</tr>\n\t\t\t\t\t<tr>\n\t\t\t\t\t\t<td>Id</td>\n\t\t\t\t\t\t<td>MRN: 12345 (Acme Healthcare)</td>\n\t\t\t\t\t</tr>\n\t\t\t\t</tbody>\n\t\t\t</table>\n\t\t</div>"
            },
            "identifier": [
                {
                    "use": "usual",
                    "type": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/v2-0203",
                                "code": "MR"
                            }
                        ]
                    },
                    "system": "urn:oid:1.2.36.146.595.217.0.1",
                    "value": "12345",
                    "period": {
                        "start": "2001-05-06"
                    },
                    "assigner": {
                        "display": "Acme Healthcare"
                    }
                }
            ],
            "active": true,
            "name": [
                {
                    "use": "official",
                    "family": "Chalmers",
                    "given": [
                        "Peter",
                        "James"
                    ]
                },
                {
                    "use": "usual",
                    "given": [
                        "Jim"
                    ]
                },
                {
                    "use": "maiden",
                    "family": "Windsor",
                    "given": [
                        "Peter",
                        "James"
                    ],
                    "period": {
                        "end": "2002"
                    }
                }
            ],
            "managingOrganization": {
                "reference": "Organization/1"
            }
        };
    }
};
