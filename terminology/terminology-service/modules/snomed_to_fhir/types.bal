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

public const string SNOMED_SYSTEM_URL = "http://snomed.info/sct";
public const string SNOMED_CODE_SYSTEM_ID = "snomed-ct";

// International Edition core module. Used to build the module/version
// canonical URI (SNOMED_SYSTEM_URL/SNOMED_CORE_MODULE_ID/version/YYYYMMDD)
// that CodeSystem.version is set to - the standard SNOMED FHIR convention for
// disambiguating which edition/version a code came from.
public const string SNOMED_CORE_MODULE_ID = "900000000000207008";
public const string SNOMED_CODE_SYSTEM_NAME = "SNOMEDCT";
public const string SNOMED_CODE_SYSTEM_TITLE = "SNOMED Clinical Terms";
public const string SNOMED_PUBLISHER = "SNOMED International";

public const string SNOMED_FSN_TYPE_ID = "900000000000003001";
public const string SNOMED_SYNONYM_TYPE_ID = "900000000000013009";

// Marks a designation built from an inactive (historical) RF2 description row.
// $lookup projects this as a status: inactive sub-part rather than dropping
// the designation entirely.
public const string DESIGNATION_INACTIVE_EXTENSION_URL = "https://wso2.org/fhir/StructureDefinition/designation-inactive";

public type SnomedConceptImport record {|
    string code;
    string display;
    string? definition;
    string effectiveTime;
    string active;
    string moduleId;
    string definitionStatusId;
    string? fsn;
    string[] synonyms;
    string[] inactiveSynonyms;
    string? caseSignificanceId;
|};

// A non-is-a RF2 relationship row (typeId != SNOMED_IS_A_TYPE_ID) - e.g. Finding
// site, Associated morphology. Projected as a $lookup property keyed by typeId.
public type SnomedAttributeRelationship record {|
    string sourceId;
    string typeId;
    string destinationId;
|};

public type SnomedImportSummary record {|
    string codeSystemId;
    string system;
    string version;
    int conceptsRead;
    int conceptsImported;
    int descriptionsRead;
    int textDefinitionsRead;
    int relationshipsRead;
    int closureRowsWritten;
    int relationshipRowsWritten;
|};

// Carries the parsed + assembled inputs the DB layer needs
public type SnomedImportBundle record {|
    r4:CodeSystem codeSystemMetadata;
    SnomedConceptImport[] concepts;
    // Full multi-parent is-a adjacency: child SCTID -> [parent SCTID, ...],
    // from active is-a Relationship rows.
    map<string[]> isaParentsByChild;
    // Active non-is-a Relationship rows (clinical attributes: Finding site,
    // Associated morphology, etc).
    SnomedAttributeRelationship[] attributeRelationships;
    int conceptsRead;
    int descriptionsRead;
    int textDefinitionsRead;
    int relationshipsRead;
|};

