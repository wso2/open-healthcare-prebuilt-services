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

import ballerina/io;
import ballerina/lang.'xml as xmllib;

# A section grouping node parsed from the tabular XML (e.g. section
# "E08-E13", "Diabetes mellitus (E08-E13)", under chapter "4").
#
# + id - The section's id attribute (e.g. "E08-E13")
# + desc - The section's title
# + chapterName - The name of the chapter this section belongs to (e.g. "4")
public type TabularSection record {|
    string id;
    string desc;
    string chapterName;
|};

# The chapter/section skeleton parsed from the tabular XML - the part of the
# ICD-10-CM tree the order file can't supply on its own. Deeper `<diag>`
# nesting in the XML is deliberately not read here: it's missing 7th-character
# extension codes, so everything from category level down is instead derived
# from the order file's own code-truncation rule (see `icd10cm_to_fhir.bal`).
#
# + chapterDescByName - Chapter name (e.g. "4") -> chapter title
# + sections - Every parsed section, in document order
# + categoryToSectionId - 3-character category code (e.g. "E11") -> the id of the section that directly lists it as a child
public type TabularIndex record {|
    map<string> chapterDescByName;
    TabularSection[] sections;
    map<string> categoryToSectionId;
|};

# Parses the ICD-10-CM tabular XML release file for its chapter/section
# skeleton only.
#
# + filePath - The path to `icd10cm-tabular_-<year>.xml`
# + return - The parsed `TabularIndex`, or an `error` if the file can't be read or parsed
public isolated function parseTabularXml(string filePath) returns TabularIndex|error {
    string rawContent = check io:fileReadString(filePath);
    xml doc = check xmllib:fromString(stripXmlDeclaration(rawContent));

    map<string> chapterDescByName = {};
    TabularSection[] sections = [];
    map<string> categoryToSectionId = {};

    xml chapters = doc.elementChildren("chapter");
    foreach xml chapter in chapters {
        string chapterName = chapter.elementChildren("name").data().trim();
        string chapterDesc = chapter.elementChildren("desc").data().trim();
        if chapterName == "" {
            continue;
        }
        chapterDescByName[chapterName] = chapterDesc;

        xml chapterSections = chapter.elementChildren("section");
        foreach xml section in chapterSections {
            string sectionId = "";
            if section is xml:Element {
                sectionId = section.getAttributes()["id"] ?: "";
            }
            if sectionId == "" {
                continue;
            }
            string sectionDesc = section.elementChildren("desc").data().trim();
            sections.push({id: sectionId, desc: sectionDesc, chapterName: chapterName});

            // Only direct <diag> children are category codes belonging to
            // this section - deeper nesting is intentionally not walked.
            xml categoryDiags = section.elementChildren("diag");
            foreach xml diag in categoryDiags {
                string categoryCode = diag.elementChildren("name").data().trim();
                if categoryCode != "" {
                    categoryToSectionId[categoryCode] = sectionId;
                }
            }
        }
    }

    return {
        chapterDescByName: chapterDescByName,
        sections: sections,
        categoryToSectionId: categoryToSectionId
    };
}

# Strips a leading XML declaration (e.g. `<?xml version="1.0" encoding="utf-8"?>`)
# if present. `xml:fromString` rejects the declaration outright, so it has to
# be removed before parsing rather than left for the parser to skip.
#
# + content - The raw file content, with or without a leading XML declaration
# + return - `content` with any leading XML declaration removed, trimmed
isolated function stripXmlDeclaration(string content) returns string {
    string trimmed = content.trim();
    if trimmed.startsWith("<?xml") {
        int? declEnd = trimmed.indexOf("?>");
        if declEnd is int {
            return trimmed.substring(declEnd + 2).trim();
        }
    }
    return trimmed;
}
