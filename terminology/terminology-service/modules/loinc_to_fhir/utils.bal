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
import ballerina/regex;
import ballerinax/health.fhir.r4;

public const string FHIR_LOINC_FILE_NAME = "/loinc-codesystem.json";

# Finds a directory with the given exact name anywhere under `dirPath`, checking immediate children first, then recursing into subdirectories. LOINC releases distribute LoincTable/ and AccessoryFiles/PartFile/ either bare at the zip root, or wrapped in the release folder LOINC ships them in (e.g. "Loinc_2.82/"), so this tolerates either layout without the caller needing to know which.
#
# + dirPath - The directory to search under
# + targetName - The exact directory name to look for
# + return - The absolute path of the matching directory, `()` if none was found, or an `error` if a directory could not be read
isolated function findDirNamed(string dirPath, string targetName) returns string?|error {
    boolean exists = check file:test(dirPath, file:EXISTS);
    if !exists {
        return ();
    }
    file:MetaData[] entries = check file:readDir(dirPath);
    foreach file:MetaData entry in entries {
        if entry.dir && getLoincBaseName(entry.absPath) == targetName {
            return entry.absPath;
        }
    }
    foreach file:MetaData entry in entries {
        if entry.dir {
            string? nested = check findDirNamed(entry.absPath, targetName);
            if nested is string {
                return nested;
            }
        }
    }
    return ();
}

# Returns the final path segment (file or directory name) of the given path, splitting on either forward or backward slashes.
#
# + path - The file or directory path
# + return - The last segment of the path
isolated function getLoincBaseName(string path) returns string {
    string[] parts = regex:split(path, "[\\\\/]");
    return parts[parts.length() - 1];
}

# Converts LOINC concepts into FHIR `CodeSystemConcept` entries, resolving each concept's display, designations, and axis properties from the Part File index.
#
# + loincConcepts - The LOINC concepts to convert, or `()` for an empty result
# + partIndex - LoincNumber -> {axis: LoincPartRef} index used to resolve LP-code properties
# + return - The converted `CodeSystemConcept` array
isolated function LoincConceptToR4Concept(LoincConcept[]? loincConcepts, map<map<LoincPartRef>> partIndex) returns r4:CodeSystemConcept[] {
    if loincConcepts is null {
        return [];
    }

    r4:CodeSystemConcept[] r4Concepts = [];
    foreach LoincConcept loinc in loincConcepts {
        // LONG_COMMON_NAME is the human-readable clinical display (e.g. "Hospice care
        // Note"); COMPONENT is just one axis of the 6-part LOINC name (e.g. "Note") and
        // is meaningless as a display on its own. Fall back to COMPONENT only when
        // LONG_COMMON_NAME is absent.
        string? longCommonName = loinc?.LONG_COMMON_NAME;
        string display = longCommonName is string && longCommonName != "" ? longCommonName : loinc.COMPONENT;

        map<LoincPartRef> parts = partIndex[loinc.LOINC_NUM] ?: {};
        r4:CodeSystemConcept concept = {
            code: loinc.LOINC_NUM,
            display: display,
            designation: getDesignations(loinc),
            property: getProperties(loinc, parts)
        };
        r4Concepts.push(concept);
    }
    return r4Concepts;
}

# Builds the designation array for a LOINC concept from its LONG_COMMON_NAME, SHORTNAME, and CONSUMER_NAME fields, tagging each with its LOINC field name as the designation's use.code so a `$lookup` consumer can tell which variant (long common name, short name, consumer-friendly name) a given entry is.
#
# + loinc - The LOINC concept to build designations for
# + return - The concept's designations, one per non-empty name variant
isolated function getDesignations(LoincConcept loinc) returns r4:CodeSystemConceptDesignation[] {
    r4:CodeSystemConceptDesignation[] designations = [];

    string? longCommonName = loinc?.LONG_COMMON_NAME;
    if longCommonName is string && longCommonName != "" {
        designations.push({
            language: "en-US",
            value: longCommonName,
            use: {system: "http://loinc.org", code: "LONG_COMMON_NAME"}
        });
    }

    string? shortName = loinc?.SHORTNAME;
    if shortName is string && shortName != "" {
        designations.push({
            language: "en-US",
            value: shortName,
            use: {system: "http://loinc.org", code: "SHORTNAME"}
        });
    }

    string? consumerName = loinc?.CONSUMER_NAME;
    if consumerName is string && consumerName != "" {
        designations.push({
            language: "en-US",
            value: consumerName,
            use: {system: "http://loinc.org", code: "CONSUMER_NAME"}
        });
    }

    return designations;
}

