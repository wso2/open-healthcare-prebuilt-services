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
import ballerina/http;
import ballerina/test;

http:Client testClient = check new ("http://localhost:9090");
map<string> cdaDocumentMap = {};

@test:BeforeSuite
function beforeSuiteFunc() returns error? {
    string validDocument = check io:fileReadString("tests/test_valid_ccda_document.xml");
    string invalidDocument = check io:fileReadString("tests/test_invalid_ccda_document.xml");
    cdaDocumentMap["valid"] = validDocument;
    cdaDocumentMap["invalid"] = invalidDocument;
}

@test:Config {}
function testCcdaDocumentToFhir() returns error? {
    http:Response|error response = testClient->/transform.post(cdaDocumentMap["valid"]);
    test:assertTrue(response is http:Response, "Error occurred while transforming CCDA document to FHIR!");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, "Response status code mismatched!");
        json jsonPayload = check response.getJsonPayload();
        test:assertEquals(jsonPayload.resourceType, "Bundle", "Error occurred while transforming CCDA document to FHIR!");
        
        json[] entries = <json[]>check jsonPayload.entry;
        test:assertEquals(entries.length(), 7, "Incorrect number of bundle entries from the conversion!");
        test:assertEquals(check entries[0].'resource.resourceType, "Patient", "Incorrect resource type from the conversion!");

        json[] addresses = <json[]>check entries[0].'resource.address;
        test:assertEquals(addresses.length(), 2, "Incorrect number of addresses from the conversion!");
        test:assertEquals(check addresses[0].use, "home", "Incorrect home from the conversion!");
        test:assertEquals(check addresses[1].use, "work", "Incorrect home from the conversion!");

        json[] addressesLines = <json[]>check addresses[0].line;
        test:assertEquals(addressesLines.length(), 2, "Incorrect number of address lines from the conversion!");
        test:assertEquals(addressesLines[0], "1357 Amber Drive", "Incorrect address line from the conversion!");
        test:assertEquals(addressesLines[1], "Amber Ave", "Incorrect address line from the conversion!");

        json[] names = <json[]>check entries[0].'resource.name;
        test:assertEquals(names.length(), 2, "Incorrect number of names from the conversion!");
        test:assertEquals(check names[0].use, "official", "Incorrect name use from the conversion!");
        test:assertEquals(check names[1].use, "nickname", "Incorrect name use from the conversion!");

        json[] nameOneGiven = <json[]>check names[0].given;
        test:assertEquals(nameOneGiven.length(), 2, "Incorrect number of given names from the conversion!");
        test:assertEquals(nameOneGiven[0], "John", "Incorrect given name from the conversion!");
        test:assertEquals(nameOneGiven[1], "Shane", "Incorrect given name from the conversion!");
        json[] nameOnePrefix = <json[]>check names[0].prefix;
        test:assertEquals(nameOnePrefix.length(), 1, "Incorrect number of prefixes from the conversion!");
        test:assertEquals(nameOnePrefix[0], "Mr", "Incorrect prefix from the conversion!");
        json[] nameOneSuffix = <json[]>check names[0].suffix;
        test:assertEquals(nameOneSuffix.length(), 1, "Incorrect number of suffixes from the conversion!");
        test:assertEquals(nameOneSuffix[0], "PhD", "Incorrect suffix from the conversion!");
        json[] nameTwoGiven = <json[]>check names[1].given;
        test:assertEquals(nameTwoGiven.length(), 1, "Incorrect number of given names from the conversion!");
        test:assertEquals(nameTwoGiven[0], "Leonardo", "Incorrect given name from the conversion!");
        test:assertEquals(entries[0].'resource.birthDate, "1947-05-01", "Incorrect birth date from the conversion!");
        json[] maritalStatusCoding = <json[]>check entries[0].'resource.maritalStatus.coding;
        test:assertEquals(maritalStatusCoding.length(), 1, "Incorrect number of marital status codings from the conversion!");
        test:assertEquals(check maritalStatusCoding[0].code, "D", "Incorrect marital status code from the conversion!");
        test:assertEquals(check maritalStatusCoding[0].display, "Divorced", "Incorrect marital status display from the conversion!");
        test:assertEquals(check maritalStatusCoding[0].system, "urn:oid:2.16.840.1.113883.4.642.3.29", "Incorrect marital status system from the conversion!");
        test:assertEquals(check entries[0].'resource.maritalStatus.text, "Divorced 2 years ago", "Incorrect marital status text from the conversion!");
        json[] extensions = <json[]>check entries[0].'resource.extension;
        test:assertEquals(extensions.length(), 2, "Incorrect number of extensions from the conversion!");
        test:assertEquals(extensions[0].url, "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race", "Incorrect extension url from the conversion!");
        test:assertEquals(extensions[1].url, "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity", "Incorrect extension url from the conversion!");
        test:assertEquals(entries[0].'resource.managingOrganization.reference, "Organization/3", "Incorrect managing organization reference from the conversion!");
        test:assertEquals(entries[0].'resource.managingOrganization.display, "Primary Care's Partners Test", "Incorrect managing organization display from the conversion!");

        test:assertEquals(entries[1].'resource.resourceType, "AllergyIntolerance", "Incorrect resource type from the conversion!");
        json[] clinicalStatusCoding = <json[]>check entries[1].'resource.clinicalStatus.coding;
        test:assertEquals(clinicalStatusCoding[0].code, "active", "Incorrect clinical status from the conversion!");
        test:assertEquals(clinicalStatusCoding[0].system, "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical", "Incorrect clinical status system from the conversion!");
        json[] AllergyIntoleranceIdentifier = <json[]>check entries[1].'resource.identifier;
        test:assertEquals(AllergyIntoleranceIdentifier.length(), 1, "Incorrect number of identifiers from the conversion!");
        test:assertEquals(check AllergyIntoleranceIdentifier[0].system, "urn:ietf:rfc:3986", "Incorrect identifier system from the conversion!");
        test:assertEquals(check AllergyIntoleranceIdentifier[0].value, "urn:oid:36e3e930-7b14-11db-9fe1-0800200c9a66", "Incorrect identifier value from the conversion!");
        test:assertEquals(entries[1].'resource.onsetDateTime, "2023-05-31T22:05-05:00", "Incorrect onsetDateTime from the conversion!");
        json[] allergyIntoleranceCodeCodings = <json[]>check entries[1].'resource.code.coding;
        test:assertEquals(allergyIntoleranceCodeCodings.length(), 1, "Incorrect number of codes from the conversion!");
        test:assertEquals(check allergyIntoleranceCodeCodings[0].system, "http://snomed.info/sct", "Incorrect system from the conversion!");
        test:assertEquals(check allergyIntoleranceCodeCodings[0].code, "105590001", "Incorrect code from the conversion!");
        test:assertEquals(check allergyIntoleranceCodeCodings[0].display, "Substance", "Incorrect display from the conversion!");
        test:assertEquals(entries[1].'resource.recordedDate, "2014-10-03T10:30-05:00", "Incorrect recorded date from the conversion!");

        test:assertEquals(entries[2].'resource.resourceType, "MedicationRequest", "Incorrect resource type from the conversion!");

        test:assertEquals(entries[3].'resource.resourceType, "Immunization", "Incorrect resource type from the conversion!");
        test:assertEquals(entries[3].'resource.status, "completed", "Incorrect status from the conversion!");
        json[] ImmunizationStatusReason = <json[]>check entries[3].'resource.statusReason.coding;
        test:assertEquals(ImmunizationStatusReason.length(), 1, "Incorrect number of status reasons from the conversion!");
        test:assertEquals(check ImmunizationStatusReason[0].code, "MEDPREC", "Incorrect status reason code from the conversion!");

        test:assertEquals(entries[4].'resource.resourceType, "Procedure", "Incorrect resource type from the conversion!");
        test:assertEquals(entries[4].'resource.status, "not-done", "Incorrect status from the conversion!");
        test:assertEquals(entries[5].'resource.resourceType, "Procedure", "Incorrect resource type from the conversion!");
        test:assertEquals(entries[5].'resource.status, "in-progress", "Incorrect status from the conversion!");
        test:assertEquals(entries[5].'resource.performedDateTime, "2021-05-31", "Incorrect performed date from the conversion!");

        test:assertEquals(entries[6].'resource.resourceType, "Condition", "Incorrect resource type from the conversion!");
        json[] conditionVerificationStatusCoding = <json[]>check entries[6].'resource.verificationStatus.coding;
        test:assertEquals(conditionVerificationStatusCoding.length(), 1, "Incorrect number of verification status codings from the conversion!");
        test:assertEquals(conditionVerificationStatusCoding[0].code, "refuted", "Incorrect clinical status from the conversion!");
        json[] conditionCategory = <json[]>check entries[6].'resource.category;
        test:assertEquals(conditionCategory.length(), 1, "Incorrect number of categories from the conversion!");
        json[] conditionCategoryCoding = <json[]>check conditionCategory[0].coding;
        test:assertEquals(conditionCategoryCoding.length(), 1, "Incorrect number of category codings from the conversion!");
        test:assertEquals(check conditionCategoryCoding[0].code, "problem-list-item", "Incorrect category code from the conversion!");
        json[] conditionIdentifier = <json[]>check entries[6].'resource.identifier;
        test:assertEquals(conditionIdentifier.length(), 1, "Incorrect number of identifiers from the conversion!");
        test:assertEquals(entries[6].'resource.onsetDateTime, "2022-01-01", "Incorrect onset datetime from the conversion!");
        test:assertEquals(entries[6].'resource.abatementDateTime, "2023-12-31", "Incorrect onset datetime from the conversion!");
    }
}

@test:Config {}
function testErrorneousCcdaDocument() returns error? {
    http:Response|error response = testClient->/transform.post(cdaDocumentMap["invalid"]);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400, "Response status code mismatched!");
        json jsonPayload = check response.getJsonPayload();
        test:assertEquals(jsonPayload.resourceType, "OperationOutcome", "Response should be an OperationOutcome!");
        json[] issues = <json[]>check jsonPayload.issue;
        json textElement = check issues[0].details.text;
        test:assertTrue(string:startsWith(textElement.toString(), "Invalid xml document."),
            "Incorrect error message from the invalid document conversion!");
    }
}

