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

http:Client testAllergyIntoleranceClient = check new ("http://localhost:9091");

@test:Config {enable: false}
function testAllergyIntoleranceGetById() returns error? {
    
    http:Response response = check testAllergyIntoleranceClient->/fhir/r4/AllergyIntolerance/["erXuFYUfucBZaryVksYEcMg3"];
    json fhirPayload = check response.getJsonPayload();
    anydata|r4:FHIRParseError fhirResource = parser:parse(fhirPayload);
    test:assertTrue(fhirResource is r4:DomainResource);
}


@test:Config {}
function testAllergyIntoleranceGetByIdError() returns error? {
    
    http:Response response = check testAllergyIntoleranceClient->/fhir/r4/AllergyIntolerance/["invalidId"];
    json fhirPayload = check response.getJsonPayload();
    anydata|r4:FHIRParseError fhirResource = parser:parse(fhirPayload);
    test:assertTrue(fhirResource is r4:DomainResource);
}

@test:Config {}
function testAllergyIntoleranceSearchError() returns error? {

    http:Response response = check testAllergyIntoleranceClient->/fhir/r4/AllergyIntolerance/get({"_id": "11"});  // 11 is not a valid AllergyIntolerance id

    //check for opearion outcome
    json fhirPayload = check response.getJsonPayload();
    anydata|r4:FHIRParseError fhirResource = parser:parse(fhirPayload);
    test:assertTrue(fhirResource is r4:OperationOutcome);
}
