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

import ballerina/test;
import ballerinax/health.fhir.r4;

@test:Config {
    groups: ["unit", "filter_operators", "successful_scenario"]
}
public function testStringEqualsMatches() {
    test:assertTrue(stringEquals("new", "new"));
    test:assertTrue(stringEquals("", ""));
    test:assertFalse(stringEquals("new", "old"));
    test:assertFalse(stringEquals("New", "new"));
}

@test:Config {
    groups: ["unit", "filter_operators", "successful_scenario"]
}
public function testRegexMatchesIsFullMatch() {
    // Pattern from the tx-ecosystem simple-cases fixtures: exactly five
    // non-whitespace characters ending in a digit.
    string fiveCharsEndingInDigit = "[^ \\t\\r\\n\\f]{4}[0-9]";
    test:assertTrue(regexMatches("code1", fiveCharsEndingInDigit));
    // Full-string semantics: a longer code must not match even though its
    // first five characters would.
    test:assertFalse(regexMatches("code2a", fiveCharsEndingInDigit));

    test:assertTrue(regexMatches("old", "o[a-z]*"));
    test:assertFalse(regexMatches("new", "o[a-z]*"));
}

@test:Config {
    groups: ["unit", "filter_operators", "successful_scenario"]
}
public function testPropertyValueAsStringReadsEachValueType() {
    r4:CodeSystemConceptProperty stringProp = {code: "prop", valueString: "hello"};
    test:assertEquals(propertyValueAsString(stringProp), "hello");

    r4:CodeSystemConceptProperty codeProp = {code: "prop", valueCode: "new"};
    test:assertEquals(propertyValueAsString(codeProp), "new");

    r4:CodeSystemConceptProperty boolProp = {code: "notSelectable", valueBoolean: true};
    test:assertEquals(propertyValueAsString(boolProp), "true");

    r4:CodeSystemConceptProperty intProp = {code: "rank", valueInteger: 42};
    test:assertEquals(propertyValueAsString(intProp), "42");
}

@test:Config {
    groups: ["unit", "filter_operators", "successful_scenario"]
}
public function testPropertyValueAsStringReturnsNilWhenNoValue() {
    r4:CodeSystemConceptProperty emptyProp = {code: "prop"};
    test:assertEquals(propertyValueAsString(emptyProp), ());
}

@test:Config {
    groups: ["unit", "lookup_shape", "successful_scenario"]
}
public function testConceptPropertyToParameterCarriesValueCode() {
    r4:CodeSystemConceptProperty prop = {code: "prop", valueCode: "new"};
    r4:ParametersParameter result = codeSystemConceptPropertyToParameter(prop);

    test:assertEquals(result.name, "property");
    r4:ParametersParameter? codePart = findPart(result, "code");
    r4:ParametersParameter? valuePart = findPart(result, "value");
    test:assertTrue(codePart is r4:ParametersParameter);
    test:assertTrue(valuePart is r4:ParametersParameter);
    test:assertEquals((<r4:ParametersParameter>codePart).valueCode, "prop");
    test:assertEquals((<r4:ParametersParameter>valuePart).valueCode, "new");
}

@test:Config {
    groups: ["unit", "lookup_shape", "successful_scenario"]
}
public function testConceptPropertyToParameterOmitsEmptyPart() {
    // A property with no value[x] set must not produce an empty part array,
    // which previously crashed the tx-ecosystem parameter sorter.
    r4:CodeSystemConceptProperty valueless = {code: "prop"};
    r4:ParametersParameter result = codeSystemConceptPropertyToParameter(valueless);
    test:assertEquals(result.part, ());
}

@test:Config {
    groups: ["unit", "lookup_shape", "successful_scenario"]
}
public function testLookupParametersIncludeCodeSystemMetadata() {
    r4:CodeSystemConcept concept = {code: "code1", display: "Display 1"};
    r4:CodeSystem cs = {
        content: "complete",
        status: "active",
        name: "SimpleTestCodeSystem",
        url: "http://hl7.org/fhir/test/CodeSystem/simple",
        version: "0.1.0"
    };

    r4:Parameters result = codesystemConceptsToParameters(concept, cs);

    r4:ParametersParameter? nameParam = findParam(result, "name");
    r4:ParametersParameter? systemParam = findParam(result, "system");
    r4:ParametersParameter? versionParam = findParam(result, "version");
    r4:ParametersParameter? codeParam = findParam(result, "code");

    test:assertEquals((<r4:ParametersParameter>nameParam).valueString, "SimpleTestCodeSystem");
    test:assertEquals((<r4:ParametersParameter>systemParam).valueUri, "http://hl7.org/fhir/test/CodeSystem/simple");
    test:assertEquals((<r4:ParametersParameter>versionParam).valueString, "0.1.0");
    test:assertEquals((<r4:ParametersParameter>codeParam).valueCode, "code1");
}

