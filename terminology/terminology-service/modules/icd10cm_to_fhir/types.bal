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

public const string ICD10CM_SYSTEM_URL = "http://hl7.org/fhir/sid/icd-10-cm";
public const string ICD10CM_CODE_SYSTEM_ID = "icd-10-cm";
public const string ICD10CM_CODE_SYSTEM_NAME = "ICD_10_CM";
public const string ICD10CM_CODE_SYSTEM_TITLE = "International Classification of Diseases, Tenth Revision, Clinical Modification (ICD-10-CM)";
public const string ICD10CM_PUBLISHER = "National Center for Health Statistics (NCHS)";

// Synthetic tree-root id prefixes. ICD-10-CM chapters and sections aren't
// real codes - they're grouping nodes only present in the tabular release,
// minted here to match the id shape a live reference terminology server
// (tx.fhir.org) already uses for this CodeSystem, e.g. "Chapter-4",
// "Section-E08-E13".
public const string CHAPTER_ID_PREFIX = "Chapter-";
public const string SECTION_ID_PREFIX = "Section-";

// ICD-10-CM has exactly one name per code - no separate synonyms/alternate
// terms file the way SNOMED has a Description file. The single display text
// is still projected as a "preferredForLanguage" designation (matching a live
// reference terminology server's $lookup shape for this CodeSystem), since
// it genuinely is the preferred (only) term - not data pulled from another
// source file.
public const string DESIGNATION_USE_SYSTEM = "http://terminology.hl7.org/CodeSystem/hl7TermMaintInfra";
public const string DESIGNATION_USE_CODE = "preferredForLanguage";
public const string DESIGNATION_USE_DISPLAY = "Preferred For Language";

// Sort-group values used to keep `Icd10cmImportBundle.concepts` in
// topological order (every concept's parent appears in an earlier group),
// so the DB writer can resolve `parentConceptId` in a single insertion pass.
// Order-file-derived concepts use their own raw (undotted) code length as the
// sort group, which is always >= 3 and strictly increases from a category
// code down to its deepest descendant.
public const int SORT_GROUP_CHAPTER = 0;
public const int SORT_GROUP_SECTION = 1;

# A single ICD-10-CM concept - a chapter, section, category, or order-file
# code - ready to be converted to an `r4:CodeSystemConcept` and inserted.
#
# + code - The final code: dotted (e.g. "E11.1") for real ICD-10-CM codes, 3-character undotted for category codes (e.g. "E11"), or a synthetic id (e.g. "Chapter-4", "Section-E08-E13")
# + display - The long description / title for this concept
# + parentCode - The parent's `code`, or `()` only for chapter roots
# + billable - `true` for a real, billable leaf code; `false` for chapters, sections, and non-billable header codes
# + sortGroup - The topological sort key; see `SORT_GROUP_CHAPTER`/`SORT_GROUP_SECTION` and the order-file-derived rule above
public type IcdConceptImport record {|
    string code;
    string display;
    string? parentCode;
    boolean billable;
    int sortGroup;
|};

# Summary counts returned after a completed ICD-10-CM import.
#
# + codeSystemId - The database id of the inserted CodeSystem row
# + system - The CodeSystem canonical URL
# + 'version - The CodeSystem version recorded for this import
# + chaptersRead - The number of chapter nodes parsed from the tabular XML
# + sectionsRead - The number of section nodes parsed from the tabular XML
# + orderFileRowsRead - The number of code rows parsed from the order file
# + conceptsImported - The number of concept rows inserted
# + closureRowsWritten - The number of `concept_closure` rows inserted
public type Icd10cmImportSummary record {|
    string codeSystemId;
    string system;
    string 'version;
    int chaptersRead;
    int sectionsRead;
    int orderFileRowsRead;
    int conceptsImported;
    int closureRowsWritten;
|};

# Carries the parsed and merged inputs the DB layer needs to import ICD-10-CM.
#
# + codeSystemMetadata - The `r4:CodeSystem` metadata resource for this import
# + concepts - Every chapter, section, and code concept, pre-sorted topologically: chapters, then sections, then order-file rows grouped by raw code length ascending
# + chaptersRead - The number of chapter nodes parsed from the tabular XML
# + sectionsRead - The number of section nodes parsed from the tabular XML
# + orderFileRowsRead - The number of code rows parsed from the order file
public type Icd10cmImportBundle record {|
    r4:CodeSystem codeSystemMetadata;
    IcdConceptImport[] concepts;
    int chaptersRead;
    int sectionsRead;
    int orderFileRowsRead;
|};
