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
    groups: ["unit", "snomed_mapping", "successful_scenario"]
}
public function testSnomedConceptImportToR4EmitsDesignationsAndProperties() {
    SnomedConceptImport item = {
        code: "123456",
        display: "Test concept",
        definition: (),
        effectiveTime: "20260401",
        active: "1",
        moduleId: "900000000000207008",
        definitionStatusId: "900000000000074008",
        fsn: "Test concept (finding)",
        synonyms: ["Test concept"],
        inactiveSynonyms: [],
        caseSignificanceId: "900000000000448009"
    };

    r4:CodeSystemConcept concept = snomedConceptImportToR4(item);

    test:assertEquals(concept.code, "123456");
    test:assertEquals(concept.display, "Test concept");

    r4:CodeSystemConceptDesignation[]? designations = concept.designation;
    test:assertTrue(designations is r4:CodeSystemConceptDesignation[]);
    test:assertEquals((<r4:CodeSystemConceptDesignation[]>designations).length(), 2);
    test:assertEquals((<r4:CodeSystemConceptDesignation[]>designations)[0].value, "Test concept (finding)");
    test:assertEquals((<r4:CodeSystemConceptDesignation[]>designations)[1].value, "Test concept");

    r4:CodeSystemConceptProperty[]? properties = concept.property;
    test:assertTrue(properties is r4:CodeSystemConceptProperty[]);
    // active + moduleId + definitionStatusId + effectiveTime
    test:assertEquals((<r4:CodeSystemConceptProperty[]>properties).length(), 4);
}

@test:Config {
    groups: ["unit", "snomed_mapping", "successful_scenario"]
}
public function testBuildSnomedCodeSystemMetadataHasFragmentContentAndNoConcepts() {
    r4:CodeSystem cs = buildSnomedCodeSystemMetadata("20260401");

    test:assertEquals(cs.id, SNOMED_CODE_SYSTEM_ID);
    test:assertEquals(cs.url, SNOMED_SYSTEM_URL);
    test:assertEquals(cs.version, "http://snomed.info/sct/900000000000207008/version/20260401");
    test:assertEquals(cs.date, "2026-04-01");
    test:assertEquals(cs.content, r4:CODE_CONTENT_FRAGMENT);
    test:assertEquals(cs.caseSensitive, true);
    test:assertEquals(cs.hierarchyMeaning, r4:CODE_HIERARCHYMEANING_IS_A);
    test:assertEquals(cs.concept, ());
}

@test:Config {
    groups: ["unit", "snomed_mapping", "successful_scenario"]
}
public function testTruncate191() {
    test:assertEquals(truncate191(()), ());
    test:assertEquals(truncate191("short"), "short");

    string longStr = "";
    int i = 0;
    while i < 200 {
        longStr += "x";
        i += 1;
    }
    string? truncated = truncate191(longStr);
    test:assertTrue(truncated is string);
    test:assertEquals((<string>truncated).length(), 191);
}

@test:Config {
    groups: ["unit", "snomed_parsing", "successful_scenario"]
}
public function testStreamDescriptionIndex() returns error? {
    [map<ConceptDescriptions>, int] result = check streamDescriptionIndex(
            "modules/snomed_to_fhir/tests/resources/sct2_Description_Snapshot-en_INT_20260401.txt"
    );
    map<ConceptDescriptions> index = result[0];

    test:assertEquals(result[1], 2);
    ConceptDescriptions? descriptions = index["123456"];
    test:assertTrue(descriptions is ConceptDescriptions);
    ConceptDescriptions c = <ConceptDescriptions>descriptions;
    test:assertEquals(c.fsn, "Test concept (finding)");
    test:assertEquals(c.synonyms.length(), 1);
    test:assertEquals(c.synonyms[0], "Test concept");
}

@test:Config {
    groups: ["unit", "snomed_parsing", "successful_scenario"]
}
public function testStreamConceptImportsJoinsDescriptions() returns error? {
    [map<ConceptDescriptions>, int] descResult = check streamDescriptionIndex(
            "modules/snomed_to_fhir/tests/resources/sct2_Description_Snapshot-en_INT_20260401.txt"
    );
    // Empty text definition map, so definition stays absent — the FSN is a
    // display label, not a clinical definition, and is not used as a fallback.
    [SnomedConceptImport[], int] conceptResult = check streamConceptImports(
            "modules/snomed_to_fhir/tests/resources/sct2_Concept_Snapshot_INT_20260401.txt",
            descResult[0],
            {}
    );
    SnomedConceptImport[] imports = conceptResult[0];

    test:assertEquals(conceptResult[1], 1);
    test:assertEquals(imports.length(), 1);
    test:assertEquals(imports[0].code, "123456");
    // Synonym wins over FSN for display.
    test:assertEquals(imports[0].display, "Test concept");
    test:assertEquals(imports[0].definition, ());
    test:assertEquals(imports[0].synonyms.length(), 1);
}

