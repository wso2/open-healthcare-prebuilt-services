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

import terminology_service.icd10cm_to_fhir as icd10cm;

import ballerina/test;
import ballerinax/health.fhir.r4;

@test:Config {
    groups: ["unit", "icd10cm_mapping", "successful_scenario"]
}
public function testFormatIcd10cmCode() {
    // Category code (3 chars) is returned unchanged.
    test:assertEquals(icd10cm:formatIcd10cmCode("E11"), "E11");
    // Everything longer gets a decimal point after the third character.
    test:assertEquals(icd10cm:formatIcd10cmCode("E119"), "E11.9");
    test:assertEquals(icd10cm:formatIcd10cmCode("E1121"), "E11.21");
    // Padding/whitespace around the raw code is trimmed first.
    test:assertEquals(icd10cm:formatIcd10cmCode("  E119  "), "E11.9");
}

@test:Config {
    groups: ["unit", "icd10cm_mapping", "successful_scenario"]
}
public function testIcdConceptImportToR4EmitsPropertiesAndDesignation() {
    icd10cm:IcdConceptImport billableLeaf = {
        code: "E11.9",
        display: "Type 2 diabetes mellitus without complications",
        parentCode: "E11",
        billable: true,
        sortGroup: 5
    };

    r4:CodeSystemConcept concept = icd10cm:icdConceptImportToR4(billableLeaf);

    test:assertEquals(concept.code, "E11.9");
    test:assertEquals(concept.display, "Type 2 diabetes mellitus without complications");

    r4:CodeSystemConceptProperty[]? properties = concept.property;
    test:assertTrue(properties is r4:CodeSystemConceptProperty[]);
    r4:CodeSystemConceptProperty[] props = <r4:CodeSystemConceptProperty[]>properties;
    test:assertEquals(props.length(), 2);
    test:assertEquals(props[0].code, "notSelectable");
    // A billable leaf is selectable, so notSelectable is false.
    test:assertEquals(props[0].valueBoolean, false);
    test:assertEquals(props[1].code, "inactive");
    test:assertEquals(props[1].valueBoolean, false);

    r4:CodeSystemConceptDesignation[]? designations = concept.designation;
    test:assertTrue(designations is r4:CodeSystemConceptDesignation[]);
    r4:CodeSystemConceptDesignation[] desigs = <r4:CodeSystemConceptDesignation[]>designations;
    test:assertEquals(desigs.length(), 1);
    test:assertEquals(desigs[0].value, "Type 2 diabetes mellitus without complications");
    test:assertEquals(desigs[0].use?.code, icd10cm:DESIGNATION_USE_CODE);
}

@test:Config {
    groups: ["unit", "icd10cm_mapping", "successful_scenario"]
}
public function testIcdConceptImportToR4MarksNonBillableAsNotSelectable() {
    icd10cm:IcdConceptImport chapterConcept = {
        code: icd10cm:CHAPTER_ID_PREFIX + "4",
        display: "Endocrine, nutritional and metabolic diseases (E00-E89)",
        parentCode: (),
        billable: false,
        sortGroup: icd10cm:SORT_GROUP_CHAPTER
    };

    r4:CodeSystemConcept concept = icd10cm:icdConceptImportToR4(chapterConcept);
    r4:CodeSystemConceptProperty[] props = <r4:CodeSystemConceptProperty[]>concept.property;
    test:assertEquals(props[0].code, "notSelectable");
    test:assertEquals(props[0].valueBoolean, true);
}

@test:Config {
    groups: ["unit", "icd10cm_mapping", "successful_scenario"]
}
public function testBuildIcd10cmCodeSystemMetadata() {
    r4:CodeSystem cs = icd10cm:buildIcd10cmCodeSystemMetadata("2026-10-01");

    test:assertEquals(cs.id, icd10cm:ICD10CM_CODE_SYSTEM_ID);
    test:assertEquals(cs.url, icd10cm:ICD10CM_SYSTEM_URL);
    test:assertEquals(cs.name, icd10cm:ICD10CM_CODE_SYSTEM_NAME);
    test:assertEquals(cs.title, icd10cm:ICD10CM_CODE_SYSTEM_TITLE);
    test:assertEquals(cs.version, "2026-10-01");
    test:assertEquals(cs.date, "2026-10-01");
    test:assertEquals(cs.content, r4:CODE_CONTENT_COMPLETE);
    test:assertEquals(cs.caseSensitive, false);
    test:assertEquals(cs.hierarchyMeaning, r4:CODE_HIERARCHYMEANING_IS_A);
}

@test:Config {
    groups: ["unit", "icd10cm_mapping", "successful_scenario"]
}
public function testBuildIcd10cmCodeSystemMetadataWithNoVersion() {
    r4:CodeSystem cs = icd10cm:buildIcd10cmCodeSystemMetadata(());
    test:assertEquals(cs.version, ());
    test:assertEquals(cs.date, ());
}

@test:Config {
    groups: ["unit", "icd10cm_mapping", "successful_scenario"]
}
public function testBuildIcd10cmCodeSystemMetadataWithNonDateVersion() {
    // icd10cm-version is free text - a value that isn't shaped like a FHIR date 
    // must still be recorded as the version, but must NOT be written to date,
    //  which would otherwise store an invalid FHIR dateTime.
    r4:CodeSystem cs = icd10cm:buildIcd10cmCodeSystemMetadata("FY2027");
    test:assertEquals(cs.version, "FY2027");
    test:assertEquals(cs.date, ());
}