@test:Config {
    groups: ["unit", "lookup_shape", "successful_scenario"]
}
public function testLookupParametersAreSortedByName() {
    r4:CodeSystemConcept concept = {code: "code1", display: "Display 1"};
    r4:CodeSystem cs = {
        content: "complete",
        status: "active",
        name: "SimpleTestCodeSystem",
        url: "http://hl7.org/fhir/test/CodeSystem/simple",
        version: "0.1.0"
    };

    r4:Parameters result = codesystemConceptsToParameters(concept, cs);
    r4:ParametersParameter[] entries = <r4:ParametersParameter[]>result.'parameter;

    string previous = "";
    foreach r4:ParametersParameter entry in entries {
        test:assertTrue(entry.name >= previous,
                string `Parameters are not sorted: "${entry.name}" came after "${previous}"`);
        previous = entry.name;
    }
}

@test:Config {
    groups: ["unit", "lookup_shape", "successful_scenario"]
}
public function testAbstractDerivedFromNotSelectable() {
    r4:CodeSystemConcept abstractConcept = {
        code: "code2",
        display: "Display 2",
        property: [{code: "notSelectable", valueBoolean: true}]
    };
    r4:Parameters result = codesystemConceptsToParameters(abstractConcept);
    r4:ParametersParameter? abstractParam = findParam(result, "abstract");
    test:assertEquals((<r4:ParametersParameter>abstractParam).valueBoolean, true);

    r4:CodeSystemConcept plainConcept = {code: "code1", display: "Display 1"};
    r4:Parameters plainResult = codesystemConceptsToParameters(plainConcept);
    r4:ParametersParameter? plainAbstract = findParam(plainResult, "abstract");
    test:assertEquals((<r4:ParametersParameter>plainAbstract).valueBoolean, false);
}

@test:Config {
    groups: ["unit", "lookup_shape", "successful_scenario"]
}
public function testInactiveDerivedFromRetiredStatus() {
    r4:CodeSystemConcept retiredConcept = {
        code: "code2",
        display: "Display 2",
        property: [{code: "status", valueCode: "retired"}]
    };
    r4:Parameters result = codesystemConceptsToParameters(retiredConcept);

    boolean foundInactiveTrue = false;
    foreach r4:ParametersParameter param in findAllParams(result, "property") {
        r4:ParametersParameter? codePart = findPart(param, "code");
        if codePart is r4:ParametersParameter && codePart.valueCode == "inactive" {
            r4:ParametersParameter? valuePart = findPart(param, "value");
            if valuePart is r4:ParametersParameter && valuePart.valueBoolean == true {
                foundInactiveTrue = true;
            }
        }
    }
    test:assertTrue(foundInactiveTrue, "Expected inactive=true derived from status=retired");
}

@test:Config {
    groups: ["unit", "lookup_shape", "successful_scenario"]
}
public function testHierarchyEmittedAsParentAndChildProperties() {
    r4:CodeSystemConcept concept = {code: "code2a", display: "Display 2a"};
    r4:CodeSystemConcept parent = {code: "code2", display: "Display 2"};
    r4:CodeSystemConcept[] children = [
        {code: "code2aI", display: "Display 2aI"},
        {code: "code2aII", display: "Display 2aII"}
    ];

    r4:Parameters result = codesystemConceptsToParameters(concept, (), [parent], children);

    string[] parentValues = [];
    string[] childValues = [];
    foreach r4:ParametersParameter param in findAllParams(result, "property") {
        r4:ParametersParameter? codePart = findPart(param, "code");
        r4:ParametersParameter? valuePart = findPart(param, "value");
        if codePart is () || valuePart is () {
            continue;
        }
        r4:code? propertyCode = codePart.valueCode;
        r4:code? propertyValue = valuePart.valueCode;
        if propertyValue is () {
            continue;
        }
        if propertyCode == "parent" {
            parentValues.push(propertyValue);
        } else if propertyCode == "child" {
            childValues.push(propertyValue);
        }
    }

    test:assertEquals(parentValues, ["code2"]);
    test:assertEquals(childValues, ["code2aI", "code2aII"]);
}

