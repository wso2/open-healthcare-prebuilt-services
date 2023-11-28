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
import ballerina/test;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;

http:Client testClient = check new ("http://localhost:9090");

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