@test:Config {
    groups: ["unit", "snomed_parsing", "successful_scenario"]
}
public function testStreamSnomedIsaAdjacency() returns error? {
    // Fixture has 3 rows: one active is-a, one inactive is-a, one active
    // non-is-a. Only the active is-a row should reach the adjacency map; the
    // active non-is-a row should reach attributeRelationships instead.
    [map<string[]>, SnomedAttributeRelationship[], int] result = check streamSnomedIsaAdjacency(
            "modules/snomed_to_fhir/tests/resources/sct2_Relationship_Snapshot_INT_20260401.txt"
    );
    map<string[]> adjacency = result[0];
    SnomedAttributeRelationship[] attributeRelationships = result[1];
    int rowsRead = result[2];

    test:assertEquals(rowsRead, 3);
    test:assertEquals(adjacency.length(), 1);
    string[]? parents = adjacency["123456"];
    test:assertTrue(parents is string[]);
    test:assertEquals(<string[]>parents, ["138875005"]);

    test:assertEquals(attributeRelationships.length(), 1);
    test:assertEquals(attributeRelationships[0].sourceId, "123456");
    test:assertEquals(attributeRelationships[0].typeId, "363698007");
    test:assertEquals(attributeRelationships[0].destinationId, "442083009");
}

@test:Config {
    groups: ["unit", "snomed_hierarchy", "successful_scenario"]
}
public function testComputeAncestorDepths() {
    // Diamond: apex A is reachable only at depth 2, via either B or C.
    map<string[]> diamond = {
        "D": ["B", "C"],
        "B": ["A"],
        "C": ["A"],
        "A": []
    };
    map<int> anc = computeAncestorDepths("D", diamond);
    test:assertEquals(anc.length(), 3);
    test:assertEquals(anc["B"], 1);
    test:assertEquals(anc["C"], 1);
    test:assertEquals(anc["A"], 2);
    // Self must be excluded.
    test:assertTrue(anc["D"] is ());

    // Z is reachable directly (depth 1) and via Y (depth 2); shorter wins.
    map<string[]> shortcut = {
        "X": ["Y", "Z"],
        "Y": ["Z"],
        "Z": []
    };
    map<int> anc2 = computeAncestorDepths("X", shortcut);
    test:assertEquals(anc2.length(), 2);
    test:assertEquals(anc2["Y"], 1);
    test:assertEquals(anc2["Z"], 1);

    map<int> anc3 = computeAncestorDepths("A", diamond);
    test:assertEquals(anc3.length(), 0);
}

@test:Config {
    groups: ["unit", "snomed_mapping", "successful_scenario"]
}
public function testSnomedCodeSystemTitleMatchesConformanceDoc() {
    test:assertEquals(SNOMED_CODE_SYSTEM_TITLE, "SNOMED Clinical Terms");
    r4:CodeSystem cs = buildSnomedCodeSystemMetadata("20260401");
    test:assertEquals(cs.title, "SNOMED Clinical Terms");
}

@test:Config {
    groups: ["unit", "snomed_parsing", "successful_scenario"]
}
public function testBuildSnomedImportEndToEnd() returns error? {
    SnomedImportBundle bundle = check buildSnomedImport(
            "modules/snomed_to_fhir/tests/resources",
            "20260401"
    );

    test:assertEquals(bundle.conceptsRead, 1);
    test:assertEquals(bundle.descriptionsRead, 2);
    test:assertEquals(bundle.textDefinitionsRead, 0);
    test:assertEquals(bundle.relationshipsRead, 3);
    test:assertEquals(bundle.concepts.length(), 1);
    test:assertEquals(bundle.concepts[0].code, "123456");
    test:assertEquals(bundle.isaParentsByChild.length(), 1);
    test:assertEquals(bundle.isaParentsByChild["123456"], ["138875005"]);
    test:assertEquals(bundle.codeSystemMetadata.version, "http://snomed.info/sct/900000000000207008/version/20260401");
    test:assertEquals(bundle.codeSystemMetadata.content, r4:CODE_CONTENT_FRAGMENT);
}