// A concept can have more than one is-a parent (e.g. SNOMED) - verifies that
// codesystemConceptsToParameters emits one "parent" property entry per parent,
// not just the first one.
@test:Config {
    groups: ["unit", "lookup_shape", "successful_scenario"]
}
public function testMultipleParentsEmittedAsSeparatePropertyEntries() {
    r4:CodeSystemConcept concept = {code: "10000006", display: "Radiating chest pain"};
    r4:CodeSystemConcept[] parents = [
        {code: "29857009", display: "Chest pain"},
        {code: "9972008", display: "Radiating pain"}
    ];

    r4:Parameters result = codesystemConceptsToParameters(concept, (), parents);

    string[] parentValues = [];
    foreach r4:ParametersParameter param in findAllParams(result, "property") {
        r4:ParametersParameter? codePart = findPart(param, "code");
        r4:ParametersParameter? valuePart = findPart(param, "value");
        if codePart is () || valuePart is () {
            continue;
        }
        r4:code? propertyValue = valuePart.valueCode;
        if codePart.valueCode == "parent" && propertyValue is r4:code {
            parentValues.push(propertyValue);
        }
    }

    test:assertEquals(parentValues, ["29857009", "9972008"]);
}

@test:Config {
    groups: ["unit", "validate_code_shape", "successful_scenario"]
}
public function testFindConceptInConceptListFindsNestedCode() {
    r4:CodeSystemConcept[] concepts = [
        {
            code: "chapter1",
            display: "Chapter 1",
            concept: [
                {code: "section1a", display: "Section 1a"},
                {
                    code: "section1b",
                    display: "Section 1b",
                    concept: [
                        {code: "leaf1b1", display: "Leaf 1b1"}
                    ]
                }
            ]
        }
    ];

    r4:CodeSystemConcept? found = findConceptInConceptList(concepts, ["leaf1b1"]);
    test:assertTrue(found is r4:CodeSystemConcept);
    test:assertEquals((<r4:CodeSystemConcept>found).display, "Leaf 1b1");
}

@test:Config {
    groups: ["unit", "validate_code_shape", "successful_scenario"]
}
public function testFindConceptInConceptListReturnsNilWhenNotFound() {
    r4:CodeSystemConcept[] concepts = [
        {code: "chapter1", display: "Chapter 1", concept: [{code: "section1a", display: "Section 1a"}]}
    ];

    test:assertEquals(findConceptInConceptList(concepts, ["does-not-exist"]), ());
}

