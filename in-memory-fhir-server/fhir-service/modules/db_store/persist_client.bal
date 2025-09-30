// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

import ballerina/jballerina.java;
import ballerina/persist;
import ballerina/sql;
import ballerinax/h2.driver as _;
import ballerinax/java.jdbc;
import ballerinax/persist.sql as psql;

const S_E_A_R_C_H__P_A_R_A_M__R_E_S__E_X_P_R_E_S_S_I_O_N_S = "search_param_res_expressions";
const R_E_F_E_R_E_N_C_E_S = "references";
const TEST_SCRIPT_TABLE = "testscripttables";
const TEST_REPORT_TABLE = "testreporttables";
const RELATED_PERSON_TABLE = "relatedpersontables";
const EVIDENCE_VARIABLE_TABLE = "evidencevariabletables";
const VALUE_SET_TABLE = "valuesettables";
const DOCUMENT_MANIFEST_TABLE = "documentmanifesttables";
const IMMUNIZATION_RECOMMENDATION_TABLE = "immunizationrecommendationtables";
const DEVICE_METRIC_TABLE = "devicemetrictables";
const LOCATION_TABLE = "locationtables";
const EXPLANATION_OF_BENEFIT_TABLE = "explanationofbenefittables";
const FLAG_TABLE = "flagtables";
const MEDICATION_STATEMENT_TABLE = "medicationstatementtables";
const INSURANCE_PLAN_TABLE = "insuranceplantables";
const MEDICINAL_PRODUCT_CONTRAINDICATION_TABLE = "medicinalproductcontraindicationtables";
const CLAIM_RESPONSE_TABLE = "claimresponsetables";
const MEDICINAL_PRODUCT_AUTHORIZATION_TABLE = "medicinalproductauthorizationtables";
const IMAGING_STUDY_TABLE = "imagingstudytables";
const PRACTITIONER_ROLE_TABLE = "practitionerroletables";
const GROUP_TABLE = "grouptables";
const PERSON_TABLE = "persontables";
const PRACTITIONER_TABLE = "practitionertables";
const ACTIVITY_DEFINITION_TABLE = "activitydefinitiontables";
const EVIDENCE_TABLE = "evidencetables";
const DEVICE_TABLE = "devicetables";
const FAMILY_MEMBER_HISTORY_TABLE = "familymemberhistorytables";
const ADVERSE_EVENT_TABLE = "adverseeventtables";
const SUPPLY_REQUEST_TABLE = "supplyrequesttables";
const EXAMPLE_SCENARIO_TABLE = "examplescenariotables";
const INVOICE_TABLE = "invoicetables";
const QUESTIONNAIRE_RESPONSE_TABLE = "questionnaireresponsetables";
const OBSERVATION_TABLE = "observationtables";
const EFFECT_EVIDENCE_SYNTHESIS_TABLE = "effectevidencesynthesistables";
const OPERATION_DEFINITION_TABLE = "operationdefinitiontables";
const MEASURE_REPORT_TABLE = "measurereporttables";
const SUPPLY_DELIVERY_TABLE = "supplydeliverytables";
const SERVICE_REQUEST_TABLE = "servicerequesttables";
const BASIC_TABLE = "basictables";
const SUBSCRIPTION_TABLE = "subscriptiontables";
const ENROLLMENT_RESPONSE_TABLE = "enrollmentresponsetables";
const DEVICE_REQUEST_TABLE = "devicerequesttables";
const APPOINTMENT_TABLE = "appointmenttables";
const NAMING_SYSTEM_TABLE = "namingsystemtables";
const STRUCTURE_DEFINITION_TABLE = "structuredefinitiontables";
const CLINICAL_IMPRESSION_TABLE = "clinicalimpressiontables";
const COMMUNICATION_TABLE = "communicationtables";
const ORGANIZATION_TABLE = "organizationtables";
const COVERAGE_ELIGIBILITY_RESPONSE_TABLE = "coverageeligibilityresponsetables";
const RESEARCH_STUDY_TABLE = "researchstudytables";
const BUNDLE_TABLE = "bundletables";
const ENCOUNTER_TABLE = "encountertables";
const RISK_ASSESSMENT_TABLE = "riskassessmenttables";
const LIST_TABLE = "listtables";
const ORGANIZATION_AFFILIATION_TABLE = "organizationaffiliationtables";
const CHARGE_ITEM_TABLE = "chargeitemtables";
const MEDICATION_KNOWLEDGE_TABLE = "medicationknowledgetables";
const PLAN_DEFINITION_TABLE = "plandefinitiontables";
const CARE_PLAN_TABLE = "careplantables";
const VISION_PRESCRIPTION_TABLE = "visionprescriptiontables";
const EPISODE_OF_CARE_TABLE = "episodeofcaretables";
const CARE_TEAM_TABLE = "careteamtables";
const MEDICATION_ADMINISTRATION_TABLE = "medicationadministrationtables";
const CONSENT_TABLE = "consenttables";
const DETECTED_ISSUE_TABLE = "detectedissuetables";
const SUBSTANCE_SPECIFICATION_TABLE = "substancespecificationtables";
const ALLERGY_INTOLERANCE_TABLE = "allergyintolerancetables";
const MEDICINAL_PRODUCT_INDICATION_TABLE = "medicinalproductindicationtables";
const MEDICINAL_PRODUCT_PHARMACEUTICAL_TABLE = "medicinalproductpharmaceuticaltables";
const SLOT_TABLE = "slottables";
const VERIFICATION_RESULT_TABLE = "verificationresulttables";
const SPECIMEN_TABLE = "specimentables";
const RESEARCH_SUBJECT_TABLE = "researchsubjecttables";
const MEDICATION_TABLE = "medicationtables";
const RESEARCH_DEFINITION_TABLE = "researchdefinitiontables";
const HEALTHCARE_SERVICE_TABLE = "healthcareservicetables";
const PAYMENT_NOTICE_TABLE = "paymentnoticetables";
const PROVENANCE_TABLE = "provenancetables";
const GRAPH_DEFINITION_TABLE = "graphdefinitiontables";
const MEDIA_TABLE = "mediatables";
const BODY_STRUCTURE_TABLE = "bodystructuretables";
const DIAGNOSTIC_REPORT_TABLE = "diagnosticreporttables";
const GOAL_TABLE = "goaltables";
const CAPABILITY_STATEMENT_TABLE = "capabilitystatementtables";
const DEVICE_USE_STATEMENT_TABLE = "deviceusestatementtables";
const SCHEDULE_TABLE = "scheduletables";
const MEDICINAL_PRODUCT_PACKAGED_TABLE = "medicinalproductpackagedtables";
const PROCEDURE_TABLE = "proceduretables";
const LIBRARY_TABLE = "librarytables";
const CODE_SYSTEM_TABLE = "codesystemtables";
const COMMUNICATION_REQUEST_TABLE = "communicationrequesttables";
const DOCUMENT_REFERENCE_TABLE = "documentreferencetables";
const REQUEST_GROUP_TABLE = "requestgrouptables";
const CLAIM_TABLE = "claimtables";
const MESSAGE_DEFINITION_TABLE = "messagedefinitiontables";
const RISK_EVIDENCE_SYNTHESIS_TABLE = "riskevidencesynthesistables";
const TASK_TABLE = "tasktables";
const IMPLEMENTATION_GUIDE_TABLE = "implementationguidetables";
const STRUCTURE_MAP_TABLE = "structuremaptables";
const MEDICINAL_PRODUCT_UNDESIRABLE_EFFECT_TABLE = "medicinalproductundesirableeffecttables";
const COMPARTMENT_DEFINITION_TABLE = "compartmentdefinitiontables";
const ENDPOINT_TABLE = "endpointtables";
const TERMINOLOGY_CAPABILITIES_TABLE = "terminologycapabilitiestables";
const CONDITION_TABLE = "conditiontables";
const COMPOSITION_TABLE = "compositiontables";
const CONTRACT_TABLE = "contracttables";
const IMMUNIZATION_TABLE = "immunizationtables";
const MEDICATION_DISPENSE_TABLE = "medicationdispensetables";
const MOLECULAR_SEQUENCE_TABLE = "molecularsequencetables";
const SEARCH_PARAMETER_TABLE = "searchparametertables";
const MEDICATION_REQUEST_TABLE = "medicationrequesttables";
const ENROLLMENT_REQUEST_TABLE = "enrollmentrequesttables";
const SPECIMEN_DEFINITION_TABLE = "specimendefinitiontables";
const EVENT_DEFINITION_TABLE = "eventdefinitiontables";
const IMMUNIZATION_EVALUATION_TABLE = "immunizationevaluationtables";
const PAYMENT_RECONCILIATION_TABLE = "paymentreconciliationtables";
const MEASURE_TABLE = "measuretables";
const CONCEPT_MAP_TABLE = "conceptmaptables";
const RESEARCH_ELEMENT_DEFINITION_TABLE = "researchelementdefinitiontables";
const GUIDANCE_RESPONSE_TABLE = "guidanceresponsetables";
const LINKAGE_TABLE = "linkagetables";
const MEDICINAL_PRODUCT_TABLE = "medicinalproducttables";
const DEVICE_DEFINITION_TABLE = "devicedefinitiontables";
const COVERAGE_ELIGIBILITY_REQUEST_TABLE = "coverageeligibilityrequesttables";
const PATIENT_TABLE = "patienttables";
const COVERAGE_TABLE = "coveragetables";
const SUBSTANCE_TABLE = "substancetables";
const CHARGE_ITEM_DEFINITION_TABLE = "chargeitemdefinitiontables";
const MEDICINAL_PRODUCT_INTERACTION_TABLE = "medicinalproductinteractiontables";
const ACCOUNT_TABLE = "accounttables";
const MESSAGE_HEADER_TABLE = "messageheadertables";
const AUDIT_EVENT_TABLE = "auditeventtables";
const NUTRITION_ORDER_TABLE = "nutritionordertables";
const QUESTIONNAIRE_TABLE = "questionnairetables";
const APPOINTMENT_RESPONSE_TABLE = "appointmentresponsetables";

