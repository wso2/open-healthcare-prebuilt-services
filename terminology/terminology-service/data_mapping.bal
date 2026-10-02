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
import terminology_service.store_h2;

import ballerina/log;
import ballerina/persist;
import ballerina/sql;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;

// A resolved non-hierarchical concept relationship (SNOMED clinical attributes:
// Finding site, Associated morphology, etc) for $lookup property projection.
// typeDisplay/valueDisplay are omitted when the type/destination concept isn't
// found (e.g. only a subset of the CodeSystem was imported).
type ConceptAttributeRelationship record {|
    string typeCode;
    string? typeDisplay;
    string valueCode;
    string? valueDisplay;
|};

# Builds the FHIR Parameters response for a $lookup operation from one or more CodeSystem concepts, including standard elements (name, display, code, system, version, abstract, inactive, definition, designation, property) plus optional parent/child hierarchy and attribute relationship properties. When multiple concepts are given, the parameters for all of them are concatenated. The final parameter list is sorted by name.
#
# + concepts - The concept(s) to project into $lookup parameters
# + cs - The owning CodeSystem, used for name/system/version; `()` if unavailable
# + parentConcepts - The concept's parents, added as "parent" property parameters
# + childConcepts - The concept's children, added as "child" property parameters
# + attributeRelationships - Resolved non-hierarchical relationships (e.g. SNOMED clinical attributes), added as property parameters
# + return - The assembled $lookup Parameters, sorted by parameter name
isolated function codesystemConceptsToParameters(r4:CodeSystemConcept[]|r4:CodeSystemConcept concepts, r4:CodeSystem? cs = (), r4:CodeSystemConcept[] parentConcepts = [], r4:CodeSystemConcept[] childConcepts = [], ConceptAttributeRelationship[] attributeRelationships = []) returns r4:Parameters {
    // Per the FHIR $lookup convention, "name" is normally the CodeSystem's
    // computer-friendly name. But when version is itself a canonical URI (the
    // convention SNOMED CT uses to disambiguate editions - see
    // SNOMED_CORE_MODULE_ID in modules/snomed_to_fhir/types.bal) it takes
    // precedence, emitting the versioned canonical reference url|version instead.
    string csName = "";
    if cs is r4:CodeSystem {
        string? csVersion = cs.version;
        string? csUrl = cs.url;
        if csVersion is string && csVersion.startsWith("http") && csUrl is string {
            csName = csUrl + "|" + csVersion;
        } else {
            csName = cs.name ?: (cs.url ?: "");
        }
    }
    r4:Parameters parameters = {};
    if concepts is r4:CodeSystemConcept {
        parameters = {
            'parameter: [
                {name: "name", valueString: csName},
                {name: "display", valueString: concepts.display},
                {name: "code", valueCode: concepts.code}
            ]
        };
        if cs is r4:CodeSystem && cs.url is r4:uri {
            (<r4:ParametersParameter[]>parameters.'parameter).push({name: "system", valueUri: <r4:uri>cs.url});
        }
        if cs is r4:CodeSystem && cs.version is string {
            (<r4:ParametersParameter[]>parameters.'parameter).push({name: "version", valueString: <string>cs.version});
        }

        boolean isAbstract = false;
        if concepts.property is r4:CodeSystemConceptProperty[] {
            foreach var prop in <r4:CodeSystemConceptProperty[]>concepts.property {
                if (prop.code == "notSelectable" || prop.code == "abstract")
                        && prop.valueBoolean is boolean && <boolean>prop.valueBoolean {
                    isAbstract = true;
                    break;
                }
            }
        }
        (<r4:ParametersParameter[]>parameters.'parameter).push({name: "abstract", valueBoolean: isAbstract});

        boolean hasExplicitInactive = false;
        boolean derivedInactive = false;
        if concepts.property is r4:CodeSystemConceptProperty[] {
            foreach var prop in <r4:CodeSystemConceptProperty[]>concepts.property {
                if prop.code == "inactive" {
                    hasExplicitInactive = true;
                }
                if prop.code == "status" && prop.valueCode is r4:code {
                    string s = <string>prop.valueCode;
                    if s == "retired" || s == "deprecated" {
                        derivedInactive = true;
                    }
                }
            }
        }
        if !hasExplicitInactive {
            (<r4:ParametersParameter[]>parameters.'parameter).push({
                name: "property",
                part: [
                    {name: "code", valueCode: "inactive"},
                    {name: "value", valueBoolean: derivedInactive}
                ]
            });
        }

        foreach var parent in parentConcepts {
            r4:ParametersParameter[] parentPart = [{name: "code", valueCode: "parent"}];
            if parent.display is string {
                parentPart.push({name: "description", valueString: <string>parent.display});
            }
            parentPart.push({name: "value", valueCode: parent.code});
            (<r4:ParametersParameter[]>parameters.'parameter).push({name: "property", part: parentPart});
        }

        foreach var child in childConcepts {
            r4:ParametersParameter[] childPart = [{name: "code", valueCode: "child"}];
            if child.display is string {
                childPart.push({name: "description", valueString: <string>child.display});
            }
            childPart.push({name: "value", valueCode: child.code});
            (<r4:ParametersParameter[]>parameters.'parameter).push({name: "property", part: childPart});
        }

        foreach var rel in attributeRelationships {
            r4:ParametersParameter[] relPart = [
                {name: "code", valueCode: rel.typeCode},
                {name: "value", valueCode: rel.valueCode}
            ];
            if rel.valueDisplay is string {
                relPart.push({name: "description", valueString: <string>rel.valueDisplay});
            }
            if rel.typeDisplay is string {
                relPart.push({name: "code-display", valueString: <string>rel.typeDisplay});
            }
            (<r4:ParametersParameter[]>parameters.'parameter).push({name: "property", part: relPart});
        }

        if concepts.definition is string {
            (<r4:ParametersParameter[]>parameters.'parameter).push({name: "definition", valueString: concepts.definition});
        }

        if concepts.property is r4:CodeSystemConceptProperty[] {
            foreach var item in <r4:CodeSystemConceptProperty[]>concepts.property {
                r4:ParametersParameter result = codeSystemConceptPropertyToParameter(item);
                (<r4:ParametersParameter[]>parameters.'parameter).push(result);
            }
        }

        if concepts.designation is r4:CodeSystemConceptDesignation[] {
            foreach var item in <r4:CodeSystemConceptDesignation[]>concepts.designation {
                r4:ParametersParameter result = designationToParameter(item);
                (<r4:ParametersParameter[]>parameters.'parameter).push(result);
            }
        }
    } else {
        r4:ParametersParameter[] p = [];
        foreach r4:CodeSystemConcept item in concepts {
            p.push({name: "name", valueString: csName},
                    {name: "display", valueString: item.display},
                    {name: "code", valueCode: item.code});
            if cs is r4:CodeSystem && cs.url is r4:uri {
                p.push({name: "system", valueUri: <r4:uri>cs.url});
            }
            if cs is r4:CodeSystem && cs.version is string {
                p.push({name: "version", valueString: <string>cs.version});
            }
            boolean isAbstract = false;
            if item.property is r4:CodeSystemConceptProperty[] {
                foreach var prop in <r4:CodeSystemConceptProperty[]>item.property {
                    if (prop.code == "notSelectable" || prop.code == "abstract")
                            && prop.valueBoolean is boolean && <boolean>prop.valueBoolean {
                        isAbstract = true;
                        break;
                    }
                }
            }
            p.push({name: "abstract", valueBoolean: isAbstract});

            boolean hasExplicitInactive = false;
            boolean derivedInactive = false;
            if item.property is r4:CodeSystemConceptProperty[] {
                foreach var prop in <r4:CodeSystemConceptProperty[]>item.property {
                    if prop.code == "inactive" {
                        hasExplicitInactive = true;
                    }
                    if prop.code == "status" && prop.valueCode is r4:code {
                        string s = <string>prop.valueCode;
                        if s == "retired" || s == "deprecated" {
                            derivedInactive = true;
                        }
                    }
                }
            }
            if !hasExplicitInactive {
                p.push({
                    name: "property",
                    part: [
                        {name: "code", valueCode: "inactive"},
                        {name: "value", valueBoolean: derivedInactive}
                    ]
                });
            }

            foreach var parent in parentConcepts {
                r4:ParametersParameter[] parentPart = [{name: "code", valueCode: "parent"}];
                if parent.display is string {
                    parentPart.push({name: "description", valueString: <string>parent.display});
                }
                parentPart.push({name: "value", valueCode: parent.code});
                (<r4:ParametersParameter[]>p).push({name: "property", part: parentPart});
            }

            foreach var child in childConcepts {
                r4:ParametersParameter[] childPart = [{name: "code", valueCode: "child"}];
                if child.display is string {
                    childPart.push({name: "description", valueString: <string>child.display});
                }
                childPart.push({name: "value", valueCode: child.code});
                (<r4:ParametersParameter[]>p).push({name: "property", part: childPart});
            }

            foreach var rel in attributeRelationships {
                r4:ParametersParameter[] relPart = [
                    {name: "code", valueCode: rel.typeCode},
                    {name: "value", valueCode: rel.valueCode}
                ];
                if rel.valueDisplay is string {
                    relPart.push({name: "description", valueString: <string>rel.valueDisplay});
                }
                if rel.typeDisplay is string {
                    relPart.push({name: "code-display", valueString: <string>rel.typeDisplay});
                }
                (<r4:ParametersParameter[]>p).push({name: "property", part: relPart});
            }

            if item.definition is string {
                p.push({name: "definition", valueString: item.definition});
            }

            if item.property is r4:CodeSystemConceptProperty[] {
                foreach var prop in <r4:CodeSystemConceptProperty[]>item.property {
                    r4:ParametersParameter result = codeSystemConceptPropertyToParameter(prop);
                    p.push(result);
                }
            }

            if item.designation is r4:CodeSystemConceptDesignation[] {
                foreach var desg in <r4:CodeSystemConceptDesignation[]>item.designation {
                    r4:ParametersParameter result = designationToParameter(desg);
                    p.push(result);
                }
            }
        }
        parameters = {'parameter: p};
    }
    r4:ParametersParameter[] finalParams = <r4:ParametersParameter[]>parameters.'parameter;
    r4:ParametersParameter[] sorted = from var p in finalParams
        order by p.name ascending
        select p;
    parameters = {'parameter: sorted};

    return parameters;
}

// Same value as modules/snomed_to_fhir/types.bal's DESIGNATION_INACTIVE_EXTENSION_URL.
// Kept as a private literal here rather than importing snomed_to_fhir, since this
// builder is generic across every ingest source, not SNOMED-specific.
const string DESIGNATION_INACTIVE_EXTENSION_URL = "https://wso2.org/fhir/StructureDefinition/designation-inactive";

# Converts a single CodeSystem concept designation into a $lookup "designation" Parameters part (language, use, inactive status extension, and value).
#
# + designation - The concept designation to convert
# + return - The "designation" ParametersParameter
isolated function designationToParameter(r4:CodeSystemConceptDesignation designation) returns r4:ParametersParameter {
    r4:ParametersParameter param = {name: "designation"};
    r4:ParametersParameter[] part = [];

    if designation.language is string {
        part.push({name: "language", valueCode: designation.language});
    }

    if designation.use is r4:Coding {
        part.push({name: "use", valueCoding: designation.use});
    }

    r4:Extension[]? extensions = designation.extension;
    if extensions is r4:Extension[] {
        foreach var ext in extensions {
            if ext is r4:BooleanExtension && ext.url == DESIGNATION_INACTIVE_EXTENSION_URL && ext.valueBoolean {
                part.push({name: "status", valueCode: "inactive"});
                break;
            }
        }
    }

    part.push({name: "value", valueString: designation.value});

    param.part = part;

    return param;
}

# Wraps a raw SQL string as a parameterized query with no bind parameters.
#
# + queryStr - The raw SQL string
# + return - A ParameterizedQuery whose `strings` is the given string
isolated function stringToParameterizedQuery(string queryStr) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery query = ``;
    query.strings = [queryStr];
    return query;
}

# Serializes a CodeSystem to bytes for storage, stripping the `concept` field since concepts are stored separately in the concepts table. The field is removed rather than set to `()`, because assigning `()` serializes as `"concept":null`, which the strict parser used by byteToCodeSystem rejects on read. The incoming CodeSystem is already validated by fhirr4:Listener, so no round-trip re-parse is needed here.
#
# + codeSystem - The CodeSystem to serialize
# + return - The serialized bytes, or an `r4:FHIRError` if serialization fails
isolated function codeSystemToByte(r4:CodeSystem codeSystem) returns byte[]|r4:FHIRError {
    log:printDebug("Converting CodeSystem to byte array, codeSystem id: " + (codeSystem.id ?: "unknown"));
    // Concepts are stripped here because they are stored separately in the concepts table.
    // The incoming CodeSystem is already validated by fhirr4:Listener, so no round-trip
    // re-parse is needed.
    // NOTE: the optional 'concept' field must be REMOVED, not set to (). Assigning ()
    // serializes as "concept":null, and the strict parser used by byteToCodeSystem rejects
    // null for the CodeSystemConcept[] field on read ("found '()'"), so every POST-created
    // CodeSystem became unreadable (breaking lookup/expand/read for it).
    r4:CodeSystem codeSystemWithoutConcepts = codeSystem.clone();
    _ = codeSystemWithoutConcepts.removeIfHasKey("concept");
    return codeSystemWithoutConcepts.toJsonString().toBytes();
}

# Deserializes a stored byte array back into a CodeSystem.
#
# + byteArray - The stored bytes to decode
# + return - The decoded CodeSystem, or an `error` if decoding fails
isolated function byteToCodeSystem(byte[] byteArray) returns r4:CodeSystem|error {
    string codeSystemJsonString = check 'string:fromBytes(byteArray);
    r4:CodeSystem parsedCodeSystem = check parser:parse(codeSystemJsonString).ensureType();

    return parsedCodeSystem;
}

# Serializes a CodeSystemConcept to bytes for storage, removing its nested `concept` field rather than setting it to `()`. Assigning `()` would serialize as `"concept":null`, which the strict parser in byteToConcept rejects on read, making the concept invisible to $lookup/$expand.
#
# + concept - The concept to serialize
# + return - The serialized bytes, or an `r4:FHIRError` if serialization fails
isolated function conceptToByte(r4:CodeSystemConcept concept) returns byte[]|r4:FHIRError {
    // Same bug as codeSystemToByte: assigning () serializes as "concept":null, which
    // the strict parser in byteToConcept rejects on read (ConversionError -> the concept
    // becomes invisible to $lookup/$expand). Remove the field instead.
    r4:CodeSystemConcept conceptWithoutInternlConcept = concept.clone();
    _ = conceptWithoutInternlConcept.removeIfHasKey("concept");
    return conceptWithoutInternlConcept.toJsonString().toBytes();
}

# Deserializes a stored byte array back into a CodeSystemConcept.
#
# + byteArray - The stored bytes to decode
# + return - The decoded CodeSystemConcept, or an `error` if decoding fails
isolated function byteToConcept(byte[] byteArray) returns r4:CodeSystemConcept|error {
    string conceptJsonString = check 'string:fromBytes(byteArray);
    json conceptJson = check conceptJsonString.fromJsonString();
    r4:CodeSystemConcept parsedConcept = check conceptJson.fromJsonWithType(r4:CodeSystemConcept);

    return parsedConcept;
}

# Serializes a ValueSet to bytes for storage.
#
# + valueSet - The ValueSet to serialize
# + return - The serialized bytes, or an `r4:FHIRError` if serialization fails
isolated function valueSetToByte(r4:ValueSet valueSet) returns byte[]|r4:FHIRError {
    return valueSet.toJsonString().toBytes();
}

# Deserializes a stored byte array back into a ValueSet.
#
# + byteArray - The stored bytes to decode
# + return - The decoded ValueSet, or an `error` if decoding fails
isolated function byteToValueSet(byte[] byteArray) returns r4:ValueSet|error {
    string valueSetJsonString = check 'string:fromBytes(byteArray);
    r4:ValueSet parsedValueSet = check parser:parse(valueSetJsonString).ensureType();

    return parsedValueSet;
}

# Serializes a ConceptMap to bytes for storage.
#
# + conceptMap - The ConceptMap to serialize
# + return - The serialized bytes, or an `r4:FHIRError` if serialization fails
isolated function conceptMapToByte(r4:ConceptMap conceptMap) returns byte[]|r4:FHIRError {
    return conceptMap.toJsonString().toBytes();
}

# Deserializes a stored byte array back into a ConceptMap. Unlike CodeSystem/ValueSet, ConceptMap isn't a profile the Terminology IG registers, so parser:parse resolves it against the default (international401) IG and returns an international401:ConceptMap - a different nominal type from r4:ConceptMap despite being structurally identical on the wire. Retyping via JSON rather than ensureType() sidesteps this nominal mismatch.
#
# + byteArray - The stored bytes to decode
# + return - The decoded ConceptMap, or an `error` if decoding fails
isolated function byteToConceptMap(byte[] byteArray) returns r4:ConceptMap|error {
    string conceptMapJsonString = check 'string:fromBytes(byteArray);
    // Unlike CodeSystem/ValueSet, ConceptMap isn't a profile the Terminology IG
    // registers, so parser:parse resolves it against the default (international401)
    // IG and returns an international401:ConceptMap - a different nominal type
    // from r4:ConceptMap despite being structurally identical on the wire. Retype
    // via JSON instead of ensureType() to sidestep the nominal mismatch.
    anydata parsed = check parser:parse(conceptMapJsonString);
    r4:ConceptMap parsedConceptMap = check parsed.toJson().cloneWithType(r4:ConceptMap);

    return parsedConceptMap;
}

# Drains a persist query stream of store_h2 CodeSystem rows into an array.
#
# + codeSystemStream - The stream of stored CodeSystem rows to collect
# + return - The collected rows, or an `error` if the stream fails
isolated function streamToStoreCodeSystem(stream<store_h2:CodeSystem, persist:Error?> codeSystemStream) returns store_h2:CodeSystem[]|error {
    store_h2:CodeSystem[] dbCodeSystems = check from store_h2:CodeSystem codeSystem in codeSystemStream
        select codeSystem;
    return dbCodeSystems;
}

# Drains a persist query stream of store_h2 Concept rows into an array.
#
# + conceptStream - The stream of stored Concept rows to collect
# + return - The collected rows, or an `error` if the stream fails
isolated function streamToStoreConcept(stream<store_h2:Concept, persist:Error?> conceptStream) returns store_h2:Concept[]|error {
    store_h2:Concept[] dbConcepts = check from store_h2:Concept concept in conceptStream
        select concept;
    return dbConcepts;
}

# Drains a persist query stream of store_h2 ValueSet rows into an array.
#
# + valueSetStream - The stream of stored ValueSet rows to collect
# + return - The collected rows, or an `error` if the stream fails
isolated function streamToStoreValueSet(stream<store_h2:ValueSet, persist:Error?> valueSetStream) returns store_h2:ValueSet[]|error {
    store_h2:ValueSet[] dbValueSets = check from store_h2:ValueSet valueSet in valueSetStream
        select valueSet;
    return dbValueSets;
}

# Converts a loosely-typed parsed CodeSystem (ParseCodeSystem) into a strict r4:CodeSystem record, defaulting `content` to "example" and `status` to "unknown" when absent.
#
# + customCodeSystem - The loosely-typed parsed CodeSystem
# + return - The equivalent r4:CodeSystem
isolated function parseCodeSystemToR4CodeSystem(ParseCodeSystem customCodeSystem) returns r4:CodeSystem => {
    resourceType: customCodeSystem.resourceType,
    meta: customCodeSystem.meta,
    valueSet: customCodeSystem.valueSet,
    date: customCodeSystem.date,
    purpose: customCodeSystem.purpose,
    description: customCodeSystem.description,
    experimental: customCodeSystem.experimental,
    content: customCodeSystem.content ?: "example",
    status: customCodeSystem.status ?: "unknown",
    title: customCodeSystem.title,
    language: customCodeSystem.language,
    id: customCodeSystem.id,
    hierarchyMeaning: customCodeSystem.hierarchyMeaning,
    extension: customCodeSystem.extension,
    copyright: customCodeSystem.copyright,
    jurisdiction: customCodeSystem.jurisdiction,
    modifierExtension: customCodeSystem.modifierExtension,
    contact: customCodeSystem.contact,
    property: customCodeSystem.property,
    text: customCodeSystem.text,
    caseSensitive: customCodeSystem.caseSensitive,
    identifier: customCodeSystem.identifier,
    publisher: customCodeSystem.publisher,
    implicitRules: customCodeSystem.implicitRules,
    name: customCodeSystem.name,
    compositional: customCodeSystem.compositional,
    supplements: customCodeSystem.supplements,
    url: customCodeSystem.url,
    'version: customCodeSystem.'version,
    count: customCodeSystem.count,
    versionNeeded: customCodeSystem.versionNeeded,
    filter: customCodeSystem.filter,
    contained: customCodeSystem.contained,
    useContext: customCodeSystem.useContext,
    concept: customCodeSystem.concept
};

# Converts a loosely-typed parsed ValueSet (ParseValueSet) into a strict r4:ValueSet record, defaulting `status` to "unknown" when absent.
#
# + customValueSet - The loosely-typed parsed ValueSet
# + return - The equivalent r4:ValueSet
isolated function parseValueSetToR4ValueSet(ParseValueSet customValueSet) returns r4:ValueSet => {
    resourceType: customValueSet.resourceType,
    meta: customValueSet.meta,
    date: customValueSet.date,
    copyright: customValueSet.copyright,
    extension: customValueSet.extension,
    purpose: customValueSet.purpose,
    jurisdiction: customValueSet.jurisdiction,
    modifierExtension: customValueSet.modifierExtension,
    description: customValueSet.description,
    experimental: customValueSet.experimental,
    language: customValueSet.language,
    title: customValueSet.title,
    contact: customValueSet.contact,
    id: customValueSet.id,
    text: customValueSet.text,
    identifier: customValueSet.identifier,
    'version: customValueSet.'version,
    url: customValueSet.url,
    expansion: customValueSet.expansion,
    contained: customValueSet.contained,
    immutable: customValueSet.immutable,
    compose: customValueSet.compose,
    name: customValueSet.name,
    implicitRules: customValueSet.implicitRules,
    publisher: customValueSet.publisher,
    useContext: customValueSet.useContext,
    status: customValueSet.status ?: "unknown"
};

# Converts an XML-parsed CodeSystem (XMLCodeSystem) into a strict r4:CodeSystem record, unwrapping each XML element's `.value` and delegating nested structures (text, identifiers, filters, properties, contacts, hierarchyMeaning, concepts) to the corresponding map* helper functions.
#
# + xmlCodeSystem - The XML-parsed CodeSystem
# + return - The equivalent r4:CodeSystem
isolated function xmlCodeSystemToR4CodeSystem(XMLCodeSystem xmlCodeSystem) returns r4:CodeSystem => {
    resourceType: xmlCodeSystem.resourceType,
    meta: xmlCodeSystem.meta,
    valueSet: xmlCodeSystem.valueSet?.value,
    date: xmlCodeSystem.date?.value,
    purpose: xmlCodeSystem.purpose?.value,
    description: xmlCodeSystem.description?.value,
    experimental: xmlCodeSystem.experimental?.value,
    content: <r4:CodeSystemContent>xmlCodeSystem.content?.value,
    status: <r4:CodeSystemStatus>xmlCodeSystem.status?.value,
    title: xmlCodeSystem.title?.value,
    language: xmlCodeSystem.language?.value,
    id: xmlCodeSystem.id?.value,
    copyright: xmlCodeSystem.copyright?.value,
    caseSensitive: xmlCodeSystem.caseSensitive?.value,
    publisher: xmlCodeSystem.publisher?.value,
    implicitRules: xmlCodeSystem.implicitRules?.value,
    name: xmlCodeSystem.name?.value,
    compositional: xmlCodeSystem.compositional?.value,
    supplements: xmlCodeSystem.supplements?.value,
    url: xmlCodeSystem.url?.value,
    'version: xmlCodeSystem.version?.value,
    count: xmlCodeSystem.count?.value,
    versionNeeded: xmlCodeSystem.versionNeeded?.value,
    text: mapText(xmlCodeSystem.text),
    identifier: mapIdentifiers(xmlCodeSystem.identifier),
    filter: mapFilters(xmlCodeSystem.filter),
    property: mapProperties(xmlCodeSystem.property),
    contact: mapContacts(xmlCodeSystem.contact),
    hierarchyMeaning: mapHierarchyMeaning(xmlCodeSystem.hierarchyMeaning),
    concept: mapConcepts(xmlCodeSystem.concept)
};

# Maps XML CodeSystem filter elements to r4:CodeSystemFilter records.
#
# + filters - The XML filter elements to map, or `()`
# + return - The mapped filters, or `()` if there are none
isolated function mapFilters(ValueFilter[]? filters) returns r4:CodeSystemFilter[]? {
    if filters is () {
        return ();
    }
    r4:CodeSystemFilter[] r4Filters = [];
    foreach var filter in filters {
        r4Filters.push({
            code: filter.code.value,
            description: filter.description?.value,
            operator: filter.operator.map(op => <r4:CodeSystemFilterOperator>op.value),
            value: filter.value.value
        });
    }

    if r4Filters.length() == 0 {
        return ();
    }
    return r4Filters;
}

# Maps XML CodeSystem property elements to r4:CodeSystemProperty records.
#
# + properties - The XML property elements to map, or `()`
# + return - The mapped properties, or `()` if there are none
isolated function mapProperties(ValueProperty[]? properties) returns r4:CodeSystemProperty[]? {
    if properties is () {
        return ();
    }
    r4:CodeSystemProperty[] r4Properties = [];
    foreach var property in properties {
        r4Properties.push({
            code: property.code.value,
            uri: property.uri?.value,
            description: property.description?.value,
            'type: <r4:CodeSystemPropertyType>property.'type.value
        });
    }

    if r4Properties.length() == 0 {
        return ();
    }
    return r4Properties;
}

# Maps XML CodeSystem concept elements to r4:CodeSystemConcept records, carrying over code, display, and definition.
#
# + concepts - The XML concept elements to map, or `()`
# + return - The mapped concepts, or `()` if there are none
isolated function mapConcepts(ValueConcept[]? concepts) returns r4:CodeSystemConcept[]? {
    if concepts is () {
        return ();
    }
    r4:CodeSystemConcept[] r4Concepts = [];
    foreach var concept in concepts {
        r4:CodeSystemConcept r4Concept = {code: concept.code.value};
        if concept.display is ValueString {
            r4Concept.display = concept.display?.value;
        }
        if concept.definition is ValueString {
            r4Concept.definition = concept.definition?.value;
        }
        r4Concepts.push(r4Concept);
    }

    if r4Concepts.length() == 0 {
        return ();
    }
    return r4Concepts;
}

# Maps XML identifier value elements to r4:Identifier records.
#
# + identifiers - The XML identifier elements to map, or `()`
# + return - The mapped identifiers, or `()` if there are none
isolated function mapIdentifiers(ValueString[]? identifiers) returns r4:Identifier[]? {
    if identifiers is () {
        return ();
    }
    r4:Identifier[] r4Identifiers = [];
    foreach var identifier in identifiers {
        r4Identifiers.push({value: identifier.value});
    }

    if r4Identifiers.length() == 0 {
        return ();
    }
    return r4Identifiers;
}

# Maps an XML narrative text element to an r4:Narrative with a "generated" status.
#
# + text - The XML text element to map, or `()`
# + return - The mapped narrative, or `()` if `text` is `()`
isolated function mapText(ValueString? text) returns r4:Narrative? {
    if text is () {
        return ();
    }
    return {div: text.value, status: "generated"};
}

# Maps XML contact elements to r4:ContactDetail records, converting each contact's telecom entries.
#
# + contacts - The XML contact elements to map, or `()`
# + return - The mapped contacts, or `()` if there are none
isolated function mapContacts(ValueContact[]? contacts) returns r4:ContactDetail[]? {
    if contacts is () {
        return ();
    }
    r4:ContactDetail[] r4Contacts = [];
    foreach var contact in contacts {
        r4:ContactPoint[] r4Telecoms = [];
        foreach var telecom in contact.telecom {
            r4Telecoms.push({
                system: <r4:ContactPointSystem>telecom.system.value,
                value: telecom.value.value
            });
        }
        r4Contacts.push({
            telecom: r4Telecoms
        });
    }
    if r4Contacts.length() == 0 {
        return ();
    }
    return r4Contacts;
}

# Maps an XML hierarchyMeaning value element to the r4:CodeSystemHierarchyMeaning enum.
#
# + hierarchyMeaning - The XML hierarchyMeaning element to map, or `()`
# + return - The mapped hierarchy meaning, or `()` if `hierarchyMeaning` is `()`
isolated function mapHierarchyMeaning(ValueHierarchyMeaning? hierarchyMeaning) returns r4:CodeSystemHierarchyMeaning? {
    if hierarchyMeaning is () {
        return ();
    }
    // Map string value to r4:CodeSystemHierarchyMeaning enum
    return <r4:CodeSystemHierarchyMeaning>hierarchyMeaning.value;
}

# Wraps a list of terminology concept details as a searchset Bundle of Coding resources, one entry per concept.
#
# + codeSystemDetails - The concept details (CodeSystem url plus concept) to wrap
# + return - A searchset Bundle whose entries are Coding resources
isolated function codeSystemDetailsIntoBundle(TerminologyConcept[] codeSystemDetails) returns r4:Bundle {
    r4:BundleEntry[] entries = [];
    foreach var detail in codeSystemDetails {
        r4:Coding coding = {
            system: detail.url,
            code: detail.concept.code,
            display: detail.concept.display
        };
        // Each entry resource is a Coding resource (wrapped as json)
        entries.push({
            'resource: coding
        });
    }

    return {
        'type: r4:BUNDLE_TYPE_SEARCHSET,
        total: entries.length(),
        entry: entries
    };
}