@test:Config {
    groups: ["unit", "validate_code_shape", "successful_scenario"]
}
public function testApplyDisplayCheckPassesOnExactMatch() {
    r4:CodeSystemConcept concept = {code: "code1", display: "Display 1"};
    r4:Parameters validated = {'parameter: [{name: "result", valueBoolean: true}]};

    r4:Parameters checked = applyDisplayCheck(validated, concept, "Display 1");

    test:assertEquals((<r4:ParametersParameter>findParam(checked, "result")).valueBoolean, true);
    test:assertEquals(findParam(checked, "message"), ());
}

@test:Config {
    groups: ["unit", "validate_code_shape", "successful_scenario"]
}
public function testApplyDisplayCheckPassesOnDesignationMatch() {
    // A mismatch against the primary display is still a match if it equals a
    // designation (synonym) value - synonyms are valid displays too.
    r4:CodeSystemConcept concept = {
        code: "code1",
        display: "Display 1",
        designation: [{value: "Synonym For Display 1"}]
    };
    r4:Parameters validated = {'parameter: [{name: "result", valueBoolean: true}]};

    r4:Parameters checked = applyDisplayCheck(validated, concept, "Synonym For Display 1");

    test:assertEquals((<r4:ParametersParameter>findParam(checked, "result")).valueBoolean, true);
    test:assertEquals(findParam(checked, "message"), ());
}

@test:Config {
    groups: ["unit", "validate_code_shape", "successful_scenario"]
}
public function testApplyDisplayCheckFlipsResultOnMismatch() {
    r4:CodeSystemConcept concept = {code: "code1", display: "Display 1"};
    r4:Parameters validated = {'parameter: [{name: "result", valueBoolean: true}]};

    r4:Parameters checked = applyDisplayCheck(validated, concept, "Wrong Display");

    test:assertEquals((<r4:ParametersParameter>findParam(checked, "result")).valueBoolean, false);
    r4:ParametersParameter? messageParam = findParam(checked, "message");
    test:assertTrue(messageParam is r4:ParametersParameter);
    test:assertEquals((<r4:ParametersParameter>messageParam).valueString,
            "Display \"Wrong Display\" does not match the expected display \"Display 1\"");
}

@test:Config {
    groups: ["unit", "validate_code_shape", "successful_scenario"]
}
public function testLookupInInlineCodeSystemMatchesSameSystemCoding() {
    r4:CodeSystem codeSystem = {
        content: "complete",
        status: "active",
        url: "http://example.org/fhir/CodeSystem/inline-a",
        concept: [{code: "shared-code", display: "From System A"}]
    };
    r4:Coding coding = {system: "http://example.org/fhir/CodeSystem/inline-a", code: "shared-code"};

    r4:CodeSystemConcept|r4:FHIRError result = lookupInInlineCodeSystem(coding, codeSystem);
    if result is r4:FHIRError {
        test:assertFail("Expected a matching concept, got: " + result.message());
    }
    test:assertEquals(result.display, "From System A");
}

@test:Config {
    groups: ["unit", "validate_code_shape", "failure_scenario"]
}
public function testLookupInInlineCodeSystemRejectsDifferentSystemCoding() {
    // A coding whose own system differs from the inline CodeSystem's url
    // must not match just because the code string happens to collide.
    r4:CodeSystem codeSystem = {
        content: "complete",
        status: "active",
        url: "http://example.org/fhir/CodeSystem/inline-a",
        concept: [{code: "shared-code", display: "From System A"}]
    };
    r4:Coding coding = {system: "http://example.org/fhir/CodeSystem/inline-b", code: "shared-code"};

    r4:CodeSystemConcept|r4:FHIRError result = lookupInInlineCodeSystem(coding, codeSystem);
    test:assertTrue(result is r4:FHIRError, "Expected a different-system coding not to match by code alone");
}

@test:Config {
    groups: ["unit", "validate_code_shape", "successful_scenario"]
}
public function testLookupInInlineCodeSystemWithoutRealUrlMatchesByCodeAlone() {
    // codeSystem.url here stands in for the synthetic urn:uuid: assigned by
    // codeSystemValidateCodePost when the caller's inline CodeSystem had no
    // url of its own - a coding's system can never legitimately equal that
    // synthetic value, so requireSystemMatch=false must skip the comparison
    // entirely instead of rejecting every such coding.
    r4:CodeSystem codeSystem = {
        content: "complete",
        status: "active",
        url: "urn:uuid:11111111-1111-1111-1111-111111111111",
        concept: [{code: "shared-code", display: "From System A"}]
    };
    r4:Coding coding = {system: "http://example.org/fhir/CodeSystem/caller-supplied", code: "shared-code"};

    r4:CodeSystemConcept|r4:FHIRError result = lookupInInlineCodeSystem(coding, codeSystem, requireSystemMatch = false);
    if result is r4:FHIRError {
        test:assertFail("Expected a matching concept, got: " + result.message());
    }
    test:assertEquals(result.display, "From System A");
}

@test:Config {
    groups: ["unit", "validate_code_shape", "failure_scenario"]
}
public function testLookupInInlineCodeSystemUnknownCodeConvertsToResultFalse() {
    r4:CodeSystem codeSystem = {
        content: "complete",
        status: "active",
        url: "http://example.org/fhir/CodeSystem/inline-a",
        concept: [{code: "known-code", display: "Known"}]
    };
    r4:Coding coding = {system: "http://example.org/fhir/CodeSystem/inline-a", code: "unknown-code"};

    r4:CodeSystemConcept|r4:FHIRError result = lookupInInlineCodeSystem(coding, codeSystem);
    if result is r4:CodeSystemConcept {
        test:assertFail("Expected no match for an unknown code, got: " + result.toString());
    }

    // The error must match validationResultToParameters' recognized
    // not-found contract, converting to a result:false Parameters response
    // rather than propagating as a raw error.
    r4:Parameters|r4:FHIRError converted = validationResultToParameters(result);
    if converted is r4:FHIRError {
        test:assertFail("Expected a result:false Parameters response, got a FHIRError: " + converted.message());
    }
    test:assertEquals((<r4:ParametersParameter>findParam(converted, "result")).valueBoolean, false);
}