@test:Config {
    groups: ["unit", "icd10cm_parsing", "successful_scenario"]
}
public function testStreamOrderFile() returns error? {
    [icd10cm:OrderFileRow[], int] result = check icd10cm:streamOrderFile(
            "tests/resources/icd10cm/icd10cm-order-fixture.txt"
    );
    icd10cm:OrderFileRow[] rows = result[0];
    int rowsRead = result[1];

    test:assertEquals(rowsRead, 4);
    test:assertEquals(rows.length(), 4);

    // Category row: unchanged (3-char) code, non-billable.
    test:assertEquals(rows[0].rawCode, "E11");
    test:assertEquals(rows[0].code, "E11");
    test:assertEquals(rows[0].billable, false);
    test:assertEquals(rows[0].display, "Type 2 diabetes mellitus");

    // Leaf rows: raw code gets a decimal point, billable.
    test:assertEquals(rows[1].rawCode, "E119");
    test:assertEquals(rows[1].code, "E11.9");
    test:assertEquals(rows[1].billable, true);
    test:assertEquals(rows[1].display, "Type 2 diabetes mellitus without complications");

    test:assertEquals(rows[2].rawCode, "E118");
    test:assertEquals(rows[2].code, "E11.8");
    test:assertEquals(rows[2].billable, true);
    test:assertEquals(rows[2].display, "Type 2 diabetes mellitus with unspecified complications");

    // Placeholder-"X" leaf: "E119X" is never a real code in the order
    // file - only formatIcd10cmCode's own dotted conversion
    // is exercised at this parsing layer.
    test:assertEquals(rows[3].rawCode, "E119XA");
    test:assertEquals(rows[3].code, "E11.9XA");
    test:assertEquals(rows[3].billable, true);
    test:assertEquals(rows[3].display, "Type 2 diabetes mellitus without complications, placeholder example");
}

@test:Config {
    groups: ["unit", "icd10cm_parsing", "successful_scenario"]
}
public function testParseTabularXml() returns error? {
    icd10cm:TabularIndex tabular = check icd10cm:parseTabularXml(
            "tests/resources/icd10cm/icd10cm-tabular-fixture.xml"
    );

    test:assertEquals(tabular.chapterDescByName.length(), 1);
    test:assertEquals(tabular.chapterDescByName["4"], "Endocrine, nutritional and metabolic diseases (E00-E89)");

    test:assertEquals(tabular.sections.length(), 1);
    test:assertEquals(tabular.sections[0].id, "E08-E13");
    test:assertEquals(tabular.sections[0].desc, "Diabetes mellitus (E08-E13)");
    test:assertEquals(tabular.sections[0].chapterName, "4");

    test:assertEquals(tabular.categoryToSectionId.length(), 1);
    test:assertEquals(tabular.categoryToSectionId["E11"], "E08-E13");
}

@test:Config {
    groups: ["unit", "icd10cm_parsing", "successful_scenario"]
}
public function testBuildIcd10cmImportEndToEnd() returns error? {
    icd10cm:Icd10cmImportBundle bundle = check icd10cm:buildIcd10cmImport(
            "tests/resources/icd10cm",
            "2026-10-01"
    );

    test:assertEquals(bundle.chaptersRead, 1);
    test:assertEquals(bundle.sectionsRead, 1);
    test:assertEquals(bundle.orderFileRowsRead, 4);
    // chapter + section + 4 order-file rows.
    test:assertEquals(bundle.concepts.length(), 6);

    // Topological order: chapter first, then section, then codes by raw length ascending.
    test:assertEquals(bundle.concepts[0].code, icd10cm:CHAPTER_ID_PREFIX + "4");
    test:assertEquals(bundle.concepts[0].parentCode, ());

    test:assertEquals(bundle.concepts[1].code, icd10cm:SECTION_ID_PREFIX + "E08-E13");
    test:assertEquals(bundle.concepts[1].parentCode, icd10cm:CHAPTER_ID_PREFIX + "4");

    test:assertEquals(bundle.concepts[2].code, "E11");
    // The category code's parent is resolved via the tabular XML's
    // category -> section mapping, not by truncating the code string.
    test:assertEquals(bundle.concepts[2].parentCode, icd10cm:SECTION_ID_PREFIX + "E08-E13");

    test:assertEquals(bundle.concepts[3].code, "E11.9");
    test:assertEquals(bundle.concepts[3].parentCode, "E11");

    test:assertEquals(bundle.concepts[4].code, "E11.8");
    test:assertEquals(bundle.concepts[4].parentCode, "E11");

    // Regression coverage for the placeholder-"X" parent-resolution fix:
    // "E11.9XA"'s naive truncated parent "E119X" is never a real 
    // order-file row, so resolution must keep dropping characters until
    // it lands on "E119" ("E11.9").
    test:assertEquals(bundle.concepts[5].code, "E11.9XA");
    test:assertEquals(bundle.concepts[5].parentCode, "E11.9");

    test:assertEquals(bundle.codeSystemMetadata.version, "2026-10-01");
    test:assertEquals(bundle.codeSystemMetadata.content, r4:CODE_CONTENT_COMPLETE);
}