public isolated client class Client {
    *persist:AbstractPersistClient;

    private final jdbc:Client dbClient;

    private final map<psql:SQLClient> persistClients;

    private final record {|psql:SQLMetadata...;|} & readonly metadata = {
        [S_E_A_R_C_H__P_A_R_A_M__R_E_S__E_X_P_R_E_S_S_I_O_N_S]: {
            entityName: "SEARCH_PARAM_RES_EXPRESSIONS",
            tableName: "SEARCH_PARAM_RES_EXPRESSIONS",
            fieldMetadata: {
                ID: {columnName: "ID", dbGenerated: true},
                SEARCH_PARAM_NAME: {columnName: "SEARCH_PARAM_NAME"},
                SEARCH_PARAM_TYPE: {columnName: "SEARCH_PARAM_TYPE"},
                RESOURCE_NAME: {columnName: "RESOURCE_NAME"},
                EXPRESSION: {columnName: "EXPRESSION"}
            },
            keyFields: ["ID"]
        },
        [R_E_F_E_R_E_N_C_E_S]: {
            entityName: "REFERENCES",
            tableName: "REFERENCES",
            fieldMetadata: {
                ID: {columnName: "ID", dbGenerated: true},
                SOURCE_RESOURCE_TYPE: {columnName: "SOURCE_RESOURCE_TYPE"},
                SOURCE_RESOURCE_ID: {columnName: "SOURCE_RESOURCE_ID"},
                SOURCE_EXPRESSION: {columnName: "SOURCE_EXPRESSION"},
                TARGET_RESOURCE_TYPE: {columnName: "TARGET_RESOURCE_TYPE"},
                TARGET_RESOURCE_ID: {columnName: "TARGET_RESOURCE_ID"},
                DISPLAY_VALUE: {columnName: "DISPLAY_VALUE"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"}
            },
            keyFields: ["ID"]
        },
        [TEST_SCRIPT_TABLE]: {
            entityName: "TestScriptTable",
            tableName: "TestScriptTable",
            fieldMetadata: {
                TESTSCRIPTTABLE_ID: {columnName: "TESTSCRIPTTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TESTSCRIPT_CAPABILITY: {columnName: "TESTSCRIPT_CAPABILITY"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["TESTSCRIPTTABLE_ID"]
        },
        [TEST_REPORT_TABLE]: {
            entityName: "TestReportTable",
            tableName: "TestReportTable",
            fieldMetadata: {
                TESTREPORTTABLE_ID: {columnName: "TESTREPORTTABLE_ID"},
                ISSUED: {columnName: "ISSUED"},
                PARTICIPANT: {columnName: "PARTICIPANT"},
                TESTER: {columnName: "TESTER"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                RESULT: {columnName: "RESULT"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["TESTREPORTTABLE_ID"]
        },
        [RELATED_PERSON_TABLE]: {
            entityName: "RelatedPersonTable",
            tableName: "RelatedPersonTable",
            fieldMetadata: {
                RELATEDPERSONTABLE_ID: {columnName: "RELATEDPERSONTABLE_ID"},
                ADDRESS_COUNTRY: {columnName: "ADDRESS_COUNTRY"},
                ADDRESS_POSTALCODE: {columnName: "ADDRESS_POSTALCODE"},
                ACTIVE: {columnName: "ACTIVE"},
                PHONE: {columnName: "PHONE"},
                BIRTHDATE: {columnName: "BIRTHDATE"},
                ADDRESS_CITY: {columnName: "ADDRESS_CITY"},
                EMAIL: {columnName: "EMAIL"},
                ADDRESS_STATE: {columnName: "ADDRESS_STATE"},
                TELECOM: {columnName: "TELECOM"},
                NAME: {columnName: "NAME"},
                ADDRESS_USE: {columnName: "ADDRESS_USE"},
                ADDRESS: {columnName: "ADDRESS"},
                GENDER: {columnName: "GENDER"},
                PHONETIC: {columnName: "PHONETIC"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                RELATIONSHIP: {columnName: "RELATIONSHIP"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["RELATEDPERSONTABLE_ID"]
        },
        [EVIDENCE_VARIABLE_TABLE]: {
            entityName: "EvidenceVariableTable",
            tableName: "EvidenceVariableTable",
            fieldMetadata: {
                EVIDENCEVARIABLETABLE_ID: {columnName: "EVIDENCEVARIABLETABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                TOPIC: {columnName: "TOPIC"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["EVIDENCEVARIABLETABLE_ID"]
        },
        [VALUE_SET_TABLE]: {
            entityName: "ValueSetTable",
            tableName: "ValueSetTable",
            fieldMetadata: {
                VALUESETTABLE_ID: {columnName: "VALUESETTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                EXPANSION: {columnName: "EXPANSION"},
                VERSION: {columnName: "VERSION"},
                REFERENCE: {columnName: "REFERENCE"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["VALUESETTABLE_ID"]
        },
        [DOCUMENT_MANIFEST_TABLE]: {
            entityName: "DocumentManifestTable",
            tableName: "DocumentManifestTable",
            fieldMetadata: {
                DOCUMENTMANIFESTTABLE_ID: {columnName: "DOCUMENTMANIFESTTABLE_ID"},
                CREATED: {columnName: "CREATED"},
                STATUS: {columnName: "STATUS"},
                RELATED_ID: {columnName: "RELATED_ID"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                SOURCE: {columnName: "SOURCE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["DOCUMENTMANIFESTTABLE_ID"]
        },
        [IMMUNIZATION_RECOMMENDATION_TABLE]: {
            entityName: "ImmunizationRecommendationTable",
            tableName: "ImmunizationRecommendationTable",
            fieldMetadata: {
                IMMUNIZATIONRECOMMENDATIONTABLE_ID: {columnName: "IMMUNIZATIONRECOMMENDATIONTABLE_ID"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                TARGET_DISEASE: {columnName: "TARGET_DISEASE"},
                VACCINE_TYPE: {columnName: "VACCINE_TYPE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["IMMUNIZATIONRECOMMENDATIONTABLE_ID"]
        },
        [DEVICE_METRIC_TABLE]: {
            entityName: "DeviceMetricTable",
            tableName: "DeviceMetricTable",
            fieldMetadata: {
                DEVICEMETRICTABLE_ID: {columnName: "DEVICEMETRICTABLE_ID"},
                CATEGORY: {columnName: "CATEGORY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["DEVICEMETRICTABLE_ID"]
        },
        [LOCATION_TABLE]: {
            entityName: "LocationTable",
            tableName: "LocationTable",
            fieldMetadata: {
                LOCATIONTABLE_ID: {columnName: "LOCATIONTABLE_ID"},
                ADDRESS_COUNTRY: {columnName: "ADDRESS_COUNTRY"},
                ADDRESS_POSTALCODE: {columnName: "ADDRESS_POSTALCODE"},
                STATUS: {columnName: "STATUS"},
                ADDRESS_USE: {columnName: "ADDRESS_USE"},
                ADDRESS: {columnName: "ADDRESS"},
                OPERATIONAL_STATUS: {columnName: "OPERATIONAL_STATUS"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                ADDRESS_CITY: {columnName: "ADDRESS_CITY"},
                TYPE: {columnName: "TYPE"},
                ADDRESS_STATE: {columnName: "ADDRESS_STATE"},
                NAME: {columnName: "NAME"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["LOCATIONTABLE_ID"]
        },
        [EXPLANATION_OF_BENEFIT_TABLE]: {
            entityName: "ExplanationOfBenefitTable",
            tableName: "ExplanationOfBenefitTable",
            fieldMetadata: {
                EXPLANATIONOFBENEFITTABLE_ID: {columnName: "EXPLANATIONOFBENEFITTABLE_ID"},
                CREATED: {columnName: "CREATED"},
                STATUS: {columnName: "STATUS"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                DISPOSITION: {columnName: "DISPOSITION"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["EXPLANATIONOFBENEFITTABLE_ID"]
        },
        [FLAG_TABLE]: {
            entityName: "FlagTable",
            tableName: "FlagTable",
            fieldMetadata: {
                FLAGTABLE_ID: {columnName: "FLAGTABLE_ID"},
                DATE: {columnName: "DATE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["FLAGTABLE_ID"]
        },
        [MEDICATION_STATEMENT_TABLE]: {
            entityName: "MedicationStatementTable",
            tableName: "MedicationStatementTable",
            fieldMetadata: {
                MEDICATIONSTATEMENTTABLE_ID: {columnName: "MEDICATIONSTATEMENTTABLE_ID"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                CATEGORY: {columnName: "CATEGORY"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICATIONSTATEMENTTABLE_ID"]
        },
        [INSURANCE_PLAN_TABLE]: {
            entityName: "InsurancePlanTable",
            tableName: "InsurancePlanTable",
            fieldMetadata: {
                INSURANCEPLANTABLE_ID: {columnName: "INSURANCEPLANTABLE_ID"},
                ADDRESS_COUNTRY: {columnName: "ADDRESS_COUNTRY"},
                ADDRESS_POSTALCODE: {columnName: "ADDRESS_POSTALCODE"},
                STATUS: {columnName: "STATUS"},
                ADDRESS_USE: {columnName: "ADDRESS_USE"},
                ADDRESS: {columnName: "ADDRESS"},
                PHONETIC: {columnName: "PHONETIC"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                ADDRESS_CITY: {columnName: "ADDRESS_CITY"},
                TYPE: {columnName: "TYPE"},
                ADDRESS_STATE: {columnName: "ADDRESS_STATE"},
                NAME: {columnName: "NAME"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["INSURANCEPLANTABLE_ID"]
        },
        [MEDICINAL_PRODUCT_CONTRAINDICATION_TABLE]: {
            entityName: "MedicinalProductContraindicationTable",
            tableName: "MedicinalProductContraindicationTable",
            fieldMetadata: {
                MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID: {columnName: "MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID"]
        },
        [CLAIM_RESPONSE_TABLE]: {
            entityName: "ClaimResponseTable",
            tableName: "ClaimResponseTable",
            fieldMetadata: {
                CLAIMRESPONSETABLE_ID: {columnName: "CLAIMRESPONSETABLE_ID"},
                CREATED: {columnName: "CREATED"},
                STATUS: {columnName: "STATUS"},
                OUTCOME: {columnName: "OUTCOME"},
                USE: {columnName: "USE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                PAYMENT_DATE: {columnName: "PAYMENT_DATE"},
                DISPOSITION: {columnName: "DISPOSITION"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["CLAIMRESPONSETABLE_ID"]
        },
        [MEDICINAL_PRODUCT_AUTHORIZATION_TABLE]: {
            entityName: "MedicinalProductAuthorizationTable",
            tableName: "MedicinalProductAuthorizationTable",
            fieldMetadata: {
                MEDICINALPRODUCTAUTHORIZATIONTABLE_ID: {columnName: "MEDICINALPRODUCTAUTHORIZATIONTABLE_ID"},
                STATUS: {columnName: "STATUS"},
                COUNTRY: {columnName: "COUNTRY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICINALPRODUCTAUTHORIZATIONTABLE_ID"]
        },
        [IMAGING_STUDY_TABLE]: {
            entityName: "ImagingStudyTable",
            tableName: "ImagingStudyTable",
            fieldMetadata: {
                IMAGINGSTUDYTABLE_ID: {columnName: "IMAGINGSTUDYTABLE_ID"},
                STATUS: {columnName: "STATUS"},
                DICOM_CLASS: {columnName: "DICOM_CLASS"},
                SERIES: {columnName: "SERIES"},
                MODALITY: {columnName: "MODALITY"},
                STARTED: {columnName: "STARTED"},
                BODYSITE: {columnName: "BODYSITE"},
                INSTANCE: {columnName: "INSTANCE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                REASON: {columnName: "REASON"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["IMAGINGSTUDYTABLE_ID"]
        },
        [PRACTITIONER_ROLE_TABLE]: {
            entityName: "PractitionerRoleTable",
            tableName: "PractitionerRoleTable",
            fieldMetadata: {
                PRACTITIONERROLETABLE_ID: {columnName: "PRACTITIONERROLETABLE_ID"},
                ROLE: {columnName: "ROLE"},
                DATE: {columnName: "DATE"},
                ACTIVE: {columnName: "ACTIVE"},
                PHONE: {columnName: "PHONE"},
                SPECIALTY: {columnName: "SPECIALTY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                EMAIL: {columnName: "EMAIL"},
                TELECOM: {columnName: "TELECOM"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["PRACTITIONERROLETABLE_ID"]
        },
        [GROUP_TABLE]: {
            entityName: "GroupTable",
            tableName: "GroupTable",
            fieldMetadata: {
                GROUPTABLE_ID: {columnName: "GROUPTABLE_ID"},
                CHARACTERISTIC: {columnName: "CHARACTERISTIC"},
                CODE: {columnName: "CODE"},
                EXCLUDE: {columnName: "EXCLUDE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VALUE: {columnName: "VALUE"},
                ACTUAL: {columnName: "ACTUAL"},
                TYPE: {columnName: "TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["GROUPTABLE_ID"]
        },
        [PERSON_TABLE]: {
            entityName: "PersonTable",
            tableName: "PersonTable",
            fieldMetadata: {
                PERSONTABLE_ID: {columnName: "PERSONTABLE_ID"},
                ADDRESS_COUNTRY: {columnName: "ADDRESS_COUNTRY"},
                ADDRESS_POSTALCODE: {columnName: "ADDRESS_POSTALCODE"},
                PHONE: {columnName: "PHONE"},
                BIRTHDATE: {columnName: "BIRTHDATE"},
                ADDRESS_CITY: {columnName: "ADDRESS_CITY"},
                EMAIL: {columnName: "EMAIL"},
                ADDRESS_STATE: {columnName: "ADDRESS_STATE"},
                TELECOM: {columnName: "TELECOM"},
                NAME: {columnName: "NAME"},
                ADDRESS_USE: {columnName: "ADDRESS_USE"},
                ADDRESS: {columnName: "ADDRESS"},
                GENDER: {columnName: "GENDER"},
                PHONETIC: {columnName: "PHONETIC"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["PERSONTABLE_ID"]
        },
        [PRACTITIONER_TABLE]: {
            entityName: "PractitionerTable",
            tableName: "PractitionerTable",
            fieldMetadata: {
                PRACTITIONERTABLE_ID: {columnName: "PRACTITIONERTABLE_ID"},
                ADDRESS_COUNTRY: {columnName: "ADDRESS_COUNTRY"},
                ADDRESS_POSTALCODE: {columnName: "ADDRESS_POSTALCODE"},
                ACTIVE: {columnName: "ACTIVE"},
                PHONE: {columnName: "PHONE"},
                ADDRESS_CITY: {columnName: "ADDRESS_CITY"},
                EMAIL: {columnName: "EMAIL"},
                ADDRESS_STATE: {columnName: "ADDRESS_STATE"},
                TELECOM: {columnName: "TELECOM"},
                NAME: {columnName: "NAME"},
                FAMILY: {columnName: "FAMILY"},
                ADDRESS_USE: {columnName: "ADDRESS_USE"},
                GIVEN: {columnName: "GIVEN"},
                ADDRESS: {columnName: "ADDRESS"},
                GENDER: {columnName: "GENDER"},
                PHONETIC: {columnName: "PHONETIC"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                COMMUNICATION: {columnName: "COMMUNICATION"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["PRACTITIONERTABLE_ID"]
        },
        [ACTIVITY_DEFINITION_TABLE]: {
            entityName: "ActivityDefinitionTable",
            tableName: "ActivityDefinitionTable",
            fieldMetadata: {
                ACTIVITYDEFINITIONTABLE_ID: {columnName: "ACTIVITYDEFINITIONTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                TOPIC: {columnName: "TOPIC"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["ACTIVITYDEFINITIONTABLE_ID"]
        },
        [EVIDENCE_TABLE]: {
            entityName: "EvidenceTable",
            tableName: "EvidenceTable",
            fieldMetadata: {
                EVIDENCETABLE_ID: {columnName: "EVIDENCETABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                TOPIC: {columnName: "TOPIC"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["EVIDENCETABLE_ID"]
        },
        [DEVICE_TABLE]: {
            entityName: "DeviceTable",
            tableName: "DeviceTable",
            fieldMetadata: {
                DEVICETABLE_ID: {columnName: "DEVICETABLE_ID"},
                STATUS: {columnName: "STATUS"},
                UDI_DI: {columnName: "UDI_DI"},
                UDI_CARRIER: {columnName: "UDI_CARRIER"},
                DEVICE_NAME: {columnName: "DEVICE_NAME"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                MODEL: {columnName: "MODEL"},
                MANUFACTURER: {columnName: "MANUFACTURER"},
                TYPE: {columnName: "TYPE"},
                URL: {columnName: "URL"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["DEVICETABLE_ID"]
        },
        [FAMILY_MEMBER_HISTORY_TABLE]: {
            entityName: "FamilyMemberHistoryTable",
            tableName: "FamilyMemberHistoryTable",
            fieldMetadata: {
                FAMILYMEMBERHISTORYTABLE_ID: {columnName: "FAMILYMEMBERHISTORYTABLE_ID"},
                DATE: {columnName: "DATE"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                INSTANTIATES_URI: {columnName: "INSTANTIATES_URI"},
                SEX: {columnName: "SEX"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                RELATIONSHIP: {columnName: "RELATIONSHIP"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["FAMILYMEMBERHISTORYTABLE_ID"]
        },
        [ADVERSE_EVENT_TABLE]: {
            entityName: "AdverseEventTable",
            tableName: "AdverseEventTable",
            fieldMetadata: {
                ADVERSEEVENTTABLE_ID: {columnName: "ADVERSEEVENTTABLE_ID"},
                DATE: {columnName: "DATE"},
                CATEGORY: {columnName: "CATEGORY"},
                SERIOUSNESS: {columnName: "SERIOUSNESS"},
                ACTUALITY: {columnName: "ACTUALITY"},
                SEVERITY: {columnName: "SEVERITY"},
                EVENT: {columnName: "EVENT"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["ADVERSEEVENTTABLE_ID"]
        },
        [SUPPLY_REQUEST_TABLE]: {
            entityName: "SupplyRequestTable",
            tableName: "SupplyRequestTable",
            fieldMetadata: {
                SUPPLYREQUESTTABLE_ID: {columnName: "SUPPLYREQUESTTABLE_ID"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                CATEGORY: {columnName: "CATEGORY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["SUPPLYREQUESTTABLE_ID"]
        },
        [EXAMPLE_SCENARIO_TABLE]: {
            entityName: "ExampleScenarioTable",
            tableName: "ExampleScenarioTable",
            fieldMetadata: {
                EXAMPLESCENARIOTABLE_ID: {columnName: "EXAMPLESCENARIOTABLE_ID"},
                DATE: {columnName: "DATE"},
                PUBLISHER: {columnName: "PUBLISHER"},
                STATUS: {columnName: "STATUS"},
                JURISDICTION: {columnName: "JURISDICTION"},
                VERSION: {columnName: "VERSION"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                NAME: {columnName: "NAME"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["EXAMPLESCENARIOTABLE_ID"]
        },
        [INVOICE_TABLE]: {
            entityName: "InvoiceTable",
            tableName: "InvoiceTable",
            fieldMetadata: {
                INVOICETABLE_ID: {columnName: "INVOICETABLE_ID"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                TOTALNET: {columnName: "TOTALNET"},
                PARTICIPANT_ROLE: {columnName: "PARTICIPANT_ROLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                TOTALGROSS: {columnName: "TOTALGROSS"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["INVOICETABLE_ID"]
        },
        [QUESTIONNAIRE_RESPONSE_TABLE]: {
            entityName: "QuestionnaireResponseTable",
            tableName: "QuestionnaireResponseTable",
            fieldMetadata: {
                QUESTIONNAIRERESPONSETABLE_ID: {columnName: "QUESTIONNAIRERESPONSETABLE_ID"},
                STATUS: {columnName: "STATUS"},
                AUTHORED: {columnName: "AUTHORED"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["QUESTIONNAIRERESPONSETABLE_ID"]
        },
        [OBSERVATION_TABLE]: {
            entityName: "ObservationTable",
            tableName: "ObservationTable",
            fieldMetadata: {
                OBSERVATIONTABLE_ID: {columnName: "OBSERVATIONTABLE_ID"},
                COMPONENT_CODE: {columnName: "COMPONENT_CODE"},
                VALUE_QUANTITY: {columnName: "VALUE_QUANTITY"},
                COMBO_CODE: {columnName: "COMBO_CODE"},
                VALUE_DATE: {columnName: "VALUE_DATE"},
                DATE: {columnName: "DATE"},
                VALUE_STRING: {columnName: "VALUE_STRING"},
                COMBO_DATA_ABSENT_REASON: {columnName: "COMBO_DATA_ABSENT_REASON"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                CATEGORY: {columnName: "CATEGORY"},
                COMBO_VALUE_QUANTITY: {columnName: "COMBO_VALUE_QUANTITY"},
                VALUE_CONCEPT: {columnName: "VALUE_CONCEPT"},
                METHOD: {columnName: "METHOD"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                COMPONENT_DATA_ABSENT_REASON: {columnName: "COMPONENT_DATA_ABSENT_REASON"},
                DATA_ABSENT_REASON: {columnName: "DATA_ABSENT_REASON"},
                COMPONENT_VALUE_QUANTITY: {columnName: "COMPONENT_VALUE_QUANTITY"},
                COMPONENT_VALUE_CONCEPT: {columnName: "COMPONENT_VALUE_CONCEPT"},
                COMBO_VALUE_CONCEPT: {columnName: "COMBO_VALUE_CONCEPT"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["OBSERVATIONTABLE_ID"]
        },
        [EFFECT_EVIDENCE_SYNTHESIS_TABLE]: {
            entityName: "EffectEvidenceSynthesisTable",
            tableName: "EffectEvidenceSynthesisTable",
            fieldMetadata: {
                EFFECTEVIDENCESYNTHESISTABLE_ID: {columnName: "EFFECTEVIDENCESYNTHESISTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["EFFECTEVIDENCESYNTHESISTABLE_ID"]
        },
        [OPERATION_DEFINITION_TABLE]: {
            entityName: "OperationDefinitionTable",
            tableName: "OperationDefinitionTable",
            fieldMetadata: {
                OPERATIONDEFINITIONTABLE_ID: {columnName: "OPERATIONDEFINITIONTABLE_ID"},
                SYSTEM: {columnName: "SYSTEM"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                INSTANCE: {columnName: "INSTANCE"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                KIND: {columnName: "KIND"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                TYPE: {columnName: "TYPE"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["OPERATIONDEFINITIONTABLE_ID"]
        },
        [MEASURE_REPORT_TABLE]: {
            entityName: "MeasureReportTable",
            tableName: "MeasureReportTable",
            fieldMetadata: {
                MEASUREREPORTTABLE_ID: {columnName: "MEASUREREPORTTABLE_ID"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                PERIOD: {columnName: "PERIOD"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEASUREREPORTTABLE_ID"]
        },
        [SUPPLY_DELIVERY_TABLE]: {
            entityName: "SupplyDeliveryTable",
            tableName: "SupplyDeliveryTable",
            fieldMetadata: {
                SUPPLYDELIVERYTABLE_ID: {columnName: "SUPPLYDELIVERYTABLE_ID"},
                STATUS: {columnName: "STATUS"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["SUPPLYDELIVERYTABLE_ID"]
        },
        [SERVICE_REQUEST_TABLE]: {
            entityName: "ServiceRequestTable",
            tableName: "ServiceRequestTable",
            fieldMetadata: {
                SERVICEREQUESTTABLE_ID: {columnName: "SERVICEREQUESTTABLE_ID"},
                REQUISITION: {columnName: "REQUISITION"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                OCCURRENCE: {columnName: "OCCURRENCE"},
                INSTANTIATES_URI: {columnName: "INSTANTIATES_URI"},
                PERFORMER_TYPE: {columnName: "PERFORMER_TYPE"},
                CATEGORY: {columnName: "CATEGORY"},
                INTENT: {columnName: "INTENT"},
                AUTHORED: {columnName: "AUTHORED"},
                PRIORITY: {columnName: "PRIORITY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                BODY_SITE: {columnName: "BODY_SITE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["SERVICEREQUESTTABLE_ID"]
        },
        [BASIC_TABLE]: {
            entityName: "BasicTable",
            tableName: "BasicTable",
            fieldMetadata: {
                BASICTABLE_ID: {columnName: "BASICTABLE_ID"},
                CODE: {columnName: "CODE"},
                CREATED: {columnName: "CREATED"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["BASICTABLE_ID"]
        },
        [SUBSCRIPTION_TABLE]: {
            entityName: "SubscriptionTable",
            tableName: "SubscriptionTable",
            fieldMetadata: {
                SUBSCRIPTIONTABLE_ID: {columnName: "SUBSCRIPTIONTABLE_ID"},
                CRITERIA: {columnName: "CRITERIA"},
                CONTACT: {columnName: "CONTACT"},
                STATUS: {columnName: "STATUS"},
                PAYLOAD: {columnName: "PAYLOAD"},
                TYPE: {columnName: "TYPE"},
                URL: {columnName: "URL"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["SUBSCRIPTIONTABLE_ID"]
        },
        [ENROLLMENT_RESPONSE_TABLE]: {
            entityName: "EnrollmentResponseTable",
            tableName: "EnrollmentResponseTable",
            fieldMetadata: {
                ENROLLMENTRESPONSETABLE_ID: {columnName: "ENROLLMENTRESPONSETABLE_ID"},
                STATUS: {columnName: "STATUS"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["ENROLLMENTRESPONSETABLE_ID"]
        },
        [DEVICE_REQUEST_TABLE]: {
            entityName: "DeviceRequestTable",
            tableName: "DeviceRequestTable",
            fieldMetadata: {
                DEVICEREQUESTTABLE_ID: {columnName: "DEVICEREQUESTTABLE_ID"},
                CODE: {columnName: "CODE"},
                EVENT_DATE: {columnName: "EVENT_DATE"},
                STATUS: {columnName: "STATUS"},
                INSTANTIATES_URI: {columnName: "INSTANTIATES_URI"},
                AUTHORED_ON: {columnName: "AUTHORED_ON"},
                INTENT: {columnName: "INTENT"},
                GROUP_IDENTIFIER: {columnName: "GROUP_IDENTIFIER"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["DEVICEREQUESTTABLE_ID"]
        },
        [APPOINTMENT_TABLE]: {
            entityName: "AppointmentTable",
            tableName: "AppointmentTable",
            fieldMetadata: {
                APPOINTMENTTABLE_ID: {columnName: "APPOINTMENTTABLE_ID"},
                DATE: {columnName: "DATE"},
                SERVICE_CATEGORY: {columnName: "SERVICE_CATEGORY"},
                PART_STATUS: {columnName: "PART_STATUS"},
                STATUS: {columnName: "STATUS"},
                APPOINTMENT_TYPE: {columnName: "APPOINTMENT_TYPE"},
                REASON_CODE: {columnName: "REASON_CODE"},
                SPECIALTY: {columnName: "SPECIALTY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                SERVICE_TYPE: {columnName: "SERVICE_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["APPOINTMENTTABLE_ID"]
        },
        [NAMING_SYSTEM_TABLE]: {
            entityName: "NamingSystemTable",
            tableName: "NamingSystemTable",
            fieldMetadata: {
                NAMINGSYSTEMTABLE_ID: {columnName: "NAMINGSYSTEMTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                RESPONSIBLE: {columnName: "RESPONSIBLE"},
                CONTACT: {columnName: "CONTACT"},
                JURISDICTION: {columnName: "JURISDICTION"},
                VALUE: {columnName: "VALUE"},
                ID_TYPE: {columnName: "ID_TYPE"},
                CONTEXT: {columnName: "CONTEXT"},
                TELECOM: {columnName: "TELECOM"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                PERIOD: {columnName: "PERIOD"},
                KIND: {columnName: "KIND"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                TYPE: {columnName: "TYPE"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["NAMINGSYSTEMTABLE_ID"]
        },
        [STRUCTURE_DEFINITION_TABLE]: {
            entityName: "StructureDefinitionTable",
            tableName: "StructureDefinitionTable",
            fieldMetadata: {
                STRUCTUREDEFINITIONTABLE_ID: {columnName: "STRUCTUREDEFINITIONTABLE_ID"},
                PATH: {columnName: "PATH"},
                DERIVATION: {columnName: "DERIVATION"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                BASE_PATH: {columnName: "BASE_PATH"},
                EXPERIMENTAL: {columnName: "EXPERIMENTAL"},
                KEYWORD: {columnName: "KEYWORD"},
                CONTEXT: {columnName: "CONTEXT"},
                ABSTRACT: {columnName: "ABSTRACT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                KIND: {columnName: "KIND"},
                VERSION: {columnName: "VERSION"},
                EXT_CONTEXT: {columnName: "EXT_CONTEXT"},
                TITLE: {columnName: "TITLE"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["STRUCTUREDEFINITIONTABLE_ID"]
        },
        [CLINICAL_IMPRESSION_TABLE]: {
            entityName: "ClinicalImpressionTable",
            tableName: "ClinicalImpressionTable",
            fieldMetadata: {
                CLINICALIMPRESSIONTABLE_ID: {columnName: "CLINICALIMPRESSIONTABLE_ID"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                FINDING_CODE: {columnName: "FINDING_CODE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["CLINICALIMPRESSIONTABLE_ID"]
        },
        [COMMUNICATION_TABLE]: {
            entityName: "CommunicationTable",
            tableName: "CommunicationTable",
            fieldMetadata: {
                COMMUNICATIONTABLE_ID: {columnName: "COMMUNICATIONTABLE_ID"},
                RECEIVED: {columnName: "RECEIVED"},
                STATUS: {columnName: "STATUS"},
                MEDIUM: {columnName: "MEDIUM"},
                INSTANTIATES_URI: {columnName: "INSTANTIATES_URI"},
                CATEGORY: {columnName: "CATEGORY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                SENT: {columnName: "SENT"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["COMMUNICATIONTABLE_ID"]
        },
        [ORGANIZATION_TABLE]: {
            entityName: "OrganizationTable",
            tableName: "OrganizationTable",
            fieldMetadata: {
                ORGANIZATIONTABLE_ID: {columnName: "ORGANIZATIONTABLE_ID"},
                ADDRESS_COUNTRY: {columnName: "ADDRESS_COUNTRY"},
                ADDRESS_POSTALCODE: {columnName: "ADDRESS_POSTALCODE"},
                ADDRESS_USE: {columnName: "ADDRESS_USE"},
                ACTIVE: {columnName: "ACTIVE"},
                ADDRESS: {columnName: "ADDRESS"},
                PHONETIC: {columnName: "PHONETIC"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                ADDRESS_CITY: {columnName: "ADDRESS_CITY"},
                TYPE: {columnName: "TYPE"},
                ADDRESS_STATE: {columnName: "ADDRESS_STATE"},
                NAME: {columnName: "NAME"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["ORGANIZATIONTABLE_ID"]
        },
        [COVERAGE_ELIGIBILITY_RESPONSE_TABLE]: {
            entityName: "CoverageEligibilityResponseTable",
            tableName: "CoverageEligibilityResponseTable",
            fieldMetadata: {
                COVERAGEELIGIBILITYRESPONSETABLE_ID: {columnName: "COVERAGEELIGIBILITYRESPONSETABLE_ID"},
                CREATED: {columnName: "CREATED"},
                STATUS: {columnName: "STATUS"},
                OUTCOME: {columnName: "OUTCOME"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                DISPOSITION: {columnName: "DISPOSITION"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["COVERAGEELIGIBILITYRESPONSETABLE_ID"]
        },
        [RESEARCH_STUDY_TABLE]: {
            entityName: "ResearchStudyTable",
            tableName: "ResearchStudyTable",
            fieldMetadata: {
                RESEARCHSTUDYTABLE_ID: {columnName: "RESEARCHSTUDYTABLE_ID"},
                LOCATION: {columnName: "LOCATION"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                CATEGORY: {columnName: "CATEGORY"},
                FOCUS: {columnName: "FOCUS"},
                KEYWORD: {columnName: "KEYWORD"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["RESEARCHSTUDYTABLE_ID"]
        },
        [BUNDLE_TABLE]: {
            entityName: "BundleTable",
            tableName: "BundleTable",
            fieldMetadata: {
                BUNDLETABLE_ID: {columnName: "BUNDLETABLE_ID"},
                TIMESTAMP: {columnName: "TIMESTAMP"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["BUNDLETABLE_ID"]
        },
        [ENCOUNTER_TABLE]: {
            entityName: "EncounterTable",
            tableName: "EncounterTable",
            fieldMetadata: {
                ENCOUNTERTABLE_ID: {columnName: "ENCOUNTERTABLE_ID"},
                PARTICIPANT_TYPE: {columnName: "PARTICIPANT_TYPE"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                LENGTH: {columnName: "LENGTH"},
                REASON_CODE: {columnName: "REASON_CODE"},
                SPECIAL_ARRANGEMENT: {columnName: "SPECIAL_ARRANGEMENT"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CLASS: {columnName: "CLASS"},
                TYPE: {columnName: "TYPE"},
                LOCATION_PERIOD: {columnName: "LOCATION_PERIOD"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["ENCOUNTERTABLE_ID"]
        },
        [RISK_ASSESSMENT_TABLE]: {
            entityName: "RiskAssessmentTable",
            tableName: "RiskAssessmentTable",
            fieldMetadata: {
                RISKASSESSMENTTABLE_ID: {columnName: "RISKASSESSMENTTABLE_ID"},
                DATE: {columnName: "DATE"},
                PROBABILITY: {columnName: "PROBABILITY"},
                METHOD: {columnName: "METHOD"},
                RISK: {columnName: "RISK"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["RISKASSESSMENTTABLE_ID"]
        },
        [LIST_TABLE]: {
            entityName: "ListTable",
            tableName: "ListTable",
            fieldMetadata: {
                LISTTABLE_ID: {columnName: "LISTTABLE_ID"},
                DATE: {columnName: "DATE"},
                NOTES: {columnName: "NOTES"},
                EMPTY_REASON: {columnName: "EMPTY_REASON"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["LISTTABLE_ID"]
        },
        [ORGANIZATION_AFFILIATION_TABLE]: {
            entityName: "OrganizationAffiliationTable",
            tableName: "OrganizationAffiliationTable",
            fieldMetadata: {
                ORGANIZATIONAFFILIATIONTABLE_ID: {columnName: "ORGANIZATIONAFFILIATIONTABLE_ID"},
                ROLE: {columnName: "ROLE"},
                DATE: {columnName: "DATE"},
                ACTIVE: {columnName: "ACTIVE"},
                PHONE: {columnName: "PHONE"},
                SPECIALTY: {columnName: "SPECIALTY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                EMAIL: {columnName: "EMAIL"},
                TELECOM: {columnName: "TELECOM"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["ORGANIZATIONAFFILIATIONTABLE_ID"]
        },
        [CHARGE_ITEM_TABLE]: {
            entityName: "ChargeItemTable",
            tableName: "ChargeItemTable",
            fieldMetadata: {
                CHARGEITEMTABLE_ID: {columnName: "CHARGEITEMTABLE_ID"},
                CODE: {columnName: "CODE"},
                FACTOR_OVERRIDE: {columnName: "FACTOR_OVERRIDE"},
                QUANTITY: {columnName: "QUANTITY"},
                OCCURRENCE: {columnName: "OCCURRENCE"},
                PRICE_OVERRIDE: {columnName: "PRICE_OVERRIDE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                ENTERED_DATE: {columnName: "ENTERED_DATE"},
                PERFORMER_FUNCTION: {columnName: "PERFORMER_FUNCTION"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["CHARGEITEMTABLE_ID"]
        },
        [MEDICATION_KNOWLEDGE_TABLE]: {
            entityName: "MedicationKnowledgeTable",
            tableName: "MedicationKnowledgeTable",
            fieldMetadata: {
                MEDICATIONKNOWLEDGETABLE_ID: {columnName: "MEDICATIONKNOWLEDGETABLE_ID"},
                CODE: {columnName: "CODE"},
                SOURCE_COST: {columnName: "SOURCE_COST"},
                STATUS: {columnName: "STATUS"},
                MONITORING_PROGRAM_NAME: {columnName: "MONITORING_PROGRAM_NAME"},
                CLASSIFICATION_TYPE: {columnName: "CLASSIFICATION_TYPE"},
                CLASSIFICATION: {columnName: "CLASSIFICATION"},
                DOSEFORM: {columnName: "DOSEFORM"},
                MONOGRAPH_TYPE: {columnName: "MONOGRAPH_TYPE"},
                MONITORING_PROGRAM_TYPE: {columnName: "MONITORING_PROGRAM_TYPE"},
                INGREDIENT_CODE: {columnName: "INGREDIENT_CODE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICATIONKNOWLEDGETABLE_ID"]
        },
        [PLAN_DEFINITION_TABLE]: {
            entityName: "PlanDefinitionTable",
            tableName: "PlanDefinitionTable",
            fieldMetadata: {
                PLANDEFINITIONTABLE_ID: {columnName: "PLANDEFINITIONTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                TOPIC: {columnName: "TOPIC"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                TYPE: {columnName: "TYPE"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["PLANDEFINITIONTABLE_ID"]
        },
        [CARE_PLAN_TABLE]: {
            entityName: "CarePlanTable",
            tableName: "CarePlanTable",
            fieldMetadata: {
                CAREPLANTABLE_ID: {columnName: "CAREPLANTABLE_ID"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                INSTANTIATES_URI: {columnName: "INSTANTIATES_URI"},
                CATEGORY: {columnName: "CATEGORY"},
                INTENT: {columnName: "INTENT"},
                ACTIVITY_DATE: {columnName: "ACTIVITY_DATE"},
                ACTIVITY_CODE: {columnName: "ACTIVITY_CODE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["CAREPLANTABLE_ID"]
        },
        [VISION_PRESCRIPTION_TABLE]: {
            entityName: "VisionPrescriptionTable",
            tableName: "VisionPrescriptionTable",
            fieldMetadata: {
                VISIONPRESCRIPTIONTABLE_ID: {columnName: "VISIONPRESCRIPTIONTABLE_ID"},
                STATUS: {columnName: "STATUS"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                DATEWRITTEN: {columnName: "DATEWRITTEN"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["VISIONPRESCRIPTIONTABLE_ID"]
        },
        [EPISODE_OF_CARE_TABLE]: {
            entityName: "EpisodeOfCareTable",
            tableName: "EpisodeOfCareTable",
            fieldMetadata: {
                EPISODEOFCARETABLE_ID: {columnName: "EPISODEOFCARETABLE_ID"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["EPISODEOFCARETABLE_ID"]
        },
        [CARE_TEAM_TABLE]: {
            entityName: "CareTeamTable",
            tableName: "CareTeamTable",
            fieldMetadata: {
                CARETEAMTABLE_ID: {columnName: "CARETEAMTABLE_ID"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                CATEGORY: {columnName: "CATEGORY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["CARETEAMTABLE_ID"]
        },
        [MEDICATION_ADMINISTRATION_TABLE]: {
            entityName: "MedicationAdministrationTable",
            tableName: "MedicationAdministrationTable",
            fieldMetadata: {
                MEDICATIONADMINISTRATIONTABLE_ID: {columnName: "MEDICATIONADMINISTRATIONTABLE_ID"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                REASON_NOT_GIVEN: {columnName: "REASON_NOT_GIVEN"},
                EFFECTIVE_TIME: {columnName: "EFFECTIVE_TIME"},
                REASON_GIVEN: {columnName: "REASON_GIVEN"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICATIONADMINISTRATIONTABLE_ID"]
        },
        [CONSENT_TABLE]: {
            entityName: "ConsentTable",
            tableName: "ConsentTable",
            fieldMetadata: {
                CONSENTTABLE_ID: {columnName: "CONSENTTABLE_ID"},
                DATE: {columnName: "DATE"},
                SECURITY_LABEL: {columnName: "SECURITY_LABEL"},
                STATUS: {columnName: "STATUS"},
                ACTION: {columnName: "ACTION"},
                SCOPE: {columnName: "SCOPE"},
                CATEGORY: {columnName: "CATEGORY"},
                PERIOD: {columnName: "PERIOD"},
                PURPOSE: {columnName: "PURPOSE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["CONSENTTABLE_ID"]
        },
        [DETECTED_ISSUE_TABLE]: {
            entityName: "DetectedIssueTable",
            tableName: "DetectedIssueTable",
            fieldMetadata: {
                DETECTEDISSUETABLE_ID: {columnName: "DETECTEDISSUETABLE_ID"},
                CODE: {columnName: "CODE"},
                IDENTIFIED: {columnName: "IDENTIFIED"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["DETECTEDISSUETABLE_ID"]
        },
        [SUBSTANCE_SPECIFICATION_TABLE]: {
            entityName: "SubstanceSpecificationTable",
            tableName: "SubstanceSpecificationTable",
            fieldMetadata: {
                SUBSTANCESPECIFICATIONTABLE_ID: {columnName: "SUBSTANCESPECIFICATIONTABLE_ID"},
                CODE: {columnName: "CODE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["SUBSTANCESPECIFICATIONTABLE_ID"]
        },
        [ALLERGY_INTOLERANCE_TABLE]: {
            entityName: "AllergyIntoleranceTable",
            tableName: "AllergyIntoleranceTable",
            fieldMetadata: {
                ALLERGYINTOLERANCETABLE_ID: {columnName: "ALLERGYINTOLERANCETABLE_ID"},
                ROUTE: {columnName: "ROUTE"},
                LAST_DATE: {columnName: "LAST_DATE"},
                MANIFESTATION: {columnName: "MANIFESTATION"},
                CLINICAL_STATUS: {columnName: "CLINICAL_STATUS"},
                VERIFICATION_STATUS: {columnName: "VERIFICATION_STATUS"},
                DATE: {columnName: "DATE"},
                CODE: {columnName: "CODE"},
                CRITICALITY: {columnName: "CRITICALITY"},
                CATEGORY: {columnName: "CATEGORY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                SEVERITY: {columnName: "SEVERITY"},
                ONSET: {columnName: "ONSET"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["ALLERGYINTOLERANCETABLE_ID"]
        },
        [MEDICINAL_PRODUCT_INDICATION_TABLE]: {
            entityName: "MedicinalProductIndicationTable",
            tableName: "MedicinalProductIndicationTable",
            fieldMetadata: {
                MEDICINALPRODUCTINDICATIONTABLE_ID: {columnName: "MEDICINALPRODUCTINDICATIONTABLE_ID"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICINALPRODUCTINDICATIONTABLE_ID"]
        },
        [MEDICINAL_PRODUCT_PHARMACEUTICAL_TABLE]: {
            entityName: "MedicinalProductPharmaceuticalTable",
            tableName: "MedicinalProductPharmaceuticalTable",
            fieldMetadata: {
                MEDICINALPRODUCTPHARMACEUTICALTABLE_ID: {columnName: "MEDICINALPRODUCTPHARMACEUTICALTABLE_ID"},
                ROUTE: {columnName: "ROUTE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TARGET_SPECIES: {columnName: "TARGET_SPECIES"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICINALPRODUCTPHARMACEUTICALTABLE_ID"]
        },
        [SLOT_TABLE]: {
            entityName: "SlotTable",
            tableName: "SlotTable",
            fieldMetadata: {
                SLOTTABLE_ID: {columnName: "SLOTTABLE_ID"},
                SERVICE_CATEGORY: {columnName: "SERVICE_CATEGORY"},
                STATUS: {columnName: "STATUS"},
                APPOINTMENT_TYPE: {columnName: "APPOINTMENT_TYPE"},
                SPECIALTY: {columnName: "SPECIALTY"},
                START: {columnName: "START"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                SERVICE_TYPE: {columnName: "SERVICE_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["SLOTTABLE_ID"]
        },
        [VERIFICATION_RESULT_TABLE]: {
            entityName: "VerificationResultTable",
            tableName: "VerificationResultTable",
            fieldMetadata: {
                VERIFICATIONRESULTTABLE_ID: {columnName: "VERIFICATIONRESULTTABLE_ID"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["VERIFICATIONRESULTTABLE_ID"]
        },
        [SPECIMEN_TABLE]: {
            entityName: "SpecimenTable",
            tableName: "SpecimenTable",
            fieldMetadata: {
                SPECIMENTABLE_ID: {columnName: "SPECIMENTABLE_ID"},
                COLLECTED: {columnName: "COLLECTED"},
                STATUS: {columnName: "STATUS"},
                ACCESSION: {columnName: "ACCESSION"},
                CONTAINER: {columnName: "CONTAINER"},
                BODYSITE: {columnName: "BODYSITE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                CONTAINER_ID: {columnName: "CONTAINER_ID"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["SPECIMENTABLE_ID"]
        },
        [RESEARCH_SUBJECT_TABLE]: {
            entityName: "ResearchSubjectTable",
            tableName: "ResearchSubjectTable",
            fieldMetadata: {
                RESEARCHSUBJECTTABLE_ID: {columnName: "RESEARCHSUBJECTTABLE_ID"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["RESEARCHSUBJECTTABLE_ID"]
        },
        [MEDICATION_TABLE]: {
            entityName: "MedicationTable",
            tableName: "MedicationTable",
            fieldMetadata: {
                MEDICATIONTABLE_ID: {columnName: "MEDICATIONTABLE_ID"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                EXPIRATION_DATE: {columnName: "EXPIRATION_DATE"},
                FORM: {columnName: "FORM"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                LOT_NUMBER: {columnName: "LOT_NUMBER"},
                INGREDIENT_CODE: {columnName: "INGREDIENT_CODE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICATIONTABLE_ID"]
        },
        [RESEARCH_DEFINITION_TABLE]: {
            entityName: "ResearchDefinitionTable",
            tableName: "ResearchDefinitionTable",
            fieldMetadata: {
                RESEARCHDEFINITIONTABLE_ID: {columnName: "RESEARCHDEFINITIONTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                TOPIC: {columnName: "TOPIC"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["RESEARCHDEFINITIONTABLE_ID"]
        },
        [HEALTHCARE_SERVICE_TABLE]: {
            entityName: "HealthcareServiceTable",
            tableName: "HealthcareServiceTable",
            fieldMetadata: {
                HEALTHCARESERVICETABLE_ID: {columnName: "HEALTHCARESERVICETABLE_ID"},
                SERVICE_CATEGORY: {columnName: "SERVICE_CATEGORY"},
                CHARACTERISTIC: {columnName: "CHARACTERISTIC"},
                ACTIVE: {columnName: "ACTIVE"},
                SPECIALTY: {columnName: "SPECIALTY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                SERVICE_TYPE: {columnName: "SERVICE_TYPE"},
                PROGRAM: {columnName: "PROGRAM"},
                NAME: {columnName: "NAME"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["HEALTHCARESERVICETABLE_ID"]
        },
        [PAYMENT_NOTICE_TABLE]: {
            entityName: "PaymentNoticeTable",
            tableName: "PaymentNoticeTable",
            fieldMetadata: {
                PAYMENTNOTICETABLE_ID: {columnName: "PAYMENTNOTICETABLE_ID"},
                CREATED: {columnName: "CREATED"},
                STATUS: {columnName: "STATUS"},
                PAYMENT_STATUS: {columnName: "PAYMENT_STATUS"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["PAYMENTNOTICETABLE_ID"]
        },
        [PROVENANCE_TABLE]: {
            entityName: "ProvenanceTable",
            tableName: "ProvenanceTable",
            fieldMetadata: {
                PROVENANCETABLE_ID: {columnName: "PROVENANCETABLE_ID"},
                RECORDED: {columnName: "RECORDED"},
                WHEN: {columnName: "WHEN"},
                AGENT_TYPE: {columnName: "AGENT_TYPE"},
                SIGNATURE_TYPE: {columnName: "SIGNATURE_TYPE"},
                AGENT_ROLE: {columnName: "AGENT_ROLE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["PROVENANCETABLE_ID"]
        },
        [GRAPH_DEFINITION_TABLE]: {
            entityName: "GraphDefinitionTable",
            tableName: "GraphDefinitionTable",
            fieldMetadata: {
                GRAPHDEFINITIONTABLE_ID: {columnName: "GRAPHDEFINITIONTABLE_ID"},
                DATE: {columnName: "DATE"},
                PUBLISHER: {columnName: "PUBLISHER"},
                STATUS: {columnName: "STATUS"},
                JURISDICTION: {columnName: "JURISDICTION"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                START: {columnName: "START"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                NAME: {columnName: "NAME"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["GRAPHDEFINITIONTABLE_ID"]
        },
        [MEDIA_TABLE]: {
            entityName: "MediaTable",
            tableName: "MediaTable",
            fieldMetadata: {
                MEDIATABLE_ID: {columnName: "MEDIATABLE_ID"},
                SITE: {columnName: "SITE"},
                CREATED: {columnName: "CREATED"},
                STATUS: {columnName: "STATUS"},
                MODALITY: {columnName: "MODALITY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                VIEW: {columnName: "VIEW"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDIATABLE_ID"]
        },
        [BODY_STRUCTURE_TABLE]: {
            entityName: "BodyStructureTable",
            tableName: "BodyStructureTable",
            fieldMetadata: {
                BODYSTRUCTURETABLE_ID: {columnName: "BODYSTRUCTURETABLE_ID"},
                LOCATION: {columnName: "LOCATION"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                MORPHOLOGY: {columnName: "MORPHOLOGY"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["BODYSTRUCTURETABLE_ID"]
        },
        [DIAGNOSTIC_REPORT_TABLE]: {
            entityName: "DiagnosticReportTable",
            tableName: "DiagnosticReportTable",
            fieldMetadata: {
                DIAGNOSTICREPORTTABLE_ID: {columnName: "DIAGNOSTICREPORTTABLE_ID"},
                DATE: {columnName: "DATE"},
                ISSUED: {columnName: "ISSUED"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                CATEGORY: {columnName: "CATEGORY"},
                CONCLUSION: {columnName: "CONCLUSION"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["DIAGNOSTICREPORTTABLE_ID"]
        },
        [GOAL_TABLE]: {
            entityName: "GoalTable",
            tableName: "GoalTable",
            fieldMetadata: {
                GOALTABLE_ID: {columnName: "GOALTABLE_ID"},
                TARGET_DATE: {columnName: "TARGET_DATE"},
                ACHIEVEMENT_STATUS: {columnName: "ACHIEVEMENT_STATUS"},
                CATEGORY: {columnName: "CATEGORY"},
                LIFECYCLE_STATUS: {columnName: "LIFECYCLE_STATUS"},
                START_DATE: {columnName: "START_DATE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["GOALTABLE_ID"]
        },
        [CAPABILITY_STATEMENT_TABLE]: {
            entityName: "CapabilityStatementTable",
            tableName: "CapabilityStatementTable",
            fieldMetadata: {
                CAPABILITYSTATEMENTTABLE_ID: {columnName: "CAPABILITYSTATEMENTTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                FORMAT: {columnName: "FORMAT"},
                MODE: {columnName: "MODE"},
                SECURITY_SERVICE: {columnName: "SECURITY_SERVICE"},
                CONTEXT: {columnName: "CONTEXT"},
                SOFTWARE: {columnName: "SOFTWARE"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                FHIRVERSION: {columnName: "FHIRVERSION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                RESOURCE: {columnName: "RESOURCE"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["CAPABILITYSTATEMENTTABLE_ID"]
        },
        [DEVICE_USE_STATEMENT_TABLE]: {
            entityName: "DeviceUseStatementTable",
            tableName: "DeviceUseStatementTable",
            fieldMetadata: {
                DEVICEUSESTATEMENTTABLE_ID: {columnName: "DEVICEUSESTATEMENTTABLE_ID"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["DEVICEUSESTATEMENTTABLE_ID"]
        },
        [SCHEDULE_TABLE]: {
            entityName: "ScheduleTable",
            tableName: "ScheduleTable",
            fieldMetadata: {
                SCHEDULETABLE_ID: {columnName: "SCHEDULETABLE_ID"},
                DATE: {columnName: "DATE"},
                SERVICE_CATEGORY: {columnName: "SERVICE_CATEGORY"},
                ACTIVE: {columnName: "ACTIVE"},
                SPECIALTY: {columnName: "SPECIALTY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                SERVICE_TYPE: {columnName: "SERVICE_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["SCHEDULETABLE_ID"]
        },
        [MEDICINAL_PRODUCT_PACKAGED_TABLE]: {
            entityName: "MedicinalProductPackagedTable",
            tableName: "MedicinalProductPackagedTable",
            fieldMetadata: {
                MEDICINALPRODUCTPACKAGEDTABLE_ID: {columnName: "MEDICINALPRODUCTPACKAGEDTABLE_ID"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICINALPRODUCTPACKAGEDTABLE_ID"]
        },
        [PROCEDURE_TABLE]: {
            entityName: "ProcedureTable",
            tableName: "ProcedureTable",
            fieldMetadata: {
                PROCEDURETABLE_ID: {columnName: "PROCEDURETABLE_ID"},
                DATE: {columnName: "DATE"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                INSTANTIATES_URI: {columnName: "INSTANTIATES_URI"},
                CATEGORY: {columnName: "CATEGORY"},
                REASON_CODE: {columnName: "REASON_CODE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["PROCEDURETABLE_ID"]
        },
        [LIBRARY_TABLE]: {
            entityName: "LibraryTable",
            tableName: "LibraryTable",
            fieldMetadata: {
                LIBRARYTABLE_ID: {columnName: "LIBRARYTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                TOPIC: {columnName: "TOPIC"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                CONTENT_TYPE: {columnName: "CONTENT_TYPE"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                TYPE: {columnName: "TYPE"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["LIBRARYTABLE_ID"]
        },
        [CODE_SYSTEM_TABLE]: {
            entityName: "CodeSystemTable",
            tableName: "CodeSystemTable",
            fieldMetadata: {
                CODESYSTEMTABLE_ID: {columnName: "CODESYSTEMTABLE_ID"},
                LANGUAGE: {columnName: "LANGUAGE"},
                SYSTEM: {columnName: "SYSTEM"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                CONTENT_MODE: {columnName: "CONTENT_MODE"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["CODESYSTEMTABLE_ID"]
        },
        [COMMUNICATION_REQUEST_TABLE]: {
            entityName: "CommunicationRequestTable",
            tableName: "CommunicationRequestTable",
            fieldMetadata: {
                COMMUNICATIONREQUESTTABLE_ID: {columnName: "COMMUNICATIONREQUESTTABLE_ID"},
                STATUS: {columnName: "STATUS"},
                MEDIUM: {columnName: "MEDIUM"},
                OCCURRENCE: {columnName: "OCCURRENCE"},
                CATEGORY: {columnName: "CATEGORY"},
                AUTHORED: {columnName: "AUTHORED"},
                PRIORITY: {columnName: "PRIORITY"},
                GROUP_IDENTIFIER: {columnName: "GROUP_IDENTIFIER"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["COMMUNICATIONREQUESTTABLE_ID"]
        },
        [DOCUMENT_REFERENCE_TABLE]: {
            entityName: "DocumentReferenceTable",
            tableName: "DocumentReferenceTable",
            fieldMetadata: {
                DOCUMENTREFERENCETABLE_ID: {columnName: "DOCUMENTREFERENCETABLE_ID"},
                LANGUAGE: {columnName: "LANGUAGE"},
                LOCATION: {columnName: "LOCATION"},
                CONTENTTYPE: {columnName: "CONTENTTYPE"},
                RELATION: {columnName: "RELATION"},
                FORMAT: {columnName: "FORMAT"},
                FACILITY: {columnName: "FACILITY"},
                EVENT: {columnName: "EVENT"},
                DATE: {columnName: "DATE"},
                SECURITY_LABEL: {columnName: "SECURITY_LABEL"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                CATEGORY: {columnName: "CATEGORY"},
                PERIOD: {columnName: "PERIOD"},
                SETTING: {columnName: "SETTING"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["DOCUMENTREFERENCETABLE_ID"]
        },
        [REQUEST_GROUP_TABLE]: {
            entityName: "RequestGroupTable",
            tableName: "RequestGroupTable",
            fieldMetadata: {
                REQUESTGROUPTABLE_ID: {columnName: "REQUESTGROUPTABLE_ID"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                INSTANTIATES_URI: {columnName: "INSTANTIATES_URI"},
                INTENT: {columnName: "INTENT"},
                AUTHORED: {columnName: "AUTHORED"},
                PRIORITY: {columnName: "PRIORITY"},
                GROUP_IDENTIFIER: {columnName: "GROUP_IDENTIFIER"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["REQUESTGROUPTABLE_ID"]
        },
        [CLAIM_TABLE]: {
            entityName: "ClaimTable",
            tableName: "ClaimTable",
            fieldMetadata: {
                CLAIMTABLE_ID: {columnName: "CLAIMTABLE_ID"},
                CREATED: {columnName: "CREATED"},
                STATUS: {columnName: "STATUS"},
                USE: {columnName: "USE"},
                PRIORITY: {columnName: "PRIORITY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["CLAIMTABLE_ID"]
        },
        [MESSAGE_DEFINITION_TABLE]: {
            entityName: "MessageDefinitionTable",
            tableName: "MessageDefinitionTable",
            fieldMetadata: {
                MESSAGEDEFINITIONTABLE_ID: {columnName: "MESSAGEDEFINITIONTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                FOCUS: {columnName: "FOCUS"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                EVENT: {columnName: "EVENT"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                CATEGORY: {columnName: "CATEGORY"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MESSAGEDEFINITIONTABLE_ID"]
        },
        [RISK_EVIDENCE_SYNTHESIS_TABLE]: {
            entityName: "RiskEvidenceSynthesisTable",
            tableName: "RiskEvidenceSynthesisTable",
            fieldMetadata: {
                RISKEVIDENCESYNTHESISTABLE_ID: {columnName: "RISKEVIDENCESYNTHESISTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["RISKEVIDENCESYNTHESISTABLE_ID"]
        },
        [TASK_TABLE]: {
            entityName: "TaskTable",
            tableName: "TaskTable",
            fieldMetadata: {
                TASKTABLE_ID: {columnName: "TASKTABLE_ID"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                BUSINESS_STATUS: {columnName: "BUSINESS_STATUS"},
                PERIOD: {columnName: "PERIOD"},
                AUTHORED_ON: {columnName: "AUTHORED_ON"},
                INTENT: {columnName: "INTENT"},
                PRIORITY: {columnName: "PRIORITY"},
                GROUP_IDENTIFIER: {columnName: "GROUP_IDENTIFIER"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                PERFORMER: {columnName: "PERFORMER"},
                MODIFIED: {columnName: "MODIFIED"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["TASKTABLE_ID"]
        },
        [IMPLEMENTATION_GUIDE_TABLE]: {
            entityName: "ImplementationGuideTable",
            tableName: "ImplementationGuideTable",
            fieldMetadata: {
                IMPLEMENTATIONGUIDETABLE_ID: {columnName: "IMPLEMENTATIONGUIDETABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                EXPERIMENTAL: {columnName: "EXPERIMENTAL"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["IMPLEMENTATIONGUIDETABLE_ID"]
        },
        [STRUCTURE_MAP_TABLE]: {
            entityName: "StructureMapTable",
            tableName: "StructureMapTable",
            fieldMetadata: {
                STRUCTUREMAPTABLE_ID: {columnName: "STRUCTUREMAPTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["STRUCTUREMAPTABLE_ID"]
        },
        [MEDICINAL_PRODUCT_UNDESIRABLE_EFFECT_TABLE]: {
            entityName: "MedicinalProductUndesirableEffectTable",
            tableName: "MedicinalProductUndesirableEffectTable",
            fieldMetadata: {
                MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID: {columnName: "MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID"]
        },
        [COMPARTMENT_DEFINITION_TABLE]: {
            entityName: "CompartmentDefinitionTable",
            tableName: "CompartmentDefinitionTable",
            fieldMetadata: {
                COMPARTMENTDEFINITIONTABLE_ID: {columnName: "COMPARTMENTDEFINITIONTABLE_ID"},
                DATE: {columnName: "DATE"},
                PUBLISHER: {columnName: "PUBLISHER"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                RESOURCE: {columnName: "RESOURCE"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                NAME: {columnName: "NAME"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["COMPARTMENTDEFINITIONTABLE_ID"]
        },
        [ENDPOINT_TABLE]: {
            entityName: "EndpointTable",
            tableName: "EndpointTable",
            fieldMetadata: {
                ENDPOINTTABLE_ID: {columnName: "ENDPOINTTABLE_ID"},
                CONNECTION_TYPE: {columnName: "CONNECTION_TYPE"},
                STATUS: {columnName: "STATUS"},
                PAYLOAD_TYPE: {columnName: "PAYLOAD_TYPE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                NAME: {columnName: "NAME"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["ENDPOINTTABLE_ID"]
        },
        [TERMINOLOGY_CAPABILITIES_TABLE]: {
            entityName: "TerminologyCapabilitiesTable",
            tableName: "TerminologyCapabilitiesTable",
            fieldMetadata: {
                TERMINOLOGYCAPABILITIESTABLE_ID: {columnName: "TERMINOLOGYCAPABILITIESTABLE_ID"},
                DATE: {columnName: "DATE"},
                PUBLISHER: {columnName: "PUBLISHER"},
                STATUS: {columnName: "STATUS"},
                JURISDICTION: {columnName: "JURISDICTION"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                NAME: {columnName: "NAME"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["TERMINOLOGYCAPABILITIESTABLE_ID"]
        },
        [CONDITION_TABLE]: {
            entityName: "ConditionTable",
            tableName: "ConditionTable",
            fieldMetadata: {
                CONDITIONTABLE_ID: {columnName: "CONDITIONTABLE_ID"},
                CLINICAL_STATUS: {columnName: "CLINICAL_STATUS"},
                STAGE: {columnName: "STAGE"},
                ONSET_AGE: {columnName: "ONSET_AGE"},
                ONSET_INFO: {columnName: "ONSET_INFO"},
                EVIDENCE: {columnName: "EVIDENCE"},
                ONSET_DATE: {columnName: "ONSET_DATE"},
                BODY_SITE: {columnName: "BODY_SITE"},
                VERIFICATION_STATUS: {columnName: "VERIFICATION_STATUS"},
                CODE: {columnName: "CODE"},
                ABATEMENT_AGE: {columnName: "ABATEMENT_AGE"},
                ABATEMENT_STRING: {columnName: "ABATEMENT_STRING"},
                RECORDED_DATE: {columnName: "RECORDED_DATE"},
                CATEGORY: {columnName: "CATEGORY"},
                ABATEMENT_DATE: {columnName: "ABATEMENT_DATE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                SEVERITY: {columnName: "SEVERITY"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["CONDITIONTABLE_ID"]
        },
        [COMPOSITION_TABLE]: {
            entityName: "CompositionTable",
            tableName: "CompositionTable",
            fieldMetadata: {
                COMPOSITIONTABLE_ID: {columnName: "COMPOSITIONTABLE_ID"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                RELATED_ID: {columnName: "RELATED_ID"},
                CATEGORY: {columnName: "CATEGORY"},
                PERIOD: {columnName: "PERIOD"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                CONTEXT: {columnName: "CONTEXT"},
                CONFIDENTIALITY: {columnName: "CONFIDENTIALITY"},
                SECTION: {columnName: "SECTION"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["COMPOSITIONTABLE_ID"]
        },
        [CONTRACT_TABLE]: {
            entityName: "ContractTable",
            tableName: "ContractTable",
            fieldMetadata: {
                CONTRACTTABLE_ID: {columnName: "CONTRACTTABLE_ID"},
                ISSUED: {columnName: "ISSUED"},
                STATUS: {columnName: "STATUS"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                INSTANTIATES: {columnName: "INSTANTIATES"},
                URL: {columnName: "URL"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["CONTRACTTABLE_ID"]
        },
        [IMMUNIZATION_TABLE]: {
            entityName: "ImmunizationTable",
            tableName: "ImmunizationTable",
            fieldMetadata: {
                IMMUNIZATIONTABLE_ID: {columnName: "IMMUNIZATIONTABLE_ID"},
                DATE: {columnName: "DATE"},
                VACCINE_CODE: {columnName: "VACCINE_CODE"},
                STATUS: {columnName: "STATUS"},
                STATUS_REASON: {columnName: "STATUS_REASON"},
                SERIES: {columnName: "SERIES"},
                TARGET_DISEASE: {columnName: "TARGET_DISEASE"},
                REASON_CODE: {columnName: "REASON_CODE"},
                REACTION_DATE: {columnName: "REACTION_DATE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                LOT_NUMBER: {columnName: "LOT_NUMBER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["IMMUNIZATIONTABLE_ID"]
        },
        [MEDICATION_DISPENSE_TABLE]: {
            entityName: "MedicationDispenseTable",
            tableName: "MedicationDispenseTable",
            fieldMetadata: {
                MEDICATIONDISPENSETABLE_ID: {columnName: "MEDICATIONDISPENSETABLE_ID"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                WHENHANDEDOVER: {columnName: "WHENHANDEDOVER"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                WHENPREPARED: {columnName: "WHENPREPARED"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICATIONDISPENSETABLE_ID"]
        },
        [MOLECULAR_SEQUENCE_TABLE]: {
            entityName: "MolecularSequenceTable",
            tableName: "MolecularSequenceTable",
            fieldMetadata: {
                MOLECULARSEQUENCETABLE_ID: {columnName: "MOLECULARSEQUENCETABLE_ID"},
                CHROMOSOME: {columnName: "CHROMOSOME"},
                VARIANT_START: {columnName: "VARIANT_START"},
                WINDOW_START: {columnName: "WINDOW_START"},
                VARIANT_END: {columnName: "VARIANT_END"},
                REFERENCESEQID: {columnName: "REFERENCESEQID"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                WINDOW_END: {columnName: "WINDOW_END"},
                TYPE: {columnName: "TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MOLECULARSEQUENCETABLE_ID"]
        },
        [SEARCH_PARAMETER_TABLE]: {
            entityName: "SearchParameterTable",
            tableName: "SearchParameterTable",
            fieldMetadata: {
                SEARCHPARAMETERTABLE_ID: {columnName: "SEARCHPARAMETERTABLE_ID"},
                TARGET: {columnName: "TARGET"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                BASE: {columnName: "BASE"},
                DATE: {columnName: "DATE"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                TYPE: {columnName: "TYPE"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["SEARCHPARAMETERTABLE_ID"]
        },
        [MEDICATION_REQUEST_TABLE]: {
            entityName: "MedicationRequestTable",
            tableName: "MedicationRequestTable",
            fieldMetadata: {
                MEDICATIONREQUESTTABLE_ID: {columnName: "MEDICATIONREQUESTTABLE_ID"},
                DATE: {columnName: "DATE"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                CATEGORY: {columnName: "CATEGORY"},
                INTENT: {columnName: "INTENT"},
                PRIORITY: {columnName: "PRIORITY"},
                INTENDED_PERFORMERTYPE: {columnName: "INTENDED_PERFORMERTYPE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                AUTHOREDON: {columnName: "AUTHOREDON"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICATIONREQUESTTABLE_ID"]
        },
        [ENROLLMENT_REQUEST_TABLE]: {
            entityName: "EnrollmentRequestTable",
            tableName: "EnrollmentRequestTable",
            fieldMetadata: {
                ENROLLMENTREQUESTTABLE_ID: {columnName: "ENROLLMENTREQUESTTABLE_ID"},
                STATUS: {columnName: "STATUS"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["ENROLLMENTREQUESTTABLE_ID"]
        },
        [SPECIMEN_DEFINITION_TABLE]: {
            entityName: "SpecimenDefinitionTable",
            tableName: "SpecimenDefinitionTable",
            fieldMetadata: {
                SPECIMENDEFINITIONTABLE_ID: {columnName: "SPECIMENDEFINITIONTABLE_ID"},
                CONTAINER: {columnName: "CONTAINER"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["SPECIMENDEFINITIONTABLE_ID"]
        },
        [EVENT_DEFINITION_TABLE]: {
            entityName: "EventDefinitionTable",
            tableName: "EventDefinitionTable",
            fieldMetadata: {
                EVENTDEFINITIONTABLE_ID: {columnName: "EVENTDEFINITIONTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                TOPIC: {columnName: "TOPIC"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["EVENTDEFINITIONTABLE_ID"]
        },
        [IMMUNIZATION_EVALUATION_TABLE]: {
            entityName: "ImmunizationEvaluationTable",
            tableName: "ImmunizationEvaluationTable",
            fieldMetadata: {
                IMMUNIZATIONEVALUATIONTABLE_ID: {columnName: "IMMUNIZATIONEVALUATIONTABLE_ID"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                TARGET_DISEASE: {columnName: "TARGET_DISEASE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                DOSE_STATUS: {columnName: "DOSE_STATUS"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["IMMUNIZATIONEVALUATIONTABLE_ID"]
        },
        [PAYMENT_RECONCILIATION_TABLE]: {
            entityName: "PaymentReconciliationTable",
            tableName: "PaymentReconciliationTable",
            fieldMetadata: {
                PAYMENTRECONCILIATIONTABLE_ID: {columnName: "PAYMENTRECONCILIATIONTABLE_ID"},
                CREATED: {columnName: "CREATED"},
                STATUS: {columnName: "STATUS"},
                OUTCOME: {columnName: "OUTCOME"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                DISPOSITION: {columnName: "DISPOSITION"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["PAYMENTRECONCILIATIONTABLE_ID"]
        },
        [MEASURE_TABLE]: {
            entityName: "MeasureTable",
            tableName: "MeasureTable",
            fieldMetadata: {
                MEASURETABLE_ID: {columnName: "MEASURETABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                TOPIC: {columnName: "TOPIC"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEASURETABLE_ID"]
        },
        [CONCEPT_MAP_TABLE]: {
            entityName: "ConceptMapTable",
            tableName: "ConceptMapTable",
            fieldMetadata: {
                CONCEPTMAPTABLE_ID: {columnName: "CONCEPTMAPTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                SOURCE_SYSTEM: {columnName: "SOURCE_SYSTEM"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                TARGET_SYSTEM: {columnName: "TARGET_SYSTEM"},
                SOURCE_CODE: {columnName: "SOURCE_CODE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                TARGET_CODE: {columnName: "TARGET_CODE"},
                PRODUCT: {columnName: "PRODUCT"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                DEPENDSON: {columnName: "DEPENDSON"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["CONCEPTMAPTABLE_ID"]
        },
        [RESEARCH_ELEMENT_DEFINITION_TABLE]: {
            entityName: "ResearchElementDefinitionTable",
            tableName: "ResearchElementDefinitionTable",
            fieldMetadata: {
                RESEARCHELEMENTDEFINITIONTABLE_ID: {columnName: "RESEARCHELEMENTDEFINITIONTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                TOPIC: {columnName: "TOPIC"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["RESEARCHELEMENTDEFINITIONTABLE_ID"]
        },
        [GUIDANCE_RESPONSE_TABLE]: {
            entityName: "GuidanceResponseTable",
            tableName: "GuidanceResponseTable",
            fieldMetadata: {
                GUIDANCERESPONSETABLE_ID: {columnName: "GUIDANCERESPONSETABLE_ID"},
                REQUEST: {columnName: "REQUEST"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["GUIDANCERESPONSETABLE_ID"]
        },
        [LINKAGE_TABLE]: {
            entityName: "LinkageTable",
            tableName: "LinkageTable",
            fieldMetadata: {
                LINKAGETABLE_ID: {columnName: "LINKAGETABLE_ID"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["LINKAGETABLE_ID"]
        },
        [MEDICINAL_PRODUCT_TABLE]: {
            entityName: "MedicinalProductTable",
            tableName: "MedicinalProductTable",
            fieldMetadata: {
                MEDICINALPRODUCTTABLE_ID: {columnName: "MEDICINALPRODUCTTABLE_ID"},
                NAME_LANGUAGE: {columnName: "NAME_LANGUAGE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                NAME: {columnName: "NAME"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICINALPRODUCTTABLE_ID"]
        },
        [DEVICE_DEFINITION_TABLE]: {
            entityName: "DeviceDefinitionTable",
            tableName: "DeviceDefinitionTable",
            fieldMetadata: {
                DEVICEDEFINITIONTABLE_ID: {columnName: "DEVICEDEFINITIONTABLE_ID"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["DEVICEDEFINITIONTABLE_ID"]
        },
        [COVERAGE_ELIGIBILITY_REQUEST_TABLE]: {
            entityName: "CoverageEligibilityRequestTable",
            tableName: "CoverageEligibilityRequestTable",
            fieldMetadata: {
                COVERAGEELIGIBILITYREQUESTTABLE_ID: {columnName: "COVERAGEELIGIBILITYREQUESTTABLE_ID"},
                CREATED: {columnName: "CREATED"},
                STATUS: {columnName: "STATUS"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["COVERAGEELIGIBILITYREQUESTTABLE_ID"]
        },
        [PATIENT_TABLE]: {
            entityName: "PatientTable",
            tableName: "PatientTable",
            fieldMetadata: {
                PATIENTTABLE_ID: {columnName: "PATIENTTABLE_ID"},
                LANGUAGE: {columnName: "LANGUAGE"},
                ADDRESS_COUNTRY: {columnName: "ADDRESS_COUNTRY"},
                ADDRESS_POSTALCODE: {columnName: "ADDRESS_POSTALCODE"},
                ACTIVE: {columnName: "ACTIVE"},
                PHONE: {columnName: "PHONE"},
                DECEASED: {columnName: "DECEASED"},
                BIRTHDATE: {columnName: "BIRTHDATE"},
                ADDRESS_CITY: {columnName: "ADDRESS_CITY"},
                EMAIL: {columnName: "EMAIL"},
                ADDRESS_STATE: {columnName: "ADDRESS_STATE"},
                TELECOM: {columnName: "TELECOM"},
                NAME: {columnName: "NAME"},
                FAMILY: {columnName: "FAMILY"},
                ADDRESS_USE: {columnName: "ADDRESS_USE"},
                GIVEN: {columnName: "GIVEN"},
                ADDRESS: {columnName: "ADDRESS"},
                GENDER: {columnName: "GENDER"},
                PHONETIC: {columnName: "PHONETIC"},
                DEATH_DATE: {columnName: "DEATH_DATE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["PATIENTTABLE_ID"]
        },
        [COVERAGE_TABLE]: {
            entityName: "CoverageTable",
            tableName: "CoverageTable",
            fieldMetadata: {
                COVERAGETABLE_ID: {columnName: "COVERAGETABLE_ID"},
                STATUS: {columnName: "STATUS"},
                DEPENDENT: {columnName: "DEPENDENT"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CLASS_VALUE: {columnName: "CLASS_VALUE"},
                TYPE: {columnName: "TYPE"},
                CLASS_TYPE: {columnName: "CLASS_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["COVERAGETABLE_ID"]
        },
        [SUBSTANCE_TABLE]: {
            entityName: "SubstanceTable",
            tableName: "SubstanceTable",
            fieldMetadata: {
                SUBSTANCETABLE_ID: {columnName: "SUBSTANCETABLE_ID"},
                CONTAINER_IDENTIFIER: {columnName: "CONTAINER_IDENTIFIER"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                QUANTITY: {columnName: "QUANTITY"},
                CATEGORY: {columnName: "CATEGORY"},
                EXPIRY: {columnName: "EXPIRY"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["SUBSTANCETABLE_ID"]
        },
        [CHARGE_ITEM_DEFINITION_TABLE]: {
            entityName: "ChargeItemDefinitionTable",
            tableName: "ChargeItemDefinitionTable",
            fieldMetadata: {
                CHARGEITEMDEFINITIONTABLE_ID: {columnName: "CHARGEITEMDEFINITIONTABLE_ID"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                DATE: {columnName: "DATE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["CHARGEITEMDEFINITIONTABLE_ID"]
        },
        [MEDICINAL_PRODUCT_INTERACTION_TABLE]: {
            entityName: "MedicinalProductInteractionTable",
            tableName: "MedicinalProductInteractionTable",
            fieldMetadata: {
                MEDICINALPRODUCTINTERACTIONTABLE_ID: {columnName: "MEDICINALPRODUCTINTERACTIONTABLE_ID"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MEDICINALPRODUCTINTERACTIONTABLE_ID"]
        },
        [ACCOUNT_TABLE]: {
            entityName: "AccountTable",
            tableName: "AccountTable",
            fieldMetadata: {
                ACCOUNTTABLE_ID: {columnName: "ACCOUNTTABLE_ID"},
                STATUS: {columnName: "STATUS"},
                PERIOD: {columnName: "PERIOD"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                TYPE: {columnName: "TYPE"},
                NAME: {columnName: "NAME"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["ACCOUNTTABLE_ID"]
        },
        [MESSAGE_HEADER_TABLE]: {
            entityName: "MessageHeaderTable",
            tableName: "MessageHeaderTable",
            fieldMetadata: {
                MESSAGEHEADERTABLE_ID: {columnName: "MESSAGEHEADERTABLE_ID"},
                CODE: {columnName: "CODE"},
                SOURCE_URI: {columnName: "SOURCE_URI"},
                DESTINATION: {columnName: "DESTINATION"},
                DESTINATION_URI: {columnName: "DESTINATION_URI"},
                SOURCE: {columnName: "SOURCE"},
                RESPONSE_ID: {columnName: "RESPONSE_ID"},
                EVENT: {columnName: "EVENT"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["MESSAGEHEADERTABLE_ID"]
        },
        [AUDIT_EVENT_TABLE]: {
            entityName: "AuditEventTable",
            tableName: "AuditEventTable",
            fieldMetadata: {
                AUDITEVENTTABLE_ID: {columnName: "AUDITEVENTTABLE_ID"},
                SUBTYPE: {columnName: "SUBTYPE"},
                SITE: {columnName: "SITE"},
                OUTCOME: {columnName: "OUTCOME"},
                ENTITY_ROLE: {columnName: "ENTITY_ROLE"},
                AGENT_NAME: {columnName: "AGENT_NAME"},
                ENTITY_TYPE: {columnName: "ENTITY_TYPE"},
                DATE: {columnName: "DATE"},
                POLICY: {columnName: "POLICY"},
                ALTID: {columnName: "ALTID"},
                ACTION: {columnName: "ACTION"},
                ADDRESS: {columnName: "ADDRESS"},
                TYPE: {columnName: "TYPE"},
                ENTITY_NAME: {columnName: "ENTITY_NAME"},
                AGENT_ROLE: {columnName: "AGENT_ROLE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["AUDITEVENTTABLE_ID"]
        },
        [NUTRITION_ORDER_TABLE]: {
            entityName: "NutritionOrderTable",
            tableName: "NutritionOrderTable",
            fieldMetadata: {
                NUTRITIONORDERTABLE_ID: {columnName: "NUTRITIONORDERTABLE_ID"},
                SUPPLEMENT: {columnName: "SUPPLEMENT"},
                STATUS: {columnName: "STATUS"},
                DATETIME: {columnName: "DATETIME"},
                INSTANTIATES_URI: {columnName: "INSTANTIATES_URI"},
                ADDITIVE: {columnName: "ADDITIVE"},
                ORALDIET: {columnName: "ORALDIET"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                FORMULA: {columnName: "FORMULA"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["NUTRITIONORDERTABLE_ID"]
        },
        [QUESTIONNAIRE_TABLE]: {
            entityName: "QuestionnaireTable",
            tableName: "QuestionnaireTable",
            fieldMetadata: {
                QUESTIONNAIRETABLE_ID: {columnName: "QUESTIONNAIRETABLE_ID"},
                DEFINITION: {columnName: "DEFINITION"},
                PUBLISHER: {columnName: "PUBLISHER"},
                JURISDICTION: {columnName: "JURISDICTION"},
                SUBJECT_TYPE: {columnName: "SUBJECT_TYPE"},
                EFFECTIVE: {columnName: "EFFECTIVE"},
                CONTEXT: {columnName: "CONTEXT"},
                URL: {columnName: "URL"},
                NAME: {columnName: "NAME"},
                DATE: {columnName: "DATE"},
                CODE: {columnName: "CODE"},
                STATUS: {columnName: "STATUS"},
                DESCRIPTION: {columnName: "DESCRIPTION"},
                VERSION: {columnName: "VERSION"},
                TITLE: {columnName: "TITLE"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                CONTEXT_QUANTITY: {columnName: "CONTEXT_QUANTITY"},
                CONTEXT_TYPE: {columnName: "CONTEXT_TYPE"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["QUESTIONNAIRETABLE_ID"]
        },
        [APPOINTMENT_RESPONSE_TABLE]: {
            entityName: "AppointmentResponseTable",
            tableName: "AppointmentResponseTable",
            fieldMetadata: {
                APPOINTMENTRESPONSETABLE_ID: {columnName: "APPOINTMENTRESPONSETABLE_ID"},
                PART_STATUS: {columnName: "PART_STATUS"},
                IDENTIFIER: {columnName: "IDENTIFIER"},
                VERSION_ID: {columnName: "VERSION_ID"},
                CREATED_AT: {columnName: "CREATED_AT"},
                UPDATED_AT: {columnName: "UPDATED_AT"},
                LAST_UPDATED: {columnName: "LAST_UPDATED"},
                RESOURCE_JSON: {columnName: "RESOURCE_JSON"}
            },
            keyFields: ["APPOINTMENTRESPONSETABLE_ID"]
        }
    };

    public isolated function init() returns persist:Error? {
        jdbc:Client|error dbClient = new (url = url, user = user, password = password, options = connectionOptions);
        if dbClient is error {
            return <persist:Error>error(dbClient.message());
        }
        self.dbClient = dbClient;
        self.persistClients = {
            [S_E_A_R_C_H__P_A_R_A_M__R_E_S__E_X_P_R_E_S_S_I_O_N_S]: check new (dbClient, self.metadata.get(S_E_A_R_C_H__P_A_R_A_M__R_E_S__E_X_P_R_E_S_S_I_O_N_S), psql:MYSQL_SPECIFICS),
            [R_E_F_E_R_E_N_C_E_S]: check new (dbClient, self.metadata.get(R_E_F_E_R_E_N_C_E_S), psql:MYSQL_SPECIFICS),
            [TEST_SCRIPT_TABLE]: check new (dbClient, self.metadata.get(TEST_SCRIPT_TABLE), psql:MYSQL_SPECIFICS),
            [TEST_REPORT_TABLE]: check new (dbClient, self.metadata.get(TEST_REPORT_TABLE), psql:MYSQL_SPECIFICS),
            [RELATED_PERSON_TABLE]: check new (dbClient, self.metadata.get(RELATED_PERSON_TABLE), psql:MYSQL_SPECIFICS),
            [EVIDENCE_VARIABLE_TABLE]: check new (dbClient, self.metadata.get(EVIDENCE_VARIABLE_TABLE), psql:MYSQL_SPECIFICS),
            [VALUE_SET_TABLE]: check new (dbClient, self.metadata.get(VALUE_SET_TABLE), psql:MYSQL_SPECIFICS),
            [DOCUMENT_MANIFEST_TABLE]: check new (dbClient, self.metadata.get(DOCUMENT_MANIFEST_TABLE), psql:MYSQL_SPECIFICS),
            [IMMUNIZATION_RECOMMENDATION_TABLE]: check new (dbClient, self.metadata.get(IMMUNIZATION_RECOMMENDATION_TABLE), psql:MYSQL_SPECIFICS),
            [DEVICE_METRIC_TABLE]: check new (dbClient, self.metadata.get(DEVICE_METRIC_TABLE), psql:MYSQL_SPECIFICS),
            [LOCATION_TABLE]: check new (dbClient, self.metadata.get(LOCATION_TABLE), psql:MYSQL_SPECIFICS),
            [EXPLANATION_OF_BENEFIT_TABLE]: check new (dbClient, self.metadata.get(EXPLANATION_OF_BENEFIT_TABLE), psql:MYSQL_SPECIFICS),
            [FLAG_TABLE]: check new (dbClient, self.metadata.get(FLAG_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICATION_STATEMENT_TABLE]: check new (dbClient, self.metadata.get(MEDICATION_STATEMENT_TABLE), psql:MYSQL_SPECIFICS),
            [INSURANCE_PLAN_TABLE]: check new (dbClient, self.metadata.get(INSURANCE_PLAN_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICINAL_PRODUCT_CONTRAINDICATION_TABLE]: check new (dbClient, self.metadata.get(MEDICINAL_PRODUCT_CONTRAINDICATION_TABLE), psql:MYSQL_SPECIFICS),
            [CLAIM_RESPONSE_TABLE]: check new (dbClient, self.metadata.get(CLAIM_RESPONSE_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICINAL_PRODUCT_AUTHORIZATION_TABLE]: check new (dbClient, self.metadata.get(MEDICINAL_PRODUCT_AUTHORIZATION_TABLE), psql:MYSQL_SPECIFICS),
            [IMAGING_STUDY_TABLE]: check new (dbClient, self.metadata.get(IMAGING_STUDY_TABLE), psql:MYSQL_SPECIFICS),
            [PRACTITIONER_ROLE_TABLE]: check new (dbClient, self.metadata.get(PRACTITIONER_ROLE_TABLE), psql:MYSQL_SPECIFICS),
            [GROUP_TABLE]: check new (dbClient, self.metadata.get(GROUP_TABLE), psql:MYSQL_SPECIFICS),
            [PERSON_TABLE]: check new (dbClient, self.metadata.get(PERSON_TABLE), psql:MYSQL_SPECIFICS),
            [PRACTITIONER_TABLE]: check new (dbClient, self.metadata.get(PRACTITIONER_TABLE), psql:MYSQL_SPECIFICS),
            [ACTIVITY_DEFINITION_TABLE]: check new (dbClient, self.metadata.get(ACTIVITY_DEFINITION_TABLE), psql:MYSQL_SPECIFICS),
            [EVIDENCE_TABLE]: check new (dbClient, self.metadata.get(EVIDENCE_TABLE), psql:MYSQL_SPECIFICS),
            [DEVICE_TABLE]: check new (dbClient, self.metadata.get(DEVICE_TABLE), psql:MYSQL_SPECIFICS),
            [FAMILY_MEMBER_HISTORY_TABLE]: check new (dbClient, self.metadata.get(FAMILY_MEMBER_HISTORY_TABLE), psql:MYSQL_SPECIFICS),
            [ADVERSE_EVENT_TABLE]: check new (dbClient, self.metadata.get(ADVERSE_EVENT_TABLE), psql:MYSQL_SPECIFICS),
            [SUPPLY_REQUEST_TABLE]: check new (dbClient, self.metadata.get(SUPPLY_REQUEST_TABLE), psql:MYSQL_SPECIFICS),
            [EXAMPLE_SCENARIO_TABLE]: check new (dbClient, self.metadata.get(EXAMPLE_SCENARIO_TABLE), psql:MYSQL_SPECIFICS),
            [INVOICE_TABLE]: check new (dbClient, self.metadata.get(INVOICE_TABLE), psql:MYSQL_SPECIFICS),
            [QUESTIONNAIRE_RESPONSE_TABLE]: check new (dbClient, self.metadata.get(QUESTIONNAIRE_RESPONSE_TABLE), psql:MYSQL_SPECIFICS),
            [OBSERVATION_TABLE]: check new (dbClient, self.metadata.get(OBSERVATION_TABLE), psql:MYSQL_SPECIFICS),
            [EFFECT_EVIDENCE_SYNTHESIS_TABLE]: check new (dbClient, self.metadata.get(EFFECT_EVIDENCE_SYNTHESIS_TABLE), psql:MYSQL_SPECIFICS),
            [OPERATION_DEFINITION_TABLE]: check new (dbClient, self.metadata.get(OPERATION_DEFINITION_TABLE), psql:MYSQL_SPECIFICS),
            [MEASURE_REPORT_TABLE]: check new (dbClient, self.metadata.get(MEASURE_REPORT_TABLE), psql:MYSQL_SPECIFICS),
            [SUPPLY_DELIVERY_TABLE]: check new (dbClient, self.metadata.get(SUPPLY_DELIVERY_TABLE), psql:MYSQL_SPECIFICS),
            [SERVICE_REQUEST_TABLE]: check new (dbClient, self.metadata.get(SERVICE_REQUEST_TABLE), psql:MYSQL_SPECIFICS),
            [BASIC_TABLE]: check new (dbClient, self.metadata.get(BASIC_TABLE), psql:MYSQL_SPECIFICS),
            [SUBSCRIPTION_TABLE]: check new (dbClient, self.metadata.get(SUBSCRIPTION_TABLE), psql:MYSQL_SPECIFICS),
            [ENROLLMENT_RESPONSE_TABLE]: check new (dbClient, self.metadata.get(ENROLLMENT_RESPONSE_TABLE), psql:MYSQL_SPECIFICS),
            [DEVICE_REQUEST_TABLE]: check new (dbClient, self.metadata.get(DEVICE_REQUEST_TABLE), psql:MYSQL_SPECIFICS),
            [APPOINTMENT_TABLE]: check new (dbClient, self.metadata.get(APPOINTMENT_TABLE), psql:MYSQL_SPECIFICS),
            [NAMING_SYSTEM_TABLE]: check new (dbClient, self.metadata.get(NAMING_SYSTEM_TABLE), psql:MYSQL_SPECIFICS),
            [STRUCTURE_DEFINITION_TABLE]: check new (dbClient, self.metadata.get(STRUCTURE_DEFINITION_TABLE), psql:MYSQL_SPECIFICS),
            [CLINICAL_IMPRESSION_TABLE]: check new (dbClient, self.metadata.get(CLINICAL_IMPRESSION_TABLE), psql:MYSQL_SPECIFICS),
            [COMMUNICATION_TABLE]: check new (dbClient, self.metadata.get(COMMUNICATION_TABLE), psql:MYSQL_SPECIFICS),
            [ORGANIZATION_TABLE]: check new (dbClient, self.metadata.get(ORGANIZATION_TABLE), psql:MYSQL_SPECIFICS),
            [COVERAGE_ELIGIBILITY_RESPONSE_TABLE]: check new (dbClient, self.metadata.get(COVERAGE_ELIGIBILITY_RESPONSE_TABLE), psql:MYSQL_SPECIFICS),
            [RESEARCH_STUDY_TABLE]: check new (dbClient, self.metadata.get(RESEARCH_STUDY_TABLE), psql:MYSQL_SPECIFICS),
            [BUNDLE_TABLE]: check new (dbClient, self.metadata.get(BUNDLE_TABLE), psql:MYSQL_SPECIFICS),
            [ENCOUNTER_TABLE]: check new (dbClient, self.metadata.get(ENCOUNTER_TABLE), psql:MYSQL_SPECIFICS),
            [RISK_ASSESSMENT_TABLE]: check new (dbClient, self.metadata.get(RISK_ASSESSMENT_TABLE), psql:MYSQL_SPECIFICS),
            [LIST_TABLE]: check new (dbClient, self.metadata.get(LIST_TABLE), psql:MYSQL_SPECIFICS),
            [ORGANIZATION_AFFILIATION_TABLE]: check new (dbClient, self.metadata.get(ORGANIZATION_AFFILIATION_TABLE), psql:MYSQL_SPECIFICS),
            [CHARGE_ITEM_TABLE]: check new (dbClient, self.metadata.get(CHARGE_ITEM_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICATION_KNOWLEDGE_TABLE]: check new (dbClient, self.metadata.get(MEDICATION_KNOWLEDGE_TABLE), psql:MYSQL_SPECIFICS),
            [PLAN_DEFINITION_TABLE]: check new (dbClient, self.metadata.get(PLAN_DEFINITION_TABLE), psql:MYSQL_SPECIFICS),
            [CARE_PLAN_TABLE]: check new (dbClient, self.metadata.get(CARE_PLAN_TABLE), psql:MYSQL_SPECIFICS),
            [VISION_PRESCRIPTION_TABLE]: check new (dbClient, self.metadata.get(VISION_PRESCRIPTION_TABLE), psql:MYSQL_SPECIFICS),
            [EPISODE_OF_CARE_TABLE]: check new (dbClient, self.metadata.get(EPISODE_OF_CARE_TABLE), psql:MYSQL_SPECIFICS),
            [CARE_TEAM_TABLE]: check new (dbClient, self.metadata.get(CARE_TEAM_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICATION_ADMINISTRATION_TABLE]: check new (dbClient, self.metadata.get(MEDICATION_ADMINISTRATION_TABLE), psql:MYSQL_SPECIFICS),
            [CONSENT_TABLE]: check new (dbClient, self.metadata.get(CONSENT_TABLE), psql:MYSQL_SPECIFICS),
            [DETECTED_ISSUE_TABLE]: check new (dbClient, self.metadata.get(DETECTED_ISSUE_TABLE), psql:MYSQL_SPECIFICS),
            [SUBSTANCE_SPECIFICATION_TABLE]: check new (dbClient, self.metadata.get(SUBSTANCE_SPECIFICATION_TABLE), psql:MYSQL_SPECIFICS),
            [ALLERGY_INTOLERANCE_TABLE]: check new (dbClient, self.metadata.get(ALLERGY_INTOLERANCE_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICINAL_PRODUCT_INDICATION_TABLE]: check new (dbClient, self.metadata.get(MEDICINAL_PRODUCT_INDICATION_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICINAL_PRODUCT_PHARMACEUTICAL_TABLE]: check new (dbClient, self.metadata.get(MEDICINAL_PRODUCT_PHARMACEUTICAL_TABLE), psql:MYSQL_SPECIFICS),
            [SLOT_TABLE]: check new (dbClient, self.metadata.get(SLOT_TABLE), psql:MYSQL_SPECIFICS),
            [VERIFICATION_RESULT_TABLE]: check new (dbClient, self.metadata.get(VERIFICATION_RESULT_TABLE), psql:MYSQL_SPECIFICS),
            [SPECIMEN_TABLE]: check new (dbClient, self.metadata.get(SPECIMEN_TABLE), psql:MYSQL_SPECIFICS),
            [RESEARCH_SUBJECT_TABLE]: check new (dbClient, self.metadata.get(RESEARCH_SUBJECT_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICATION_TABLE]: check new (dbClient, self.metadata.get(MEDICATION_TABLE), psql:MYSQL_SPECIFICS),
            [RESEARCH_DEFINITION_TABLE]: check new (dbClient, self.metadata.get(RESEARCH_DEFINITION_TABLE), psql:MYSQL_SPECIFICS),
            [HEALTHCARE_SERVICE_TABLE]: check new (dbClient, self.metadata.get(HEALTHCARE_SERVICE_TABLE), psql:MYSQL_SPECIFICS),
            [PAYMENT_NOTICE_TABLE]: check new (dbClient, self.metadata.get(PAYMENT_NOTICE_TABLE), psql:MYSQL_SPECIFICS),
            [PROVENANCE_TABLE]: check new (dbClient, self.metadata.get(PROVENANCE_TABLE), psql:MYSQL_SPECIFICS),
            [GRAPH_DEFINITION_TABLE]: check new (dbClient, self.metadata.get(GRAPH_DEFINITION_TABLE), psql:MYSQL_SPECIFICS),
            [MEDIA_TABLE]: check new (dbClient, self.metadata.get(MEDIA_TABLE), psql:MYSQL_SPECIFICS),
            [BODY_STRUCTURE_TABLE]: check new (dbClient, self.metadata.get(BODY_STRUCTURE_TABLE), psql:MYSQL_SPECIFICS),
            [DIAGNOSTIC_REPORT_TABLE]: check new (dbClient, self.metadata.get(DIAGNOSTIC_REPORT_TABLE), psql:MYSQL_SPECIFICS),
            [GOAL_TABLE]: check new (dbClient, self.metadata.get(GOAL_TABLE), psql:MYSQL_SPECIFICS),
            [CAPABILITY_STATEMENT_TABLE]: check new (dbClient, self.metadata.get(CAPABILITY_STATEMENT_TABLE), psql:MYSQL_SPECIFICS),
            [DEVICE_USE_STATEMENT_TABLE]: check new (dbClient, self.metadata.get(DEVICE_USE_STATEMENT_TABLE), psql:MYSQL_SPECIFICS),
            [SCHEDULE_TABLE]: check new (dbClient, self.metadata.get(SCHEDULE_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICINAL_PRODUCT_PACKAGED_TABLE]: check new (dbClient, self.metadata.get(MEDICINAL_PRODUCT_PACKAGED_TABLE), psql:MYSQL_SPECIFICS),
            [PROCEDURE_TABLE]: check new (dbClient, self.metadata.get(PROCEDURE_TABLE), psql:MYSQL_SPECIFICS),
            [LIBRARY_TABLE]: check new (dbClient, self.metadata.get(LIBRARY_TABLE), psql:MYSQL_SPECIFICS),
            [CODE_SYSTEM_TABLE]: check new (dbClient, self.metadata.get(CODE_SYSTEM_TABLE), psql:MYSQL_SPECIFICS),
            [COMMUNICATION_REQUEST_TABLE]: check new (dbClient, self.metadata.get(COMMUNICATION_REQUEST_TABLE), psql:MYSQL_SPECIFICS),
            [DOCUMENT_REFERENCE_TABLE]: check new (dbClient, self.metadata.get(DOCUMENT_REFERENCE_TABLE), psql:MYSQL_SPECIFICS),
            [REQUEST_GROUP_TABLE]: check new (dbClient, self.metadata.get(REQUEST_GROUP_TABLE), psql:MYSQL_SPECIFICS),
            [CLAIM_TABLE]: check new (dbClient, self.metadata.get(CLAIM_TABLE), psql:MYSQL_SPECIFICS),
            [MESSAGE_DEFINITION_TABLE]: check new (dbClient, self.metadata.get(MESSAGE_DEFINITION_TABLE), psql:MYSQL_SPECIFICS),
            [RISK_EVIDENCE_SYNTHESIS_TABLE]: check new (dbClient, self.metadata.get(RISK_EVIDENCE_SYNTHESIS_TABLE), psql:MYSQL_SPECIFICS),
            [TASK_TABLE]: check new (dbClient, self.metadata.get(TASK_TABLE), psql:MYSQL_SPECIFICS),
            [IMPLEMENTATION_GUIDE_TABLE]: check new (dbClient, self.metadata.get(IMPLEMENTATION_GUIDE_TABLE), psql:MYSQL_SPECIFICS),
            [STRUCTURE_MAP_TABLE]: check new (dbClient, self.metadata.get(STRUCTURE_MAP_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICINAL_PRODUCT_UNDESIRABLE_EFFECT_TABLE]: check new (dbClient, self.metadata.get(MEDICINAL_PRODUCT_UNDESIRABLE_EFFECT_TABLE), psql:MYSQL_SPECIFICS),
            [COMPARTMENT_DEFINITION_TABLE]: check new (dbClient, self.metadata.get(COMPARTMENT_DEFINITION_TABLE), psql:MYSQL_SPECIFICS),
            [ENDPOINT_TABLE]: check new (dbClient, self.metadata.get(ENDPOINT_TABLE), psql:MYSQL_SPECIFICS),
            [TERMINOLOGY_CAPABILITIES_TABLE]: check new (dbClient, self.metadata.get(TERMINOLOGY_CAPABILITIES_TABLE), psql:MYSQL_SPECIFICS),
            [CONDITION_TABLE]: check new (dbClient, self.metadata.get(CONDITION_TABLE), psql:MYSQL_SPECIFICS),
            [COMPOSITION_TABLE]: check new (dbClient, self.metadata.get(COMPOSITION_TABLE), psql:MYSQL_SPECIFICS),
            [CONTRACT_TABLE]: check new (dbClient, self.metadata.get(CONTRACT_TABLE), psql:MYSQL_SPECIFICS),
            [IMMUNIZATION_TABLE]: check new (dbClient, self.metadata.get(IMMUNIZATION_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICATION_DISPENSE_TABLE]: check new (dbClient, self.metadata.get(MEDICATION_DISPENSE_TABLE), psql:MYSQL_SPECIFICS),
            [MOLECULAR_SEQUENCE_TABLE]: check new (dbClient, self.metadata.get(MOLECULAR_SEQUENCE_TABLE), psql:MYSQL_SPECIFICS),
            [SEARCH_PARAMETER_TABLE]: check new (dbClient, self.metadata.get(SEARCH_PARAMETER_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICATION_REQUEST_TABLE]: check new (dbClient, self.metadata.get(MEDICATION_REQUEST_TABLE), psql:MYSQL_SPECIFICS),
            [ENROLLMENT_REQUEST_TABLE]: check new (dbClient, self.metadata.get(ENROLLMENT_REQUEST_TABLE), psql:MYSQL_SPECIFICS),
            [SPECIMEN_DEFINITION_TABLE]: check new (dbClient, self.metadata.get(SPECIMEN_DEFINITION_TABLE), psql:MYSQL_SPECIFICS),
            [EVENT_DEFINITION_TABLE]: check new (dbClient, self.metadata.get(EVENT_DEFINITION_TABLE), psql:MYSQL_SPECIFICS),
            [IMMUNIZATION_EVALUATION_TABLE]: check new (dbClient, self.metadata.get(IMMUNIZATION_EVALUATION_TABLE), psql:MYSQL_SPECIFICS),
            [PAYMENT_RECONCILIATION_TABLE]: check new (dbClient, self.metadata.get(PAYMENT_RECONCILIATION_TABLE), psql:MYSQL_SPECIFICS),
            [MEASURE_TABLE]: check new (dbClient, self.metadata.get(MEASURE_TABLE), psql:MYSQL_SPECIFICS),
            [CONCEPT_MAP_TABLE]: check new (dbClient, self.metadata.get(CONCEPT_MAP_TABLE), psql:MYSQL_SPECIFICS),
            [RESEARCH_ELEMENT_DEFINITION_TABLE]: check new (dbClient, self.metadata.get(RESEARCH_ELEMENT_DEFINITION_TABLE), psql:MYSQL_SPECIFICS),
            [GUIDANCE_RESPONSE_TABLE]: check new (dbClient, self.metadata.get(GUIDANCE_RESPONSE_TABLE), psql:MYSQL_SPECIFICS),
            [LINKAGE_TABLE]: check new (dbClient, self.metadata.get(LINKAGE_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICINAL_PRODUCT_TABLE]: check new (dbClient, self.metadata.get(MEDICINAL_PRODUCT_TABLE), psql:MYSQL_SPECIFICS),
            [DEVICE_DEFINITION_TABLE]: check new (dbClient, self.metadata.get(DEVICE_DEFINITION_TABLE), psql:MYSQL_SPECIFICS),
            [COVERAGE_ELIGIBILITY_REQUEST_TABLE]: check new (dbClient, self.metadata.get(COVERAGE_ELIGIBILITY_REQUEST_TABLE), psql:MYSQL_SPECIFICS),
            [PATIENT_TABLE]: check new (dbClient, self.metadata.get(PATIENT_TABLE), psql:MYSQL_SPECIFICS),
            [COVERAGE_TABLE]: check new (dbClient, self.metadata.get(COVERAGE_TABLE), psql:MYSQL_SPECIFICS),
            [SUBSTANCE_TABLE]: check new (dbClient, self.metadata.get(SUBSTANCE_TABLE), psql:MYSQL_SPECIFICS),
            [CHARGE_ITEM_DEFINITION_TABLE]: check new (dbClient, self.metadata.get(CHARGE_ITEM_DEFINITION_TABLE), psql:MYSQL_SPECIFICS),
            [MEDICINAL_PRODUCT_INTERACTION_TABLE]: check new (dbClient, self.metadata.get(MEDICINAL_PRODUCT_INTERACTION_TABLE), psql:MYSQL_SPECIFICS),
            [ACCOUNT_TABLE]: check new (dbClient, self.metadata.get(ACCOUNT_TABLE), psql:MYSQL_SPECIFICS),
            [MESSAGE_HEADER_TABLE]: check new (dbClient, self.metadata.get(MESSAGE_HEADER_TABLE), psql:MYSQL_SPECIFICS),
            [AUDIT_EVENT_TABLE]: check new (dbClient, self.metadata.get(AUDIT_EVENT_TABLE), psql:MYSQL_SPECIFICS),
            [NUTRITION_ORDER_TABLE]: check new (dbClient, self.metadata.get(NUTRITION_ORDER_TABLE), psql:MYSQL_SPECIFICS),
            [QUESTIONNAIRE_TABLE]: check new (dbClient, self.metadata.get(QUESTIONNAIRE_TABLE), psql:MYSQL_SPECIFICS),
            [APPOINTMENT_RESPONSE_TABLE]: check new (dbClient, self.metadata.get(APPOINTMENT_RESPONSE_TABLE), psql:MYSQL_SPECIFICS)
        };
    }

    isolated resource function get search_param_res_expressions(SEARCH_PARAM_RES_EXPRESSIONSTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get search_param_res_expressions/[int ID](SEARCH_PARAM_RES_EXPRESSIONSTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post search_param_res_expressions(SEARCH_PARAM_RES_EXPRESSIONSInsert[] data) returns int[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(S_E_A_R_C_H__P_A_R_A_M__R_E_S__E_X_P_R_E_S_S_I_O_N_S);
        }
        sql:ExecutionResult[] result = check sqlClient.runBatchInsertQuery(data);
        return from sql:ExecutionResult inserted in result
            where inserted.lastInsertId != ()
            select <int>inserted.lastInsertId;
    }

    isolated resource function put search_param_res_expressions/[int ID](SEARCH_PARAM_RES_EXPRESSIONSUpdate value) returns SEARCH_PARAM_RES_EXPRESSIONS|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(S_E_A_R_C_H__P_A_R_A_M__R_E_S__E_X_P_R_E_S_S_I_O_N_S);
        }
        _ = check sqlClient.runUpdateQuery(ID, value);
        return self->/search_param_res_expressions/[ID].get();
    }

    isolated resource function delete search_param_res_expressions/[int ID]() returns SEARCH_PARAM_RES_EXPRESSIONS|persist:Error {
        SEARCH_PARAM_RES_EXPRESSIONS result = check self->/search_param_res_expressions/[ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(S_E_A_R_C_H__P_A_R_A_M__R_E_S__E_X_P_R_E_S_S_I_O_N_S);
        }
        _ = check sqlClient.runDeleteQuery(ID);
        return result;
    }

    isolated resource function get references(REFERENCESTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get references/[int ID](REFERENCESTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post references(REFERENCESInsert[] data) returns int[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(R_E_F_E_R_E_N_C_E_S);
        }
        sql:ExecutionResult[] result = check sqlClient.runBatchInsertQuery(data);
        return from sql:ExecutionResult inserted in result
            where inserted.lastInsertId != ()
            select <int>inserted.lastInsertId;
    }

    isolated resource function put references/[int ID](REFERENCESUpdate value) returns REFERENCES|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(R_E_F_E_R_E_N_C_E_S);
        }
        _ = check sqlClient.runUpdateQuery(ID, value);
        return self->/references/[ID].get();
    }

    isolated resource function delete references/[int ID]() returns REFERENCES|persist:Error {
        REFERENCES result = check self->/references/[ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(R_E_F_E_R_E_N_C_E_S);
        }
        _ = check sqlClient.runDeleteQuery(ID);
        return result;
    }

    isolated resource function get testscripttables(TestScriptTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get testscripttables/[string TESTSCRIPTTABLE_ID](TestScriptTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post testscripttables(TestScriptTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TEST_SCRIPT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from TestScriptTableInsert inserted in data
            select inserted.TESTSCRIPTTABLE_ID;
    }

    isolated resource function put testscripttables/[string TESTSCRIPTTABLE_ID](TestScriptTableUpdate value) returns TestScriptTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TEST_SCRIPT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(TESTSCRIPTTABLE_ID, value);
        return self->/testscripttables/[TESTSCRIPTTABLE_ID].get();
    }

    isolated resource function delete testscripttables/[string TESTSCRIPTTABLE_ID]() returns TestScriptTable|persist:Error {
        TestScriptTable result = check self->/testscripttables/[TESTSCRIPTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TEST_SCRIPT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(TESTSCRIPTTABLE_ID);
        return result;
    }

    isolated resource function get testreporttables(TestReportTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get testreporttables/[string TESTREPORTTABLE_ID](TestReportTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post testreporttables(TestReportTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TEST_REPORT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from TestReportTableInsert inserted in data
            select inserted.TESTREPORTTABLE_ID;
    }

    isolated resource function put testreporttables/[string TESTREPORTTABLE_ID](TestReportTableUpdate value) returns TestReportTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TEST_REPORT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(TESTREPORTTABLE_ID, value);
        return self->/testreporttables/[TESTREPORTTABLE_ID].get();
    }

    isolated resource function delete testreporttables/[string TESTREPORTTABLE_ID]() returns TestReportTable|persist:Error {
        TestReportTable result = check self->/testreporttables/[TESTREPORTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TEST_REPORT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(TESTREPORTTABLE_ID);
        return result;
    }

    isolated resource function get relatedpersontables(RelatedPersonTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get relatedpersontables/[string RELATEDPERSONTABLE_ID](RelatedPersonTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post relatedpersontables(RelatedPersonTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RELATED_PERSON_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from RelatedPersonTableInsert inserted in data
            select inserted.RELATEDPERSONTABLE_ID;
    }

    isolated resource function put relatedpersontables/[string RELATEDPERSONTABLE_ID](RelatedPersonTableUpdate value) returns RelatedPersonTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RELATED_PERSON_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(RELATEDPERSONTABLE_ID, value);
        return self->/relatedpersontables/[RELATEDPERSONTABLE_ID].get();
    }

    isolated resource function delete relatedpersontables/[string RELATEDPERSONTABLE_ID]() returns RelatedPersonTable|persist:Error {
        RelatedPersonTable result = check self->/relatedpersontables/[RELATEDPERSONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RELATED_PERSON_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(RELATEDPERSONTABLE_ID);
        return result;
    }

    isolated resource function get evidencevariabletables(EvidenceVariableTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get evidencevariabletables/[string EVIDENCEVARIABLETABLE_ID](EvidenceVariableTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post evidencevariabletables(EvidenceVariableTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EVIDENCE_VARIABLE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from EvidenceVariableTableInsert inserted in data
            select inserted.EVIDENCEVARIABLETABLE_ID;
    }

    isolated resource function put evidencevariabletables/[string EVIDENCEVARIABLETABLE_ID](EvidenceVariableTableUpdate value) returns EvidenceVariableTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EVIDENCE_VARIABLE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(EVIDENCEVARIABLETABLE_ID, value);
        return self->/evidencevariabletables/[EVIDENCEVARIABLETABLE_ID].get();
    }

    isolated resource function delete evidencevariabletables/[string EVIDENCEVARIABLETABLE_ID]() returns EvidenceVariableTable|persist:Error {
        EvidenceVariableTable result = check self->/evidencevariabletables/[EVIDENCEVARIABLETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EVIDENCE_VARIABLE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(EVIDENCEVARIABLETABLE_ID);
        return result;
    }

    isolated resource function get valuesettables(ValueSetTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get valuesettables/[string VALUESETTABLE_ID](ValueSetTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post valuesettables(ValueSetTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VALUE_SET_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ValueSetTableInsert inserted in data
            select inserted.VALUESETTABLE_ID;
    }

    isolated resource function put valuesettables/[string VALUESETTABLE_ID](ValueSetTableUpdate value) returns ValueSetTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VALUE_SET_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(VALUESETTABLE_ID, value);
        return self->/valuesettables/[VALUESETTABLE_ID].get();
    }

    isolated resource function delete valuesettables/[string VALUESETTABLE_ID]() returns ValueSetTable|persist:Error {
        ValueSetTable result = check self->/valuesettables/[VALUESETTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VALUE_SET_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(VALUESETTABLE_ID);
        return result;
    }

    isolated resource function get documentmanifesttables(DocumentManifestTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get documentmanifesttables/[string DOCUMENTMANIFESTTABLE_ID](DocumentManifestTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post documentmanifesttables(DocumentManifestTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DOCUMENT_MANIFEST_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from DocumentManifestTableInsert inserted in data
            select inserted.DOCUMENTMANIFESTTABLE_ID;
    }

    isolated resource function put documentmanifesttables/[string DOCUMENTMANIFESTTABLE_ID](DocumentManifestTableUpdate value) returns DocumentManifestTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DOCUMENT_MANIFEST_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(DOCUMENTMANIFESTTABLE_ID, value);
        return self->/documentmanifesttables/[DOCUMENTMANIFESTTABLE_ID].get();
    }

    isolated resource function delete documentmanifesttables/[string DOCUMENTMANIFESTTABLE_ID]() returns DocumentManifestTable|persist:Error {
        DocumentManifestTable result = check self->/documentmanifesttables/[DOCUMENTMANIFESTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DOCUMENT_MANIFEST_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(DOCUMENTMANIFESTTABLE_ID);
        return result;
    }

    isolated resource function get immunizationrecommendationtables(ImmunizationRecommendationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get immunizationrecommendationtables/[string IMMUNIZATIONRECOMMENDATIONTABLE_ID](ImmunizationRecommendationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post immunizationrecommendationtables(ImmunizationRecommendationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMMUNIZATION_RECOMMENDATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ImmunizationRecommendationTableInsert inserted in data
            select inserted.IMMUNIZATIONRECOMMENDATIONTABLE_ID;
    }

    isolated resource function put immunizationrecommendationtables/[string IMMUNIZATIONRECOMMENDATIONTABLE_ID](ImmunizationRecommendationTableUpdate value) returns ImmunizationRecommendationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMMUNIZATION_RECOMMENDATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(IMMUNIZATIONRECOMMENDATIONTABLE_ID, value);
        return self->/immunizationrecommendationtables/[IMMUNIZATIONRECOMMENDATIONTABLE_ID].get();
    }

    isolated resource function delete immunizationrecommendationtables/[string IMMUNIZATIONRECOMMENDATIONTABLE_ID]() returns ImmunizationRecommendationTable|persist:Error {
        ImmunizationRecommendationTable result = check self->/immunizationrecommendationtables/[IMMUNIZATIONRECOMMENDATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMMUNIZATION_RECOMMENDATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(IMMUNIZATIONRECOMMENDATIONTABLE_ID);
        return result;
    }

    isolated resource function get devicemetrictables(DeviceMetricTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get devicemetrictables/[string DEVICEMETRICTABLE_ID](DeviceMetricTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post devicemetrictables(DeviceMetricTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_METRIC_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from DeviceMetricTableInsert inserted in data
            select inserted.DEVICEMETRICTABLE_ID;
    }

    isolated resource function put devicemetrictables/[string DEVICEMETRICTABLE_ID](DeviceMetricTableUpdate value) returns DeviceMetricTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_METRIC_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(DEVICEMETRICTABLE_ID, value);
        return self->/devicemetrictables/[DEVICEMETRICTABLE_ID].get();
    }

    isolated resource function delete devicemetrictables/[string DEVICEMETRICTABLE_ID]() returns DeviceMetricTable|persist:Error {
        DeviceMetricTable result = check self->/devicemetrictables/[DEVICEMETRICTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_METRIC_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(DEVICEMETRICTABLE_ID);
        return result;
    }

    isolated resource function get locationtables(LocationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get locationtables/[string LOCATIONTABLE_ID](LocationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post locationtables(LocationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(LOCATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from LocationTableInsert inserted in data
            select inserted.LOCATIONTABLE_ID;
    }

    isolated resource function put locationtables/[string LOCATIONTABLE_ID](LocationTableUpdate value) returns LocationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(LOCATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(LOCATIONTABLE_ID, value);
        return self->/locationtables/[LOCATIONTABLE_ID].get();
    }

    isolated resource function delete locationtables/[string LOCATIONTABLE_ID]() returns LocationTable|persist:Error {
        LocationTable result = check self->/locationtables/[LOCATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(LOCATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(LOCATIONTABLE_ID);
        return result;
    }

    isolated resource function get explanationofbenefittables(ExplanationOfBenefitTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get explanationofbenefittables/[string EXPLANATIONOFBENEFITTABLE_ID](ExplanationOfBenefitTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post explanationofbenefittables(ExplanationOfBenefitTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EXPLANATION_OF_BENEFIT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ExplanationOfBenefitTableInsert inserted in data
            select inserted.EXPLANATIONOFBENEFITTABLE_ID;
    }

    isolated resource function put explanationofbenefittables/[string EXPLANATIONOFBENEFITTABLE_ID](ExplanationOfBenefitTableUpdate value) returns ExplanationOfBenefitTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EXPLANATION_OF_BENEFIT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(EXPLANATIONOFBENEFITTABLE_ID, value);
        return self->/explanationofbenefittables/[EXPLANATIONOFBENEFITTABLE_ID].get();
    }

    isolated resource function delete explanationofbenefittables/[string EXPLANATIONOFBENEFITTABLE_ID]() returns ExplanationOfBenefitTable|persist:Error {
        ExplanationOfBenefitTable result = check self->/explanationofbenefittables/[EXPLANATIONOFBENEFITTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EXPLANATION_OF_BENEFIT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(EXPLANATIONOFBENEFITTABLE_ID);
        return result;
    }

    isolated resource function get flagtables(FlagTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get flagtables/[string FLAGTABLE_ID](FlagTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post flagtables(FlagTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(FLAG_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from FlagTableInsert inserted in data
            select inserted.FLAGTABLE_ID;
    }

    isolated resource function put flagtables/[string FLAGTABLE_ID](FlagTableUpdate value) returns FlagTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(FLAG_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(FLAGTABLE_ID, value);
        return self->/flagtables/[FLAGTABLE_ID].get();
    }

    isolated resource function delete flagtables/[string FLAGTABLE_ID]() returns FlagTable|persist:Error {
        FlagTable result = check self->/flagtables/[FLAGTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(FLAG_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(FLAGTABLE_ID);
        return result;
    }

    isolated resource function get medicationstatementtables(MedicationStatementTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicationstatementtables/[string MEDICATIONSTATEMENTTABLE_ID](MedicationStatementTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicationstatementtables(MedicationStatementTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_STATEMENT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicationStatementTableInsert inserted in data
            select inserted.MEDICATIONSTATEMENTTABLE_ID;
    }

    isolated resource function put medicationstatementtables/[string MEDICATIONSTATEMENTTABLE_ID](MedicationStatementTableUpdate value) returns MedicationStatementTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_STATEMENT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICATIONSTATEMENTTABLE_ID, value);
        return self->/medicationstatementtables/[MEDICATIONSTATEMENTTABLE_ID].get();
    }

    isolated resource function delete medicationstatementtables/[string MEDICATIONSTATEMENTTABLE_ID]() returns MedicationStatementTable|persist:Error {
        MedicationStatementTable result = check self->/medicationstatementtables/[MEDICATIONSTATEMENTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_STATEMENT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICATIONSTATEMENTTABLE_ID);
        return result;
    }

    isolated resource function get insuranceplantables(InsurancePlanTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get insuranceplantables/[string INSURANCEPLANTABLE_ID](InsurancePlanTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post insuranceplantables(InsurancePlanTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(INSURANCE_PLAN_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from InsurancePlanTableInsert inserted in data
            select inserted.INSURANCEPLANTABLE_ID;
    }

    isolated resource function put insuranceplantables/[string INSURANCEPLANTABLE_ID](InsurancePlanTableUpdate value) returns InsurancePlanTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(INSURANCE_PLAN_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(INSURANCEPLANTABLE_ID, value);
        return self->/insuranceplantables/[INSURANCEPLANTABLE_ID].get();
    }

    isolated resource function delete insuranceplantables/[string INSURANCEPLANTABLE_ID]() returns InsurancePlanTable|persist:Error {
        InsurancePlanTable result = check self->/insuranceplantables/[INSURANCEPLANTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(INSURANCE_PLAN_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(INSURANCEPLANTABLE_ID);
        return result;
    }

    isolated resource function get medicinalproductcontraindicationtables(MedicinalProductContraindicationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicinalproductcontraindicationtables/[string MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID](MedicinalProductContraindicationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicinalproductcontraindicationtables(MedicinalProductContraindicationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_CONTRAINDICATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicinalProductContraindicationTableInsert inserted in data
            select inserted.MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID;
    }

    isolated resource function put medicinalproductcontraindicationtables/[string MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID](MedicinalProductContraindicationTableUpdate value) returns MedicinalProductContraindicationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_CONTRAINDICATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID, value);
        return self->/medicinalproductcontraindicationtables/[MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID].get();
    }

    isolated resource function delete medicinalproductcontraindicationtables/[string MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID]() returns MedicinalProductContraindicationTable|persist:Error {
        MedicinalProductContraindicationTable result = check self->/medicinalproductcontraindicationtables/[MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_CONTRAINDICATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID);
        return result;
    }

    isolated resource function get claimresponsetables(ClaimResponseTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get claimresponsetables/[string CLAIMRESPONSETABLE_ID](ClaimResponseTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post claimresponsetables(ClaimResponseTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CLAIM_RESPONSE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ClaimResponseTableInsert inserted in data
            select inserted.CLAIMRESPONSETABLE_ID;
    }

    isolated resource function put claimresponsetables/[string CLAIMRESPONSETABLE_ID](ClaimResponseTableUpdate value) returns ClaimResponseTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CLAIM_RESPONSE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(CLAIMRESPONSETABLE_ID, value);
        return self->/claimresponsetables/[CLAIMRESPONSETABLE_ID].get();
    }

    isolated resource function delete claimresponsetables/[string CLAIMRESPONSETABLE_ID]() returns ClaimResponseTable|persist:Error {
        ClaimResponseTable result = check self->/claimresponsetables/[CLAIMRESPONSETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CLAIM_RESPONSE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(CLAIMRESPONSETABLE_ID);
        return result;
    }

    isolated resource function get medicinalproductauthorizationtables(MedicinalProductAuthorizationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicinalproductauthorizationtables/[string MEDICINALPRODUCTAUTHORIZATIONTABLE_ID](MedicinalProductAuthorizationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicinalproductauthorizationtables(MedicinalProductAuthorizationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_AUTHORIZATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicinalProductAuthorizationTableInsert inserted in data
            select inserted.MEDICINALPRODUCTAUTHORIZATIONTABLE_ID;
    }

    isolated resource function put medicinalproductauthorizationtables/[string MEDICINALPRODUCTAUTHORIZATIONTABLE_ID](MedicinalProductAuthorizationTableUpdate value) returns MedicinalProductAuthorizationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_AUTHORIZATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICINALPRODUCTAUTHORIZATIONTABLE_ID, value);
        return self->/medicinalproductauthorizationtables/[MEDICINALPRODUCTAUTHORIZATIONTABLE_ID].get();
    }

    isolated resource function delete medicinalproductauthorizationtables/[string MEDICINALPRODUCTAUTHORIZATIONTABLE_ID]() returns MedicinalProductAuthorizationTable|persist:Error {
        MedicinalProductAuthorizationTable result = check self->/medicinalproductauthorizationtables/[MEDICINALPRODUCTAUTHORIZATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_AUTHORIZATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICINALPRODUCTAUTHORIZATIONTABLE_ID);
        return result;
    }

    isolated resource function get imagingstudytables(ImagingStudyTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get imagingstudytables/[string IMAGINGSTUDYTABLE_ID](ImagingStudyTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post imagingstudytables(ImagingStudyTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMAGING_STUDY_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ImagingStudyTableInsert inserted in data
            select inserted.IMAGINGSTUDYTABLE_ID;
    }

    isolated resource function put imagingstudytables/[string IMAGINGSTUDYTABLE_ID](ImagingStudyTableUpdate value) returns ImagingStudyTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMAGING_STUDY_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(IMAGINGSTUDYTABLE_ID, value);
        return self->/imagingstudytables/[IMAGINGSTUDYTABLE_ID].get();
    }

    isolated resource function delete imagingstudytables/[string IMAGINGSTUDYTABLE_ID]() returns ImagingStudyTable|persist:Error {
        ImagingStudyTable result = check self->/imagingstudytables/[IMAGINGSTUDYTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMAGING_STUDY_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(IMAGINGSTUDYTABLE_ID);
        return result;
    }

    isolated resource function get practitionerroletables(PractitionerRoleTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get practitionerroletables/[string PRACTITIONERROLETABLE_ID](PractitionerRoleTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post practitionerroletables(PractitionerRoleTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PRACTITIONER_ROLE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from PractitionerRoleTableInsert inserted in data
            select inserted.PRACTITIONERROLETABLE_ID;
    }

    isolated resource function put practitionerroletables/[string PRACTITIONERROLETABLE_ID](PractitionerRoleTableUpdate value) returns PractitionerRoleTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PRACTITIONER_ROLE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(PRACTITIONERROLETABLE_ID, value);
        return self->/practitionerroletables/[PRACTITIONERROLETABLE_ID].get();
    }

    isolated resource function delete practitionerroletables/[string PRACTITIONERROLETABLE_ID]() returns PractitionerRoleTable|persist:Error {
        PractitionerRoleTable result = check self->/practitionerroletables/[PRACTITIONERROLETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PRACTITIONER_ROLE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(PRACTITIONERROLETABLE_ID);
        return result;
    }

    isolated resource function get grouptables(GroupTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get grouptables/[string GROUPTABLE_ID](GroupTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post grouptables(GroupTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GROUP_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from GroupTableInsert inserted in data
            select inserted.GROUPTABLE_ID;
    }

    isolated resource function put grouptables/[string GROUPTABLE_ID](GroupTableUpdate value) returns GroupTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GROUP_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(GROUPTABLE_ID, value);
        return self->/grouptables/[GROUPTABLE_ID].get();
    }

    isolated resource function delete grouptables/[string GROUPTABLE_ID]() returns GroupTable|persist:Error {
        GroupTable result = check self->/grouptables/[GROUPTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GROUP_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(GROUPTABLE_ID);
        return result;
    }

    isolated resource function get persontables(PersonTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get persontables/[string PERSONTABLE_ID](PersonTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post persontables(PersonTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PERSON_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from PersonTableInsert inserted in data
            select inserted.PERSONTABLE_ID;
    }

    isolated resource function put persontables/[string PERSONTABLE_ID](PersonTableUpdate value) returns PersonTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PERSON_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(PERSONTABLE_ID, value);
        return self->/persontables/[PERSONTABLE_ID].get();
    }

    isolated resource function delete persontables/[string PERSONTABLE_ID]() returns PersonTable|persist:Error {
        PersonTable result = check self->/persontables/[PERSONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PERSON_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(PERSONTABLE_ID);
        return result;
    }

    isolated resource function get practitionertables(PractitionerTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get practitionertables/[string PRACTITIONERTABLE_ID](PractitionerTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post practitionertables(PractitionerTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PRACTITIONER_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from PractitionerTableInsert inserted in data
            select inserted.PRACTITIONERTABLE_ID;
    }

    isolated resource function put practitionertables/[string PRACTITIONERTABLE_ID](PractitionerTableUpdate value) returns PractitionerTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PRACTITIONER_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(PRACTITIONERTABLE_ID, value);
        return self->/practitionertables/[PRACTITIONERTABLE_ID].get();
    }

    isolated resource function delete practitionertables/[string PRACTITIONERTABLE_ID]() returns PractitionerTable|persist:Error {
        PractitionerTable result = check self->/practitionertables/[PRACTITIONERTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PRACTITIONER_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(PRACTITIONERTABLE_ID);
        return result;
    }

    isolated resource function get activitydefinitiontables(ActivityDefinitionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get activitydefinitiontables/[string ACTIVITYDEFINITIONTABLE_ID](ActivityDefinitionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post activitydefinitiontables(ActivityDefinitionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ACTIVITY_DEFINITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ActivityDefinitionTableInsert inserted in data
            select inserted.ACTIVITYDEFINITIONTABLE_ID;
    }

    isolated resource function put activitydefinitiontables/[string ACTIVITYDEFINITIONTABLE_ID](ActivityDefinitionTableUpdate value) returns ActivityDefinitionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ACTIVITY_DEFINITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(ACTIVITYDEFINITIONTABLE_ID, value);
        return self->/activitydefinitiontables/[ACTIVITYDEFINITIONTABLE_ID].get();
    }

    isolated resource function delete activitydefinitiontables/[string ACTIVITYDEFINITIONTABLE_ID]() returns ActivityDefinitionTable|persist:Error {
        ActivityDefinitionTable result = check self->/activitydefinitiontables/[ACTIVITYDEFINITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ACTIVITY_DEFINITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(ACTIVITYDEFINITIONTABLE_ID);
        return result;
    }

    isolated resource function get evidencetables(EvidenceTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get evidencetables/[string EVIDENCETABLE_ID](EvidenceTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post evidencetables(EvidenceTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EVIDENCE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from EvidenceTableInsert inserted in data
            select inserted.EVIDENCETABLE_ID;
    }

    isolated resource function put evidencetables/[string EVIDENCETABLE_ID](EvidenceTableUpdate value) returns EvidenceTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EVIDENCE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(EVIDENCETABLE_ID, value);
        return self->/evidencetables/[EVIDENCETABLE_ID].get();
    }

    isolated resource function delete evidencetables/[string EVIDENCETABLE_ID]() returns EvidenceTable|persist:Error {
        EvidenceTable result = check self->/evidencetables/[EVIDENCETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EVIDENCE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(EVIDENCETABLE_ID);
        return result;
    }

    isolated resource function get devicetables(DeviceTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get devicetables/[string DEVICETABLE_ID](DeviceTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post devicetables(DeviceTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from DeviceTableInsert inserted in data
            select inserted.DEVICETABLE_ID;
    }

    isolated resource function put devicetables/[string DEVICETABLE_ID](DeviceTableUpdate value) returns DeviceTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(DEVICETABLE_ID, value);
        return self->/devicetables/[DEVICETABLE_ID].get();
    }

    isolated resource function delete devicetables/[string DEVICETABLE_ID]() returns DeviceTable|persist:Error {
        DeviceTable result = check self->/devicetables/[DEVICETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(DEVICETABLE_ID);
        return result;
    }

    isolated resource function get familymemberhistorytables(FamilyMemberHistoryTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get familymemberhistorytables/[string FAMILYMEMBERHISTORYTABLE_ID](FamilyMemberHistoryTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post familymemberhistorytables(FamilyMemberHistoryTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(FAMILY_MEMBER_HISTORY_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from FamilyMemberHistoryTableInsert inserted in data
            select inserted.FAMILYMEMBERHISTORYTABLE_ID;
    }

    isolated resource function put familymemberhistorytables/[string FAMILYMEMBERHISTORYTABLE_ID](FamilyMemberHistoryTableUpdate value) returns FamilyMemberHistoryTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(FAMILY_MEMBER_HISTORY_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(FAMILYMEMBERHISTORYTABLE_ID, value);
        return self->/familymemberhistorytables/[FAMILYMEMBERHISTORYTABLE_ID].get();
    }

    isolated resource function delete familymemberhistorytables/[string FAMILYMEMBERHISTORYTABLE_ID]() returns FamilyMemberHistoryTable|persist:Error {
        FamilyMemberHistoryTable result = check self->/familymemberhistorytables/[FAMILYMEMBERHISTORYTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(FAMILY_MEMBER_HISTORY_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(FAMILYMEMBERHISTORYTABLE_ID);
        return result;
    }

    isolated resource function get adverseeventtables(AdverseEventTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get adverseeventtables/[string ADVERSEEVENTTABLE_ID](AdverseEventTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post adverseeventtables(AdverseEventTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ADVERSE_EVENT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from AdverseEventTableInsert inserted in data
            select inserted.ADVERSEEVENTTABLE_ID;
    }

    isolated resource function put adverseeventtables/[string ADVERSEEVENTTABLE_ID](AdverseEventTableUpdate value) returns AdverseEventTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ADVERSE_EVENT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(ADVERSEEVENTTABLE_ID, value);
        return self->/adverseeventtables/[ADVERSEEVENTTABLE_ID].get();
    }

    isolated resource function delete adverseeventtables/[string ADVERSEEVENTTABLE_ID]() returns AdverseEventTable|persist:Error {
        AdverseEventTable result = check self->/adverseeventtables/[ADVERSEEVENTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ADVERSE_EVENT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(ADVERSEEVENTTABLE_ID);
        return result;
    }

    isolated resource function get supplyrequesttables(SupplyRequestTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get supplyrequesttables/[string SUPPLYREQUESTTABLE_ID](SupplyRequestTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post supplyrequesttables(SupplyRequestTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUPPLY_REQUEST_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from SupplyRequestTableInsert inserted in data
            select inserted.SUPPLYREQUESTTABLE_ID;
    }

    isolated resource function put supplyrequesttables/[string SUPPLYREQUESTTABLE_ID](SupplyRequestTableUpdate value) returns SupplyRequestTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUPPLY_REQUEST_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(SUPPLYREQUESTTABLE_ID, value);
        return self->/supplyrequesttables/[SUPPLYREQUESTTABLE_ID].get();
    }

    isolated resource function delete supplyrequesttables/[string SUPPLYREQUESTTABLE_ID]() returns SupplyRequestTable|persist:Error {
        SupplyRequestTable result = check self->/supplyrequesttables/[SUPPLYREQUESTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUPPLY_REQUEST_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(SUPPLYREQUESTTABLE_ID);
        return result;
    }

    isolated resource function get examplescenariotables(ExampleScenarioTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get examplescenariotables/[string EXAMPLESCENARIOTABLE_ID](ExampleScenarioTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post examplescenariotables(ExampleScenarioTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EXAMPLE_SCENARIO_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ExampleScenarioTableInsert inserted in data
            select inserted.EXAMPLESCENARIOTABLE_ID;
    }

    isolated resource function put examplescenariotables/[string EXAMPLESCENARIOTABLE_ID](ExampleScenarioTableUpdate value) returns ExampleScenarioTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EXAMPLE_SCENARIO_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(EXAMPLESCENARIOTABLE_ID, value);
        return self->/examplescenariotables/[EXAMPLESCENARIOTABLE_ID].get();
    }

    isolated resource function delete examplescenariotables/[string EXAMPLESCENARIOTABLE_ID]() returns ExampleScenarioTable|persist:Error {
        ExampleScenarioTable result = check self->/examplescenariotables/[EXAMPLESCENARIOTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EXAMPLE_SCENARIO_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(EXAMPLESCENARIOTABLE_ID);
        return result;
    }

    isolated resource function get invoicetables(InvoiceTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get invoicetables/[string INVOICETABLE_ID](InvoiceTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post invoicetables(InvoiceTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(INVOICE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from InvoiceTableInsert inserted in data
            select inserted.INVOICETABLE_ID;
    }

    isolated resource function put invoicetables/[string INVOICETABLE_ID](InvoiceTableUpdate value) returns InvoiceTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(INVOICE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(INVOICETABLE_ID, value);
        return self->/invoicetables/[INVOICETABLE_ID].get();
    }

    isolated resource function delete invoicetables/[string INVOICETABLE_ID]() returns InvoiceTable|persist:Error {
        InvoiceTable result = check self->/invoicetables/[INVOICETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(INVOICE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(INVOICETABLE_ID);
        return result;
    }

    isolated resource function get questionnaireresponsetables(QuestionnaireResponseTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get questionnaireresponsetables/[string QUESTIONNAIRERESPONSETABLE_ID](QuestionnaireResponseTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post questionnaireresponsetables(QuestionnaireResponseTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(QUESTIONNAIRE_RESPONSE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from QuestionnaireResponseTableInsert inserted in data
            select inserted.QUESTIONNAIRERESPONSETABLE_ID;
    }

    isolated resource function put questionnaireresponsetables/[string QUESTIONNAIRERESPONSETABLE_ID](QuestionnaireResponseTableUpdate value) returns QuestionnaireResponseTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(QUESTIONNAIRE_RESPONSE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(QUESTIONNAIRERESPONSETABLE_ID, value);
        return self->/questionnaireresponsetables/[QUESTIONNAIRERESPONSETABLE_ID].get();
    }

    isolated resource function delete questionnaireresponsetables/[string QUESTIONNAIRERESPONSETABLE_ID]() returns QuestionnaireResponseTable|persist:Error {
        QuestionnaireResponseTable result = check self->/questionnaireresponsetables/[QUESTIONNAIRERESPONSETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(QUESTIONNAIRE_RESPONSE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(QUESTIONNAIRERESPONSETABLE_ID);
        return result;
    }

    isolated resource function get observationtables(ObservationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get observationtables/[string OBSERVATIONTABLE_ID](ObservationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post observationtables(ObservationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(OBSERVATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ObservationTableInsert inserted in data
            select inserted.OBSERVATIONTABLE_ID;
    }

    isolated resource function put observationtables/[string OBSERVATIONTABLE_ID](ObservationTableUpdate value) returns ObservationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(OBSERVATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(OBSERVATIONTABLE_ID, value);
        return self->/observationtables/[OBSERVATIONTABLE_ID].get();
    }

    isolated resource function delete observationtables/[string OBSERVATIONTABLE_ID]() returns ObservationTable|persist:Error {
        ObservationTable result = check self->/observationtables/[OBSERVATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(OBSERVATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(OBSERVATIONTABLE_ID);
        return result;
    }

    isolated resource function get effectevidencesynthesistables(EffectEvidenceSynthesisTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get effectevidencesynthesistables/[string EFFECTEVIDENCESYNTHESISTABLE_ID](EffectEvidenceSynthesisTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post effectevidencesynthesistables(EffectEvidenceSynthesisTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EFFECT_EVIDENCE_SYNTHESIS_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from EffectEvidenceSynthesisTableInsert inserted in data
            select inserted.EFFECTEVIDENCESYNTHESISTABLE_ID;
    }

    isolated resource function put effectevidencesynthesistables/[string EFFECTEVIDENCESYNTHESISTABLE_ID](EffectEvidenceSynthesisTableUpdate value) returns EffectEvidenceSynthesisTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EFFECT_EVIDENCE_SYNTHESIS_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(EFFECTEVIDENCESYNTHESISTABLE_ID, value);
        return self->/effectevidencesynthesistables/[EFFECTEVIDENCESYNTHESISTABLE_ID].get();
    }

    isolated resource function delete effectevidencesynthesistables/[string EFFECTEVIDENCESYNTHESISTABLE_ID]() returns EffectEvidenceSynthesisTable|persist:Error {
        EffectEvidenceSynthesisTable result = check self->/effectevidencesynthesistables/[EFFECTEVIDENCESYNTHESISTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EFFECT_EVIDENCE_SYNTHESIS_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(EFFECTEVIDENCESYNTHESISTABLE_ID);
        return result;
    }

    isolated resource function get operationdefinitiontables(OperationDefinitionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get operationdefinitiontables/[string OPERATIONDEFINITIONTABLE_ID](OperationDefinitionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post operationdefinitiontables(OperationDefinitionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(OPERATION_DEFINITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from OperationDefinitionTableInsert inserted in data
            select inserted.OPERATIONDEFINITIONTABLE_ID;
    }

    isolated resource function put operationdefinitiontables/[string OPERATIONDEFINITIONTABLE_ID](OperationDefinitionTableUpdate value) returns OperationDefinitionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(OPERATION_DEFINITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(OPERATIONDEFINITIONTABLE_ID, value);
        return self->/operationdefinitiontables/[OPERATIONDEFINITIONTABLE_ID].get();
    }

    isolated resource function delete operationdefinitiontables/[string OPERATIONDEFINITIONTABLE_ID]() returns OperationDefinitionTable|persist:Error {
        OperationDefinitionTable result = check self->/operationdefinitiontables/[OPERATIONDEFINITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(OPERATION_DEFINITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(OPERATIONDEFINITIONTABLE_ID);
        return result;
    }

    isolated resource function get measurereporttables(MeasureReportTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get measurereporttables/[string MEASUREREPORTTABLE_ID](MeasureReportTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post measurereporttables(MeasureReportTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEASURE_REPORT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MeasureReportTableInsert inserted in data
            select inserted.MEASUREREPORTTABLE_ID;
    }

    isolated resource function put measurereporttables/[string MEASUREREPORTTABLE_ID](MeasureReportTableUpdate value) returns MeasureReportTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEASURE_REPORT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEASUREREPORTTABLE_ID, value);
        return self->/measurereporttables/[MEASUREREPORTTABLE_ID].get();
    }

    isolated resource function delete measurereporttables/[string MEASUREREPORTTABLE_ID]() returns MeasureReportTable|persist:Error {
        MeasureReportTable result = check self->/measurereporttables/[MEASUREREPORTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEASURE_REPORT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEASUREREPORTTABLE_ID);
        return result;
    }

    isolated resource function get supplydeliverytables(SupplyDeliveryTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get supplydeliverytables/[string SUPPLYDELIVERYTABLE_ID](SupplyDeliveryTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post supplydeliverytables(SupplyDeliveryTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUPPLY_DELIVERY_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from SupplyDeliveryTableInsert inserted in data
            select inserted.SUPPLYDELIVERYTABLE_ID;
    }

    isolated resource function put supplydeliverytables/[string SUPPLYDELIVERYTABLE_ID](SupplyDeliveryTableUpdate value) returns SupplyDeliveryTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUPPLY_DELIVERY_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(SUPPLYDELIVERYTABLE_ID, value);
        return self->/supplydeliverytables/[SUPPLYDELIVERYTABLE_ID].get();
    }

    isolated resource function delete supplydeliverytables/[string SUPPLYDELIVERYTABLE_ID]() returns SupplyDeliveryTable|persist:Error {
        SupplyDeliveryTable result = check self->/supplydeliverytables/[SUPPLYDELIVERYTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUPPLY_DELIVERY_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(SUPPLYDELIVERYTABLE_ID);
        return result;
    }

    isolated resource function get servicerequesttables(ServiceRequestTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get servicerequesttables/[string SERVICEREQUESTTABLE_ID](ServiceRequestTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post servicerequesttables(ServiceRequestTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SERVICE_REQUEST_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ServiceRequestTableInsert inserted in data
            select inserted.SERVICEREQUESTTABLE_ID;
    }

    isolated resource function put servicerequesttables/[string SERVICEREQUESTTABLE_ID](ServiceRequestTableUpdate value) returns ServiceRequestTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SERVICE_REQUEST_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(SERVICEREQUESTTABLE_ID, value);
        return self->/servicerequesttables/[SERVICEREQUESTTABLE_ID].get();
    }

    isolated resource function delete servicerequesttables/[string SERVICEREQUESTTABLE_ID]() returns ServiceRequestTable|persist:Error {
        ServiceRequestTable result = check self->/servicerequesttables/[SERVICEREQUESTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SERVICE_REQUEST_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(SERVICEREQUESTTABLE_ID);
        return result;
    }

    isolated resource function get basictables(BasicTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get basictables/[string BASICTABLE_ID](BasicTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post basictables(BasicTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(BASIC_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from BasicTableInsert inserted in data
            select inserted.BASICTABLE_ID;
    }

    isolated resource function put basictables/[string BASICTABLE_ID](BasicTableUpdate value) returns BasicTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(BASIC_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(BASICTABLE_ID, value);
        return self->/basictables/[BASICTABLE_ID].get();
    }

    isolated resource function delete basictables/[string BASICTABLE_ID]() returns BasicTable|persist:Error {
        BasicTable result = check self->/basictables/[BASICTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(BASIC_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(BASICTABLE_ID);
        return result;
    }

    isolated resource function get subscriptiontables(SubscriptionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get subscriptiontables/[string SUBSCRIPTIONTABLE_ID](SubscriptionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post subscriptiontables(SubscriptionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUBSCRIPTION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from SubscriptionTableInsert inserted in data
            select inserted.SUBSCRIPTIONTABLE_ID;
    }

    isolated resource function put subscriptiontables/[string SUBSCRIPTIONTABLE_ID](SubscriptionTableUpdate value) returns SubscriptionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUBSCRIPTION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(SUBSCRIPTIONTABLE_ID, value);
        return self->/subscriptiontables/[SUBSCRIPTIONTABLE_ID].get();
    }

    isolated resource function delete subscriptiontables/[string SUBSCRIPTIONTABLE_ID]() returns SubscriptionTable|persist:Error {
        SubscriptionTable result = check self->/subscriptiontables/[SUBSCRIPTIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUBSCRIPTION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(SUBSCRIPTIONTABLE_ID);
        return result;
    }

    isolated resource function get enrollmentresponsetables(EnrollmentResponseTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get enrollmentresponsetables/[string ENROLLMENTRESPONSETABLE_ID](EnrollmentResponseTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post enrollmentresponsetables(EnrollmentResponseTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENROLLMENT_RESPONSE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from EnrollmentResponseTableInsert inserted in data
            select inserted.ENROLLMENTRESPONSETABLE_ID;
    }

    isolated resource function put enrollmentresponsetables/[string ENROLLMENTRESPONSETABLE_ID](EnrollmentResponseTableUpdate value) returns EnrollmentResponseTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENROLLMENT_RESPONSE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(ENROLLMENTRESPONSETABLE_ID, value);
        return self->/enrollmentresponsetables/[ENROLLMENTRESPONSETABLE_ID].get();
    }

    isolated resource function delete enrollmentresponsetables/[string ENROLLMENTRESPONSETABLE_ID]() returns EnrollmentResponseTable|persist:Error {
        EnrollmentResponseTable result = check self->/enrollmentresponsetables/[ENROLLMENTRESPONSETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENROLLMENT_RESPONSE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(ENROLLMENTRESPONSETABLE_ID);
        return result;
    }

    isolated resource function get devicerequesttables(DeviceRequestTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get devicerequesttables/[string DEVICEREQUESTTABLE_ID](DeviceRequestTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post devicerequesttables(DeviceRequestTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_REQUEST_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from DeviceRequestTableInsert inserted in data
            select inserted.DEVICEREQUESTTABLE_ID;
    }

    isolated resource function put devicerequesttables/[string DEVICEREQUESTTABLE_ID](DeviceRequestTableUpdate value) returns DeviceRequestTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_REQUEST_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(DEVICEREQUESTTABLE_ID, value);
        return self->/devicerequesttables/[DEVICEREQUESTTABLE_ID].get();
    }

    isolated resource function delete devicerequesttables/[string DEVICEREQUESTTABLE_ID]() returns DeviceRequestTable|persist:Error {
        DeviceRequestTable result = check self->/devicerequesttables/[DEVICEREQUESTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_REQUEST_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(DEVICEREQUESTTABLE_ID);
        return result;
    }

    isolated resource function get appointmenttables(AppointmentTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get appointmenttables/[string APPOINTMENTTABLE_ID](AppointmentTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post appointmenttables(AppointmentTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(APPOINTMENT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from AppointmentTableInsert inserted in data
            select inserted.APPOINTMENTTABLE_ID;
    }

    isolated resource function put appointmenttables/[string APPOINTMENTTABLE_ID](AppointmentTableUpdate value) returns AppointmentTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(APPOINTMENT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(APPOINTMENTTABLE_ID, value);
        return self->/appointmenttables/[APPOINTMENTTABLE_ID].get();
    }

    isolated resource function delete appointmenttables/[string APPOINTMENTTABLE_ID]() returns AppointmentTable|persist:Error {
        AppointmentTable result = check self->/appointmenttables/[APPOINTMENTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(APPOINTMENT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(APPOINTMENTTABLE_ID);
        return result;
    }

    isolated resource function get namingsystemtables(NamingSystemTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get namingsystemtables/[string NAMINGSYSTEMTABLE_ID](NamingSystemTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post namingsystemtables(NamingSystemTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(NAMING_SYSTEM_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from NamingSystemTableInsert inserted in data
            select inserted.NAMINGSYSTEMTABLE_ID;
    }

    isolated resource function put namingsystemtables/[string NAMINGSYSTEMTABLE_ID](NamingSystemTableUpdate value) returns NamingSystemTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(NAMING_SYSTEM_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(NAMINGSYSTEMTABLE_ID, value);
        return self->/namingsystemtables/[NAMINGSYSTEMTABLE_ID].get();
    }

    isolated resource function delete namingsystemtables/[string NAMINGSYSTEMTABLE_ID]() returns NamingSystemTable|persist:Error {
        NamingSystemTable result = check self->/namingsystemtables/[NAMINGSYSTEMTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(NAMING_SYSTEM_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(NAMINGSYSTEMTABLE_ID);
        return result;
    }

    isolated resource function get structuredefinitiontables(StructureDefinitionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get structuredefinitiontables/[string STRUCTUREDEFINITIONTABLE_ID](StructureDefinitionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post structuredefinitiontables(StructureDefinitionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(STRUCTURE_DEFINITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from StructureDefinitionTableInsert inserted in data
            select inserted.STRUCTUREDEFINITIONTABLE_ID;
    }

    isolated resource function put structuredefinitiontables/[string STRUCTUREDEFINITIONTABLE_ID](StructureDefinitionTableUpdate value) returns StructureDefinitionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(STRUCTURE_DEFINITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(STRUCTUREDEFINITIONTABLE_ID, value);
        return self->/structuredefinitiontables/[STRUCTUREDEFINITIONTABLE_ID].get();
    }

    isolated resource function delete structuredefinitiontables/[string STRUCTUREDEFINITIONTABLE_ID]() returns StructureDefinitionTable|persist:Error {
        StructureDefinitionTable result = check self->/structuredefinitiontables/[STRUCTUREDEFINITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(STRUCTURE_DEFINITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(STRUCTUREDEFINITIONTABLE_ID);
        return result;
    }

    isolated resource function get clinicalimpressiontables(ClinicalImpressionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get clinicalimpressiontables/[string CLINICALIMPRESSIONTABLE_ID](ClinicalImpressionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post clinicalimpressiontables(ClinicalImpressionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CLINICAL_IMPRESSION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ClinicalImpressionTableInsert inserted in data
            select inserted.CLINICALIMPRESSIONTABLE_ID;
    }

    isolated resource function put clinicalimpressiontables/[string CLINICALIMPRESSIONTABLE_ID](ClinicalImpressionTableUpdate value) returns ClinicalImpressionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CLINICAL_IMPRESSION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(CLINICALIMPRESSIONTABLE_ID, value);
        return self->/clinicalimpressiontables/[CLINICALIMPRESSIONTABLE_ID].get();
    }

    isolated resource function delete clinicalimpressiontables/[string CLINICALIMPRESSIONTABLE_ID]() returns ClinicalImpressionTable|persist:Error {
        ClinicalImpressionTable result = check self->/clinicalimpressiontables/[CLINICALIMPRESSIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CLINICAL_IMPRESSION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(CLINICALIMPRESSIONTABLE_ID);
        return result;
    }

    isolated resource function get communicationtables(CommunicationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get communicationtables/[string COMMUNICATIONTABLE_ID](CommunicationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post communicationtables(CommunicationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COMMUNICATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from CommunicationTableInsert inserted in data
            select inserted.COMMUNICATIONTABLE_ID;
    }

    isolated resource function put communicationtables/[string COMMUNICATIONTABLE_ID](CommunicationTableUpdate value) returns CommunicationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COMMUNICATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(COMMUNICATIONTABLE_ID, value);
        return self->/communicationtables/[COMMUNICATIONTABLE_ID].get();
    }

    isolated resource function delete communicationtables/[string COMMUNICATIONTABLE_ID]() returns CommunicationTable|persist:Error {
        CommunicationTable result = check self->/communicationtables/[COMMUNICATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COMMUNICATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(COMMUNICATIONTABLE_ID);
        return result;
    }

    isolated resource function get organizationtables(OrganizationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get organizationtables/[string ORGANIZATIONTABLE_ID](OrganizationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post organizationtables(OrganizationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ORGANIZATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from OrganizationTableInsert inserted in data
            select inserted.ORGANIZATIONTABLE_ID;
    }

    isolated resource function put organizationtables/[string ORGANIZATIONTABLE_ID](OrganizationTableUpdate value) returns OrganizationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ORGANIZATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(ORGANIZATIONTABLE_ID, value);
        return self->/organizationtables/[ORGANIZATIONTABLE_ID].get();
    }

    isolated resource function delete organizationtables/[string ORGANIZATIONTABLE_ID]() returns OrganizationTable|persist:Error {
        OrganizationTable result = check self->/organizationtables/[ORGANIZATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ORGANIZATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(ORGANIZATIONTABLE_ID);
        return result;
    }

    isolated resource function get coverageeligibilityresponsetables(CoverageEligibilityResponseTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get coverageeligibilityresponsetables/[string COVERAGEELIGIBILITYRESPONSETABLE_ID](CoverageEligibilityResponseTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post coverageeligibilityresponsetables(CoverageEligibilityResponseTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COVERAGE_ELIGIBILITY_RESPONSE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from CoverageEligibilityResponseTableInsert inserted in data
            select inserted.COVERAGEELIGIBILITYRESPONSETABLE_ID;
    }

    isolated resource function put coverageeligibilityresponsetables/[string COVERAGEELIGIBILITYRESPONSETABLE_ID](CoverageEligibilityResponseTableUpdate value) returns CoverageEligibilityResponseTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COVERAGE_ELIGIBILITY_RESPONSE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(COVERAGEELIGIBILITYRESPONSETABLE_ID, value);
        return self->/coverageeligibilityresponsetables/[COVERAGEELIGIBILITYRESPONSETABLE_ID].get();
    }

    isolated resource function delete coverageeligibilityresponsetables/[string COVERAGEELIGIBILITYRESPONSETABLE_ID]() returns CoverageEligibilityResponseTable|persist:Error {
        CoverageEligibilityResponseTable result = check self->/coverageeligibilityresponsetables/[COVERAGEELIGIBILITYRESPONSETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COVERAGE_ELIGIBILITY_RESPONSE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(COVERAGEELIGIBILITYRESPONSETABLE_ID);
        return result;
    }

    isolated resource function get researchstudytables(ResearchStudyTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get researchstudytables/[string RESEARCHSTUDYTABLE_ID](ResearchStudyTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post researchstudytables(ResearchStudyTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RESEARCH_STUDY_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ResearchStudyTableInsert inserted in data
            select inserted.RESEARCHSTUDYTABLE_ID;
    }

    isolated resource function put researchstudytables/[string RESEARCHSTUDYTABLE_ID](ResearchStudyTableUpdate value) returns ResearchStudyTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RESEARCH_STUDY_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(RESEARCHSTUDYTABLE_ID, value);
        return self->/researchstudytables/[RESEARCHSTUDYTABLE_ID].get();
    }

    isolated resource function delete researchstudytables/[string RESEARCHSTUDYTABLE_ID]() returns ResearchStudyTable|persist:Error {
        ResearchStudyTable result = check self->/researchstudytables/[RESEARCHSTUDYTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RESEARCH_STUDY_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(RESEARCHSTUDYTABLE_ID);
        return result;
    }

    isolated resource function get bundletables(BundleTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get bundletables/[string BUNDLETABLE_ID](BundleTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post bundletables(BundleTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(BUNDLE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from BundleTableInsert inserted in data
            select inserted.BUNDLETABLE_ID;
    }

    isolated resource function put bundletables/[string BUNDLETABLE_ID](BundleTableUpdate value) returns BundleTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(BUNDLE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(BUNDLETABLE_ID, value);
        return self->/bundletables/[BUNDLETABLE_ID].get();
    }

    isolated resource function delete bundletables/[string BUNDLETABLE_ID]() returns BundleTable|persist:Error {
        BundleTable result = check self->/bundletables/[BUNDLETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(BUNDLE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(BUNDLETABLE_ID);
        return result;
    }

    isolated resource function get encountertables(EncounterTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get encountertables/[string ENCOUNTERTABLE_ID](EncounterTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post encountertables(EncounterTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENCOUNTER_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from EncounterTableInsert inserted in data
            select inserted.ENCOUNTERTABLE_ID;
    }

    isolated resource function put encountertables/[string ENCOUNTERTABLE_ID](EncounterTableUpdate value) returns EncounterTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENCOUNTER_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(ENCOUNTERTABLE_ID, value);
        return self->/encountertables/[ENCOUNTERTABLE_ID].get();
    }

    isolated resource function delete encountertables/[string ENCOUNTERTABLE_ID]() returns EncounterTable|persist:Error {
        EncounterTable result = check self->/encountertables/[ENCOUNTERTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENCOUNTER_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(ENCOUNTERTABLE_ID);
        return result;
    }

    isolated resource function get riskassessmenttables(RiskAssessmentTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get riskassessmenttables/[string RISKASSESSMENTTABLE_ID](RiskAssessmentTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post riskassessmenttables(RiskAssessmentTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RISK_ASSESSMENT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from RiskAssessmentTableInsert inserted in data
            select inserted.RISKASSESSMENTTABLE_ID;
    }

    isolated resource function put riskassessmenttables/[string RISKASSESSMENTTABLE_ID](RiskAssessmentTableUpdate value) returns RiskAssessmentTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RISK_ASSESSMENT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(RISKASSESSMENTTABLE_ID, value);
        return self->/riskassessmenttables/[RISKASSESSMENTTABLE_ID].get();
    }

    isolated resource function delete riskassessmenttables/[string RISKASSESSMENTTABLE_ID]() returns RiskAssessmentTable|persist:Error {
        RiskAssessmentTable result = check self->/riskassessmenttables/[RISKASSESSMENTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RISK_ASSESSMENT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(RISKASSESSMENTTABLE_ID);
        return result;
    }

    isolated resource function get listtables(ListTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get listtables/[string LISTTABLE_ID](ListTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post listtables(ListTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(LIST_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ListTableInsert inserted in data
            select inserted.LISTTABLE_ID;
    }

    isolated resource function put listtables/[string LISTTABLE_ID](ListTableUpdate value) returns ListTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(LIST_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(LISTTABLE_ID, value);
        return self->/listtables/[LISTTABLE_ID].get();
    }

    isolated resource function delete listtables/[string LISTTABLE_ID]() returns ListTable|persist:Error {
        ListTable result = check self->/listtables/[LISTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(LIST_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(LISTTABLE_ID);
        return result;
    }

    isolated resource function get organizationaffiliationtables(OrganizationAffiliationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get organizationaffiliationtables/[string ORGANIZATIONAFFILIATIONTABLE_ID](OrganizationAffiliationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post organizationaffiliationtables(OrganizationAffiliationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ORGANIZATION_AFFILIATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from OrganizationAffiliationTableInsert inserted in data
            select inserted.ORGANIZATIONAFFILIATIONTABLE_ID;
    }

    isolated resource function put organizationaffiliationtables/[string ORGANIZATIONAFFILIATIONTABLE_ID](OrganizationAffiliationTableUpdate value) returns OrganizationAffiliationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ORGANIZATION_AFFILIATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(ORGANIZATIONAFFILIATIONTABLE_ID, value);
        return self->/organizationaffiliationtables/[ORGANIZATIONAFFILIATIONTABLE_ID].get();
    }

    isolated resource function delete organizationaffiliationtables/[string ORGANIZATIONAFFILIATIONTABLE_ID]() returns OrganizationAffiliationTable|persist:Error {
        OrganizationAffiliationTable result = check self->/organizationaffiliationtables/[ORGANIZATIONAFFILIATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ORGANIZATION_AFFILIATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(ORGANIZATIONAFFILIATIONTABLE_ID);
        return result;
    }

    isolated resource function get chargeitemtables(ChargeItemTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get chargeitemtables/[string CHARGEITEMTABLE_ID](ChargeItemTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post chargeitemtables(ChargeItemTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CHARGE_ITEM_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ChargeItemTableInsert inserted in data
            select inserted.CHARGEITEMTABLE_ID;
    }

    isolated resource function put chargeitemtables/[string CHARGEITEMTABLE_ID](ChargeItemTableUpdate value) returns ChargeItemTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CHARGE_ITEM_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(CHARGEITEMTABLE_ID, value);
        return self->/chargeitemtables/[CHARGEITEMTABLE_ID].get();
    }

    isolated resource function delete chargeitemtables/[string CHARGEITEMTABLE_ID]() returns ChargeItemTable|persist:Error {
        ChargeItemTable result = check self->/chargeitemtables/[CHARGEITEMTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CHARGE_ITEM_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(CHARGEITEMTABLE_ID);
        return result;
    }

    isolated resource function get medicationknowledgetables(MedicationKnowledgeTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicationknowledgetables/[string MEDICATIONKNOWLEDGETABLE_ID](MedicationKnowledgeTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicationknowledgetables(MedicationKnowledgeTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_KNOWLEDGE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicationKnowledgeTableInsert inserted in data
            select inserted.MEDICATIONKNOWLEDGETABLE_ID;
    }

    isolated resource function put medicationknowledgetables/[string MEDICATIONKNOWLEDGETABLE_ID](MedicationKnowledgeTableUpdate value) returns MedicationKnowledgeTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_KNOWLEDGE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICATIONKNOWLEDGETABLE_ID, value);
        return self->/medicationknowledgetables/[MEDICATIONKNOWLEDGETABLE_ID].get();
    }

    isolated resource function delete medicationknowledgetables/[string MEDICATIONKNOWLEDGETABLE_ID]() returns MedicationKnowledgeTable|persist:Error {
        MedicationKnowledgeTable result = check self->/medicationknowledgetables/[MEDICATIONKNOWLEDGETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_KNOWLEDGE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICATIONKNOWLEDGETABLE_ID);
        return result;
    }

    isolated resource function get plandefinitiontables(PlanDefinitionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get plandefinitiontables/[string PLANDEFINITIONTABLE_ID](PlanDefinitionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post plandefinitiontables(PlanDefinitionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PLAN_DEFINITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from PlanDefinitionTableInsert inserted in data
            select inserted.PLANDEFINITIONTABLE_ID;
    }

    isolated resource function put plandefinitiontables/[string PLANDEFINITIONTABLE_ID](PlanDefinitionTableUpdate value) returns PlanDefinitionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PLAN_DEFINITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(PLANDEFINITIONTABLE_ID, value);
        return self->/plandefinitiontables/[PLANDEFINITIONTABLE_ID].get();
    }

    isolated resource function delete plandefinitiontables/[string PLANDEFINITIONTABLE_ID]() returns PlanDefinitionTable|persist:Error {
        PlanDefinitionTable result = check self->/plandefinitiontables/[PLANDEFINITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PLAN_DEFINITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(PLANDEFINITIONTABLE_ID);
        return result;
    }

    isolated resource function get careplantables(CarePlanTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get careplantables/[string CAREPLANTABLE_ID](CarePlanTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post careplantables(CarePlanTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CARE_PLAN_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from CarePlanTableInsert inserted in data
            select inserted.CAREPLANTABLE_ID;
    }

    isolated resource function put careplantables/[string CAREPLANTABLE_ID](CarePlanTableUpdate value) returns CarePlanTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CARE_PLAN_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(CAREPLANTABLE_ID, value);
        return self->/careplantables/[CAREPLANTABLE_ID].get();
    }

    isolated resource function delete careplantables/[string CAREPLANTABLE_ID]() returns CarePlanTable|persist:Error {
        CarePlanTable result = check self->/careplantables/[CAREPLANTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CARE_PLAN_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(CAREPLANTABLE_ID);
        return result;
    }

    isolated resource function get visionprescriptiontables(VisionPrescriptionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get visionprescriptiontables/[string VISIONPRESCRIPTIONTABLE_ID](VisionPrescriptionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post visionprescriptiontables(VisionPrescriptionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VISION_PRESCRIPTION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from VisionPrescriptionTableInsert inserted in data
            select inserted.VISIONPRESCRIPTIONTABLE_ID;
    }

    isolated resource function put visionprescriptiontables/[string VISIONPRESCRIPTIONTABLE_ID](VisionPrescriptionTableUpdate value) returns VisionPrescriptionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VISION_PRESCRIPTION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(VISIONPRESCRIPTIONTABLE_ID, value);
        return self->/visionprescriptiontables/[VISIONPRESCRIPTIONTABLE_ID].get();
    }

    isolated resource function delete visionprescriptiontables/[string VISIONPRESCRIPTIONTABLE_ID]() returns VisionPrescriptionTable|persist:Error {
        VisionPrescriptionTable result = check self->/visionprescriptiontables/[VISIONPRESCRIPTIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VISION_PRESCRIPTION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(VISIONPRESCRIPTIONTABLE_ID);
        return result;
    }

    isolated resource function get episodeofcaretables(EpisodeOfCareTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get episodeofcaretables/[string EPISODEOFCARETABLE_ID](EpisodeOfCareTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post episodeofcaretables(EpisodeOfCareTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EPISODE_OF_CARE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from EpisodeOfCareTableInsert inserted in data
            select inserted.EPISODEOFCARETABLE_ID;
    }

    isolated resource function put episodeofcaretables/[string EPISODEOFCARETABLE_ID](EpisodeOfCareTableUpdate value) returns EpisodeOfCareTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EPISODE_OF_CARE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(EPISODEOFCARETABLE_ID, value);
        return self->/episodeofcaretables/[EPISODEOFCARETABLE_ID].get();
    }

    isolated resource function delete episodeofcaretables/[string EPISODEOFCARETABLE_ID]() returns EpisodeOfCareTable|persist:Error {
        EpisodeOfCareTable result = check self->/episodeofcaretables/[EPISODEOFCARETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EPISODE_OF_CARE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(EPISODEOFCARETABLE_ID);
        return result;
    }

    isolated resource function get careteamtables(CareTeamTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get careteamtables/[string CARETEAMTABLE_ID](CareTeamTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post careteamtables(CareTeamTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CARE_TEAM_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from CareTeamTableInsert inserted in data
            select inserted.CARETEAMTABLE_ID;
    }

    isolated resource function put careteamtables/[string CARETEAMTABLE_ID](CareTeamTableUpdate value) returns CareTeamTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CARE_TEAM_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(CARETEAMTABLE_ID, value);
        return self->/careteamtables/[CARETEAMTABLE_ID].get();
    }

    isolated resource function delete careteamtables/[string CARETEAMTABLE_ID]() returns CareTeamTable|persist:Error {
        CareTeamTable result = check self->/careteamtables/[CARETEAMTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CARE_TEAM_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(CARETEAMTABLE_ID);
        return result;
    }

    isolated resource function get medicationadministrationtables(MedicationAdministrationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicationadministrationtables/[string MEDICATIONADMINISTRATIONTABLE_ID](MedicationAdministrationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicationadministrationtables(MedicationAdministrationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_ADMINISTRATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicationAdministrationTableInsert inserted in data
            select inserted.MEDICATIONADMINISTRATIONTABLE_ID;
    }

    isolated resource function put medicationadministrationtables/[string MEDICATIONADMINISTRATIONTABLE_ID](MedicationAdministrationTableUpdate value) returns MedicationAdministrationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_ADMINISTRATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICATIONADMINISTRATIONTABLE_ID, value);
        return self->/medicationadministrationtables/[MEDICATIONADMINISTRATIONTABLE_ID].get();
    }

    isolated resource function delete medicationadministrationtables/[string MEDICATIONADMINISTRATIONTABLE_ID]() returns MedicationAdministrationTable|persist:Error {
        MedicationAdministrationTable result = check self->/medicationadministrationtables/[MEDICATIONADMINISTRATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_ADMINISTRATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICATIONADMINISTRATIONTABLE_ID);
        return result;
    }

    isolated resource function get consenttables(ConsentTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get consenttables/[string CONSENTTABLE_ID](ConsentTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post consenttables(ConsentTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CONSENT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ConsentTableInsert inserted in data
            select inserted.CONSENTTABLE_ID;
    }

    isolated resource function put consenttables/[string CONSENTTABLE_ID](ConsentTableUpdate value) returns ConsentTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CONSENT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(CONSENTTABLE_ID, value);
        return self->/consenttables/[CONSENTTABLE_ID].get();
    }

    isolated resource function delete consenttables/[string CONSENTTABLE_ID]() returns ConsentTable|persist:Error {
        ConsentTable result = check self->/consenttables/[CONSENTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CONSENT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(CONSENTTABLE_ID);
        return result;
    }

    isolated resource function get detectedissuetables(DetectedIssueTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get detectedissuetables/[string DETECTEDISSUETABLE_ID](DetectedIssueTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post detectedissuetables(DetectedIssueTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DETECTED_ISSUE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from DetectedIssueTableInsert inserted in data
            select inserted.DETECTEDISSUETABLE_ID;
    }

    isolated resource function put detectedissuetables/[string DETECTEDISSUETABLE_ID](DetectedIssueTableUpdate value) returns DetectedIssueTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DETECTED_ISSUE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(DETECTEDISSUETABLE_ID, value);
        return self->/detectedissuetables/[DETECTEDISSUETABLE_ID].get();
    }

    isolated resource function delete detectedissuetables/[string DETECTEDISSUETABLE_ID]() returns DetectedIssueTable|persist:Error {
        DetectedIssueTable result = check self->/detectedissuetables/[DETECTEDISSUETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DETECTED_ISSUE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(DETECTEDISSUETABLE_ID);
        return result;
    }

    isolated resource function get substancespecificationtables(SubstanceSpecificationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get substancespecificationtables/[string SUBSTANCESPECIFICATIONTABLE_ID](SubstanceSpecificationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post substancespecificationtables(SubstanceSpecificationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUBSTANCE_SPECIFICATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from SubstanceSpecificationTableInsert inserted in data
            select inserted.SUBSTANCESPECIFICATIONTABLE_ID;
    }

    isolated resource function put substancespecificationtables/[string SUBSTANCESPECIFICATIONTABLE_ID](SubstanceSpecificationTableUpdate value) returns SubstanceSpecificationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUBSTANCE_SPECIFICATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(SUBSTANCESPECIFICATIONTABLE_ID, value);
        return self->/substancespecificationtables/[SUBSTANCESPECIFICATIONTABLE_ID].get();
    }

    isolated resource function delete substancespecificationtables/[string SUBSTANCESPECIFICATIONTABLE_ID]() returns SubstanceSpecificationTable|persist:Error {
        SubstanceSpecificationTable result = check self->/substancespecificationtables/[SUBSTANCESPECIFICATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUBSTANCE_SPECIFICATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(SUBSTANCESPECIFICATIONTABLE_ID);
        return result;
    }

    isolated resource function get allergyintolerancetables(AllergyIntoleranceTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get allergyintolerancetables/[string ALLERGYINTOLERANCETABLE_ID](AllergyIntoleranceTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post allergyintolerancetables(AllergyIntoleranceTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ALLERGY_INTOLERANCE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from AllergyIntoleranceTableInsert inserted in data
            select inserted.ALLERGYINTOLERANCETABLE_ID;
    }

    isolated resource function put allergyintolerancetables/[string ALLERGYINTOLERANCETABLE_ID](AllergyIntoleranceTableUpdate value) returns AllergyIntoleranceTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ALLERGY_INTOLERANCE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(ALLERGYINTOLERANCETABLE_ID, value);
        return self->/allergyintolerancetables/[ALLERGYINTOLERANCETABLE_ID].get();
    }

    isolated resource function delete allergyintolerancetables/[string ALLERGYINTOLERANCETABLE_ID]() returns AllergyIntoleranceTable|persist:Error {
        AllergyIntoleranceTable result = check self->/allergyintolerancetables/[ALLERGYINTOLERANCETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ALLERGY_INTOLERANCE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(ALLERGYINTOLERANCETABLE_ID);
        return result;
    }

    isolated resource function get medicinalproductindicationtables(MedicinalProductIndicationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicinalproductindicationtables/[string MEDICINALPRODUCTINDICATIONTABLE_ID](MedicinalProductIndicationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicinalproductindicationtables(MedicinalProductIndicationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_INDICATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicinalProductIndicationTableInsert inserted in data
            select inserted.MEDICINALPRODUCTINDICATIONTABLE_ID;
    }

    isolated resource function put medicinalproductindicationtables/[string MEDICINALPRODUCTINDICATIONTABLE_ID](MedicinalProductIndicationTableUpdate value) returns MedicinalProductIndicationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_INDICATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICINALPRODUCTINDICATIONTABLE_ID, value);
        return self->/medicinalproductindicationtables/[MEDICINALPRODUCTINDICATIONTABLE_ID].get();
    }

    isolated resource function delete medicinalproductindicationtables/[string MEDICINALPRODUCTINDICATIONTABLE_ID]() returns MedicinalProductIndicationTable|persist:Error {
        MedicinalProductIndicationTable result = check self->/medicinalproductindicationtables/[MEDICINALPRODUCTINDICATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_INDICATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICINALPRODUCTINDICATIONTABLE_ID);
        return result;
    }

    isolated resource function get medicinalproductpharmaceuticaltables(MedicinalProductPharmaceuticalTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicinalproductpharmaceuticaltables/[string MEDICINALPRODUCTPHARMACEUTICALTABLE_ID](MedicinalProductPharmaceuticalTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicinalproductpharmaceuticaltables(MedicinalProductPharmaceuticalTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_PHARMACEUTICAL_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicinalProductPharmaceuticalTableInsert inserted in data
            select inserted.MEDICINALPRODUCTPHARMACEUTICALTABLE_ID;
    }

    isolated resource function put medicinalproductpharmaceuticaltables/[string MEDICINALPRODUCTPHARMACEUTICALTABLE_ID](MedicinalProductPharmaceuticalTableUpdate value) returns MedicinalProductPharmaceuticalTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_PHARMACEUTICAL_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICINALPRODUCTPHARMACEUTICALTABLE_ID, value);
        return self->/medicinalproductpharmaceuticaltables/[MEDICINALPRODUCTPHARMACEUTICALTABLE_ID].get();
    }

    isolated resource function delete medicinalproductpharmaceuticaltables/[string MEDICINALPRODUCTPHARMACEUTICALTABLE_ID]() returns MedicinalProductPharmaceuticalTable|persist:Error {
        MedicinalProductPharmaceuticalTable result = check self->/medicinalproductpharmaceuticaltables/[MEDICINALPRODUCTPHARMACEUTICALTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_PHARMACEUTICAL_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICINALPRODUCTPHARMACEUTICALTABLE_ID);
        return result;
    }

    isolated resource function get slottables(SlotTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get slottables/[string SLOTTABLE_ID](SlotTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post slottables(SlotTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SLOT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from SlotTableInsert inserted in data
            select inserted.SLOTTABLE_ID;
    }

    isolated resource function put slottables/[string SLOTTABLE_ID](SlotTableUpdate value) returns SlotTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SLOT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(SLOTTABLE_ID, value);
        return self->/slottables/[SLOTTABLE_ID].get();
    }

    isolated resource function delete slottables/[string SLOTTABLE_ID]() returns SlotTable|persist:Error {
        SlotTable result = check self->/slottables/[SLOTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SLOT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(SLOTTABLE_ID);
        return result;
    }

    isolated resource function get verificationresulttables(VerificationResultTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get verificationresulttables/[string VERIFICATIONRESULTTABLE_ID](VerificationResultTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post verificationresulttables(VerificationResultTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VERIFICATION_RESULT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from VerificationResultTableInsert inserted in data
            select inserted.VERIFICATIONRESULTTABLE_ID;
    }

    isolated resource function put verificationresulttables/[string VERIFICATIONRESULTTABLE_ID](VerificationResultTableUpdate value) returns VerificationResultTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VERIFICATION_RESULT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(VERIFICATIONRESULTTABLE_ID, value);
        return self->/verificationresulttables/[VERIFICATIONRESULTTABLE_ID].get();
    }

    isolated resource function delete verificationresulttables/[string VERIFICATIONRESULTTABLE_ID]() returns VerificationResultTable|persist:Error {
        VerificationResultTable result = check self->/verificationresulttables/[VERIFICATIONRESULTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VERIFICATION_RESULT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(VERIFICATIONRESULTTABLE_ID);
        return result;
    }

    isolated resource function get specimentables(SpecimenTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get specimentables/[string SPECIMENTABLE_ID](SpecimenTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post specimentables(SpecimenTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SPECIMEN_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from SpecimenTableInsert inserted in data
            select inserted.SPECIMENTABLE_ID;
    }

    isolated resource function put specimentables/[string SPECIMENTABLE_ID](SpecimenTableUpdate value) returns SpecimenTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SPECIMEN_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(SPECIMENTABLE_ID, value);
        return self->/specimentables/[SPECIMENTABLE_ID].get();
    }

    isolated resource function delete specimentables/[string SPECIMENTABLE_ID]() returns SpecimenTable|persist:Error {
        SpecimenTable result = check self->/specimentables/[SPECIMENTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SPECIMEN_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(SPECIMENTABLE_ID);
        return result;
    }

    isolated resource function get researchsubjecttables(ResearchSubjectTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get researchsubjecttables/[string RESEARCHSUBJECTTABLE_ID](ResearchSubjectTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post researchsubjecttables(ResearchSubjectTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RESEARCH_SUBJECT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ResearchSubjectTableInsert inserted in data
            select inserted.RESEARCHSUBJECTTABLE_ID;
    }

    isolated resource function put researchsubjecttables/[string RESEARCHSUBJECTTABLE_ID](ResearchSubjectTableUpdate value) returns ResearchSubjectTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RESEARCH_SUBJECT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(RESEARCHSUBJECTTABLE_ID, value);
        return self->/researchsubjecttables/[RESEARCHSUBJECTTABLE_ID].get();
    }

    isolated resource function delete researchsubjecttables/[string RESEARCHSUBJECTTABLE_ID]() returns ResearchSubjectTable|persist:Error {
        ResearchSubjectTable result = check self->/researchsubjecttables/[RESEARCHSUBJECTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RESEARCH_SUBJECT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(RESEARCHSUBJECTTABLE_ID);
        return result;
    }

    isolated resource function get medicationtables(MedicationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicationtables/[string MEDICATIONTABLE_ID](MedicationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicationtables(MedicationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicationTableInsert inserted in data
            select inserted.MEDICATIONTABLE_ID;
    }

    isolated resource function put medicationtables/[string MEDICATIONTABLE_ID](MedicationTableUpdate value) returns MedicationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICATIONTABLE_ID, value);
        return self->/medicationtables/[MEDICATIONTABLE_ID].get();
    }

    isolated resource function delete medicationtables/[string MEDICATIONTABLE_ID]() returns MedicationTable|persist:Error {
        MedicationTable result = check self->/medicationtables/[MEDICATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICATIONTABLE_ID);
        return result;
    }

    isolated resource function get researchdefinitiontables(ResearchDefinitionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get researchdefinitiontables/[string RESEARCHDEFINITIONTABLE_ID](ResearchDefinitionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post researchdefinitiontables(ResearchDefinitionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RESEARCH_DEFINITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ResearchDefinitionTableInsert inserted in data
            select inserted.RESEARCHDEFINITIONTABLE_ID;
    }

    isolated resource function put researchdefinitiontables/[string RESEARCHDEFINITIONTABLE_ID](ResearchDefinitionTableUpdate value) returns ResearchDefinitionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RESEARCH_DEFINITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(RESEARCHDEFINITIONTABLE_ID, value);
        return self->/researchdefinitiontables/[RESEARCHDEFINITIONTABLE_ID].get();
    }

    isolated resource function delete researchdefinitiontables/[string RESEARCHDEFINITIONTABLE_ID]() returns ResearchDefinitionTable|persist:Error {
        ResearchDefinitionTable result = check self->/researchdefinitiontables/[RESEARCHDEFINITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RESEARCH_DEFINITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(RESEARCHDEFINITIONTABLE_ID);
        return result;
    }

    isolated resource function get healthcareservicetables(HealthcareServiceTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get healthcareservicetables/[string HEALTHCARESERVICETABLE_ID](HealthcareServiceTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post healthcareservicetables(HealthcareServiceTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(HEALTHCARE_SERVICE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from HealthcareServiceTableInsert inserted in data
            select inserted.HEALTHCARESERVICETABLE_ID;
    }

    isolated resource function put healthcareservicetables/[string HEALTHCARESERVICETABLE_ID](HealthcareServiceTableUpdate value) returns HealthcareServiceTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(HEALTHCARE_SERVICE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(HEALTHCARESERVICETABLE_ID, value);
        return self->/healthcareservicetables/[HEALTHCARESERVICETABLE_ID].get();
    }

    isolated resource function delete healthcareservicetables/[string HEALTHCARESERVICETABLE_ID]() returns HealthcareServiceTable|persist:Error {
        HealthcareServiceTable result = check self->/healthcareservicetables/[HEALTHCARESERVICETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(HEALTHCARE_SERVICE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(HEALTHCARESERVICETABLE_ID);
        return result;
    }

    isolated resource function get paymentnoticetables(PaymentNoticeTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get paymentnoticetables/[string PAYMENTNOTICETABLE_ID](PaymentNoticeTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post paymentnoticetables(PaymentNoticeTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PAYMENT_NOTICE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from PaymentNoticeTableInsert inserted in data
            select inserted.PAYMENTNOTICETABLE_ID;
    }

    isolated resource function put paymentnoticetables/[string PAYMENTNOTICETABLE_ID](PaymentNoticeTableUpdate value) returns PaymentNoticeTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PAYMENT_NOTICE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(PAYMENTNOTICETABLE_ID, value);
        return self->/paymentnoticetables/[PAYMENTNOTICETABLE_ID].get();
    }

    isolated resource function delete paymentnoticetables/[string PAYMENTNOTICETABLE_ID]() returns PaymentNoticeTable|persist:Error {
        PaymentNoticeTable result = check self->/paymentnoticetables/[PAYMENTNOTICETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PAYMENT_NOTICE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(PAYMENTNOTICETABLE_ID);
        return result;
    }

    isolated resource function get provenancetables(ProvenanceTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get provenancetables/[string PROVENANCETABLE_ID](ProvenanceTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post provenancetables(ProvenanceTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PROVENANCE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ProvenanceTableInsert inserted in data
            select inserted.PROVENANCETABLE_ID;
    }

    isolated resource function put provenancetables/[string PROVENANCETABLE_ID](ProvenanceTableUpdate value) returns ProvenanceTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PROVENANCE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(PROVENANCETABLE_ID, value);
        return self->/provenancetables/[PROVENANCETABLE_ID].get();
    }

    isolated resource function delete provenancetables/[string PROVENANCETABLE_ID]() returns ProvenanceTable|persist:Error {
        ProvenanceTable result = check self->/provenancetables/[PROVENANCETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PROVENANCE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(PROVENANCETABLE_ID);
        return result;
    }

    isolated resource function get graphdefinitiontables(GraphDefinitionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get graphdefinitiontables/[string GRAPHDEFINITIONTABLE_ID](GraphDefinitionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post graphdefinitiontables(GraphDefinitionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GRAPH_DEFINITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from GraphDefinitionTableInsert inserted in data
            select inserted.GRAPHDEFINITIONTABLE_ID;
    }

    isolated resource function put graphdefinitiontables/[string GRAPHDEFINITIONTABLE_ID](GraphDefinitionTableUpdate value) returns GraphDefinitionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GRAPH_DEFINITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(GRAPHDEFINITIONTABLE_ID, value);
        return self->/graphdefinitiontables/[GRAPHDEFINITIONTABLE_ID].get();
    }

    isolated resource function delete graphdefinitiontables/[string GRAPHDEFINITIONTABLE_ID]() returns GraphDefinitionTable|persist:Error {
        GraphDefinitionTable result = check self->/graphdefinitiontables/[GRAPHDEFINITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GRAPH_DEFINITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(GRAPHDEFINITIONTABLE_ID);
        return result;
    }

    isolated resource function get mediatables(MediaTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get mediatables/[string MEDIATABLE_ID](MediaTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post mediatables(MediaTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDIA_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MediaTableInsert inserted in data
            select inserted.MEDIATABLE_ID;
    }

    isolated resource function put mediatables/[string MEDIATABLE_ID](MediaTableUpdate value) returns MediaTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDIA_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDIATABLE_ID, value);
        return self->/mediatables/[MEDIATABLE_ID].get();
    }

    isolated resource function delete mediatables/[string MEDIATABLE_ID]() returns MediaTable|persist:Error {
        MediaTable result = check self->/mediatables/[MEDIATABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDIA_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDIATABLE_ID);
        return result;
    }

    isolated resource function get bodystructuretables(BodyStructureTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get bodystructuretables/[string BODYSTRUCTURETABLE_ID](BodyStructureTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post bodystructuretables(BodyStructureTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(BODY_STRUCTURE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from BodyStructureTableInsert inserted in data
            select inserted.BODYSTRUCTURETABLE_ID;
    }

    isolated resource function put bodystructuretables/[string BODYSTRUCTURETABLE_ID](BodyStructureTableUpdate value) returns BodyStructureTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(BODY_STRUCTURE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(BODYSTRUCTURETABLE_ID, value);
        return self->/bodystructuretables/[BODYSTRUCTURETABLE_ID].get();
    }

    isolated resource function delete bodystructuretables/[string BODYSTRUCTURETABLE_ID]() returns BodyStructureTable|persist:Error {
        BodyStructureTable result = check self->/bodystructuretables/[BODYSTRUCTURETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(BODY_STRUCTURE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(BODYSTRUCTURETABLE_ID);
        return result;
    }

    isolated resource function get diagnosticreporttables(DiagnosticReportTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get diagnosticreporttables/[string DIAGNOSTICREPORTTABLE_ID](DiagnosticReportTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post diagnosticreporttables(DiagnosticReportTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DIAGNOSTIC_REPORT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from DiagnosticReportTableInsert inserted in data
            select inserted.DIAGNOSTICREPORTTABLE_ID;
    }

    isolated resource function put diagnosticreporttables/[string DIAGNOSTICREPORTTABLE_ID](DiagnosticReportTableUpdate value) returns DiagnosticReportTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DIAGNOSTIC_REPORT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(DIAGNOSTICREPORTTABLE_ID, value);
        return self->/diagnosticreporttables/[DIAGNOSTICREPORTTABLE_ID].get();
    }

    isolated resource function delete diagnosticreporttables/[string DIAGNOSTICREPORTTABLE_ID]() returns DiagnosticReportTable|persist:Error {
        DiagnosticReportTable result = check self->/diagnosticreporttables/[DIAGNOSTICREPORTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DIAGNOSTIC_REPORT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(DIAGNOSTICREPORTTABLE_ID);
        return result;
    }

    isolated resource function get goaltables(GoalTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get goaltables/[string GOALTABLE_ID](GoalTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post goaltables(GoalTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GOAL_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from GoalTableInsert inserted in data
            select inserted.GOALTABLE_ID;
    }

    isolated resource function put goaltables/[string GOALTABLE_ID](GoalTableUpdate value) returns GoalTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GOAL_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(GOALTABLE_ID, value);
        return self->/goaltables/[GOALTABLE_ID].get();
    }

    isolated resource function delete goaltables/[string GOALTABLE_ID]() returns GoalTable|persist:Error {
        GoalTable result = check self->/goaltables/[GOALTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GOAL_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(GOALTABLE_ID);
        return result;
    }

    isolated resource function get capabilitystatementtables(CapabilityStatementTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get capabilitystatementtables/[string CAPABILITYSTATEMENTTABLE_ID](CapabilityStatementTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post capabilitystatementtables(CapabilityStatementTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CAPABILITY_STATEMENT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from CapabilityStatementTableInsert inserted in data
            select inserted.CAPABILITYSTATEMENTTABLE_ID;
    }

    isolated resource function put capabilitystatementtables/[string CAPABILITYSTATEMENTTABLE_ID](CapabilityStatementTableUpdate value) returns CapabilityStatementTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CAPABILITY_STATEMENT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(CAPABILITYSTATEMENTTABLE_ID, value);
        return self->/capabilitystatementtables/[CAPABILITYSTATEMENTTABLE_ID].get();
    }

    isolated resource function delete capabilitystatementtables/[string CAPABILITYSTATEMENTTABLE_ID]() returns CapabilityStatementTable|persist:Error {
        CapabilityStatementTable result = check self->/capabilitystatementtables/[CAPABILITYSTATEMENTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CAPABILITY_STATEMENT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(CAPABILITYSTATEMENTTABLE_ID);
        return result;
    }

    isolated resource function get deviceusestatementtables(DeviceUseStatementTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get deviceusestatementtables/[string DEVICEUSESTATEMENTTABLE_ID](DeviceUseStatementTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post deviceusestatementtables(DeviceUseStatementTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_USE_STATEMENT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from DeviceUseStatementTableInsert inserted in data
            select inserted.DEVICEUSESTATEMENTTABLE_ID;
    }

    isolated resource function put deviceusestatementtables/[string DEVICEUSESTATEMENTTABLE_ID](DeviceUseStatementTableUpdate value) returns DeviceUseStatementTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_USE_STATEMENT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(DEVICEUSESTATEMENTTABLE_ID, value);
        return self->/deviceusestatementtables/[DEVICEUSESTATEMENTTABLE_ID].get();
    }

    isolated resource function delete deviceusestatementtables/[string DEVICEUSESTATEMENTTABLE_ID]() returns DeviceUseStatementTable|persist:Error {
        DeviceUseStatementTable result = check self->/deviceusestatementtables/[DEVICEUSESTATEMENTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_USE_STATEMENT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(DEVICEUSESTATEMENTTABLE_ID);
        return result;
    }

    isolated resource function get scheduletables(ScheduleTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get scheduletables/[string SCHEDULETABLE_ID](ScheduleTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post scheduletables(ScheduleTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SCHEDULE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ScheduleTableInsert inserted in data
            select inserted.SCHEDULETABLE_ID;
    }

    isolated resource function put scheduletables/[string SCHEDULETABLE_ID](ScheduleTableUpdate value) returns ScheduleTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SCHEDULE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(SCHEDULETABLE_ID, value);
        return self->/scheduletables/[SCHEDULETABLE_ID].get();
    }

    isolated resource function delete scheduletables/[string SCHEDULETABLE_ID]() returns ScheduleTable|persist:Error {
        ScheduleTable result = check self->/scheduletables/[SCHEDULETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SCHEDULE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(SCHEDULETABLE_ID);
        return result;
    }

    isolated resource function get medicinalproductpackagedtables(MedicinalProductPackagedTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicinalproductpackagedtables/[string MEDICINALPRODUCTPACKAGEDTABLE_ID](MedicinalProductPackagedTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicinalproductpackagedtables(MedicinalProductPackagedTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_PACKAGED_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicinalProductPackagedTableInsert inserted in data
            select inserted.MEDICINALPRODUCTPACKAGEDTABLE_ID;
    }

    isolated resource function put medicinalproductpackagedtables/[string MEDICINALPRODUCTPACKAGEDTABLE_ID](MedicinalProductPackagedTableUpdate value) returns MedicinalProductPackagedTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_PACKAGED_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICINALPRODUCTPACKAGEDTABLE_ID, value);
        return self->/medicinalproductpackagedtables/[MEDICINALPRODUCTPACKAGEDTABLE_ID].get();
    }

    isolated resource function delete medicinalproductpackagedtables/[string MEDICINALPRODUCTPACKAGEDTABLE_ID]() returns MedicinalProductPackagedTable|persist:Error {
        MedicinalProductPackagedTable result = check self->/medicinalproductpackagedtables/[MEDICINALPRODUCTPACKAGEDTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_PACKAGED_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICINALPRODUCTPACKAGEDTABLE_ID);
        return result;
    }

    isolated resource function get proceduretables(ProcedureTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get proceduretables/[string PROCEDURETABLE_ID](ProcedureTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post proceduretables(ProcedureTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PROCEDURE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ProcedureTableInsert inserted in data
            select inserted.PROCEDURETABLE_ID;
    }

    isolated resource function put proceduretables/[string PROCEDURETABLE_ID](ProcedureTableUpdate value) returns ProcedureTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PROCEDURE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(PROCEDURETABLE_ID, value);
        return self->/proceduretables/[PROCEDURETABLE_ID].get();
    }

    isolated resource function delete proceduretables/[string PROCEDURETABLE_ID]() returns ProcedureTable|persist:Error {
        ProcedureTable result = check self->/proceduretables/[PROCEDURETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PROCEDURE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(PROCEDURETABLE_ID);
        return result;
    }

    isolated resource function get librarytables(LibraryTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get librarytables/[string LIBRARYTABLE_ID](LibraryTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post librarytables(LibraryTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(LIBRARY_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from LibraryTableInsert inserted in data
            select inserted.LIBRARYTABLE_ID;
    }

    isolated resource function put librarytables/[string LIBRARYTABLE_ID](LibraryTableUpdate value) returns LibraryTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(LIBRARY_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(LIBRARYTABLE_ID, value);
        return self->/librarytables/[LIBRARYTABLE_ID].get();
    }

    isolated resource function delete librarytables/[string LIBRARYTABLE_ID]() returns LibraryTable|persist:Error {
        LibraryTable result = check self->/librarytables/[LIBRARYTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(LIBRARY_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(LIBRARYTABLE_ID);
        return result;
    }

    isolated resource function get codesystemtables(CodeSystemTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get codesystemtables/[string CODESYSTEMTABLE_ID](CodeSystemTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post codesystemtables(CodeSystemTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CODE_SYSTEM_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from CodeSystemTableInsert inserted in data
            select inserted.CODESYSTEMTABLE_ID;
    }

    isolated resource function put codesystemtables/[string CODESYSTEMTABLE_ID](CodeSystemTableUpdate value) returns CodeSystemTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CODE_SYSTEM_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(CODESYSTEMTABLE_ID, value);
        return self->/codesystemtables/[CODESYSTEMTABLE_ID].get();
    }

    isolated resource function delete codesystemtables/[string CODESYSTEMTABLE_ID]() returns CodeSystemTable|persist:Error {
        CodeSystemTable result = check self->/codesystemtables/[CODESYSTEMTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CODE_SYSTEM_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(CODESYSTEMTABLE_ID);
        return result;
    }

    isolated resource function get communicationrequesttables(CommunicationRequestTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get communicationrequesttables/[string COMMUNICATIONREQUESTTABLE_ID](CommunicationRequestTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post communicationrequesttables(CommunicationRequestTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COMMUNICATION_REQUEST_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from CommunicationRequestTableInsert inserted in data
            select inserted.COMMUNICATIONREQUESTTABLE_ID;
    }

    isolated resource function put communicationrequesttables/[string COMMUNICATIONREQUESTTABLE_ID](CommunicationRequestTableUpdate value) returns CommunicationRequestTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COMMUNICATION_REQUEST_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(COMMUNICATIONREQUESTTABLE_ID, value);
        return self->/communicationrequesttables/[COMMUNICATIONREQUESTTABLE_ID].get();
    }

    isolated resource function delete communicationrequesttables/[string COMMUNICATIONREQUESTTABLE_ID]() returns CommunicationRequestTable|persist:Error {
        CommunicationRequestTable result = check self->/communicationrequesttables/[COMMUNICATIONREQUESTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COMMUNICATION_REQUEST_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(COMMUNICATIONREQUESTTABLE_ID);
        return result;
    }

    isolated resource function get documentreferencetables(DocumentReferenceTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get documentreferencetables/[string DOCUMENTREFERENCETABLE_ID](DocumentReferenceTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post documentreferencetables(DocumentReferenceTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DOCUMENT_REFERENCE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from DocumentReferenceTableInsert inserted in data
            select inserted.DOCUMENTREFERENCETABLE_ID;
    }

    isolated resource function put documentreferencetables/[string DOCUMENTREFERENCETABLE_ID](DocumentReferenceTableUpdate value) returns DocumentReferenceTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DOCUMENT_REFERENCE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(DOCUMENTREFERENCETABLE_ID, value);
        return self->/documentreferencetables/[DOCUMENTREFERENCETABLE_ID].get();
    }

    isolated resource function delete documentreferencetables/[string DOCUMENTREFERENCETABLE_ID]() returns DocumentReferenceTable|persist:Error {
        DocumentReferenceTable result = check self->/documentreferencetables/[DOCUMENTREFERENCETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DOCUMENT_REFERENCE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(DOCUMENTREFERENCETABLE_ID);
        return result;
    }

    isolated resource function get requestgrouptables(RequestGroupTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get requestgrouptables/[string REQUESTGROUPTABLE_ID](RequestGroupTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post requestgrouptables(RequestGroupTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(REQUEST_GROUP_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from RequestGroupTableInsert inserted in data
            select inserted.REQUESTGROUPTABLE_ID;
    }

    isolated resource function put requestgrouptables/[string REQUESTGROUPTABLE_ID](RequestGroupTableUpdate value) returns RequestGroupTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(REQUEST_GROUP_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(REQUESTGROUPTABLE_ID, value);
        return self->/requestgrouptables/[REQUESTGROUPTABLE_ID].get();
    }

    isolated resource function delete requestgrouptables/[string REQUESTGROUPTABLE_ID]() returns RequestGroupTable|persist:Error {
        RequestGroupTable result = check self->/requestgrouptables/[REQUESTGROUPTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(REQUEST_GROUP_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(REQUESTGROUPTABLE_ID);
        return result;
    }

    isolated resource function get claimtables(ClaimTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get claimtables/[string CLAIMTABLE_ID](ClaimTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post claimtables(ClaimTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CLAIM_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ClaimTableInsert inserted in data
            select inserted.CLAIMTABLE_ID;
    }

    isolated resource function put claimtables/[string CLAIMTABLE_ID](ClaimTableUpdate value) returns ClaimTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CLAIM_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(CLAIMTABLE_ID, value);
        return self->/claimtables/[CLAIMTABLE_ID].get();
    }

    isolated resource function delete claimtables/[string CLAIMTABLE_ID]() returns ClaimTable|persist:Error {
        ClaimTable result = check self->/claimtables/[CLAIMTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CLAIM_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(CLAIMTABLE_ID);
        return result;
    }

    isolated resource function get messagedefinitiontables(MessageDefinitionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get messagedefinitiontables/[string MESSAGEDEFINITIONTABLE_ID](MessageDefinitionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post messagedefinitiontables(MessageDefinitionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MESSAGE_DEFINITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MessageDefinitionTableInsert inserted in data
            select inserted.MESSAGEDEFINITIONTABLE_ID;
    }

    isolated resource function put messagedefinitiontables/[string MESSAGEDEFINITIONTABLE_ID](MessageDefinitionTableUpdate value) returns MessageDefinitionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MESSAGE_DEFINITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MESSAGEDEFINITIONTABLE_ID, value);
        return self->/messagedefinitiontables/[MESSAGEDEFINITIONTABLE_ID].get();
    }

    isolated resource function delete messagedefinitiontables/[string MESSAGEDEFINITIONTABLE_ID]() returns MessageDefinitionTable|persist:Error {
        MessageDefinitionTable result = check self->/messagedefinitiontables/[MESSAGEDEFINITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MESSAGE_DEFINITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MESSAGEDEFINITIONTABLE_ID);
        return result;
    }

    isolated resource function get riskevidencesynthesistables(RiskEvidenceSynthesisTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get riskevidencesynthesistables/[string RISKEVIDENCESYNTHESISTABLE_ID](RiskEvidenceSynthesisTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post riskevidencesynthesistables(RiskEvidenceSynthesisTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RISK_EVIDENCE_SYNTHESIS_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from RiskEvidenceSynthesisTableInsert inserted in data
            select inserted.RISKEVIDENCESYNTHESISTABLE_ID;
    }

    isolated resource function put riskevidencesynthesistables/[string RISKEVIDENCESYNTHESISTABLE_ID](RiskEvidenceSynthesisTableUpdate value) returns RiskEvidenceSynthesisTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RISK_EVIDENCE_SYNTHESIS_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(RISKEVIDENCESYNTHESISTABLE_ID, value);
        return self->/riskevidencesynthesistables/[RISKEVIDENCESYNTHESISTABLE_ID].get();
    }

    isolated resource function delete riskevidencesynthesistables/[string RISKEVIDENCESYNTHESISTABLE_ID]() returns RiskEvidenceSynthesisTable|persist:Error {
        RiskEvidenceSynthesisTable result = check self->/riskevidencesynthesistables/[RISKEVIDENCESYNTHESISTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RISK_EVIDENCE_SYNTHESIS_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(RISKEVIDENCESYNTHESISTABLE_ID);
        return result;
    }

    isolated resource function get tasktables(TaskTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get tasktables/[string TASKTABLE_ID](TaskTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post tasktables(TaskTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TASK_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from TaskTableInsert inserted in data
            select inserted.TASKTABLE_ID;
    }

    isolated resource function put tasktables/[string TASKTABLE_ID](TaskTableUpdate value) returns TaskTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TASK_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(TASKTABLE_ID, value);
        return self->/tasktables/[TASKTABLE_ID].get();
    }

    isolated resource function delete tasktables/[string TASKTABLE_ID]() returns TaskTable|persist:Error {
        TaskTable result = check self->/tasktables/[TASKTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TASK_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(TASKTABLE_ID);
        return result;
    }

    isolated resource function get implementationguidetables(ImplementationGuideTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get implementationguidetables/[string IMPLEMENTATIONGUIDETABLE_ID](ImplementationGuideTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post implementationguidetables(ImplementationGuideTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMPLEMENTATION_GUIDE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ImplementationGuideTableInsert inserted in data
            select inserted.IMPLEMENTATIONGUIDETABLE_ID;
    }

    isolated resource function put implementationguidetables/[string IMPLEMENTATIONGUIDETABLE_ID](ImplementationGuideTableUpdate value) returns ImplementationGuideTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMPLEMENTATION_GUIDE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(IMPLEMENTATIONGUIDETABLE_ID, value);
        return self->/implementationguidetables/[IMPLEMENTATIONGUIDETABLE_ID].get();
    }

    isolated resource function delete implementationguidetables/[string IMPLEMENTATIONGUIDETABLE_ID]() returns ImplementationGuideTable|persist:Error {
        ImplementationGuideTable result = check self->/implementationguidetables/[IMPLEMENTATIONGUIDETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMPLEMENTATION_GUIDE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(IMPLEMENTATIONGUIDETABLE_ID);
        return result;
    }

    isolated resource function get structuremaptables(StructureMapTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get structuremaptables/[string STRUCTUREMAPTABLE_ID](StructureMapTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post structuremaptables(StructureMapTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(STRUCTURE_MAP_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from StructureMapTableInsert inserted in data
            select inserted.STRUCTUREMAPTABLE_ID;
    }

    isolated resource function put structuremaptables/[string STRUCTUREMAPTABLE_ID](StructureMapTableUpdate value) returns StructureMapTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(STRUCTURE_MAP_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(STRUCTUREMAPTABLE_ID, value);
        return self->/structuremaptables/[STRUCTUREMAPTABLE_ID].get();
    }

    isolated resource function delete structuremaptables/[string STRUCTUREMAPTABLE_ID]() returns StructureMapTable|persist:Error {
        StructureMapTable result = check self->/structuremaptables/[STRUCTUREMAPTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(STRUCTURE_MAP_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(STRUCTUREMAPTABLE_ID);
        return result;
    }

    isolated resource function get medicinalproductundesirableeffecttables(MedicinalProductUndesirableEffectTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicinalproductundesirableeffecttables/[string MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID](MedicinalProductUndesirableEffectTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicinalproductundesirableeffecttables(MedicinalProductUndesirableEffectTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_UNDESIRABLE_EFFECT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicinalProductUndesirableEffectTableInsert inserted in data
            select inserted.MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID;
    }

    isolated resource function put medicinalproductundesirableeffecttables/[string MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID](MedicinalProductUndesirableEffectTableUpdate value) returns MedicinalProductUndesirableEffectTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_UNDESIRABLE_EFFECT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID, value);
        return self->/medicinalproductundesirableeffecttables/[MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID].get();
    }

    isolated resource function delete medicinalproductundesirableeffecttables/[string MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID]() returns MedicinalProductUndesirableEffectTable|persist:Error {
        MedicinalProductUndesirableEffectTable result = check self->/medicinalproductundesirableeffecttables/[MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_UNDESIRABLE_EFFECT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID);
        return result;
    }

    isolated resource function get compartmentdefinitiontables(CompartmentDefinitionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get compartmentdefinitiontables/[string COMPARTMENTDEFINITIONTABLE_ID](CompartmentDefinitionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post compartmentdefinitiontables(CompartmentDefinitionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COMPARTMENT_DEFINITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from CompartmentDefinitionTableInsert inserted in data
            select inserted.COMPARTMENTDEFINITIONTABLE_ID;
    }

    isolated resource function put compartmentdefinitiontables/[string COMPARTMENTDEFINITIONTABLE_ID](CompartmentDefinitionTableUpdate value) returns CompartmentDefinitionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COMPARTMENT_DEFINITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(COMPARTMENTDEFINITIONTABLE_ID, value);
        return self->/compartmentdefinitiontables/[COMPARTMENTDEFINITIONTABLE_ID].get();
    }

    isolated resource function delete compartmentdefinitiontables/[string COMPARTMENTDEFINITIONTABLE_ID]() returns CompartmentDefinitionTable|persist:Error {
        CompartmentDefinitionTable result = check self->/compartmentdefinitiontables/[COMPARTMENTDEFINITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COMPARTMENT_DEFINITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(COMPARTMENTDEFINITIONTABLE_ID);
        return result;
    }

    isolated resource function get endpointtables(EndpointTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get endpointtables/[string ENDPOINTTABLE_ID](EndpointTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post endpointtables(EndpointTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENDPOINT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from EndpointTableInsert inserted in data
            select inserted.ENDPOINTTABLE_ID;
    }

    isolated resource function put endpointtables/[string ENDPOINTTABLE_ID](EndpointTableUpdate value) returns EndpointTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENDPOINT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(ENDPOINTTABLE_ID, value);
        return self->/endpointtables/[ENDPOINTTABLE_ID].get();
    }

    isolated resource function delete endpointtables/[string ENDPOINTTABLE_ID]() returns EndpointTable|persist:Error {
        EndpointTable result = check self->/endpointtables/[ENDPOINTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENDPOINT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(ENDPOINTTABLE_ID);
        return result;
    }

    isolated resource function get terminologycapabilitiestables(TerminologyCapabilitiesTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get terminologycapabilitiestables/[string TERMINOLOGYCAPABILITIESTABLE_ID](TerminologyCapabilitiesTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post terminologycapabilitiestables(TerminologyCapabilitiesTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TERMINOLOGY_CAPABILITIES_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from TerminologyCapabilitiesTableInsert inserted in data
            select inserted.TERMINOLOGYCAPABILITIESTABLE_ID;
    }

    isolated resource function put terminologycapabilitiestables/[string TERMINOLOGYCAPABILITIESTABLE_ID](TerminologyCapabilitiesTableUpdate value) returns TerminologyCapabilitiesTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TERMINOLOGY_CAPABILITIES_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(TERMINOLOGYCAPABILITIESTABLE_ID, value);
        return self->/terminologycapabilitiestables/[TERMINOLOGYCAPABILITIESTABLE_ID].get();
    }

    isolated resource function delete terminologycapabilitiestables/[string TERMINOLOGYCAPABILITIESTABLE_ID]() returns TerminologyCapabilitiesTable|persist:Error {
        TerminologyCapabilitiesTable result = check self->/terminologycapabilitiestables/[TERMINOLOGYCAPABILITIESTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TERMINOLOGY_CAPABILITIES_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(TERMINOLOGYCAPABILITIESTABLE_ID);
        return result;
    }

    isolated resource function get conditiontables(ConditionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get conditiontables/[string CONDITIONTABLE_ID](ConditionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post conditiontables(ConditionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CONDITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ConditionTableInsert inserted in data
            select inserted.CONDITIONTABLE_ID;
    }

    isolated resource function put conditiontables/[string CONDITIONTABLE_ID](ConditionTableUpdate value) returns ConditionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CONDITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(CONDITIONTABLE_ID, value);
        return self->/conditiontables/[CONDITIONTABLE_ID].get();
    }

    isolated resource function delete conditiontables/[string CONDITIONTABLE_ID]() returns ConditionTable|persist:Error {
        ConditionTable result = check self->/conditiontables/[CONDITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CONDITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(CONDITIONTABLE_ID);
        return result;
    }

    isolated resource function get compositiontables(CompositionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get compositiontables/[string COMPOSITIONTABLE_ID](CompositionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post compositiontables(CompositionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COMPOSITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from CompositionTableInsert inserted in data
            select inserted.COMPOSITIONTABLE_ID;
    }

    isolated resource function put compositiontables/[string COMPOSITIONTABLE_ID](CompositionTableUpdate value) returns CompositionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COMPOSITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(COMPOSITIONTABLE_ID, value);
        return self->/compositiontables/[COMPOSITIONTABLE_ID].get();
    }

    isolated resource function delete compositiontables/[string COMPOSITIONTABLE_ID]() returns CompositionTable|persist:Error {
        CompositionTable result = check self->/compositiontables/[COMPOSITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COMPOSITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(COMPOSITIONTABLE_ID);
        return result;
    }

    isolated resource function get contracttables(ContractTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get contracttables/[string CONTRACTTABLE_ID](ContractTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post contracttables(ContractTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CONTRACT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ContractTableInsert inserted in data
            select inserted.CONTRACTTABLE_ID;
    }

    isolated resource function put contracttables/[string CONTRACTTABLE_ID](ContractTableUpdate value) returns ContractTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CONTRACT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(CONTRACTTABLE_ID, value);
        return self->/contracttables/[CONTRACTTABLE_ID].get();
    }

    isolated resource function delete contracttables/[string CONTRACTTABLE_ID]() returns ContractTable|persist:Error {
        ContractTable result = check self->/contracttables/[CONTRACTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CONTRACT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(CONTRACTTABLE_ID);
        return result;
    }

    isolated resource function get immunizationtables(ImmunizationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get immunizationtables/[string IMMUNIZATIONTABLE_ID](ImmunizationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post immunizationtables(ImmunizationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMMUNIZATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ImmunizationTableInsert inserted in data
            select inserted.IMMUNIZATIONTABLE_ID;
    }

    isolated resource function put immunizationtables/[string IMMUNIZATIONTABLE_ID](ImmunizationTableUpdate value) returns ImmunizationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMMUNIZATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(IMMUNIZATIONTABLE_ID, value);
        return self->/immunizationtables/[IMMUNIZATIONTABLE_ID].get();
    }

    isolated resource function delete immunizationtables/[string IMMUNIZATIONTABLE_ID]() returns ImmunizationTable|persist:Error {
        ImmunizationTable result = check self->/immunizationtables/[IMMUNIZATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMMUNIZATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(IMMUNIZATIONTABLE_ID);
        return result;
    }

    isolated resource function get medicationdispensetables(MedicationDispenseTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicationdispensetables/[string MEDICATIONDISPENSETABLE_ID](MedicationDispenseTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicationdispensetables(MedicationDispenseTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_DISPENSE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicationDispenseTableInsert inserted in data
            select inserted.MEDICATIONDISPENSETABLE_ID;
    }

    isolated resource function put medicationdispensetables/[string MEDICATIONDISPENSETABLE_ID](MedicationDispenseTableUpdate value) returns MedicationDispenseTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_DISPENSE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICATIONDISPENSETABLE_ID, value);
        return self->/medicationdispensetables/[MEDICATIONDISPENSETABLE_ID].get();
    }

    isolated resource function delete medicationdispensetables/[string MEDICATIONDISPENSETABLE_ID]() returns MedicationDispenseTable|persist:Error {
        MedicationDispenseTable result = check self->/medicationdispensetables/[MEDICATIONDISPENSETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_DISPENSE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICATIONDISPENSETABLE_ID);
        return result;
    }

    isolated resource function get molecularsequencetables(MolecularSequenceTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get molecularsequencetables/[string MOLECULARSEQUENCETABLE_ID](MolecularSequenceTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post molecularsequencetables(MolecularSequenceTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MOLECULAR_SEQUENCE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MolecularSequenceTableInsert inserted in data
            select inserted.MOLECULARSEQUENCETABLE_ID;
    }

    isolated resource function put molecularsequencetables/[string MOLECULARSEQUENCETABLE_ID](MolecularSequenceTableUpdate value) returns MolecularSequenceTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MOLECULAR_SEQUENCE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MOLECULARSEQUENCETABLE_ID, value);
        return self->/molecularsequencetables/[MOLECULARSEQUENCETABLE_ID].get();
    }

    isolated resource function delete molecularsequencetables/[string MOLECULARSEQUENCETABLE_ID]() returns MolecularSequenceTable|persist:Error {
        MolecularSequenceTable result = check self->/molecularsequencetables/[MOLECULARSEQUENCETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MOLECULAR_SEQUENCE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MOLECULARSEQUENCETABLE_ID);
        return result;
    }

    isolated resource function get searchparametertables(SearchParameterTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get searchparametertables/[string SEARCHPARAMETERTABLE_ID](SearchParameterTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post searchparametertables(SearchParameterTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SEARCH_PARAMETER_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from SearchParameterTableInsert inserted in data
            select inserted.SEARCHPARAMETERTABLE_ID;
    }

    isolated resource function put searchparametertables/[string SEARCHPARAMETERTABLE_ID](SearchParameterTableUpdate value) returns SearchParameterTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SEARCH_PARAMETER_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(SEARCHPARAMETERTABLE_ID, value);
        return self->/searchparametertables/[SEARCHPARAMETERTABLE_ID].get();
    }

    isolated resource function delete searchparametertables/[string SEARCHPARAMETERTABLE_ID]() returns SearchParameterTable|persist:Error {
        SearchParameterTable result = check self->/searchparametertables/[SEARCHPARAMETERTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SEARCH_PARAMETER_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(SEARCHPARAMETERTABLE_ID);
        return result;
    }

    isolated resource function get medicationrequesttables(MedicationRequestTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicationrequesttables/[string MEDICATIONREQUESTTABLE_ID](MedicationRequestTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicationrequesttables(MedicationRequestTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_REQUEST_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicationRequestTableInsert inserted in data
            select inserted.MEDICATIONREQUESTTABLE_ID;
    }

    isolated resource function put medicationrequesttables/[string MEDICATIONREQUESTTABLE_ID](MedicationRequestTableUpdate value) returns MedicationRequestTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_REQUEST_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICATIONREQUESTTABLE_ID, value);
        return self->/medicationrequesttables/[MEDICATIONREQUESTTABLE_ID].get();
    }

    isolated resource function delete medicationrequesttables/[string MEDICATIONREQUESTTABLE_ID]() returns MedicationRequestTable|persist:Error {
        MedicationRequestTable result = check self->/medicationrequesttables/[MEDICATIONREQUESTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICATION_REQUEST_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICATIONREQUESTTABLE_ID);
        return result;
    }

    isolated resource function get enrollmentrequesttables(EnrollmentRequestTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get enrollmentrequesttables/[string ENROLLMENTREQUESTTABLE_ID](EnrollmentRequestTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post enrollmentrequesttables(EnrollmentRequestTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENROLLMENT_REQUEST_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from EnrollmentRequestTableInsert inserted in data
            select inserted.ENROLLMENTREQUESTTABLE_ID;
    }

    isolated resource function put enrollmentrequesttables/[string ENROLLMENTREQUESTTABLE_ID](EnrollmentRequestTableUpdate value) returns EnrollmentRequestTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENROLLMENT_REQUEST_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(ENROLLMENTREQUESTTABLE_ID, value);
        return self->/enrollmentrequesttables/[ENROLLMENTREQUESTTABLE_ID].get();
    }

    isolated resource function delete enrollmentrequesttables/[string ENROLLMENTREQUESTTABLE_ID]() returns EnrollmentRequestTable|persist:Error {
        EnrollmentRequestTable result = check self->/enrollmentrequesttables/[ENROLLMENTREQUESTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENROLLMENT_REQUEST_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(ENROLLMENTREQUESTTABLE_ID);
        return result;
    }

    isolated resource function get specimendefinitiontables(SpecimenDefinitionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get specimendefinitiontables/[string SPECIMENDEFINITIONTABLE_ID](SpecimenDefinitionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post specimendefinitiontables(SpecimenDefinitionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SPECIMEN_DEFINITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from SpecimenDefinitionTableInsert inserted in data
            select inserted.SPECIMENDEFINITIONTABLE_ID;
    }

    isolated resource function put specimendefinitiontables/[string SPECIMENDEFINITIONTABLE_ID](SpecimenDefinitionTableUpdate value) returns SpecimenDefinitionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SPECIMEN_DEFINITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(SPECIMENDEFINITIONTABLE_ID, value);
        return self->/specimendefinitiontables/[SPECIMENDEFINITIONTABLE_ID].get();
    }

    isolated resource function delete specimendefinitiontables/[string SPECIMENDEFINITIONTABLE_ID]() returns SpecimenDefinitionTable|persist:Error {
        SpecimenDefinitionTable result = check self->/specimendefinitiontables/[SPECIMENDEFINITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SPECIMEN_DEFINITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(SPECIMENDEFINITIONTABLE_ID);
        return result;
    }

    isolated resource function get eventdefinitiontables(EventDefinitionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get eventdefinitiontables/[string EVENTDEFINITIONTABLE_ID](EventDefinitionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post eventdefinitiontables(EventDefinitionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EVENT_DEFINITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from EventDefinitionTableInsert inserted in data
            select inserted.EVENTDEFINITIONTABLE_ID;
    }

    isolated resource function put eventdefinitiontables/[string EVENTDEFINITIONTABLE_ID](EventDefinitionTableUpdate value) returns EventDefinitionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EVENT_DEFINITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(EVENTDEFINITIONTABLE_ID, value);
        return self->/eventdefinitiontables/[EVENTDEFINITIONTABLE_ID].get();
    }

    isolated resource function delete eventdefinitiontables/[string EVENTDEFINITIONTABLE_ID]() returns EventDefinitionTable|persist:Error {
        EventDefinitionTable result = check self->/eventdefinitiontables/[EVENTDEFINITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EVENT_DEFINITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(EVENTDEFINITIONTABLE_ID);
        return result;
    }

    isolated resource function get immunizationevaluationtables(ImmunizationEvaluationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get immunizationevaluationtables/[string IMMUNIZATIONEVALUATIONTABLE_ID](ImmunizationEvaluationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post immunizationevaluationtables(ImmunizationEvaluationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMMUNIZATION_EVALUATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ImmunizationEvaluationTableInsert inserted in data
            select inserted.IMMUNIZATIONEVALUATIONTABLE_ID;
    }

    isolated resource function put immunizationevaluationtables/[string IMMUNIZATIONEVALUATIONTABLE_ID](ImmunizationEvaluationTableUpdate value) returns ImmunizationEvaluationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMMUNIZATION_EVALUATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(IMMUNIZATIONEVALUATIONTABLE_ID, value);
        return self->/immunizationevaluationtables/[IMMUNIZATIONEVALUATIONTABLE_ID].get();
    }

    isolated resource function delete immunizationevaluationtables/[string IMMUNIZATIONEVALUATIONTABLE_ID]() returns ImmunizationEvaluationTable|persist:Error {
        ImmunizationEvaluationTable result = check self->/immunizationevaluationtables/[IMMUNIZATIONEVALUATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(IMMUNIZATION_EVALUATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(IMMUNIZATIONEVALUATIONTABLE_ID);
        return result;
    }

    isolated resource function get paymentreconciliationtables(PaymentReconciliationTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get paymentreconciliationtables/[string PAYMENTRECONCILIATIONTABLE_ID](PaymentReconciliationTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post paymentreconciliationtables(PaymentReconciliationTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PAYMENT_RECONCILIATION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from PaymentReconciliationTableInsert inserted in data
            select inserted.PAYMENTRECONCILIATIONTABLE_ID;
    }

    isolated resource function put paymentreconciliationtables/[string PAYMENTRECONCILIATIONTABLE_ID](PaymentReconciliationTableUpdate value) returns PaymentReconciliationTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PAYMENT_RECONCILIATION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(PAYMENTRECONCILIATIONTABLE_ID, value);
        return self->/paymentreconciliationtables/[PAYMENTRECONCILIATIONTABLE_ID].get();
    }

    isolated resource function delete paymentreconciliationtables/[string PAYMENTRECONCILIATIONTABLE_ID]() returns PaymentReconciliationTable|persist:Error {
        PaymentReconciliationTable result = check self->/paymentreconciliationtables/[PAYMENTRECONCILIATIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PAYMENT_RECONCILIATION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(PAYMENTRECONCILIATIONTABLE_ID);
        return result;
    }

    isolated resource function get measuretables(MeasureTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get measuretables/[string MEASURETABLE_ID](MeasureTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post measuretables(MeasureTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEASURE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MeasureTableInsert inserted in data
            select inserted.MEASURETABLE_ID;
    }

    isolated resource function put measuretables/[string MEASURETABLE_ID](MeasureTableUpdate value) returns MeasureTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEASURE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEASURETABLE_ID, value);
        return self->/measuretables/[MEASURETABLE_ID].get();
    }

    isolated resource function delete measuretables/[string MEASURETABLE_ID]() returns MeasureTable|persist:Error {
        MeasureTable result = check self->/measuretables/[MEASURETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEASURE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEASURETABLE_ID);
        return result;
    }

    isolated resource function get conceptmaptables(ConceptMapTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get conceptmaptables/[string CONCEPTMAPTABLE_ID](ConceptMapTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post conceptmaptables(ConceptMapTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CONCEPT_MAP_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ConceptMapTableInsert inserted in data
            select inserted.CONCEPTMAPTABLE_ID;
    }

    isolated resource function put conceptmaptables/[string CONCEPTMAPTABLE_ID](ConceptMapTableUpdate value) returns ConceptMapTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CONCEPT_MAP_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(CONCEPTMAPTABLE_ID, value);
        return self->/conceptmaptables/[CONCEPTMAPTABLE_ID].get();
    }

    isolated resource function delete conceptmaptables/[string CONCEPTMAPTABLE_ID]() returns ConceptMapTable|persist:Error {
        ConceptMapTable result = check self->/conceptmaptables/[CONCEPTMAPTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CONCEPT_MAP_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(CONCEPTMAPTABLE_ID);
        return result;
    }

    isolated resource function get researchelementdefinitiontables(ResearchElementDefinitionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get researchelementdefinitiontables/[string RESEARCHELEMENTDEFINITIONTABLE_ID](ResearchElementDefinitionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post researchelementdefinitiontables(ResearchElementDefinitionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RESEARCH_ELEMENT_DEFINITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ResearchElementDefinitionTableInsert inserted in data
            select inserted.RESEARCHELEMENTDEFINITIONTABLE_ID;
    }

    isolated resource function put researchelementdefinitiontables/[string RESEARCHELEMENTDEFINITIONTABLE_ID](ResearchElementDefinitionTableUpdate value) returns ResearchElementDefinitionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RESEARCH_ELEMENT_DEFINITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(RESEARCHELEMENTDEFINITIONTABLE_ID, value);
        return self->/researchelementdefinitiontables/[RESEARCHELEMENTDEFINITIONTABLE_ID].get();
    }

    isolated resource function delete researchelementdefinitiontables/[string RESEARCHELEMENTDEFINITIONTABLE_ID]() returns ResearchElementDefinitionTable|persist:Error {
        ResearchElementDefinitionTable result = check self->/researchelementdefinitiontables/[RESEARCHELEMENTDEFINITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(RESEARCH_ELEMENT_DEFINITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(RESEARCHELEMENTDEFINITIONTABLE_ID);
        return result;
    }

    isolated resource function get guidanceresponsetables(GuidanceResponseTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get guidanceresponsetables/[string GUIDANCERESPONSETABLE_ID](GuidanceResponseTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post guidanceresponsetables(GuidanceResponseTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GUIDANCE_RESPONSE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from GuidanceResponseTableInsert inserted in data
            select inserted.GUIDANCERESPONSETABLE_ID;
    }

    isolated resource function put guidanceresponsetables/[string GUIDANCERESPONSETABLE_ID](GuidanceResponseTableUpdate value) returns GuidanceResponseTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GUIDANCE_RESPONSE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(GUIDANCERESPONSETABLE_ID, value);
        return self->/guidanceresponsetables/[GUIDANCERESPONSETABLE_ID].get();
    }

    isolated resource function delete guidanceresponsetables/[string GUIDANCERESPONSETABLE_ID]() returns GuidanceResponseTable|persist:Error {
        GuidanceResponseTable result = check self->/guidanceresponsetables/[GUIDANCERESPONSETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GUIDANCE_RESPONSE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(GUIDANCERESPONSETABLE_ID);
        return result;
    }

    isolated resource function get linkagetables(LinkageTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get linkagetables/[string LINKAGETABLE_ID](LinkageTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post linkagetables(LinkageTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(LINKAGE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from LinkageTableInsert inserted in data
            select inserted.LINKAGETABLE_ID;
    }

    isolated resource function put linkagetables/[string LINKAGETABLE_ID](LinkageTableUpdate value) returns LinkageTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(LINKAGE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(LINKAGETABLE_ID, value);
        return self->/linkagetables/[LINKAGETABLE_ID].get();
    }

    isolated resource function delete linkagetables/[string LINKAGETABLE_ID]() returns LinkageTable|persist:Error {
        LinkageTable result = check self->/linkagetables/[LINKAGETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(LINKAGE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(LINKAGETABLE_ID);
        return result;
    }

    isolated resource function get medicinalproducttables(MedicinalProductTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicinalproducttables/[string MEDICINALPRODUCTTABLE_ID](MedicinalProductTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicinalproducttables(MedicinalProductTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicinalProductTableInsert inserted in data
            select inserted.MEDICINALPRODUCTTABLE_ID;
    }

    isolated resource function put medicinalproducttables/[string MEDICINALPRODUCTTABLE_ID](MedicinalProductTableUpdate value) returns MedicinalProductTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICINALPRODUCTTABLE_ID, value);
        return self->/medicinalproducttables/[MEDICINALPRODUCTTABLE_ID].get();
    }

    isolated resource function delete medicinalproducttables/[string MEDICINALPRODUCTTABLE_ID]() returns MedicinalProductTable|persist:Error {
        MedicinalProductTable result = check self->/medicinalproducttables/[MEDICINALPRODUCTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICINALPRODUCTTABLE_ID);
        return result;
    }

    isolated resource function get devicedefinitiontables(DeviceDefinitionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get devicedefinitiontables/[string DEVICEDEFINITIONTABLE_ID](DeviceDefinitionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post devicedefinitiontables(DeviceDefinitionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_DEFINITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from DeviceDefinitionTableInsert inserted in data
            select inserted.DEVICEDEFINITIONTABLE_ID;
    }

    isolated resource function put devicedefinitiontables/[string DEVICEDEFINITIONTABLE_ID](DeviceDefinitionTableUpdate value) returns DeviceDefinitionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_DEFINITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(DEVICEDEFINITIONTABLE_ID, value);
        return self->/devicedefinitiontables/[DEVICEDEFINITIONTABLE_ID].get();
    }

    isolated resource function delete devicedefinitiontables/[string DEVICEDEFINITIONTABLE_ID]() returns DeviceDefinitionTable|persist:Error {
        DeviceDefinitionTable result = check self->/devicedefinitiontables/[DEVICEDEFINITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DEVICE_DEFINITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(DEVICEDEFINITIONTABLE_ID);
        return result;
    }

    isolated resource function get coverageeligibilityrequesttables(CoverageEligibilityRequestTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get coverageeligibilityrequesttables/[string COVERAGEELIGIBILITYREQUESTTABLE_ID](CoverageEligibilityRequestTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post coverageeligibilityrequesttables(CoverageEligibilityRequestTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COVERAGE_ELIGIBILITY_REQUEST_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from CoverageEligibilityRequestTableInsert inserted in data
            select inserted.COVERAGEELIGIBILITYREQUESTTABLE_ID;
    }

    isolated resource function put coverageeligibilityrequesttables/[string COVERAGEELIGIBILITYREQUESTTABLE_ID](CoverageEligibilityRequestTableUpdate value) returns CoverageEligibilityRequestTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COVERAGE_ELIGIBILITY_REQUEST_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(COVERAGEELIGIBILITYREQUESTTABLE_ID, value);
        return self->/coverageeligibilityrequesttables/[COVERAGEELIGIBILITYREQUESTTABLE_ID].get();
    }

    isolated resource function delete coverageeligibilityrequesttables/[string COVERAGEELIGIBILITYREQUESTTABLE_ID]() returns CoverageEligibilityRequestTable|persist:Error {
        CoverageEligibilityRequestTable result = check self->/coverageeligibilityrequesttables/[COVERAGEELIGIBILITYREQUESTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COVERAGE_ELIGIBILITY_REQUEST_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(COVERAGEELIGIBILITYREQUESTTABLE_ID);
        return result;
    }

    isolated resource function get patienttables(PatientTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get patienttables/[string PATIENTTABLE_ID](PatientTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post patienttables(PatientTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PATIENT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from PatientTableInsert inserted in data
            select inserted.PATIENTTABLE_ID;
    }

    isolated resource function put patienttables/[string PATIENTTABLE_ID](PatientTableUpdate value) returns PatientTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PATIENT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(PATIENTTABLE_ID, value);
        return self->/patienttables/[PATIENTTABLE_ID].get();
    }

    isolated resource function delete patienttables/[string PATIENTTABLE_ID]() returns PatientTable|persist:Error {
        PatientTable result = check self->/patienttables/[PATIENTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PATIENT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(PATIENTTABLE_ID);
        return result;
    }

    isolated resource function get coveragetables(CoverageTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get coveragetables/[string COVERAGETABLE_ID](CoverageTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post coveragetables(CoverageTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COVERAGE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from CoverageTableInsert inserted in data
            select inserted.COVERAGETABLE_ID;
    }

    isolated resource function put coveragetables/[string COVERAGETABLE_ID](CoverageTableUpdate value) returns CoverageTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COVERAGE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(COVERAGETABLE_ID, value);
        return self->/coveragetables/[COVERAGETABLE_ID].get();
    }

    isolated resource function delete coveragetables/[string COVERAGETABLE_ID]() returns CoverageTable|persist:Error {
        CoverageTable result = check self->/coveragetables/[COVERAGETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(COVERAGE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(COVERAGETABLE_ID);
        return result;
    }

    isolated resource function get substancetables(SubstanceTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get substancetables/[string SUBSTANCETABLE_ID](SubstanceTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post substancetables(SubstanceTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUBSTANCE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from SubstanceTableInsert inserted in data
            select inserted.SUBSTANCETABLE_ID;
    }

    isolated resource function put substancetables/[string SUBSTANCETABLE_ID](SubstanceTableUpdate value) returns SubstanceTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUBSTANCE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(SUBSTANCETABLE_ID, value);
        return self->/substancetables/[SUBSTANCETABLE_ID].get();
    }

    isolated resource function delete substancetables/[string SUBSTANCETABLE_ID]() returns SubstanceTable|persist:Error {
        SubstanceTable result = check self->/substancetables/[SUBSTANCETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(SUBSTANCE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(SUBSTANCETABLE_ID);
        return result;
    }

    isolated resource function get chargeitemdefinitiontables(ChargeItemDefinitionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get chargeitemdefinitiontables/[string CHARGEITEMDEFINITIONTABLE_ID](ChargeItemDefinitionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post chargeitemdefinitiontables(ChargeItemDefinitionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CHARGE_ITEM_DEFINITION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ChargeItemDefinitionTableInsert inserted in data
            select inserted.CHARGEITEMDEFINITIONTABLE_ID;
    }

    isolated resource function put chargeitemdefinitiontables/[string CHARGEITEMDEFINITIONTABLE_ID](ChargeItemDefinitionTableUpdate value) returns ChargeItemDefinitionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CHARGE_ITEM_DEFINITION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(CHARGEITEMDEFINITIONTABLE_ID, value);
        return self->/chargeitemdefinitiontables/[CHARGEITEMDEFINITIONTABLE_ID].get();
    }

    isolated resource function delete chargeitemdefinitiontables/[string CHARGEITEMDEFINITIONTABLE_ID]() returns ChargeItemDefinitionTable|persist:Error {
        ChargeItemDefinitionTable result = check self->/chargeitemdefinitiontables/[CHARGEITEMDEFINITIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CHARGE_ITEM_DEFINITION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(CHARGEITEMDEFINITIONTABLE_ID);
        return result;
    }

    isolated resource function get medicinalproductinteractiontables(MedicinalProductInteractionTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get medicinalproductinteractiontables/[string MEDICINALPRODUCTINTERACTIONTABLE_ID](MedicinalProductInteractionTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post medicinalproductinteractiontables(MedicinalProductInteractionTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_INTERACTION_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MedicinalProductInteractionTableInsert inserted in data
            select inserted.MEDICINALPRODUCTINTERACTIONTABLE_ID;
    }

    isolated resource function put medicinalproductinteractiontables/[string MEDICINALPRODUCTINTERACTIONTABLE_ID](MedicinalProductInteractionTableUpdate value) returns MedicinalProductInteractionTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_INTERACTION_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MEDICINALPRODUCTINTERACTIONTABLE_ID, value);
        return self->/medicinalproductinteractiontables/[MEDICINALPRODUCTINTERACTIONTABLE_ID].get();
    }

    isolated resource function delete medicinalproductinteractiontables/[string MEDICINALPRODUCTINTERACTIONTABLE_ID]() returns MedicinalProductInteractionTable|persist:Error {
        MedicinalProductInteractionTable result = check self->/medicinalproductinteractiontables/[MEDICINALPRODUCTINTERACTIONTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MEDICINAL_PRODUCT_INTERACTION_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MEDICINALPRODUCTINTERACTIONTABLE_ID);
        return result;
    }

    isolated resource function get accounttables(AccountTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get accounttables/[string ACCOUNTTABLE_ID](AccountTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post accounttables(AccountTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ACCOUNT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from AccountTableInsert inserted in data
            select inserted.ACCOUNTTABLE_ID;
    }

    isolated resource function put accounttables/[string ACCOUNTTABLE_ID](AccountTableUpdate value) returns AccountTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ACCOUNT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(ACCOUNTTABLE_ID, value);
        return self->/accounttables/[ACCOUNTTABLE_ID].get();
    }

    isolated resource function delete accounttables/[string ACCOUNTTABLE_ID]() returns AccountTable|persist:Error {
        AccountTable result = check self->/accounttables/[ACCOUNTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ACCOUNT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(ACCOUNTTABLE_ID);
        return result;
    }

    isolated resource function get messageheadertables(MessageHeaderTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get messageheadertables/[string MESSAGEHEADERTABLE_ID](MessageHeaderTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post messageheadertables(MessageHeaderTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MESSAGE_HEADER_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from MessageHeaderTableInsert inserted in data
            select inserted.MESSAGEHEADERTABLE_ID;
    }

    isolated resource function put messageheadertables/[string MESSAGEHEADERTABLE_ID](MessageHeaderTableUpdate value) returns MessageHeaderTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MESSAGE_HEADER_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(MESSAGEHEADERTABLE_ID, value);
        return self->/messageheadertables/[MESSAGEHEADERTABLE_ID].get();
    }

    isolated resource function delete messageheadertables/[string MESSAGEHEADERTABLE_ID]() returns MessageHeaderTable|persist:Error {
        MessageHeaderTable result = check self->/messageheadertables/[MESSAGEHEADERTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MESSAGE_HEADER_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(MESSAGEHEADERTABLE_ID);
        return result;
    }

    isolated resource function get auditeventtables(AuditEventTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get auditeventtables/[string AUDITEVENTTABLE_ID](AuditEventTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post auditeventtables(AuditEventTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(AUDIT_EVENT_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from AuditEventTableInsert inserted in data
            select inserted.AUDITEVENTTABLE_ID;
    }

    isolated resource function put auditeventtables/[string AUDITEVENTTABLE_ID](AuditEventTableUpdate value) returns AuditEventTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(AUDIT_EVENT_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(AUDITEVENTTABLE_ID, value);
        return self->/auditeventtables/[AUDITEVENTTABLE_ID].get();
    }

    isolated resource function delete auditeventtables/[string AUDITEVENTTABLE_ID]() returns AuditEventTable|persist:Error {
        AuditEventTable result = check self->/auditeventtables/[AUDITEVENTTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(AUDIT_EVENT_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(AUDITEVENTTABLE_ID);
        return result;
    }

    isolated resource function get nutritionordertables(NutritionOrderTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get nutritionordertables/[string NUTRITIONORDERTABLE_ID](NutritionOrderTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post nutritionordertables(NutritionOrderTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(NUTRITION_ORDER_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from NutritionOrderTableInsert inserted in data
            select inserted.NUTRITIONORDERTABLE_ID;
    }

    isolated resource function put nutritionordertables/[string NUTRITIONORDERTABLE_ID](NutritionOrderTableUpdate value) returns NutritionOrderTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(NUTRITION_ORDER_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(NUTRITIONORDERTABLE_ID, value);
        return self->/nutritionordertables/[NUTRITIONORDERTABLE_ID].get();
    }

    isolated resource function delete nutritionordertables/[string NUTRITIONORDERTABLE_ID]() returns NutritionOrderTable|persist:Error {
        NutritionOrderTable result = check self->/nutritionordertables/[NUTRITIONORDERTABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(NUTRITION_ORDER_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(NUTRITIONORDERTABLE_ID);
        return result;
    }

    isolated resource function get questionnairetables(QuestionnaireTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get questionnairetables/[string QUESTIONNAIRETABLE_ID](QuestionnaireTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post questionnairetables(QuestionnaireTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(QUESTIONNAIRE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from QuestionnaireTableInsert inserted in data
            select inserted.QUESTIONNAIRETABLE_ID;
    }

    isolated resource function put questionnairetables/[string QUESTIONNAIRETABLE_ID](QuestionnaireTableUpdate value) returns QuestionnaireTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(QUESTIONNAIRE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(QUESTIONNAIRETABLE_ID, value);
        return self->/questionnairetables/[QUESTIONNAIRETABLE_ID].get();
    }

    isolated resource function delete questionnairetables/[string QUESTIONNAIRETABLE_ID]() returns QuestionnaireTable|persist:Error {
        QuestionnaireTable result = check self->/questionnairetables/[QUESTIONNAIRETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(QUESTIONNAIRE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(QUESTIONNAIRETABLE_ID);
        return result;
    }

    isolated resource function get appointmentresponsetables(AppointmentResponseTableTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get appointmentresponsetables/[string APPOINTMENTRESPONSETABLE_ID](AppointmentResponseTableTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post appointmentresponsetables(AppointmentResponseTableInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(APPOINTMENT_RESPONSE_TABLE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from AppointmentResponseTableInsert inserted in data
            select inserted.APPOINTMENTRESPONSETABLE_ID;
    }

    isolated resource function put appointmentresponsetables/[string APPOINTMENTRESPONSETABLE_ID](AppointmentResponseTableUpdate value) returns AppointmentResponseTable|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(APPOINTMENT_RESPONSE_TABLE);
        }
        _ = check sqlClient.runUpdateQuery(APPOINTMENTRESPONSETABLE_ID, value);
        return self->/appointmentresponsetables/[APPOINTMENTRESPONSETABLE_ID].get();
    }

    isolated resource function delete appointmentresponsetables/[string APPOINTMENTRESPONSETABLE_ID]() returns AppointmentResponseTable|persist:Error {
        AppointmentResponseTable result = check self->/appointmentresponsetables/[APPOINTMENTRESPONSETABLE_ID].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(APPOINTMENT_RESPONSE_TABLE);
        }
        _ = check sqlClient.runDeleteQuery(APPOINTMENTRESPONSETABLE_ID);
        return result;
    }

    remote isolated function queryNativeSQL(sql:ParameterizedQuery sqlQuery, typedesc<record {}> rowType = <>) returns stream<rowType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor"
    } external;

    remote isolated function executeNativeSQL(sql:ParameterizedQuery sqlQuery) returns psql:ExecutionResult|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor"
    } external;

    public isolated function close() returns persist:Error? {
        error? result = self.dbClient.close();
        if result is error {
            return <persist:Error>error(result.message());
        }
        return result;
    }
}

