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

// Embedded CSV content for SEARCH_PARAM_RES_EXPRESSIONS population.
// Used in environments where the asset file `./assets/r4-searchParam-Expression.csv`
// is not available (e.g., some Docker deployments).
final string SEARCH_PARAM_EXPRESSIONS_CSV = string `Search_Parm,Resource,Search_Pram_Type,Expression
_text,DomainResource,string,
_content,Resource,string,
_id,Resource,token,Resource.id
_lastUpdated,Resource,date,Resource.meta.lastUpdated
_profile,Resource,uri,Resource.meta.profile
_query,Resource,token,
_security,Resource,token,Resource.meta.security
_source,Resource,uri,Resource.meta.source
_tag,Resource,token,Resource.meta.tag
identifier,Account,token,Account.identifier
name,Account,string,Account.name
owner,Account,reference,Account.owner
patient,Account,reference,Account.subject.where(resolve() is Patient)
period,Account,date,Account.servicePeriod
status,Account,token,Account.status
subject,Account,reference,Account.subject
type,Account,token,Account.type
composed-of,ActivityDefinition,reference,ActivityDefinition.relatedArtifact.where(type='composed-of').resource
context,ActivityDefinition,token,
context-quantity,ActivityDefinition,quantity,
context-type,ActivityDefinition,token,ActivityDefinition.useContext.code
date,ActivityDefinition,date,ActivityDefinition.date
depends-on,ActivityDefinition,reference,ActivityDefinition.relatedArtifact.where(type='depends-on').resource
derived-from,ActivityDefinition,reference,ActivityDefinition.relatedArtifact.where(type='derived-from').resource
description,ActivityDefinition,string,ActivityDefinition.description
effective,ActivityDefinition,date,ActivityDefinition.effectivePeriod
identifier,ActivityDefinition,token,ActivityDefinition.identifier
jurisdiction,ActivityDefinition,token,ActivityDefinition.jurisdiction
name,ActivityDefinition,string,ActivityDefinition.name
predecessor,ActivityDefinition,reference,ActivityDefinition.relatedArtifact.where(type='predecessor').resource
publisher,ActivityDefinition,string,ActivityDefinition.publisher
status,ActivityDefinition,token,ActivityDefinition.status
successor,ActivityDefinition,reference,ActivityDefinition.relatedArtifact.where(type='successor').resource
title,ActivityDefinition,string,ActivityDefinition.title
topic,ActivityDefinition,token,ActivityDefinition.topic
url,ActivityDefinition,uri,ActivityDefinition.url
version,ActivityDefinition,token,ActivityDefinition.version
context-type-quantity,ActivityDefinition,composite,ActivityDefinition.useContext
context-type-value,ActivityDefinition,composite,ActivityDefinition.useContext
actuality,AdverseEvent,token,AdverseEvent.actuality
category,AdverseEvent,token,AdverseEvent.category
date,AdverseEvent,date,AdverseEvent.date
event,AdverseEvent,token,AdverseEvent.event
location,AdverseEvent,reference,AdverseEvent.location
recorder,AdverseEvent,reference,AdverseEvent.recorder
resultingcondition,AdverseEvent,reference,AdverseEvent.resultingCondition
seriousness,AdverseEvent,token,AdverseEvent.seriousness
severity,AdverseEvent,token,AdverseEvent.severity
study,AdverseEvent,reference,AdverseEvent.study
subject,AdverseEvent,reference,AdverseEvent.subject
substance,AdverseEvent,reference,AdverseEvent.suspectEntity.instance
asserter,AllergyIntolerance,reference,AllergyIntolerance.asserter
category,AllergyIntolerance,token,AllergyIntolerance.category
clinical-status,AllergyIntolerance,token,AllergyIntolerance.clinicalStatus
code,AllergyIntolerance,token,AllergyIntolerance.code
code,Condition,token,AllergyIntolerance.reaction.substance
code,DeviceRequest,token,Condition.code
code,DiagnosticReport,token,
code,FamilyMemberHistory,token,DiagnosticReport.code
code,List,token,FamilyMemberHistory.condition.code
code,Medication,token,List.code
code,MedicationAdministration,token,Medication.code
code,MedicationDispense,token,
code,MedicationRequest,token,
code,MedicationStatement,token,
code,Observation,token,
code,Procedure,token,Observation.code
code,ServiceRequest,token,Procedure.code
criticality,AllergyIntolerance,token,AllergyIntolerance.criticality
date,AllergyIntolerance,date,AllergyIntolerance.recordedDate
date,CarePlan,date,CarePlan.period
date,CareTeam,date,CareTeam.period
date,ClinicalImpression,date,ClinicalImpression.date
date,Composition,date,Composition.date
date,Consent,date,Consent.dateTime
date,DiagnosticReport,date,DiagnosticReport.effective
date,Encounter,date,Encounter.period
date,EpisodeOfCare,date,EpisodeOfCare.period
date,FamilyMemberHistory,date,FamilyMemberHistory.date
`;

