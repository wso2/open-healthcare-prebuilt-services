// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

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
import terminology_service.store;

import ballerina/http;
import ballerina/persist;
import ballerina/sql;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

isolated function codesystemConceptsToParameters(r4:CodeSystemConcept[]|r4:CodeSystemConcept concepts) returns international401:Parameters {
    international401:Parameters parameters = {};
    if concepts is r4:CodeSystemConcept {
        parameters = {
            'parameter: [
                {name: "name", valueString: concepts.code},
                {name: "display", valueString: concepts.display}
            ]
        };

        if concepts.definition is string {
            (<international401:ParametersParameter[]>parameters.'parameter).push({name: "definition", valueString: concepts.definition});
        }

        if concepts.property is r4:CodeSystemConceptProperty[] {
            foreach var item in <r4:CodeSystemConceptProperty[]>concepts.property {
                international401:ParametersParameter result = codeSystemConceptPropertyToParameter(item);
                (<international401:ParametersParameter[]>parameters.'parameter).push(result);
            }
        }

        if concepts.designation is r4:CodeSystemConceptDesignation[] {
            foreach var item in <r4:CodeSystemConceptDesignation[]>concepts.designation {
                international401:ParametersParameter result = designationToParameter(item);
                (<international401:ParametersParameter[]>parameters.'parameter).push(result);
            }
        }
    } else {
        international401:ParametersParameter[] p = [];
        foreach r4:CodeSystemConcept item in concepts {
            p.push({name: "name", valueString: item.code},
                    {name: "display", valueString: item.display});

            if item.definition is string {
                p.push({name: "definition", valueString: item.definition});
            }

            if item.property is r4:CodeSystemConceptProperty[] {
                foreach var prop in <r4:CodeSystemConceptProperty[]>item.property {
                    international401:ParametersParameter result = codeSystemConceptPropertyToParameter(prop);
                    p.push(result);
                }
            }

            if item.designation is r4:CodeSystemConceptDesignation[] {
                foreach var desg in <r4:CodeSystemConceptDesignation[]>item.designation {
                    international401:ParametersParameter result = designationToParameter(desg);
                    (<international401:ParametersParameter[]>parameters.'parameter).push(result);
                }
            }
        }
        parameters = {'parameter: p};
    }
    return parameters;
}

isolated function designationToParameter(r4:CodeSystemConceptDesignation designation) returns international401:ParametersParameter {
    international401:ParametersParameter param = {name: "designation"};
    international401:ParametersParameter[] part = [];

    if designation.language is string {
        part.push({name: "language", valueCode: designation.language});
    }

    part.push({name: "value", valueString: designation.value});

    if designation.use is r4:Coding {
        part.push({name: "use", valueCoding: designation.use});
    }
    param.part = part;

    return param;
}

isolated function stringToParameterizedQuery(string queryStr) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery query = ``;
    query.strings = [queryStr];
    return query;
}

isolated function codeSystemToByte(r4:CodeSystem codeSystem) returns byte[]|r4:FHIRError {
    // remove concepts from the codeSystem object
    // because concepts are stored in separate table in database
    r4:CodeSystem codeSystemWithoutConcepts = codeSystem.clone();
    codeSystemWithoutConcepts.concept = ();

    byte[] byteArray = codeSystemWithoutConcepts.toJsonString().toBytes();

    // check whether the conversion was successful
    r4:CodeSystem|error parsedcs = byteToCodeSystem(byteArray);

    if parsedcs is r4:CodeSystem {
        return byteArray;
    } else {
        return r4:createFHIRError(
                "Error while converting CodeSystem to byte, CodeSystem is not valid, " + parsedcs.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = parsedcs,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }
}

isolated function byteToCodeSystem(byte[] byteArray) returns r4:CodeSystem|error {
    string codeSystemJsonString = check 'string:fromBytes(byteArray);
    r4:CodeSystem parsedCodeSystem = check parser:parse(codeSystemJsonString).ensureType();

    return parsedCodeSystem;
}

isolated function conceptToByte(r4:CodeSystemConcept concept) returns byte[]|r4:FHIRError {
    r4:CodeSystemConcept conceptWithoutInternlConcept = concept.clone();
    conceptWithoutInternlConcept.concept = ();

    return conceptWithoutInternlConcept.toJsonString().toBytes();
}

isolated function byteToConcept(byte[] byteArray) returns r4:CodeSystemConcept|error {
    string conceptJsonString = check 'string:fromBytes(byteArray);
    json conceptJson = check conceptJsonString.fromJsonString();
    r4:CodeSystemConcept parsedConcept = check conceptJson.fromJsonWithType(r4:CodeSystemConcept);

    return parsedConcept;
}

isolated function valueSetToByte(r4:ValueSet valueSet) returns byte[]|r4:FHIRError {
    return valueSet.toJsonString().toBytes();
}

isolated function byteToValueSet(byte[] byteArray) returns r4:ValueSet|error {
    string valueSetJsonString = check 'string:fromBytes(byteArray);
    r4:ValueSet parsedValueSet = check parser:parse(valueSetJsonString).ensureType();

    return parsedValueSet;
}

isolated function streamToStoreCodeSystem(stream<store:CodeSystem, persist:Error?> codeSystemStream) returns store:CodeSystem[]|error {
    store:CodeSystem[] dbCodeSystems = check from store:CodeSystem codeSystem in codeSystemStream
        select codeSystem;
    return dbCodeSystems;
}

isolated function streamToStoreConcept(stream<store:Concept, persist:Error?> conceptStream) returns store:Concept[]|error {
    store:Concept[] dbConcepts = check from store:Concept concept in conceptStream
        select concept;
    return dbConcepts;
}

isolated function streamToStoreValueSet(stream<store:ValueSet, persist:Error?> valueSetStream) returns store:ValueSet[]|error {
    store:ValueSet[] dbValueSets = check from store:ValueSet valueSet in valueSetStream
        select valueSet;
    return dbValueSets;
}

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

// Helper function to map filters
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

// Helper function to map properties
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

// Helper function to map Concept[]? to r4:CodeSystemConcept[]?
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

// Helper function to map identifiers
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

// Helper function to map text
isolated function mapText(ValueString? text) returns r4:Narrative? {
    if text is () {
        return ();
    }
    return {div: text.value, status: "generated"};
}

// Helper function to map ValueContact[]? to r4:ContactDetail[]?
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

// Helper function to map hierarchyMeaning
isolated function mapHierarchyMeaning(ValueHierarchyMeaning? hierarchyMeaning) returns r4:CodeSystemHierarchyMeaning? {
    if hierarchyMeaning is () {
        return ();
    }
    // Map string value to r4:CodeSystemHierarchyMeaning enum
    return <r4:CodeSystemHierarchyMeaning>hierarchyMeaning.value;
}

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