# Pushes one LOINC axis property onto the given array, preferring the Part File's resolved LP-code and falling back to the raw CSV text when no Part File entry is available. Omitted entirely when neither is available.
#
# + properties - The property array to append to
# + code - The property code to use (e.g. "PROPERTY", "TIME_ASPCT")
# + rawValue - The raw CSV value for this axis, used only when `part` is `()`
# + part - The resolved `LoincPartRef` for this axis, or `()` if the Part File didn't resolve one
isolated function pushAxisProperty(r4:CodeSystemConceptProperty[] properties, string code, string? rawValue, LoincPartRef? part) {
    if part is LoincPartRef {
        properties.push({code: code, valueCode: part.partNumber});
    } else if rawValue is string && rawValue != "" {
        properties.push({code: code, valueString: rawValue});
    }
}

# Pushes one plain string-valued LOINC property onto the given array, omitted when the value is `()` or empty.
#
# + properties - The property array to append to
# + code - The property code to use (e.g. "CLASSTYPE", "FORMULA")
# + value - The raw CSV value for this field
isolated function pushStringProperty(r4:CodeSystemConceptProperty[] properties, string code, string? value) {
    if value is string && value != "" {
        properties.push({code: code, valueString: value});
    }
}

# Extracts all FHIR `CodeSystemConcept` properties for a LOINC concept: the six LP-code axes (falling back to raw CSV text when unresolved), STATUS and its derived lowercase "status" property, and every other non-empty LOINC field.
#
# + loinc - The LOINC concept to extract properties from
# + parts - The resolved `LoincPartRef` map for this concept's axes, keyed by axis name
# + return - The concept's properties
isolated function getProperties(LoincConcept loinc, map<LoincPartRef> parts) returns r4:CodeSystemConceptProperty[] {
    r4:CodeSystemConceptProperty[] properties = [];

    // The six LOINC axes are themselves LOINC Part concepts (LP-codes). Emit the
    // LP-code as valueCode when the Part File resolved one for this term; fall
    // back to the raw CSV text (the old behaviour) when it didn't, e.g. the Part
    // File wasn't supplied at upload, or this term/axis isn't covered by it.
    // COMPONENT has no raw-text fallback since it was never emitted as a
    // property before - it's only ever available via the Part File.
    LoincPartRef? componentPart = parts["COMPONENT"];
    if componentPart is LoincPartRef {
        properties.push({code: "COMPONENT", valueCode: componentPart.partNumber});
    }
    pushAxisProperty(properties, "PROPERTY", loinc?.PROPERTY, parts["PROPERTY"]);
    pushAxisProperty(properties, "TIME_ASPCT", loinc?.TIME_ASPCT, parts["TIME"]);
    pushAxisProperty(properties, "SYSTEM", loinc?.SYSTEM, parts["SYSTEM"]);
    pushAxisProperty(properties, "SCALE_TYP", loinc?.SCALE_TYP, parts["SCALE"]);
    pushAxisProperty(properties, "METHOD_TYP", loinc?.METHOD_TYP, parts["METHOD"]);
    pushAxisProperty(properties, "CLASS", loinc?.CLASS, parts["CLASS"]);
    // Raw STATUS property (uppercase LOINC value, e.g. "ACTIVE") kept as-is -
    // confirmed against a live tx.fhir.org $lookup that it stays alongside the
    // derived one below, not replaced by it.
    string? status = loinc?.STATUS;
    pushStringProperty(properties, "STATUS", status);
    // Also mapped to the shared "status" property code (lowercased value) so
    // codesystemConceptsToParameters' existing inactive-derivation (status ==
    // retired/deprecated) picks up deprecated LOINC codes the same way it
    // already does for SNOMED. discouraged/trial are not inactive - those
    // codes are still valid for use, just not preferred.
    if status is string && status != "" {
        properties.push({code: "status", valueCode: status.toLowerAscii()});
    }
    pushStringProperty(properties, "CLASSTYPE", loinc?.CLASSTYPE);
    pushStringProperty(properties, "FORMULA", loinc?.FORMULA);
    pushStringProperty(properties, "EXMPL_ANSWERS", loinc?.EXMPL_ANSWERS);
    pushStringProperty(properties, "SURVEY_QUEST_TEXT", loinc?.SURVEY_QUEST_TEXT);
    pushStringProperty(properties, "SURVEY_QUEST_SRC", loinc?.SURVEY_QUEST_SRC);
    pushStringProperty(properties, "UNITSREQUIRED", loinc?.UNITSREQUIRED);
    pushStringProperty(properties, "RELATEDNAMES2", loinc?.RELATEDNAMES2);
    pushStringProperty(properties, "ORDER_OBS", loinc?.ORDER_OBS);
    pushStringProperty(properties, "HL7_FIELD_SUBFIELD_ID", loinc?.HL7_FIELD_SUBFIELD_ID);
    pushStringProperty(properties, "EXTERNAL_COPYRIGHT_NOTICE", loinc?.EXTERNAL_COPYRIGHT_NOTICE);
    pushStringProperty(properties, "EXAMPLE_UNITS", loinc?.EXAMPLE_UNITS);
    pushStringProperty(properties, "EXAMPLE_UCUM_UNITS", loinc?.EXAMPLE_UCUM_UNITS);
    pushStringProperty(properties, "STATUS_REASON", loinc?.STATUS_REASON);
    pushStringProperty(properties, "STATUS_TEXT", loinc?.STATUS_TEXT);
    pushStringProperty(properties, "CHANGE_REASON_PUBLIC", loinc?.CHANGE_REASON_PUBLIC);
    pushStringProperty(properties, "HL7_ATTACHMENT_STRUCTURE", loinc?.HL7_ATTACHMENT_STRUCTURE);
    pushStringProperty(properties, "PanelType", loinc?.PanelType);
    pushStringProperty(properties, "AskAtOrderEntry", loinc?.AskAtOrderEntry);
    pushStringProperty(properties, "AssociatedObservations", loinc?.AssociatedObservations);
    pushStringProperty(properties, "ValidHL7AttachmentRequest", loinc?.ValidHL7AttachmentRequest);

    return properties;
}

# Builds the combined LOINC `CodeSystem` FHIR resource, converting all concepts and setting the version when provided.
#
# + concepts - The LOINC concepts to include, or `()` for an empty CodeSystem
# + partIndex - LoincNumber -> {axis: LoincPartRef} index used to resolve LP-code properties
# + 'version - The CodeSystem version to set, or `()` to leave it unset
# + return - The built `CodeSystem` resource, or an `error` if it could not be built
isolated function createCodeSystemResource(LoincConcept[]? concepts, map<map<LoincPartRef>> partIndex, string? 'version) returns r4:CodeSystem|error {
    r4:CodeSystem codeSystem = {
        resourceType: "CodeSystem",
        id: "loinc",
        url: "http://loinc.org",
        name: "LOINC",
        title: "Logical Observation Identifiers Names and Codes",
        status: r4:CODE_STATUS_ACTIVE,
        content: r4:CODE_CONTENT_COMPLETE,
        caseSensitive: true,
        hierarchyMeaning: r4:CODE_HIERARCHYMEANING_IS_A
    };

    codeSystem.concept = LoincConceptToR4Concept(concepts, partIndex);

    if ('version is string) {
        codeSystem.version = 'version;
    }

    return codeSystem;
}

