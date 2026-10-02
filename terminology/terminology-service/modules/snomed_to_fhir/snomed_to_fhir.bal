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
import ballerina/file;

# Reads an RF2 Snapshot release directory and produces the inputs the DB layer needs to import SNOMED CT. Locates the Concept, Description, Relationship, and (if present) Text Definition files by prefix, streams and joins them into concept import records, and builds the is-a parent adjacency and attribute relationships from the Relationship file.
#
# + dirPath - The base directory of the extracted RF2 Snapshot release
# + version - The SNOMED release version to stamp on the CodeSystem metadata, or `()` to leave it unset
# + return - The assembled `SnomedImportBundle`, or an `error` if a required RF2 file is missing or cannot be read
public isolated function buildSnomedImport(string dirPath, string? version) returns SnomedImportBundle|error {
    string conceptFilePath = check findRf2File(dirPath, RF2_CONCEPT_PREFIX);
    string descriptionFilePath = check findRf2File(dirPath, RF2_DESCRIPTION_PREFIX);
    string relationshipFilePath = check findRf2File(dirPath, RF2_RELATIONSHIP_PREFIX);

    [map<ConceptDescriptions>, int] descResult = check streamDescriptionIndex(descriptionFilePath);
    map<ConceptDescriptions> descIndex = descResult[0];
    int descriptionsRead = descResult[1];

    // TextDefinition is optional
    map<string> defIndex = {};
    int textDefinitionsRead = 0;
    string|error textDefinitionFilePath = findRf2File(dirPath, RF2_TEXT_DEFINITION_PREFIX);
    if textDefinitionFilePath is string {
        boolean exists = check file:test(textDefinitionFilePath, file:EXISTS);
        if exists {
            [map<string>, int] defResult = check streamTextDefinitionIndex(textDefinitionFilePath);
            defIndex = defResult[0];
            textDefinitionsRead = defResult[1];
        }
    }

    // Stream concepts
    [SnomedConceptImport[], int] conceptResult = check streamConceptImports(conceptFilePath, descIndex, defIndex);
    SnomedConceptImport[] importRecords = conceptResult[0];
    int conceptsRead = conceptResult[1];

    descIndex = {};
    defIndex = {};

    [map<string[]>, SnomedAttributeRelationship[], int] adjacencyResult = check streamSnomedIsaAdjacency(relationshipFilePath);

    return {
        codeSystemMetadata: buildSnomedCodeSystemMetadata(version),
        concepts: importRecords,
        isaParentsByChild: adjacencyResult[0],
        attributeRelationships: adjacencyResult[1],
        conceptsRead: conceptsRead,
        descriptionsRead: descriptionsRead,
        textDefinitionsRead: textDefinitionsRead,
        relationshipsRead: adjacencyResult[2]
    };
}

