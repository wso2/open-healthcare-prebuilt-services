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
import ballerina/test;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.terminology;

function returnCodeSystemData(string fileName) returns json {
    string filePath = string `tests/resources/code_systems/${fileName}.json`;
    json|error data = io:fileReadJson(filePath);

    if data is json {
        return data;
    } else {
        test:assertFail(string `Can not load data from: ${filePath}`);
    }
}

function returnCodeSystemDataXml(string fileName) returns xml {
    string filePath = string `tests/resources/code_systems/${fileName}.xml`;
    xml|error data = io:fileReadXml(filePath);

    if data is xml {
        return data;
    } else {
        test:assertFail(string `Can not load data from: ${filePath}`);
    }
}

function returnValueSetData(string fileName) returns json {
    string filePath = string `tests/resources/value_sets/${fileName}.json`;
    json|error data = io:fileReadJson(filePath);

    if data is json {
        return data;
    } else {
        test:assertFail(string `Can not load data from: ${filePath}`);
    }
}

function returnConceptData(string fileName) returns json {
    string filePath = string `tests/resources/concepts/${fileName}.json`;
    json|error data = io:fileReadJson(filePath);

    if data is json {
        return data;
    } else {
        test:assertFail(string `Can not load data from: ${filePath}`);
    }
}

function returnBatchData(string fileName) returns json {
    string filePath = string `tests/resources/value_sets/batch_validation/${fileName}.json`;
    json|error data = io:fileReadJson(filePath);

    if data is json {
        return data;
    } else {
        test:assertFail(string `Cannot load data from: ${filePath}`);
    }
}

function readJsonData(string fileName) returns json {
    string filePath = string `tests/resources/terminology/${fileName}.json`;
    json|error data = io:fileReadJson(filePath);

    if data is json {
        return data;
    } else {
        test:assertFail(string `Can not load data from: ${filePath}`);
    }
}

public function readZipFileAsBytes(string fileName) returns byte[]|error {
    string filePath = string `tests/resources/zip/${fileName}`;
    return io:fileReadBytes(filePath);
}

isolated function addExampleDataToTestDB() returns error? {
    string[] codeSystemList = ["http://hl7.org/fhir/account-status", "http://hl7.org/fhir/abstract-types", "http://hl7.org/fhir/resource-status"];
    string[] valueSetList = ["http://hl7.org/fhir/ValueSet/abstract-types", "http://hl7.org/fhir/ValueSet/account-status"];

    foreach string item in codeSystemList {
        _ = check terminology:addCodeSystem(check terminology:readCodeSystemByUrl(item), terminology = terminology_source);
    }

    foreach string item in valueSetList {
        _ = check terminology:addValueSet(check terminology:readValueSetByUrl(item), terminology = terminology_source);
    }
}

function assertParametersEqual(international401:Parameters expected, international401:Parameters actual) returns boolean {
    international401:ParametersParameter[]? expectedParams = expected.'parameter;
    international401:ParametersParameter[]? actualParams = actual.'parameter;

    if expectedParams is () || actualParams is () {
        test:assertFail("Parameter arrays are empty. Expected: " + expected.'parameter.count().toString() + ", Actual: " + actual.'parameter.count().toString());
    }

    if expectedParams.length() != actualParams.length() {
        test:assertFail("Parameter array lengths differ. Expected: " + expected.'parameter.count().toString() + ", Actual: " + actual.'parameter.count().toString());
    }

    foreach var expParam in expectedParams {
        boolean found = false;
        foreach var actParam in actualParams {
            if expParam.toJson().toString() == actParam.toJson().toString() {
                found = true;
                break;
            }
        }
        if !found {
            test:assertFail("Expected parameter not found in actual: " + expParam.toJson().toString());
        }
    }

    return true;
}

function assertValueSetExpansionsEqual(r4:ValueSetExpansion? expected, r4:ValueSetExpansion? actual) returns boolean {
    if expected is () && actual is () {
        return true;
    }
    if expected is () || actual is () {
        test:assertFail("ValueSetExpansion is empty or missing.");
    }

    // Compare simple fields using assertEquals
    test:assertEquals(expected.identifier, actual.identifier, "ValueSetExpansion identifier mismatch.");
    test:assertEquals(expected.timestamp, actual.timestamp, "ValueSetExpansion timestamp mismatch.");
    test:assertEquals(expected.total, actual.total, "ValueSetExpansion total mismatch.");
    test:assertEquals(expected.offset, actual.offset, "ValueSetExpansion offset mismatch.");

    r4:ValueSetExpansionContains[]? expectedContains = expected.contains;
    r4:ValueSetExpansionContains[]? actualContains = actual.contains;

    if expectedContains is () || actualContains is () {
        test:assertFail("ValueSetExpansion 'contains' arrays are empty or missing.");
    }

    if expectedContains.length() != actualContains.length() {
        test:assertFail("ValueSetExpansion 'contains' array lengths differ. Expected: " + expectedContains.length().toString() + ", Actual: " + actualContains.length().toString());
    }

    foreach r4:ValueSetExpansionContains contain in expectedContains {
        if actualContains.indexOf(contain) == () {
            test:assertFail("Expected 'contains' item not found in actual: " + contain.toJson().toString());
        }

    }

    return true;
}

function assertBundleEqual(r4:Bundle expected, r4:Bundle actual) returns boolean {
    r4:BundleEntry[]? expectedEntries = expected.entry;
    r4:BundleEntry[]? actualEntries = actual.entry;

    if expectedEntries is () || actualEntries is () {
        test:assertFail("Bundle entries are empty. Expected: " + expected.entry.count().toString() + ", Actual: " + actual.entry.count().toString());
    }

    if expectedEntries.length() != actualEntries.length() {
        test:assertFail("Bundle entry array lengths differ. Expected: " + expectedEntries.length().toString() + ", Actual: " + actualEntries.length().toString());
    }

    foreach r4:BundleEntry entry in expectedEntries {
        if actualEntries.indexOf(entry) == () {
            test:assertFail("Expected bundle entry not found in actual: " + entry.toJson().toString());
        }
    }

    return true;
}
