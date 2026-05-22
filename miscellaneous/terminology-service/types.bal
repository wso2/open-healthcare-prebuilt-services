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
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.terminology;

type TerminologyConcept terminology:CodeConceptDetails;

type ConceptNode record {|
    int conceptId;
    int? parentConceptId;
|};

public type CodeSystemValueSetJson record {|
    json[] codeSystems;
    json[] valueSets;
|};

public type ParseCodeSystem record {|
    *r4:DomainResource;

    r4:RESOURCE_NAME_CODESYSTEM resourceType = r4:RESOURCE_NAME_CODESYSTEM;

    r4:BaseCodeSystemMeta meta = {
        profile: [r4:PROFILE_BASE_CODESYSTEM]
    };
    r4:dateTime date?;
    r4:markdown copyright?;
    r4:Extension[] extension?;
    r4:canonical valueSet?;
    r4:markdown purpose?;
    r4:CodeSystemConcept[] concept?;
    r4:CodeableConcept[] jurisdiction?;
    r4:Extension[] modifierExtension?;
    r4:markdown description?;
    boolean experimental?;
    r4:code language?;
    string title?;
    r4:CodeSystemContent content?;
    r4:CodeSystemHierarchyMeaning hierarchyMeaning?;
    r4:ContactDetail[] contact?;
    r4:CodeSystemProperty[] property?;
    string id?;
    r4:Narrative text?;
    r4:Identifier[] identifier?;
    boolean caseSensitive?;
    boolean versionNeeded?;
    r4:unsignedInt count?;
    string 'version?;
    r4:uri url?;
    r4:CodeSystemFilter[] filter?;
    r4:canonical supplements?;
    r4:Resource[] contained?;
    boolean compositional?;
    string name?;
    r4:uri implicitRules?;
    string publisher?;
    r4:UsageContext[] useContext?;
    r4:CodeSystemStatus status?;
    never...;
|};

public type ParseValueSet record {|
    *r4:DomainResource;

    r4:RESOURCE_NAME_VALUESET resourceType = r4:RESOURCE_NAME_VALUESET;

    r4:BaseValueSetMeta meta = {
        profile: [r4:PROFILE_BASE_VALUESET]
    };
    r4:dateTime date?;
    r4:markdown copyright?;
    r4:Extension[] extension?;
    r4:markdown purpose?;
    r4:CodeableConcept[] jurisdiction?;
    r4:Extension[] modifierExtension?;
    r4:markdown description?;
    boolean experimental?;
    r4:code language?;
    string title?;
    r4:ContactDetail[] contact?;
    string id?;
    r4:Narrative text?;
    r4:Identifier[] identifier?;
    string 'version?;
    r4:uri url?;
    r4:ValueSetExpansion expansion?;
    r4:Resource[] contained?;
    boolean immutable?;
    r4:ValueSetCompose compose?;
    string name?;
    r4:uri implicitRules?;
    string publisher?;
    r4:UsageContext[] useContext?;
    r4:ValueSetStatus status?;
    never...;
|};

type XMLCodeSystem record {
    ValueString id?;
    ValueString url?;
    ValueString name?;
    ValueString title?;
    ValueString status?;
    ValueBoolean experimental?;
    ValueString publisher?;
    ValueString copyright?;
    ValueBoolean caseSensitive?;
    ValueString valueSet?;
    ValueBoolean compositional?;
    ValueBoolean versionNeeded?;
    ValueString content?;
    ValueString description?;
    ValueFilter[] filter?;
    ValueProperty[] property?;
    ValueString date?;
    ValueString purpose?;
    ValueString language?;
    ValueConcept[] concept?;
    ValueString[] contactDetail?;
    ValueString[] propertyDetail?;
    ValueString[] identifier?;
    ValueString text?;
    ValueInt count?;
    ValueString version?;
    ValueString supplements?;
    ValueString implicitRules?;
    ValueString useContext?;
    ValueContact[] contact?;
    ValueHierarchyMeaning hierarchyMeaning?;
    r4:RESOURCE_NAME_CODESYSTEM resourceType = r4:RESOURCE_NAME_CODESYSTEM;
    r4:BaseCodeSystemMeta meta = {profile: [r4:PROFILE_BASE_CODESYSTEM]};
};

type ValueString record {
    string value;
};

type ValueBoolean record {
    boolean value;
};

type ValueInt record {
    int value;
};

type ValueFilter record {
    ValueString code;
    ValueString description?;
    ValueString id?;
    ValueString[] operator;
    ValueString value;
};

type ValueProperty record {
    ValueString code;
    ValueString uri?;
    ValueString description?;
    ValueString 'type;
};

type ValueConcept record {
    ValueString code;
    ValueString display?;
    ValueString definition?;
};

type ValueTelecom record {
    ValueString system;
    ValueString value;
};

type ValueContact record {
    ValueTelecom[] telecom;
};

type ValueHierarchyMeaning record {
    string value;
};
