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

import ballerinax/health.fhir.r4;

# Builds the ICD-10-CM CodeSystem metadata resource. Unlike SNOMED (a
# `CODE_CONTENT_FRAGMENT`, since only a subset is typically loaded) this is
# `CODE_CONTENT_COMPLETE` - the order file is the full annual release - and
# `caseSensitive: false`, since ICD-10-CM codes (unlike SNOMED's SCTIDs)
# aren't case-sensitive.
#
# + version - The ICD-10-CM release version (e.g. "2026-10-01"), or `()` to leave the version unset
# + return - The built `r4:CodeSystem` metadata resource
public isolated function buildIcd10cmCodeSystemMetadata(string? version) returns r4:CodeSystem {
    r4:CodeSystem codeSystem = {
        resourceType: "CodeSystem",
        id: ICD10CM_CODE_SYSTEM_ID,
        url: ICD10CM_SYSTEM_URL,
        name: ICD10CM_CODE_SYSTEM_NAME,
        title: ICD10CM_CODE_SYSTEM_TITLE,
        status: r4:CODE_STATUS_ACTIVE,
        content: r4:CODE_CONTENT_COMPLETE,
        caseSensitive: false,
        hierarchyMeaning: r4:CODE_HIERARCHYMEANING_IS_A,
        publisher: ICD10CM_PUBLISHER
    };
    if version is string && version != "" {
        codeSystem.version = version;
        // The chosen version convention for this CodeSystem is a plain FHIR
        // date (the release's effective date, e.g. "2026-10-01"), so it
        // doubles as CodeSystem.date - but icd10cm-version is free text (see
        // README), so only reuse it when it's actually shaped like a FHIR
        // date; otherwise leave date unset rather than storing an invalid
        // dateTime.
        if re `^[0-9]{4}(-[0-9]{2}(-[0-9]{2})?)?$`.isFullMatch(version) {
            codeSystem.date = version;
        }
    }
    return codeSystem;
}

# Converts a single `IcdConceptImport` into an `r4:CodeSystemConcept`,
# attaching the two properties `$lookup` needs to project `abstract`/
# `inactive` correctly: `notSelectable` (true for chapters, sections, and
# non-billable header codes) and an explicit `inactive` (always false - a
# fresh annual release has no deprecated codes of its own). Also attaches the
# concept's single display text as a "preferredForLanguage" designation - see
# the note on `DESIGNATION_USE_SYSTEM` for why that's not a stand-in for real
# synonym data.
#
# + item - The parsed ICD-10-CM concept import record to convert
# + return - The built `r4:CodeSystemConcept`
public isolated function icdConceptImportToR4(IcdConceptImport item) returns r4:CodeSystemConcept {
    return {
        code: item.code,
        display: item.display,
        property: [
            {code: "notSelectable", valueBoolean: !item.billable},
            {code: "inactive", valueBoolean: false}
        ],
        designation: [
            {
                value: item.display,
                use: {
                    system: DESIGNATION_USE_SYSTEM,
                    code: DESIGNATION_USE_CODE,
                    display: DESIGNATION_USE_DISPLAY
                }
            }
        ]
    };
}
