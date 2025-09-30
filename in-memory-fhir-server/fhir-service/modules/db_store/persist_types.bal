// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

import ballerina/time;

public type SEARCH_PARAM_RES_EXPRESSIONS record {|
    readonly int ID;
    string SEARCH_PARAM_NAME;
    string SEARCH_PARAM_TYPE;
    string RESOURCE_NAME;
    string EXPRESSION;
|};

public type SEARCH_PARAM_RES_EXPRESSIONSOptionalized record {|
    int ID?;
    string SEARCH_PARAM_NAME?;
    string SEARCH_PARAM_TYPE?;
    string RESOURCE_NAME?;
    string EXPRESSION?;
|};

public type SEARCH_PARAM_RES_EXPRESSIONSTargetType typedesc<SEARCH_PARAM_RES_EXPRESSIONSOptionalized>;

public type SEARCH_PARAM_RES_EXPRESSIONSInsert record {|
    string SEARCH_PARAM_NAME;
    string SEARCH_PARAM_TYPE;
    string RESOURCE_NAME;
    string EXPRESSION;
|};

public type SEARCH_PARAM_RES_EXPRESSIONSUpdate record {|
    string SEARCH_PARAM_NAME?;
    string SEARCH_PARAM_TYPE?;
    string RESOURCE_NAME?;
    string EXPRESSION?;
|};

public type REFERENCES record {|
    readonly int ID;
    string SOURCE_RESOURCE_TYPE;
    string SOURCE_RESOURCE_ID;
    string SOURCE_EXPRESSION;
    string TARGET_RESOURCE_TYPE;
    string TARGET_RESOURCE_ID;
    string DISPLAY_VALUE;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
|};

public type REFERENCESOptionalized record {|
    int ID?;
    string SOURCE_RESOURCE_TYPE?;
    string SOURCE_RESOURCE_ID?;
    string SOURCE_EXPRESSION?;
    string TARGET_RESOURCE_TYPE?;
    string TARGET_RESOURCE_ID?;
    string DISPLAY_VALUE?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
|};

public type REFERENCESTargetType typedesc<REFERENCESOptionalized>;

public type REFERENCESInsert record {|
    string SOURCE_RESOURCE_TYPE;
    string SOURCE_RESOURCE_ID;
    string SOURCE_EXPRESSION;
    string TARGET_RESOURCE_TYPE;
    string TARGET_RESOURCE_ID;
    string DISPLAY_VALUE;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
|};

public type REFERENCESUpdate record {|
    string SOURCE_RESOURCE_TYPE?;
    string SOURCE_RESOURCE_ID?;
    string SOURCE_EXPRESSION?;
    string TARGET_RESOURCE_TYPE?;
    string TARGET_RESOURCE_ID?;
    string DISPLAY_VALUE?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
|};

public type TestScriptTable record {|
    readonly string TESTSCRIPTTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TESTSCRIPT_CAPABILITY;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type TestScriptTableOptionalized record {|
    string TESTSCRIPTTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TESTSCRIPT_CAPABILITY?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type TestScriptTableTargetType typedesc<TestScriptTableOptionalized>;

public type TestScriptTableInsert TestScriptTable;

public type TestScriptTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TESTSCRIPT_CAPABILITY?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type TestReportTable record {|
    readonly string TESTREPORTTABLE_ID;
    time:Date? ISSUED;
    string? PARTICIPANT;
    string? TESTER;
    string? IDENTIFIER;
    string? RESULT;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type TestReportTableOptionalized record {|
    string TESTREPORTTABLE_ID?;
    time:Date? ISSUED?;
    string? PARTICIPANT?;
    string? TESTER?;
    string? IDENTIFIER?;
    string? RESULT?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type TestReportTableTargetType typedesc<TestReportTableOptionalized>;

public type TestReportTableInsert TestReportTable;

public type TestReportTableUpdate record {|
    time:Date? ISSUED?;
    string? PARTICIPANT?;
    string? TESTER?;
    string? IDENTIFIER?;
    string? RESULT?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type RelatedPersonTable record {|
    readonly string RELATEDPERSONTABLE_ID;
    string? ADDRESS_COUNTRY;
    string? ADDRESS_POSTALCODE;
    string? ACTIVE;
    string? PHONE;
    time:Date? BIRTHDATE;
    string? ADDRESS_CITY;
    string? EMAIL;
    string? ADDRESS_STATE;
    string? TELECOM;
    string? NAME;
    string? ADDRESS_USE;
    string? ADDRESS;
    string? GENDER;
    string? PHONETIC;
    string? IDENTIFIER;
    string? RELATIONSHIP;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type RelatedPersonTableOptionalized record {|
    string RELATEDPERSONTABLE_ID?;
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? ACTIVE?;
    string? PHONE?;
    time:Date? BIRTHDATE?;
    string? ADDRESS_CITY?;
    string? EMAIL?;
    string? ADDRESS_STATE?;
    string? TELECOM?;
    string? NAME?;
    string? ADDRESS_USE?;
    string? ADDRESS?;
    string? GENDER?;
    string? PHONETIC?;
    string? IDENTIFIER?;
    string? RELATIONSHIP?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type RelatedPersonTableTargetType typedesc<RelatedPersonTableOptionalized>;

public type RelatedPersonTableInsert RelatedPersonTable;

public type RelatedPersonTableUpdate record {|
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? ACTIVE?;
    string? PHONE?;
    time:Date? BIRTHDATE?;
    string? ADDRESS_CITY?;
    string? EMAIL?;
    string? ADDRESS_STATE?;
    string? TELECOM?;
    string? NAME?;
    string? ADDRESS_USE?;
    string? ADDRESS?;
    string? GENDER?;
    string? PHONETIC?;
    string? IDENTIFIER?;
    string? RELATIONSHIP?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EvidenceVariableTable record {|
    readonly string EVIDENCEVARIABLETABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    time:Date? EFFECTIVE;
    string? TOPIC;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EvidenceVariableTableOptionalized record {|
    string EVIDENCEVARIABLETABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EvidenceVariableTableTargetType typedesc<EvidenceVariableTableOptionalized>;

public type EvidenceVariableTableInsert EvidenceVariableTable;

public type EvidenceVariableTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ValueSetTable record {|
    readonly string VALUESETTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? CODE;
    string? STATUS;
    string? DESCRIPTION;
    string? EXPANSION;
    string? VERSION;
    string? REFERENCE;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ValueSetTableOptionalized record {|
    string VALUESETTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? EXPANSION?;
    string? VERSION?;
    string? REFERENCE?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ValueSetTableTargetType typedesc<ValueSetTableOptionalized>;

public type ValueSetTableInsert ValueSetTable;

public type ValueSetTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? EXPANSION?;
    string? VERSION?;
    string? REFERENCE?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DocumentManifestTable record {|
    readonly string DOCUMENTMANIFESTTABLE_ID;
    time:Date? CREATED;
    string? STATUS;
    string? RELATED_ID;
    string? DESCRIPTION;
    string? SOURCE;
    string? IDENTIFIER;
    string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DocumentManifestTableOptionalized record {|
    string DOCUMENTMANIFESTTABLE_ID?;
    time:Date? CREATED?;
    string? STATUS?;
    string? RELATED_ID?;
    string? DESCRIPTION?;
    string? SOURCE?;
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DocumentManifestTableTargetType typedesc<DocumentManifestTableOptionalized>;

public type DocumentManifestTableInsert DocumentManifestTable;

public type DocumentManifestTableUpdate record {|
    time:Date? CREATED?;
    string? STATUS?;
    string? RELATED_ID?;
    string? DESCRIPTION?;
    string? SOURCE?;
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ImmunizationRecommendationTable record {|
    readonly string IMMUNIZATIONRECOMMENDATIONTABLE_ID;
    time:Date? DATE;
    string? STATUS;
    string? TARGET_DISEASE;
    string? VACCINE_TYPE;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ImmunizationRecommendationTableOptionalized record {|
    string IMMUNIZATIONRECOMMENDATIONTABLE_ID?;
    time:Date? DATE?;
    string? STATUS?;
    string? TARGET_DISEASE?;
    string? VACCINE_TYPE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ImmunizationRecommendationTableTargetType typedesc<ImmunizationRecommendationTableOptionalized>;

public type ImmunizationRecommendationTableInsert ImmunizationRecommendationTable;

public type ImmunizationRecommendationTableUpdate record {|
    time:Date? DATE?;
    string? STATUS?;
    string? TARGET_DISEASE?;
    string? VACCINE_TYPE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DeviceMetricTable record {|
    readonly string DEVICEMETRICTABLE_ID;
    string? CATEGORY;
    string? IDENTIFIER;
    string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DeviceMetricTableOptionalized record {|
    string DEVICEMETRICTABLE_ID?;
    string? CATEGORY?;
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DeviceMetricTableTargetType typedesc<DeviceMetricTableOptionalized>;

public type DeviceMetricTableInsert DeviceMetricTable;

public type DeviceMetricTableUpdate record {|
    string? CATEGORY?;
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type LocationTable record {|
    readonly string LOCATIONTABLE_ID;
    string? ADDRESS_COUNTRY;
    string? ADDRESS_POSTALCODE;
    string? STATUS;
    string? ADDRESS_USE;
    string? ADDRESS;
    string? OPERATIONAL_STATUS;
    string? IDENTIFIER;
    string? ADDRESS_CITY;
    string? TYPE;
    string? ADDRESS_STATE;
    string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type LocationTableOptionalized record {|
    string LOCATIONTABLE_ID?;
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? STATUS?;
    string? ADDRESS_USE?;
    string? ADDRESS?;
    string? OPERATIONAL_STATUS?;
    string? IDENTIFIER?;
    string? ADDRESS_CITY?;
    string? TYPE?;
    string? ADDRESS_STATE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type LocationTableTargetType typedesc<LocationTableOptionalized>;

public type LocationTableInsert LocationTable;

public type LocationTableUpdate record {|
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? STATUS?;
    string? ADDRESS_USE?;
    string? ADDRESS?;
    string? OPERATIONAL_STATUS?;
    string? IDENTIFIER?;
    string? ADDRESS_CITY?;
    string? TYPE?;
    string? ADDRESS_STATE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ExplanationOfBenefitTable record {|
    readonly string EXPLANATIONOFBENEFITTABLE_ID;
    time:Date? CREATED;
    string? STATUS;
    string? IDENTIFIER;
    string? DISPOSITION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ExplanationOfBenefitTableOptionalized record {|
    string EXPLANATIONOFBENEFITTABLE_ID?;
    time:Date? CREATED?;
    string? STATUS?;
    string? IDENTIFIER?;
    string? DISPOSITION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ExplanationOfBenefitTableTargetType typedesc<ExplanationOfBenefitTableOptionalized>;

public type ExplanationOfBenefitTableInsert ExplanationOfBenefitTable;

public type ExplanationOfBenefitTableUpdate record {|
    time:Date? CREATED?;
    string? STATUS?;
    string? IDENTIFIER?;
    string? DISPOSITION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type FlagTable record {|
    readonly string FLAGTABLE_ID;
    time:Date? DATE;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type FlagTableOptionalized record {|
    string FLAGTABLE_ID?;
    time:Date? DATE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type FlagTableTargetType typedesc<FlagTableOptionalized>;

public type FlagTableInsert FlagTable;

public type FlagTableUpdate record {|
    time:Date? DATE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicationStatementTable record {|
    readonly string MEDICATIONSTATEMENTTABLE_ID;
    string? CODE;
    string? STATUS;
    string? CATEGORY;
    time:Date? EFFECTIVE;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicationStatementTableOptionalized record {|
    string MEDICATIONSTATEMENTTABLE_ID?;
    string? CODE?;
    string? STATUS?;
    string? CATEGORY?;
    time:Date? EFFECTIVE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicationStatementTableTargetType typedesc<MedicationStatementTableOptionalized>;

public type MedicationStatementTableInsert MedicationStatementTable;

public type MedicationStatementTableUpdate record {|
    string? CODE?;
    string? STATUS?;
    string? CATEGORY?;
    time:Date? EFFECTIVE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type InsurancePlanTable record {|
    readonly string INSURANCEPLANTABLE_ID;
    string? ADDRESS_COUNTRY;
    string? ADDRESS_POSTALCODE;
    string? STATUS;
    string? ADDRESS_USE;
    string? ADDRESS;
    string? PHONETIC;
    string? IDENTIFIER;
    string? ADDRESS_CITY;
    string? TYPE;
    string? ADDRESS_STATE;
    string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type InsurancePlanTableOptionalized record {|
    string INSURANCEPLANTABLE_ID?;
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? STATUS?;
    string? ADDRESS_USE?;
    string? ADDRESS?;
    string? PHONETIC?;
    string? IDENTIFIER?;
    string? ADDRESS_CITY?;
    string? TYPE?;
    string? ADDRESS_STATE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type InsurancePlanTableTargetType typedesc<InsurancePlanTableOptionalized>;

public type InsurancePlanTableInsert InsurancePlanTable;

public type InsurancePlanTableUpdate record {|
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? STATUS?;
    string? ADDRESS_USE?;
    string? ADDRESS?;
    string? PHONETIC?;
    string? IDENTIFIER?;
    string? ADDRESS_CITY?;
    string? TYPE?;
    string? ADDRESS_STATE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductContraindicationTable record {|
    readonly string MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductContraindicationTableOptionalized record {|
    string MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductContraindicationTableTargetType typedesc<MedicinalProductContraindicationTableOptionalized>;

public type MedicinalProductContraindicationTableInsert MedicinalProductContraindicationTable;

public type MedicinalProductContraindicationTableUpdate record {|
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ClaimResponseTable record {|
    readonly string CLAIMRESPONSETABLE_ID;
    time:Date? CREATED;
    string? STATUS;
    string? OUTCOME;
    string? USE;
    string? IDENTIFIER;
    time:Date? PAYMENT_DATE;
    string? DISPOSITION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ClaimResponseTableOptionalized record {|
    string CLAIMRESPONSETABLE_ID?;
    time:Date? CREATED?;
    string? STATUS?;
    string? OUTCOME?;
    string? USE?;
    string? IDENTIFIER?;
    time:Date? PAYMENT_DATE?;
    string? DISPOSITION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ClaimResponseTableTargetType typedesc<ClaimResponseTableOptionalized>;

public type ClaimResponseTableInsert ClaimResponseTable;

public type ClaimResponseTableUpdate record {|
    time:Date? CREATED?;
    string? STATUS?;
    string? OUTCOME?;
    string? USE?;
    string? IDENTIFIER?;
    time:Date? PAYMENT_DATE?;
    string? DISPOSITION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductAuthorizationTable record {|
    readonly string MEDICINALPRODUCTAUTHORIZATIONTABLE_ID;
    string? STATUS;
    string? COUNTRY;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductAuthorizationTableOptionalized record {|
    string MEDICINALPRODUCTAUTHORIZATIONTABLE_ID?;
    string? STATUS?;
    string? COUNTRY?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductAuthorizationTableTargetType typedesc<MedicinalProductAuthorizationTableOptionalized>;

public type MedicinalProductAuthorizationTableInsert MedicinalProductAuthorizationTable;

public type MedicinalProductAuthorizationTableUpdate record {|
    string? STATUS?;
    string? COUNTRY?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ImagingStudyTable record {|
    readonly string IMAGINGSTUDYTABLE_ID;
    string? STATUS;
    string? DICOM_CLASS;
    string? SERIES;
    string? MODALITY;
    time:Date? STARTED;
    string? BODYSITE;
    string? INSTANCE;
    string? IDENTIFIER;
    string? REASON;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ImagingStudyTableOptionalized record {|
    string IMAGINGSTUDYTABLE_ID?;
    string? STATUS?;
    string? DICOM_CLASS?;
    string? SERIES?;
    string? MODALITY?;
    time:Date? STARTED?;
    string? BODYSITE?;
    string? INSTANCE?;
    string? IDENTIFIER?;
    string? REASON?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ImagingStudyTableTargetType typedesc<ImagingStudyTableOptionalized>;

public type ImagingStudyTableInsert ImagingStudyTable;

public type ImagingStudyTableUpdate record {|
    string? STATUS?;
    string? DICOM_CLASS?;
    string? SERIES?;
    string? MODALITY?;
    time:Date? STARTED?;
    string? BODYSITE?;
    string? INSTANCE?;
    string? IDENTIFIER?;
    string? REASON?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PractitionerRoleTable record {|
    readonly string PRACTITIONERROLETABLE_ID;
    string? ROLE;
    time:Date? DATE;
    string? ACTIVE;
    string? PHONE;
    string? SPECIALTY;
    string? IDENTIFIER;
    string? EMAIL;
    string? TELECOM;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PractitionerRoleTableOptionalized record {|
    string PRACTITIONERROLETABLE_ID?;
    string? ROLE?;
    time:Date? DATE?;
    string? ACTIVE?;
    string? PHONE?;
    string? SPECIALTY?;
    string? IDENTIFIER?;
    string? EMAIL?;
    string? TELECOM?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PractitionerRoleTableTargetType typedesc<PractitionerRoleTableOptionalized>;

public type PractitionerRoleTableInsert PractitionerRoleTable;

public type PractitionerRoleTableUpdate record {|
    string? ROLE?;
    time:Date? DATE?;
    string? ACTIVE?;
    string? PHONE?;
    string? SPECIALTY?;
    string? IDENTIFIER?;
    string? EMAIL?;
    string? TELECOM?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type GroupTable record {|
    readonly string GROUPTABLE_ID;
    string? CHARACTERISTIC;
    string? CODE;
    string? EXCLUDE;
    string? IDENTIFIER;
    string? VALUE;
    string? ACTUAL;
    string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type GroupTableOptionalized record {|
    string GROUPTABLE_ID?;
    string? CHARACTERISTIC?;
    string? CODE?;
    string? EXCLUDE?;
    string? IDENTIFIER?;
    string? VALUE?;
    string? ACTUAL?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type GroupTableTargetType typedesc<GroupTableOptionalized>;

public type GroupTableInsert GroupTable;

public type GroupTableUpdate record {|
    string? CHARACTERISTIC?;
    string? CODE?;
    string? EXCLUDE?;
    string? IDENTIFIER?;
    string? VALUE?;
    string? ACTUAL?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PersonTable record {|
    readonly string PERSONTABLE_ID;
    string? ADDRESS_COUNTRY;
    string? ADDRESS_POSTALCODE;
    string? PHONE;
    time:Date? BIRTHDATE;
    string? ADDRESS_CITY;
    string? EMAIL;
    string? ADDRESS_STATE;
    string? TELECOM;
    string? NAME;
    string? ADDRESS_USE;
    string? ADDRESS;
    string? GENDER;
    string? PHONETIC;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PersonTableOptionalized record {|
    string PERSONTABLE_ID?;
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? PHONE?;
    time:Date? BIRTHDATE?;
    string? ADDRESS_CITY?;
    string? EMAIL?;
    string? ADDRESS_STATE?;
    string? TELECOM?;
    string? NAME?;
    string? ADDRESS_USE?;
    string? ADDRESS?;
    string? GENDER?;
    string? PHONETIC?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PersonTableTargetType typedesc<PersonTableOptionalized>;

public type PersonTableInsert PersonTable;

public type PersonTableUpdate record {|
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? PHONE?;
    time:Date? BIRTHDATE?;
    string? ADDRESS_CITY?;
    string? EMAIL?;
    string? ADDRESS_STATE?;
    string? TELECOM?;
    string? NAME?;
    string? ADDRESS_USE?;
    string? ADDRESS?;
    string? GENDER?;
    string? PHONETIC?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PractitionerTable record {|
    readonly string PRACTITIONERTABLE_ID;
    string? ADDRESS_COUNTRY;
    string? ADDRESS_POSTALCODE;
    string? ACTIVE;
    string? PHONE;
    string? ADDRESS_CITY;
    string? EMAIL;
    string? ADDRESS_STATE;
    string? TELECOM;
    string? NAME;
    string? FAMILY;
    string? ADDRESS_USE;
    string? GIVEN;
    string? ADDRESS;
    string? GENDER;
    string? PHONETIC;
    string? IDENTIFIER;
    string? COMMUNICATION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PractitionerTableOptionalized record {|
    string PRACTITIONERTABLE_ID?;
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? ACTIVE?;
    string? PHONE?;
    string? ADDRESS_CITY?;
    string? EMAIL?;
    string? ADDRESS_STATE?;
    string? TELECOM?;
    string? NAME?;
    string? FAMILY?;
    string? ADDRESS_USE?;
    string? GIVEN?;
    string? ADDRESS?;
    string? GENDER?;
    string? PHONETIC?;
    string? IDENTIFIER?;
    string? COMMUNICATION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PractitionerTableTargetType typedesc<PractitionerTableOptionalized>;

public type PractitionerTableInsert PractitionerTable;

public type PractitionerTableUpdate record {|
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? ACTIVE?;
    string? PHONE?;
    string? ADDRESS_CITY?;
    string? EMAIL?;
    string? ADDRESS_STATE?;
    string? TELECOM?;
    string? NAME?;
    string? FAMILY?;
    string? ADDRESS_USE?;
    string? GIVEN?;
    string? ADDRESS?;
    string? GENDER?;
    string? PHONETIC?;
    string? IDENTIFIER?;
    string? COMMUNICATION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ActivityDefinitionTable record {|
    readonly string ACTIVITYDEFINITIONTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    time:Date? EFFECTIVE;
    string? TOPIC;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ActivityDefinitionTableOptionalized record {|
    string ACTIVITYDEFINITIONTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ActivityDefinitionTableTargetType typedesc<ActivityDefinitionTableOptionalized>;

public type ActivityDefinitionTableInsert ActivityDefinitionTable;

public type ActivityDefinitionTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EvidenceTable record {|
    readonly string EVIDENCETABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    time:Date? EFFECTIVE;
    string? TOPIC;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EvidenceTableOptionalized record {|
    string EVIDENCETABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EvidenceTableTargetType typedesc<EvidenceTableOptionalized>;

public type EvidenceTableInsert EvidenceTable;

public type EvidenceTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DeviceTable record {|
    readonly string DEVICETABLE_ID;
    string? STATUS;
    string? UDI_DI;
    string? UDI_CARRIER;
    string? DEVICE_NAME;
    string? IDENTIFIER;
    string? MODEL;
    string? MANUFACTURER;
    string? TYPE;
    string? URL;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DeviceTableOptionalized record {|
    string DEVICETABLE_ID?;
    string? STATUS?;
    string? UDI_DI?;
    string? UDI_CARRIER?;
    string? DEVICE_NAME?;
    string? IDENTIFIER?;
    string? MODEL?;
    string? MANUFACTURER?;
    string? TYPE?;
    string? URL?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DeviceTableTargetType typedesc<DeviceTableOptionalized>;

public type DeviceTableInsert DeviceTable;

public type DeviceTableUpdate record {|
    string? STATUS?;
    string? UDI_DI?;
    string? UDI_CARRIER?;
    string? DEVICE_NAME?;
    string? IDENTIFIER?;
    string? MODEL?;
    string? MANUFACTURER?;
    string? TYPE?;
    string? URL?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type FamilyMemberHistoryTable record {|
    readonly string FAMILYMEMBERHISTORYTABLE_ID;
    time:Date? DATE;
    string? CODE;
    string? STATUS;
    string? INSTANTIATES_URI;
    string? SEX;
    string? IDENTIFIER;
    string? RELATIONSHIP;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type FamilyMemberHistoryTableOptionalized record {|
    string FAMILYMEMBERHISTORYTABLE_ID?;
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? INSTANTIATES_URI?;
    string? SEX?;
    string? IDENTIFIER?;
    string? RELATIONSHIP?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type FamilyMemberHistoryTableTargetType typedesc<FamilyMemberHistoryTableOptionalized>;

public type FamilyMemberHistoryTableInsert FamilyMemberHistoryTable;

public type FamilyMemberHistoryTableUpdate record {|
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? INSTANTIATES_URI?;
    string? SEX?;
    string? IDENTIFIER?;
    string? RELATIONSHIP?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type AdverseEventTable record {|
    readonly string ADVERSEEVENTTABLE_ID;
    time:Date? DATE;
    string? CATEGORY;
    string? SERIOUSNESS;
    string? ACTUALITY;
    string? SEVERITY;
    string? EVENT;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type AdverseEventTableOptionalized record {|
    string ADVERSEEVENTTABLE_ID?;
    time:Date? DATE?;
    string? CATEGORY?;
    string? SERIOUSNESS?;
    string? ACTUALITY?;
    string? SEVERITY?;
    string? EVENT?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type AdverseEventTableTargetType typedesc<AdverseEventTableOptionalized>;

public type AdverseEventTableInsert AdverseEventTable;

public type AdverseEventTableUpdate record {|
    time:Date? DATE?;
    string? CATEGORY?;
    string? SERIOUSNESS?;
    string? ACTUALITY?;
    string? SEVERITY?;
    string? EVENT?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SupplyRequestTable record {|
    readonly string SUPPLYREQUESTTABLE_ID;
    time:Date? DATE;
    string? STATUS;
    string? CATEGORY;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SupplyRequestTableOptionalized record {|
    string SUPPLYREQUESTTABLE_ID?;
    time:Date? DATE?;
    string? STATUS?;
    string? CATEGORY?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SupplyRequestTableTargetType typedesc<SupplyRequestTableOptionalized>;

public type SupplyRequestTableInsert SupplyRequestTable;

public type SupplyRequestTableUpdate record {|
    time:Date? DATE?;
    string? STATUS?;
    string? CATEGORY?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ExampleScenarioTable record {|
    readonly string EXAMPLESCENARIOTABLE_ID;
    time:Date? DATE;
    string? PUBLISHER;
    string? STATUS;
    string? JURISDICTION;
    string? VERSION;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT;
    string? URL;
    string? CONTEXT_TYPE;
    string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ExampleScenarioTableOptionalized record {|
    string EXAMPLESCENARIOTABLE_ID?;
    time:Date? DATE?;
    string? PUBLISHER?;
    string? STATUS?;
    string? JURISDICTION?;
    string? VERSION?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT?;
    string? URL?;
    string? CONTEXT_TYPE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ExampleScenarioTableTargetType typedesc<ExampleScenarioTableOptionalized>;

public type ExampleScenarioTableInsert ExampleScenarioTable;

public type ExampleScenarioTableUpdate record {|
    time:Date? DATE?;
    string? PUBLISHER?;
    string? STATUS?;
    string? JURISDICTION?;
    string? VERSION?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT?;
    string? URL?;
    string? CONTEXT_TYPE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type InvoiceTable record {|
    readonly string INVOICETABLE_ID;
    time:Date? DATE;
    string? STATUS;
    string? TOTALNET;
    string? PARTICIPANT_ROLE;
    string? IDENTIFIER;
    string? TYPE;
    string? TOTALGROSS;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type InvoiceTableOptionalized record {|
    string INVOICETABLE_ID?;
    time:Date? DATE?;
    string? STATUS?;
    string? TOTALNET?;
    string? PARTICIPANT_ROLE?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? TOTALGROSS?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type InvoiceTableTargetType typedesc<InvoiceTableOptionalized>;

public type InvoiceTableInsert InvoiceTable;

public type InvoiceTableUpdate record {|
    time:Date? DATE?;
    string? STATUS?;
    string? TOTALNET?;
    string? PARTICIPANT_ROLE?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? TOTALGROSS?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type QuestionnaireResponseTable record {|
    readonly string QUESTIONNAIRERESPONSETABLE_ID;
    string? STATUS;
    time:Date? AUTHORED;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type QuestionnaireResponseTableOptionalized record {|
    string QUESTIONNAIRERESPONSETABLE_ID?;
    string? STATUS?;
    time:Date? AUTHORED?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type QuestionnaireResponseTableTargetType typedesc<QuestionnaireResponseTableOptionalized>;

public type QuestionnaireResponseTableInsert QuestionnaireResponseTable;

public type QuestionnaireResponseTableUpdate record {|
    string? STATUS?;
    time:Date? AUTHORED?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ObservationTable record {|
    readonly string OBSERVATIONTABLE_ID;
    string? COMPONENT_CODE;
    string? VALUE_QUANTITY;
    string? COMBO_CODE;
    time:Date? VALUE_DATE;
    time:Date? DATE;
    string? VALUE_STRING;
    string? COMBO_DATA_ABSENT_REASON;
    string? CODE;
    string? STATUS;
    string? CATEGORY;
    string? COMBO_VALUE_QUANTITY;
    string? VALUE_CONCEPT;
    string? METHOD;
    string? IDENTIFIER;
    string? COMPONENT_DATA_ABSENT_REASON;
    string? DATA_ABSENT_REASON;
    string? COMPONENT_VALUE_QUANTITY;
    string? COMPONENT_VALUE_CONCEPT;
    string? COMBO_VALUE_CONCEPT;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ObservationTableOptionalized record {|
    string OBSERVATIONTABLE_ID?;
    string? COMPONENT_CODE?;
    string? VALUE_QUANTITY?;
    string? COMBO_CODE?;
    time:Date? VALUE_DATE?;
    time:Date? DATE?;
    string? VALUE_STRING?;
    string? COMBO_DATA_ABSENT_REASON?;
    string? CODE?;
    string? STATUS?;
    string? CATEGORY?;
    string? COMBO_VALUE_QUANTITY?;
    string? VALUE_CONCEPT?;
    string? METHOD?;
    string? IDENTIFIER?;
    string? COMPONENT_DATA_ABSENT_REASON?;
    string? DATA_ABSENT_REASON?;
    string? COMPONENT_VALUE_QUANTITY?;
    string? COMPONENT_VALUE_CONCEPT?;
    string? COMBO_VALUE_CONCEPT?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ObservationTableTargetType typedesc<ObservationTableOptionalized>;

public type ObservationTableInsert ObservationTable;

public type ObservationTableUpdate record {|
    string? COMPONENT_CODE?;
    string? VALUE_QUANTITY?;
    string? COMBO_CODE?;
    time:Date? VALUE_DATE?;
    time:Date? DATE?;
    string? VALUE_STRING?;
    string? COMBO_DATA_ABSENT_REASON?;
    string? CODE?;
    string? STATUS?;
    string? CATEGORY?;
    string? COMBO_VALUE_QUANTITY?;
    string? VALUE_CONCEPT?;
    string? METHOD?;
    string? IDENTIFIER?;
    string? COMPONENT_DATA_ABSENT_REASON?;
    string? DATA_ABSENT_REASON?;
    string? COMPONENT_VALUE_QUANTITY?;
    string? COMPONENT_VALUE_CONCEPT?;
    string? COMBO_VALUE_CONCEPT?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EffectEvidenceSynthesisTable record {|
    readonly string EFFECTEVIDENCESYNTHESISTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    time:Date? EFFECTIVE;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EffectEvidenceSynthesisTableOptionalized record {|
    string EFFECTEVIDENCESYNTHESISTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EffectEvidenceSynthesisTableTargetType typedesc<EffectEvidenceSynthesisTableOptionalized>;

public type EffectEvidenceSynthesisTableInsert EffectEvidenceSynthesisTable;

public type EffectEvidenceSynthesisTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type OperationDefinitionTable record {|
    readonly string OPERATIONDEFINITIONTABLE_ID;
    string? SYSTEM;
    string? PUBLISHER;
    string? JURISDICTION;
    string? INSTANCE;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? CODE;
    string? STATUS;
    string? DESCRIPTION;
    string? KIND;
    string? VERSION;
    string? TITLE;
    string? CONTEXT_QUANTITY;
    string? TYPE;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type OperationDefinitionTableOptionalized record {|
    string OPERATIONDEFINITIONTABLE_ID?;
    string? SYSTEM?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? INSTANCE?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? KIND?;
    string? VERSION?;
    string? TITLE?;
    string? CONTEXT_QUANTITY?;
    string? TYPE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type OperationDefinitionTableTargetType typedesc<OperationDefinitionTableOptionalized>;

public type OperationDefinitionTableInsert OperationDefinitionTable;

public type OperationDefinitionTableUpdate record {|
    string? SYSTEM?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? INSTANCE?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? KIND?;
    string? VERSION?;
    string? TITLE?;
    string? CONTEXT_QUANTITY?;
    string? TYPE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MeasureReportTable record {|
    readonly string MEASUREREPORTTABLE_ID;
    time:Date? DATE;
    string? STATUS;
    time:Date? PERIOD;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MeasureReportTableOptionalized record {|
    string MEASUREREPORTTABLE_ID?;
    time:Date? DATE?;
    string? STATUS?;
    time:Date? PERIOD?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MeasureReportTableTargetType typedesc<MeasureReportTableOptionalized>;

public type MeasureReportTableInsert MeasureReportTable;

public type MeasureReportTableUpdate record {|
    time:Date? DATE?;
    string? STATUS?;
    time:Date? PERIOD?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SupplyDeliveryTable record {|
    readonly string SUPPLYDELIVERYTABLE_ID;
    string? STATUS;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SupplyDeliveryTableOptionalized record {|
    string SUPPLYDELIVERYTABLE_ID?;
    string? STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SupplyDeliveryTableTargetType typedesc<SupplyDeliveryTableOptionalized>;

public type SupplyDeliveryTableInsert SupplyDeliveryTable;

public type SupplyDeliveryTableUpdate record {|
    string? STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ServiceRequestTable record {|
    readonly string SERVICEREQUESTTABLE_ID;
    string? REQUISITION;
    string? CODE;
    string? STATUS;
    time:Date? OCCURRENCE;
    string? INSTANTIATES_URI;
    string? PERFORMER_TYPE;
    string? CATEGORY;
    string? INTENT;
    time:Date? AUTHORED;
    string? PRIORITY;
    string? IDENTIFIER;
    string? BODY_SITE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ServiceRequestTableOptionalized record {|
    string SERVICEREQUESTTABLE_ID?;
    string? REQUISITION?;
    string? CODE?;
    string? STATUS?;
    time:Date? OCCURRENCE?;
    string? INSTANTIATES_URI?;
    string? PERFORMER_TYPE?;
    string? CATEGORY?;
    string? INTENT?;
    time:Date? AUTHORED?;
    string? PRIORITY?;
    string? IDENTIFIER?;
    string? BODY_SITE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ServiceRequestTableTargetType typedesc<ServiceRequestTableOptionalized>;

public type ServiceRequestTableInsert ServiceRequestTable;

public type ServiceRequestTableUpdate record {|
    string? REQUISITION?;
    string? CODE?;
    string? STATUS?;
    time:Date? OCCURRENCE?;
    string? INSTANTIATES_URI?;
    string? PERFORMER_TYPE?;
    string? CATEGORY?;
    string? INTENT?;
    time:Date? AUTHORED?;
    string? PRIORITY?;
    string? IDENTIFIER?;
    string? BODY_SITE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type BasicTable record {|
    readonly string BASICTABLE_ID;
    string? CODE;
    time:Date? CREATED;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type BasicTableOptionalized record {|
    string BASICTABLE_ID?;
    string? CODE?;
    time:Date? CREATED?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type BasicTableTargetType typedesc<BasicTableOptionalized>;

public type BasicTableInsert BasicTable;

public type BasicTableUpdate record {|
    string? CODE?;
    time:Date? CREATED?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SubscriptionTable record {|
    readonly string SUBSCRIPTIONTABLE_ID;
    string? CRITERIA;
    string? CONTACT;
    string? STATUS;
    string? PAYLOAD;
    string? TYPE;
    string? URL;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SubscriptionTableOptionalized record {|
    string SUBSCRIPTIONTABLE_ID?;
    string? CRITERIA?;
    string? CONTACT?;
    string? STATUS?;
    string? PAYLOAD?;
    string? TYPE?;
    string? URL?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SubscriptionTableTargetType typedesc<SubscriptionTableOptionalized>;

public type SubscriptionTableInsert SubscriptionTable;

public type SubscriptionTableUpdate record {|
    string? CRITERIA?;
    string? CONTACT?;
    string? STATUS?;
    string? PAYLOAD?;
    string? TYPE?;
    string? URL?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EnrollmentResponseTable record {|
    readonly string ENROLLMENTRESPONSETABLE_ID;
    string? STATUS;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EnrollmentResponseTableOptionalized record {|
    string ENROLLMENTRESPONSETABLE_ID?;
    string? STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EnrollmentResponseTableTargetType typedesc<EnrollmentResponseTableOptionalized>;

public type EnrollmentResponseTableInsert EnrollmentResponseTable;

public type EnrollmentResponseTableUpdate record {|
    string? STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DeviceRequestTable record {|
    readonly string DEVICEREQUESTTABLE_ID;
    string? CODE;
    time:Date? EVENT_DATE;
    string? STATUS;
    string? INSTANTIATES_URI;
    time:Date? AUTHORED_ON;
    string? INTENT;
    string? GROUP_IDENTIFIER;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DeviceRequestTableOptionalized record {|
    string DEVICEREQUESTTABLE_ID?;
    string? CODE?;
    time:Date? EVENT_DATE?;
    string? STATUS?;
    string? INSTANTIATES_URI?;
    time:Date? AUTHORED_ON?;
    string? INTENT?;
    string? GROUP_IDENTIFIER?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DeviceRequestTableTargetType typedesc<DeviceRequestTableOptionalized>;

public type DeviceRequestTableInsert DeviceRequestTable;

public type DeviceRequestTableUpdate record {|
    string? CODE?;
    time:Date? EVENT_DATE?;
    string? STATUS?;
    string? INSTANTIATES_URI?;
    time:Date? AUTHORED_ON?;
    string? INTENT?;
    string? GROUP_IDENTIFIER?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type AppointmentTable record {|
    readonly string APPOINTMENTTABLE_ID;
    time:Date? DATE;
    string? SERVICE_CATEGORY;
    string? PART_STATUS;
    string? STATUS;
    string? APPOINTMENT_TYPE;
    string? REASON_CODE;
    string? SPECIALTY;
    string? IDENTIFIER;
    string? SERVICE_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type AppointmentTableOptionalized record {|
    string APPOINTMENTTABLE_ID?;
    time:Date? DATE?;
    string? SERVICE_CATEGORY?;
    string? PART_STATUS?;
    string? STATUS?;
    string? APPOINTMENT_TYPE?;
    string? REASON_CODE?;
    string? SPECIALTY?;
    string? IDENTIFIER?;
    string? SERVICE_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type AppointmentTableTargetType typedesc<AppointmentTableOptionalized>;

public type AppointmentTableInsert AppointmentTable;

public type AppointmentTableUpdate record {|
    time:Date? DATE?;
    string? SERVICE_CATEGORY?;
    string? PART_STATUS?;
    string? STATUS?;
    string? APPOINTMENT_TYPE?;
    string? REASON_CODE?;
    string? SPECIALTY?;
    string? IDENTIFIER?;
    string? SERVICE_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type NamingSystemTable record {|
    readonly string NAMINGSYSTEMTABLE_ID;
    string? PUBLISHER;
    string? RESPONSIBLE;
    string? CONTACT;
    string? JURISDICTION;
    string? VALUE;
    string? ID_TYPE;
    string? CONTEXT;
    string? TELECOM;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    time:Date? PERIOD;
    string? KIND;
    string? CONTEXT_QUANTITY;
    string? TYPE;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type NamingSystemTableOptionalized record {|
    string NAMINGSYSTEMTABLE_ID?;
    string? PUBLISHER?;
    string? RESPONSIBLE?;
    string? CONTACT?;
    string? JURISDICTION?;
    string? VALUE?;
    string? ID_TYPE?;
    string? CONTEXT?;
    string? TELECOM?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    time:Date? PERIOD?;
    string? KIND?;
    string? CONTEXT_QUANTITY?;
    string? TYPE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type NamingSystemTableTargetType typedesc<NamingSystemTableOptionalized>;

public type NamingSystemTableInsert NamingSystemTable;

public type NamingSystemTableUpdate record {|
    string? PUBLISHER?;
    string? RESPONSIBLE?;
    string? CONTACT?;
    string? JURISDICTION?;
    string? VALUE?;
    string? ID_TYPE?;
    string? CONTEXT?;
    string? TELECOM?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    time:Date? PERIOD?;
    string? KIND?;
    string? CONTEXT_QUANTITY?;
    string? TYPE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type StructureDefinitionTable record {|
    readonly string STRUCTUREDEFINITIONTABLE_ID;
    string? PATH;
    string? DERIVATION;
    string? PUBLISHER;
    string? JURISDICTION;
    string? BASE_PATH;
    string? EXPERIMENTAL;
    string? KEYWORD;
    string? CONTEXT;
    string? ABSTRACT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? KIND;
    string? VERSION;
    string? EXT_CONTEXT;
    string? TITLE;
    string? CONTEXT_QUANTITY;
    string? IDENTIFIER;
    string? TYPE;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type StructureDefinitionTableOptionalized record {|
    string STRUCTUREDEFINITIONTABLE_ID?;
    string? PATH?;
    string? DERIVATION?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? BASE_PATH?;
    string? EXPERIMENTAL?;
    string? KEYWORD?;
    string? CONTEXT?;
    string? ABSTRACT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? KIND?;
    string? VERSION?;
    string? EXT_CONTEXT?;
    string? TITLE?;
    string? CONTEXT_QUANTITY?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type StructureDefinitionTableTargetType typedesc<StructureDefinitionTableOptionalized>;

public type StructureDefinitionTableInsert StructureDefinitionTable;

public type StructureDefinitionTableUpdate record {|
    string? PATH?;
    string? DERIVATION?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? BASE_PATH?;
    string? EXPERIMENTAL?;
    string? KEYWORD?;
    string? CONTEXT?;
    string? ABSTRACT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? KIND?;
    string? VERSION?;
    string? EXT_CONTEXT?;
    string? TITLE?;
    string? CONTEXT_QUANTITY?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ClinicalImpressionTable record {|
    readonly string CLINICALIMPRESSIONTABLE_ID;
    time:Date? DATE;
    string? STATUS;
    string? FINDING_CODE;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ClinicalImpressionTableOptionalized record {|
    string CLINICALIMPRESSIONTABLE_ID?;
    time:Date? DATE?;
    string? STATUS?;
    string? FINDING_CODE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ClinicalImpressionTableTargetType typedesc<ClinicalImpressionTableOptionalized>;

public type ClinicalImpressionTableInsert ClinicalImpressionTable;

public type ClinicalImpressionTableUpdate record {|
    time:Date? DATE?;
    string? STATUS?;
    string? FINDING_CODE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CommunicationTable record {|
    readonly string COMMUNICATIONTABLE_ID;
    time:Date? RECEIVED;
    string? STATUS;
    string? MEDIUM;
    string? INSTANTIATES_URI;
    string? CATEGORY;
    string? IDENTIFIER;
    time:Date? SENT;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CommunicationTableOptionalized record {|
    string COMMUNICATIONTABLE_ID?;
    time:Date? RECEIVED?;
    string? STATUS?;
    string? MEDIUM?;
    string? INSTANTIATES_URI?;
    string? CATEGORY?;
    string? IDENTIFIER?;
    time:Date? SENT?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CommunicationTableTargetType typedesc<CommunicationTableOptionalized>;

public type CommunicationTableInsert CommunicationTable;

public type CommunicationTableUpdate record {|
    time:Date? RECEIVED?;
    string? STATUS?;
    string? MEDIUM?;
    string? INSTANTIATES_URI?;
    string? CATEGORY?;
    string? IDENTIFIER?;
    time:Date? SENT?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type OrganizationTable record {|
    readonly string ORGANIZATIONTABLE_ID;
    string? ADDRESS_COUNTRY;
    string? ADDRESS_POSTALCODE;
    string? ADDRESS_USE;
    string? ACTIVE;
    string? ADDRESS;
    string? PHONETIC;
    string? IDENTIFIER;
    string? ADDRESS_CITY;
    string? TYPE;
    string? ADDRESS_STATE;
    string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type OrganizationTableOptionalized record {|
    string ORGANIZATIONTABLE_ID?;
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? ADDRESS_USE?;
    string? ACTIVE?;
    string? ADDRESS?;
    string? PHONETIC?;
    string? IDENTIFIER?;
    string? ADDRESS_CITY?;
    string? TYPE?;
    string? ADDRESS_STATE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type OrganizationTableTargetType typedesc<OrganizationTableOptionalized>;

public type OrganizationTableInsert OrganizationTable;

public type OrganizationTableUpdate record {|
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? ADDRESS_USE?;
    string? ACTIVE?;
    string? ADDRESS?;
    string? PHONETIC?;
    string? IDENTIFIER?;
    string? ADDRESS_CITY?;
    string? TYPE?;
    string? ADDRESS_STATE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CoverageEligibilityResponseTable record {|
    readonly string COVERAGEELIGIBILITYRESPONSETABLE_ID;
    time:Date? CREATED;
    string? STATUS;
    string? OUTCOME;
    string? IDENTIFIER;
    string? DISPOSITION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CoverageEligibilityResponseTableOptionalized record {|
    string COVERAGEELIGIBILITYRESPONSETABLE_ID?;
    time:Date? CREATED?;
    string? STATUS?;
    string? OUTCOME?;
    string? IDENTIFIER?;
    string? DISPOSITION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CoverageEligibilityResponseTableTargetType typedesc<CoverageEligibilityResponseTableOptionalized>;

public type CoverageEligibilityResponseTableInsert CoverageEligibilityResponseTable;

public type CoverageEligibilityResponseTableUpdate record {|
    time:Date? CREATED?;
    string? STATUS?;
    string? OUTCOME?;
    string? IDENTIFIER?;
    string? DISPOSITION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ResearchStudyTable record {|
    readonly string RESEARCHSTUDYTABLE_ID;
    string? LOCATION;
    time:Date? DATE;
    string? STATUS;
    string? CATEGORY;
    string? FOCUS;
    string? KEYWORD;
    string? TITLE;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ResearchStudyTableOptionalized record {|
    string RESEARCHSTUDYTABLE_ID?;
    string? LOCATION?;
    time:Date? DATE?;
    string? STATUS?;
    string? CATEGORY?;
    string? FOCUS?;
    string? KEYWORD?;
    string? TITLE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ResearchStudyTableTargetType typedesc<ResearchStudyTableOptionalized>;

public type ResearchStudyTableInsert ResearchStudyTable;

public type ResearchStudyTableUpdate record {|
    string? LOCATION?;
    time:Date? DATE?;
    string? STATUS?;
    string? CATEGORY?;
    string? FOCUS?;
    string? KEYWORD?;
    string? TITLE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type BundleTable record {|
    readonly string BUNDLETABLE_ID;
    time:Date? TIMESTAMP;
    string? IDENTIFIER;
    string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type BundleTableOptionalized record {|
    string BUNDLETABLE_ID?;
    time:Date? TIMESTAMP?;
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type BundleTableTargetType typedesc<BundleTableOptionalized>;

public type BundleTableInsert BundleTable;

public type BundleTableUpdate record {|
    time:Date? TIMESTAMP?;
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EncounterTable record {|
    readonly string ENCOUNTERTABLE_ID;
    string? PARTICIPANT_TYPE;
    time:Date? DATE;
    string? STATUS;
    string? LENGTH;
    string? REASON_CODE;
    string? SPECIAL_ARRANGEMENT;
    string? IDENTIFIER;
    string? CLASS;
    string? TYPE;
    time:Date? LOCATION_PERIOD;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EncounterTableOptionalized record {|
    string ENCOUNTERTABLE_ID?;
    string? PARTICIPANT_TYPE?;
    time:Date? DATE?;
    string? STATUS?;
    string? LENGTH?;
    string? REASON_CODE?;
    string? SPECIAL_ARRANGEMENT?;
    string? IDENTIFIER?;
    string? CLASS?;
    string? TYPE?;
    time:Date? LOCATION_PERIOD?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EncounterTableTargetType typedesc<EncounterTableOptionalized>;

public type EncounterTableInsert EncounterTable;

public type EncounterTableUpdate record {|
    string? PARTICIPANT_TYPE?;
    time:Date? DATE?;
    string? STATUS?;
    string? LENGTH?;
    string? REASON_CODE?;
    string? SPECIAL_ARRANGEMENT?;
    string? IDENTIFIER?;
    string? CLASS?;
    string? TYPE?;
    time:Date? LOCATION_PERIOD?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type RiskAssessmentTable record {|
    readonly string RISKASSESSMENTTABLE_ID;
    time:Date? DATE;
    int? PROBABILITY;
    string? METHOD;
    string? RISK;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type RiskAssessmentTableOptionalized record {|
    string RISKASSESSMENTTABLE_ID?;
    time:Date? DATE?;
    int? PROBABILITY?;
    string? METHOD?;
    string? RISK?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type RiskAssessmentTableTargetType typedesc<RiskAssessmentTableOptionalized>;

public type RiskAssessmentTableInsert RiskAssessmentTable;

public type RiskAssessmentTableUpdate record {|
    time:Date? DATE?;
    int? PROBABILITY?;
    string? METHOD?;
    string? RISK?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ListTable record {|
    readonly string LISTTABLE_ID;
    time:Date? DATE;
    string? NOTES;
    string? EMPTY_REASON;
    string? CODE;
    string? STATUS;
    string? TITLE;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ListTableOptionalized record {|
    string LISTTABLE_ID?;
    time:Date? DATE?;
    string? NOTES?;
    string? EMPTY_REASON?;
    string? CODE?;
    string? STATUS?;
    string? TITLE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ListTableTargetType typedesc<ListTableOptionalized>;

public type ListTableInsert ListTable;

public type ListTableUpdate record {|
    time:Date? DATE?;
    string? NOTES?;
    string? EMPTY_REASON?;
    string? CODE?;
    string? STATUS?;
    string? TITLE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type OrganizationAffiliationTable record {|
    readonly string ORGANIZATIONAFFILIATIONTABLE_ID;
    string? ROLE;
    time:Date? DATE;
    string? ACTIVE;
    string? PHONE;
    string? SPECIALTY;
    string? IDENTIFIER;
    string? EMAIL;
    string? TELECOM;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type OrganizationAffiliationTableOptionalized record {|
    string ORGANIZATIONAFFILIATIONTABLE_ID?;
    string? ROLE?;
    time:Date? DATE?;
    string? ACTIVE?;
    string? PHONE?;
    string? SPECIALTY?;
    string? IDENTIFIER?;
    string? EMAIL?;
    string? TELECOM?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type OrganizationAffiliationTableTargetType typedesc<OrganizationAffiliationTableOptionalized>;

public type OrganizationAffiliationTableInsert OrganizationAffiliationTable;

public type OrganizationAffiliationTableUpdate record {|
    string? ROLE?;
    time:Date? DATE?;
    string? ACTIVE?;
    string? PHONE?;
    string? SPECIALTY?;
    string? IDENTIFIER?;
    string? EMAIL?;
    string? TELECOM?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ChargeItemTable record {|
    readonly string CHARGEITEMTABLE_ID;
    string? CODE;
    int? FACTOR_OVERRIDE;
    string? QUANTITY;
    time:Date? OCCURRENCE;
    string? PRICE_OVERRIDE;
    string? IDENTIFIER;
    time:Date? ENTERED_DATE;
    string? PERFORMER_FUNCTION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ChargeItemTableOptionalized record {|
    string CHARGEITEMTABLE_ID?;
    string? CODE?;
    int? FACTOR_OVERRIDE?;
    string? QUANTITY?;
    time:Date? OCCURRENCE?;
    string? PRICE_OVERRIDE?;
    string? IDENTIFIER?;
    time:Date? ENTERED_DATE?;
    string? PERFORMER_FUNCTION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ChargeItemTableTargetType typedesc<ChargeItemTableOptionalized>;

public type ChargeItemTableInsert ChargeItemTable;

public type ChargeItemTableUpdate record {|
    string? CODE?;
    int? FACTOR_OVERRIDE?;
    string? QUANTITY?;
    time:Date? OCCURRENCE?;
    string? PRICE_OVERRIDE?;
    string? IDENTIFIER?;
    time:Date? ENTERED_DATE?;
    string? PERFORMER_FUNCTION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicationKnowledgeTable record {|
    readonly string MEDICATIONKNOWLEDGETABLE_ID;
    string? CODE;
    string? SOURCE_COST;
    string? STATUS;
    string? MONITORING_PROGRAM_NAME;
    string? CLASSIFICATION_TYPE;
    string? CLASSIFICATION;
    string? DOSEFORM;
    string? MONOGRAPH_TYPE;
    string? MONITORING_PROGRAM_TYPE;
    string? INGREDIENT_CODE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicationKnowledgeTableOptionalized record {|
    string MEDICATIONKNOWLEDGETABLE_ID?;
    string? CODE?;
    string? SOURCE_COST?;
    string? STATUS?;
    string? MONITORING_PROGRAM_NAME?;
    string? CLASSIFICATION_TYPE?;
    string? CLASSIFICATION?;
    string? DOSEFORM?;
    string? MONOGRAPH_TYPE?;
    string? MONITORING_PROGRAM_TYPE?;
    string? INGREDIENT_CODE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicationKnowledgeTableTargetType typedesc<MedicationKnowledgeTableOptionalized>;

public type MedicationKnowledgeTableInsert MedicationKnowledgeTable;

public type MedicationKnowledgeTableUpdate record {|
    string? CODE?;
    string? SOURCE_COST?;
    string? STATUS?;
    string? MONITORING_PROGRAM_NAME?;
    string? CLASSIFICATION_TYPE?;
    string? CLASSIFICATION?;
    string? DOSEFORM?;
    string? MONOGRAPH_TYPE?;
    string? MONITORING_PROGRAM_TYPE?;
    string? INGREDIENT_CODE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PlanDefinitionTable record {|
    readonly string PLANDEFINITIONTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    time:Date? EFFECTIVE;
    string? TOPIC;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? TYPE;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PlanDefinitionTableOptionalized record {|
    string PLANDEFINITIONTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? TYPE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PlanDefinitionTableTargetType typedesc<PlanDefinitionTableOptionalized>;

public type PlanDefinitionTableInsert PlanDefinitionTable;

public type PlanDefinitionTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? TYPE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CarePlanTable record {|
    readonly string CAREPLANTABLE_ID;
    time:Date? DATE;
    string? STATUS;
    string? INSTANTIATES_URI;
    string? CATEGORY;
    string? INTENT;
    time:Date? ACTIVITY_DATE;
    string? ACTIVITY_CODE;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CarePlanTableOptionalized record {|
    string CAREPLANTABLE_ID?;
    time:Date? DATE?;
    string? STATUS?;
    string? INSTANTIATES_URI?;
    string? CATEGORY?;
    string? INTENT?;
    time:Date? ACTIVITY_DATE?;
    string? ACTIVITY_CODE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CarePlanTableTargetType typedesc<CarePlanTableOptionalized>;

public type CarePlanTableInsert CarePlanTable;

public type CarePlanTableUpdate record {|
    time:Date? DATE?;
    string? STATUS?;
    string? INSTANTIATES_URI?;
    string? CATEGORY?;
    string? INTENT?;
    time:Date? ACTIVITY_DATE?;
    string? ACTIVITY_CODE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type VisionPrescriptionTable record {|
    readonly string VISIONPRESCRIPTIONTABLE_ID;
    string? STATUS;
    string? IDENTIFIER;
    time:Date? DATEWRITTEN;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type VisionPrescriptionTableOptionalized record {|
    string VISIONPRESCRIPTIONTABLE_ID?;
    string? STATUS?;
    string? IDENTIFIER?;
    time:Date? DATEWRITTEN?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type VisionPrescriptionTableTargetType typedesc<VisionPrescriptionTableOptionalized>;

public type VisionPrescriptionTableInsert VisionPrescriptionTable;

public type VisionPrescriptionTableUpdate record {|
    string? STATUS?;
    string? IDENTIFIER?;
    time:Date? DATEWRITTEN?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EpisodeOfCareTable record {|
    readonly string EPISODEOFCARETABLE_ID;
    time:Date? DATE;
    string? STATUS;
    string? IDENTIFIER;
    string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EpisodeOfCareTableOptionalized record {|
    string EPISODEOFCARETABLE_ID?;
    time:Date? DATE?;
    string? STATUS?;
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EpisodeOfCareTableTargetType typedesc<EpisodeOfCareTableOptionalized>;

public type EpisodeOfCareTableInsert EpisodeOfCareTable;

public type EpisodeOfCareTableUpdate record {|
    time:Date? DATE?;
    string? STATUS?;
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CareTeamTable record {|
    readonly string CARETEAMTABLE_ID;
    time:Date? DATE;
    string? STATUS;
    string? CATEGORY;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CareTeamTableOptionalized record {|
    string CARETEAMTABLE_ID?;
    time:Date? DATE?;
    string? STATUS?;
    string? CATEGORY?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CareTeamTableTargetType typedesc<CareTeamTableOptionalized>;

public type CareTeamTableInsert CareTeamTable;

public type CareTeamTableUpdate record {|
    time:Date? DATE?;
    string? STATUS?;
    string? CATEGORY?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicationAdministrationTable record {|
    readonly string MEDICATIONADMINISTRATIONTABLE_ID;
    string? CODE;
    string? STATUS;
    string? REASON_NOT_GIVEN;
    time:Date? EFFECTIVE_TIME;
    string? REASON_GIVEN;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicationAdministrationTableOptionalized record {|
    string MEDICATIONADMINISTRATIONTABLE_ID?;
    string? CODE?;
    string? STATUS?;
    string? REASON_NOT_GIVEN?;
    time:Date? EFFECTIVE_TIME?;
    string? REASON_GIVEN?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicationAdministrationTableTargetType typedesc<MedicationAdministrationTableOptionalized>;

public type MedicationAdministrationTableInsert MedicationAdministrationTable;

public type MedicationAdministrationTableUpdate record {|
    string? CODE?;
    string? STATUS?;
    string? REASON_NOT_GIVEN?;
    time:Date? EFFECTIVE_TIME?;
    string? REASON_GIVEN?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ConsentTable record {|
    readonly string CONSENTTABLE_ID;
    time:Date? DATE;
    string? SECURITY_LABEL;
    string? STATUS;
    string? ACTION;
    string? SCOPE;
    string? CATEGORY;
    time:Date? PERIOD;
    string? PURPOSE;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ConsentTableOptionalized record {|
    string CONSENTTABLE_ID?;
    time:Date? DATE?;
    string? SECURITY_LABEL?;
    string? STATUS?;
    string? ACTION?;
    string? SCOPE?;
    string? CATEGORY?;
    time:Date? PERIOD?;
    string? PURPOSE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ConsentTableTargetType typedesc<ConsentTableOptionalized>;

public type ConsentTableInsert ConsentTable;

public type ConsentTableUpdate record {|
    time:Date? DATE?;
    string? SECURITY_LABEL?;
    string? STATUS?;
    string? ACTION?;
    string? SCOPE?;
    string? CATEGORY?;
    time:Date? PERIOD?;
    string? PURPOSE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DetectedIssueTable record {|
    readonly string DETECTEDISSUETABLE_ID;
    string? CODE;
    time:Date? IDENTIFIED;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DetectedIssueTableOptionalized record {|
    string DETECTEDISSUETABLE_ID?;
    string? CODE?;
    time:Date? IDENTIFIED?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DetectedIssueTableTargetType typedesc<DetectedIssueTableOptionalized>;

public type DetectedIssueTableInsert DetectedIssueTable;

public type DetectedIssueTableUpdate record {|
    string? CODE?;
    time:Date? IDENTIFIED?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SubstanceSpecificationTable record {|
    readonly string SUBSTANCESPECIFICATIONTABLE_ID;
    string? CODE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SubstanceSpecificationTableOptionalized record {|
    string SUBSTANCESPECIFICATIONTABLE_ID?;
    string? CODE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SubstanceSpecificationTableTargetType typedesc<SubstanceSpecificationTableOptionalized>;

public type SubstanceSpecificationTableInsert SubstanceSpecificationTable;

public type SubstanceSpecificationTableUpdate record {|
    string? CODE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type AllergyIntoleranceTable record {|
    readonly string ALLERGYINTOLERANCETABLE_ID;
    string? ROUTE;
    time:Date? LAST_DATE;
    string? MANIFESTATION;
    string? CLINICAL_STATUS;
    string? VERIFICATION_STATUS;
    time:Date? DATE;
    string? CODE;
    string? CRITICALITY;
    string? CATEGORY;
    string? IDENTIFIER;
    string? TYPE;
    string? SEVERITY;
    time:Date? ONSET;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type AllergyIntoleranceTableOptionalized record {|
    string ALLERGYINTOLERANCETABLE_ID?;
    string? ROUTE?;
    time:Date? LAST_DATE?;
    string? MANIFESTATION?;
    string? CLINICAL_STATUS?;
    string? VERIFICATION_STATUS?;
    time:Date? DATE?;
    string? CODE?;
    string? CRITICALITY?;
    string? CATEGORY?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? SEVERITY?;
    time:Date? ONSET?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type AllergyIntoleranceTableTargetType typedesc<AllergyIntoleranceTableOptionalized>;

public type AllergyIntoleranceTableInsert AllergyIntoleranceTable;

public type AllergyIntoleranceTableUpdate record {|
    string? ROUTE?;
    time:Date? LAST_DATE?;
    string? MANIFESTATION?;
    string? CLINICAL_STATUS?;
    string? VERIFICATION_STATUS?;
    time:Date? DATE?;
    string? CODE?;
    string? CRITICALITY?;
    string? CATEGORY?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? SEVERITY?;
    time:Date? ONSET?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductIndicationTable record {|
    readonly string MEDICINALPRODUCTINDICATIONTABLE_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductIndicationTableOptionalized record {|
    string MEDICINALPRODUCTINDICATIONTABLE_ID?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductIndicationTableTargetType typedesc<MedicinalProductIndicationTableOptionalized>;

public type MedicinalProductIndicationTableInsert MedicinalProductIndicationTable;

public type MedicinalProductIndicationTableUpdate record {|
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductPharmaceuticalTable record {|
    readonly string MEDICINALPRODUCTPHARMACEUTICALTABLE_ID;
    string? ROUTE;
    string? IDENTIFIER;
    string? TARGET_SPECIES;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductPharmaceuticalTableOptionalized record {|
    string MEDICINALPRODUCTPHARMACEUTICALTABLE_ID?;
    string? ROUTE?;
    string? IDENTIFIER?;
    string? TARGET_SPECIES?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductPharmaceuticalTableTargetType typedesc<MedicinalProductPharmaceuticalTableOptionalized>;

public type MedicinalProductPharmaceuticalTableInsert MedicinalProductPharmaceuticalTable;

public type MedicinalProductPharmaceuticalTableUpdate record {|
    string? ROUTE?;
    string? IDENTIFIER?;
    string? TARGET_SPECIES?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SlotTable record {|
    readonly string SLOTTABLE_ID;
    string? SERVICE_CATEGORY;
    string? STATUS;
    string? APPOINTMENT_TYPE;
    string? SPECIALTY;
    time:Date? START;
    string? IDENTIFIER;
    string? SERVICE_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SlotTableOptionalized record {|
    string SLOTTABLE_ID?;
    string? SERVICE_CATEGORY?;
    string? STATUS?;
    string? APPOINTMENT_TYPE?;
    string? SPECIALTY?;
    time:Date? START?;
    string? IDENTIFIER?;
    string? SERVICE_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SlotTableTargetType typedesc<SlotTableOptionalized>;

public type SlotTableInsert SlotTable;

public type SlotTableUpdate record {|
    string? SERVICE_CATEGORY?;
    string? STATUS?;
    string? APPOINTMENT_TYPE?;
    string? SPECIALTY?;
    time:Date? START?;
    string? IDENTIFIER?;
    string? SERVICE_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type VerificationResultTable record {|
    readonly string VERIFICATIONRESULTTABLE_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type VerificationResultTableOptionalized record {|
    string VERIFICATIONRESULTTABLE_ID?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type VerificationResultTableTargetType typedesc<VerificationResultTableOptionalized>;

public type VerificationResultTableInsert VerificationResultTable;

public type VerificationResultTableUpdate record {|
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SpecimenTable record {|
    readonly string SPECIMENTABLE_ID;
    time:Date? COLLECTED;
    string? STATUS;
    string? ACCESSION;
    string? CONTAINER;
    string? BODYSITE;
    string? IDENTIFIER;
    string? TYPE;
    string? CONTAINER_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SpecimenTableOptionalized record {|
    string SPECIMENTABLE_ID?;
    time:Date? COLLECTED?;
    string? STATUS?;
    string? ACCESSION?;
    string? CONTAINER?;
    string? BODYSITE?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? CONTAINER_ID?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SpecimenTableTargetType typedesc<SpecimenTableOptionalized>;

public type SpecimenTableInsert SpecimenTable;

public type SpecimenTableUpdate record {|
    time:Date? COLLECTED?;
    string? STATUS?;
    string? ACCESSION?;
    string? CONTAINER?;
    string? BODYSITE?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? CONTAINER_ID?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ResearchSubjectTable record {|
    readonly string RESEARCHSUBJECTTABLE_ID;
    time:Date? DATE;
    string? STATUS;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ResearchSubjectTableOptionalized record {|
    string RESEARCHSUBJECTTABLE_ID?;
    time:Date? DATE?;
    string? STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ResearchSubjectTableTargetType typedesc<ResearchSubjectTableOptionalized>;

public type ResearchSubjectTableInsert ResearchSubjectTable;

public type ResearchSubjectTableUpdate record {|
    time:Date? DATE?;
    string? STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicationTable record {|
    readonly string MEDICATIONTABLE_ID;
    string? CODE;
    string? STATUS;
    time:Date? EXPIRATION_DATE;
    string? FORM;
    string? IDENTIFIER;
    string? LOT_NUMBER;
    string? INGREDIENT_CODE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicationTableOptionalized record {|
    string MEDICATIONTABLE_ID?;
    string? CODE?;
    string? STATUS?;
    time:Date? EXPIRATION_DATE?;
    string? FORM?;
    string? IDENTIFIER?;
    string? LOT_NUMBER?;
    string? INGREDIENT_CODE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicationTableTargetType typedesc<MedicationTableOptionalized>;

public type MedicationTableInsert MedicationTable;

public type MedicationTableUpdate record {|
    string? CODE?;
    string? STATUS?;
    time:Date? EXPIRATION_DATE?;
    string? FORM?;
    string? IDENTIFIER?;
    string? LOT_NUMBER?;
    string? INGREDIENT_CODE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ResearchDefinitionTable record {|
    readonly string RESEARCHDEFINITIONTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    time:Date? EFFECTIVE;
    string? TOPIC;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ResearchDefinitionTableOptionalized record {|
    string RESEARCHDEFINITIONTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ResearchDefinitionTableTargetType typedesc<ResearchDefinitionTableOptionalized>;

public type ResearchDefinitionTableInsert ResearchDefinitionTable;

public type ResearchDefinitionTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type HealthcareServiceTable record {|
    readonly string HEALTHCARESERVICETABLE_ID;
    string? SERVICE_CATEGORY;
    string? CHARACTERISTIC;
    string? ACTIVE;
    string? SPECIALTY;
    string? IDENTIFIER;
    string? SERVICE_TYPE;
    string? PROGRAM;
    string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type HealthcareServiceTableOptionalized record {|
    string HEALTHCARESERVICETABLE_ID?;
    string? SERVICE_CATEGORY?;
    string? CHARACTERISTIC?;
    string? ACTIVE?;
    string? SPECIALTY?;
    string? IDENTIFIER?;
    string? SERVICE_TYPE?;
    string? PROGRAM?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type HealthcareServiceTableTargetType typedesc<HealthcareServiceTableOptionalized>;

public type HealthcareServiceTableInsert HealthcareServiceTable;

public type HealthcareServiceTableUpdate record {|
    string? SERVICE_CATEGORY?;
    string? CHARACTERISTIC?;
    string? ACTIVE?;
    string? SPECIALTY?;
    string? IDENTIFIER?;
    string? SERVICE_TYPE?;
    string? PROGRAM?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PaymentNoticeTable record {|
    readonly string PAYMENTNOTICETABLE_ID;
    time:Date? CREATED;
    string? STATUS;
    string? PAYMENT_STATUS;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PaymentNoticeTableOptionalized record {|
    string PAYMENTNOTICETABLE_ID?;
    time:Date? CREATED?;
    string? STATUS?;
    string? PAYMENT_STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PaymentNoticeTableTargetType typedesc<PaymentNoticeTableOptionalized>;

public type PaymentNoticeTableInsert PaymentNoticeTable;

public type PaymentNoticeTableUpdate record {|
    time:Date? CREATED?;
    string? STATUS?;
    string? PAYMENT_STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ProvenanceTable record {|
    readonly string PROVENANCETABLE_ID;
    time:Date? RECORDED;
    time:Date? WHEN;
    string? AGENT_TYPE;
    string? SIGNATURE_TYPE;
    string? AGENT_ROLE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ProvenanceTableOptionalized record {|
    string PROVENANCETABLE_ID?;
    time:Date? RECORDED?;
    time:Date? WHEN?;
    string? AGENT_TYPE?;
    string? SIGNATURE_TYPE?;
    string? AGENT_ROLE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ProvenanceTableTargetType typedesc<ProvenanceTableOptionalized>;

public type ProvenanceTableInsert ProvenanceTable;

public type ProvenanceTableUpdate record {|
    time:Date? RECORDED?;
    time:Date? WHEN?;
    string? AGENT_TYPE?;
    string? SIGNATURE_TYPE?;
    string? AGENT_ROLE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type GraphDefinitionTable record {|
    readonly string GRAPHDEFINITIONTABLE_ID;
    time:Date? DATE;
    string? PUBLISHER;
    string? STATUS;
    string? JURISDICTION;
    string? DESCRIPTION;
    string? VERSION;
    string? START;
    string? CONTEXT_QUANTITY;
    string? CONTEXT;
    string? URL;
    string? CONTEXT_TYPE;
    string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type GraphDefinitionTableOptionalized record {|
    string GRAPHDEFINITIONTABLE_ID?;
    time:Date? DATE?;
    string? PUBLISHER?;
    string? STATUS?;
    string? JURISDICTION?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? START?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT?;
    string? URL?;
    string? CONTEXT_TYPE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type GraphDefinitionTableTargetType typedesc<GraphDefinitionTableOptionalized>;

public type GraphDefinitionTableInsert GraphDefinitionTable;

public type GraphDefinitionTableUpdate record {|
    time:Date? DATE?;
    string? PUBLISHER?;
    string? STATUS?;
    string? JURISDICTION?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? START?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT?;
    string? URL?;
    string? CONTEXT_TYPE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MediaTable record {|
    readonly string MEDIATABLE_ID;
    string? SITE;
    time:Date? CREATED;
    string? STATUS;
    string? MODALITY;
    string? IDENTIFIER;
    string? TYPE;
    string? VIEW;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MediaTableOptionalized record {|
    string MEDIATABLE_ID?;
    string? SITE?;
    time:Date? CREATED?;
    string? STATUS?;
    string? MODALITY?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? VIEW?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MediaTableTargetType typedesc<MediaTableOptionalized>;

public type MediaTableInsert MediaTable;

public type MediaTableUpdate record {|
    string? SITE?;
    time:Date? CREATED?;
    string? STATUS?;
    string? MODALITY?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? VIEW?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type BodyStructureTable record {|
    readonly string BODYSTRUCTURETABLE_ID;
    string? LOCATION;
    string? IDENTIFIER;
    string? MORPHOLOGY;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type BodyStructureTableOptionalized record {|
    string BODYSTRUCTURETABLE_ID?;
    string? LOCATION?;
    string? IDENTIFIER?;
    string? MORPHOLOGY?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type BodyStructureTableTargetType typedesc<BodyStructureTableOptionalized>;

public type BodyStructureTableInsert BodyStructureTable;

public type BodyStructureTableUpdate record {|
    string? LOCATION?;
    string? IDENTIFIER?;
    string? MORPHOLOGY?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DiagnosticReportTable record {|
    readonly string DIAGNOSTICREPORTTABLE_ID;
    time:Date? DATE;
    time:Date? ISSUED;
    string? CODE;
    string? STATUS;
    string? CATEGORY;
    string? CONCLUSION;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DiagnosticReportTableOptionalized record {|
    string DIAGNOSTICREPORTTABLE_ID?;
    time:Date? DATE?;
    time:Date? ISSUED?;
    string? CODE?;
    string? STATUS?;
    string? CATEGORY?;
    string? CONCLUSION?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DiagnosticReportTableTargetType typedesc<DiagnosticReportTableOptionalized>;

public type DiagnosticReportTableInsert DiagnosticReportTable;

public type DiagnosticReportTableUpdate record {|
    time:Date? DATE?;
    time:Date? ISSUED?;
    string? CODE?;
    string? STATUS?;
    string? CATEGORY?;
    string? CONCLUSION?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type GoalTable record {|
    readonly string GOALTABLE_ID;
    time:Date? TARGET_DATE;
    string? ACHIEVEMENT_STATUS;
    string? CATEGORY;
    string? LIFECYCLE_STATUS;
    time:Date? START_DATE;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type GoalTableOptionalized record {|
    string GOALTABLE_ID?;
    time:Date? TARGET_DATE?;
    string? ACHIEVEMENT_STATUS?;
    string? CATEGORY?;
    string? LIFECYCLE_STATUS?;
    time:Date? START_DATE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type GoalTableTargetType typedesc<GoalTableOptionalized>;

public type GoalTableInsert GoalTable;

public type GoalTableUpdate record {|
    time:Date? TARGET_DATE?;
    string? ACHIEVEMENT_STATUS?;
    string? CATEGORY?;
    string? LIFECYCLE_STATUS?;
    time:Date? START_DATE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CapabilityStatementTable record {|
    readonly string CAPABILITYSTATEMENTTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    string? FORMAT;
    string? MODE;
    string? SECURITY_SERVICE;
    string? CONTEXT;
    string? SOFTWARE;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? FHIRVERSION;
    string? VERSION;
    string? TITLE;
    string? CONTEXT_QUANTITY;
    string? RESOURCE;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CapabilityStatementTableOptionalized record {|
    string CAPABILITYSTATEMENTTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? FORMAT?;
    string? MODE?;
    string? SECURITY_SERVICE?;
    string? CONTEXT?;
    string? SOFTWARE?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? FHIRVERSION?;
    string? VERSION?;
    string? TITLE?;
    string? CONTEXT_QUANTITY?;
    string? RESOURCE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CapabilityStatementTableTargetType typedesc<CapabilityStatementTableOptionalized>;

public type CapabilityStatementTableInsert CapabilityStatementTable;

public type CapabilityStatementTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? FORMAT?;
    string? MODE?;
    string? SECURITY_SERVICE?;
    string? CONTEXT?;
    string? SOFTWARE?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? FHIRVERSION?;
    string? VERSION?;
    string? TITLE?;
    string? CONTEXT_QUANTITY?;
    string? RESOURCE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DeviceUseStatementTable record {|
    readonly string DEVICEUSESTATEMENTTABLE_ID;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DeviceUseStatementTableOptionalized record {|
    string DEVICEUSESTATEMENTTABLE_ID?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DeviceUseStatementTableTargetType typedesc<DeviceUseStatementTableOptionalized>;

public type DeviceUseStatementTableInsert DeviceUseStatementTable;

public type DeviceUseStatementTableUpdate record {|
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ScheduleTable record {|
    readonly string SCHEDULETABLE_ID;
    time:Date? DATE;
    string? SERVICE_CATEGORY;
    string? ACTIVE;
    string? SPECIALTY;
    string? IDENTIFIER;
    string? SERVICE_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ScheduleTableOptionalized record {|
    string SCHEDULETABLE_ID?;
    time:Date? DATE?;
    string? SERVICE_CATEGORY?;
    string? ACTIVE?;
    string? SPECIALTY?;
    string? IDENTIFIER?;
    string? SERVICE_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ScheduleTableTargetType typedesc<ScheduleTableOptionalized>;

public type ScheduleTableInsert ScheduleTable;

public type ScheduleTableUpdate record {|
    time:Date? DATE?;
    string? SERVICE_CATEGORY?;
    string? ACTIVE?;
    string? SPECIALTY?;
    string? IDENTIFIER?;
    string? SERVICE_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductPackagedTable record {|
    readonly string MEDICINALPRODUCTPACKAGEDTABLE_ID;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductPackagedTableOptionalized record {|
    string MEDICINALPRODUCTPACKAGEDTABLE_ID?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductPackagedTableTargetType typedesc<MedicinalProductPackagedTableOptionalized>;

public type MedicinalProductPackagedTableInsert MedicinalProductPackagedTable;

public type MedicinalProductPackagedTableUpdate record {|
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ProcedureTable record {|
    readonly string PROCEDURETABLE_ID;
    time:Date? DATE;
    string? CODE;
    string? STATUS;
    string? INSTANTIATES_URI;
    string? CATEGORY;
    string? REASON_CODE;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ProcedureTableOptionalized record {|
    string PROCEDURETABLE_ID?;
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? INSTANTIATES_URI?;
    string? CATEGORY?;
    string? REASON_CODE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ProcedureTableTargetType typedesc<ProcedureTableOptionalized>;

public type ProcedureTableInsert ProcedureTable;

public type ProcedureTableUpdate record {|
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? INSTANTIATES_URI?;
    string? CATEGORY?;
    string? REASON_CODE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type LibraryTable record {|
    readonly string LIBRARYTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    time:Date? EFFECTIVE;
    string? TOPIC;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? CONTENT_TYPE;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? TYPE;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type LibraryTableOptionalized record {|
    string LIBRARYTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? CONTENT_TYPE?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? TYPE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type LibraryTableTargetType typedesc<LibraryTableOptionalized>;

public type LibraryTableInsert LibraryTable;

public type LibraryTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? CONTENT_TYPE?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? TYPE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CodeSystemTable record {|
    readonly string CODESYSTEMTABLE_ID;
    string? LANGUAGE;
    string? SYSTEM;
    string? PUBLISHER;
    string? JURISDICTION;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? CODE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? CONTENT_MODE;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CodeSystemTableOptionalized record {|
    string CODESYSTEMTABLE_ID?;
    string? LANGUAGE?;
    string? SYSTEM?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? CONTENT_MODE?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CodeSystemTableTargetType typedesc<CodeSystemTableOptionalized>;

public type CodeSystemTableInsert CodeSystemTable;

public type CodeSystemTableUpdate record {|
    string? LANGUAGE?;
    string? SYSTEM?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? CONTENT_MODE?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CommunicationRequestTable record {|
    readonly string COMMUNICATIONREQUESTTABLE_ID;
    string? STATUS;
    string? MEDIUM;
    time:Date? OCCURRENCE;
    string? CATEGORY;
    time:Date? AUTHORED;
    string? PRIORITY;
    string? GROUP_IDENTIFIER;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CommunicationRequestTableOptionalized record {|
    string COMMUNICATIONREQUESTTABLE_ID?;
    string? STATUS?;
    string? MEDIUM?;
    time:Date? OCCURRENCE?;
    string? CATEGORY?;
    time:Date? AUTHORED?;
    string? PRIORITY?;
    string? GROUP_IDENTIFIER?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CommunicationRequestTableTargetType typedesc<CommunicationRequestTableOptionalized>;

public type CommunicationRequestTableInsert CommunicationRequestTable;

public type CommunicationRequestTableUpdate record {|
    string? STATUS?;
    string? MEDIUM?;
    time:Date? OCCURRENCE?;
    string? CATEGORY?;
    time:Date? AUTHORED?;
    string? PRIORITY?;
    string? GROUP_IDENTIFIER?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DocumentReferenceTable record {|
    readonly string DOCUMENTREFERENCETABLE_ID;
    string? LANGUAGE;
    string? LOCATION;
    string? CONTENTTYPE;
    string? RELATION;
    string? FORMAT;
    string? FACILITY;
    string? EVENT;
    time:Date? DATE;
    string? SECURITY_LABEL;
    string? STATUS;
    string? DESCRIPTION;
    string? CATEGORY;
    time:Date? PERIOD;
    string? SETTING;
    string? IDENTIFIER;
    string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DocumentReferenceTableOptionalized record {|
    string DOCUMENTREFERENCETABLE_ID?;
    string? LANGUAGE?;
    string? LOCATION?;
    string? CONTENTTYPE?;
    string? RELATION?;
    string? FORMAT?;
    string? FACILITY?;
    string? EVENT?;
    time:Date? DATE?;
    string? SECURITY_LABEL?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? CATEGORY?;
    time:Date? PERIOD?;
    string? SETTING?;
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DocumentReferenceTableTargetType typedesc<DocumentReferenceTableOptionalized>;

public type DocumentReferenceTableInsert DocumentReferenceTable;

public type DocumentReferenceTableUpdate record {|
    string? LANGUAGE?;
    string? LOCATION?;
    string? CONTENTTYPE?;
    string? RELATION?;
    string? FORMAT?;
    string? FACILITY?;
    string? EVENT?;
    time:Date? DATE?;
    string? SECURITY_LABEL?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? CATEGORY?;
    time:Date? PERIOD?;
    string? SETTING?;
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type RequestGroupTable record {|
    readonly string REQUESTGROUPTABLE_ID;
    string? CODE;
    string? STATUS;
    string? INSTANTIATES_URI;
    string? INTENT;
    time:Date? AUTHORED;
    string? PRIORITY;
    string? GROUP_IDENTIFIER;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type RequestGroupTableOptionalized record {|
    string REQUESTGROUPTABLE_ID?;
    string? CODE?;
    string? STATUS?;
    string? INSTANTIATES_URI?;
    string? INTENT?;
    time:Date? AUTHORED?;
    string? PRIORITY?;
    string? GROUP_IDENTIFIER?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type RequestGroupTableTargetType typedesc<RequestGroupTableOptionalized>;

public type RequestGroupTableInsert RequestGroupTable;

public type RequestGroupTableUpdate record {|
    string? CODE?;
    string? STATUS?;
    string? INSTANTIATES_URI?;
    string? INTENT?;
    time:Date? AUTHORED?;
    string? PRIORITY?;
    string? GROUP_IDENTIFIER?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ClaimTable record {|
    readonly string CLAIMTABLE_ID;
    time:Date? CREATED;
    string? STATUS;
    string? USE;
    string? PRIORITY;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ClaimTableOptionalized record {|
    string CLAIMTABLE_ID?;
    time:Date? CREATED?;
    string? STATUS?;
    string? USE?;
    string? PRIORITY?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ClaimTableTargetType typedesc<ClaimTableOptionalized>;

public type ClaimTableInsert ClaimTable;

public type ClaimTableUpdate record {|
    time:Date? CREATED?;
    string? STATUS?;
    string? USE?;
    string? PRIORITY?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MessageDefinitionTable record {|
    readonly string MESSAGEDEFINITIONTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    string? FOCUS;
    string? CONTEXT;
    string? URL;
    string? EVENT;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? CATEGORY;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MessageDefinitionTableOptionalized record {|
    string MESSAGEDEFINITIONTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? FOCUS?;
    string? CONTEXT?;
    string? URL?;
    string? EVENT?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? CATEGORY?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MessageDefinitionTableTargetType typedesc<MessageDefinitionTableOptionalized>;

public type MessageDefinitionTableInsert MessageDefinitionTable;

public type MessageDefinitionTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? FOCUS?;
    string? CONTEXT?;
    string? URL?;
    string? EVENT?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? CATEGORY?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type RiskEvidenceSynthesisTable record {|
    readonly string RISKEVIDENCESYNTHESISTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    time:Date? EFFECTIVE;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type RiskEvidenceSynthesisTableOptionalized record {|
    string RISKEVIDENCESYNTHESISTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type RiskEvidenceSynthesisTableTargetType typedesc<RiskEvidenceSynthesisTableOptionalized>;

public type RiskEvidenceSynthesisTableInsert RiskEvidenceSynthesisTable;

public type RiskEvidenceSynthesisTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type TaskTable record {|
    readonly string TASKTABLE_ID;
    string? CODE;
    string? STATUS;
    string? BUSINESS_STATUS;
    time:Date? PERIOD;
    time:Date? AUTHORED_ON;
    string? INTENT;
    string? PRIORITY;
    string? GROUP_IDENTIFIER;
    string? IDENTIFIER;
    string? PERFORMER;
    time:Date? MODIFIED;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type TaskTableOptionalized record {|
    string TASKTABLE_ID?;
    string? CODE?;
    string? STATUS?;
    string? BUSINESS_STATUS?;
    time:Date? PERIOD?;
    time:Date? AUTHORED_ON?;
    string? INTENT?;
    string? PRIORITY?;
    string? GROUP_IDENTIFIER?;
    string? IDENTIFIER?;
    string? PERFORMER?;
    time:Date? MODIFIED?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type TaskTableTargetType typedesc<TaskTableOptionalized>;

public type TaskTableInsert TaskTable;

public type TaskTableUpdate record {|
    string? CODE?;
    string? STATUS?;
    string? BUSINESS_STATUS?;
    time:Date? PERIOD?;
    time:Date? AUTHORED_ON?;
    string? INTENT?;
    string? PRIORITY?;
    string? GROUP_IDENTIFIER?;
    string? IDENTIFIER?;
    string? PERFORMER?;
    time:Date? MODIFIED?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ImplementationGuideTable record {|
    readonly string IMPLEMENTATIONGUIDETABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    string? EXPERIMENTAL;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ImplementationGuideTableOptionalized record {|
    string IMPLEMENTATIONGUIDETABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? EXPERIMENTAL?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ImplementationGuideTableTargetType typedesc<ImplementationGuideTableOptionalized>;

public type ImplementationGuideTableInsert ImplementationGuideTable;

public type ImplementationGuideTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? EXPERIMENTAL?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type StructureMapTable record {|
    readonly string STRUCTUREMAPTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type StructureMapTableOptionalized record {|
    string STRUCTUREMAPTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type StructureMapTableTargetType typedesc<StructureMapTableOptionalized>;

public type StructureMapTableInsert StructureMapTable;

public type StructureMapTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductUndesirableEffectTable record {|
    readonly string MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductUndesirableEffectTableOptionalized record {|
    string MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductUndesirableEffectTableTargetType typedesc<MedicinalProductUndesirableEffectTableOptionalized>;

public type MedicinalProductUndesirableEffectTableInsert MedicinalProductUndesirableEffectTable;

public type MedicinalProductUndesirableEffectTableUpdate record {|
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CompartmentDefinitionTable record {|
    readonly string COMPARTMENTDEFINITIONTABLE_ID;
    time:Date? DATE;
    string? PUBLISHER;
    string? CODE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? CONTEXT_QUANTITY;
    string? CONTEXT;
    string? URL;
    string? RESOURCE;
    string? CONTEXT_TYPE;
    string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CompartmentDefinitionTableOptionalized record {|
    string COMPARTMENTDEFINITIONTABLE_ID?;
    time:Date? DATE?;
    string? PUBLISHER?;
    string? CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT?;
    string? URL?;
    string? RESOURCE?;
    string? CONTEXT_TYPE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CompartmentDefinitionTableTargetType typedesc<CompartmentDefinitionTableOptionalized>;

public type CompartmentDefinitionTableInsert CompartmentDefinitionTable;

public type CompartmentDefinitionTableUpdate record {|
    time:Date? DATE?;
    string? PUBLISHER?;
    string? CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT?;
    string? URL?;
    string? RESOURCE?;
    string? CONTEXT_TYPE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EndpointTable record {|
    readonly string ENDPOINTTABLE_ID;
    string? CONNECTION_TYPE;
    string? STATUS;
    string? PAYLOAD_TYPE;
    string? IDENTIFIER;
    string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EndpointTableOptionalized record {|
    string ENDPOINTTABLE_ID?;
    string? CONNECTION_TYPE?;
    string? STATUS?;
    string? PAYLOAD_TYPE?;
    string? IDENTIFIER?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EndpointTableTargetType typedesc<EndpointTableOptionalized>;

public type EndpointTableInsert EndpointTable;

public type EndpointTableUpdate record {|
    string? CONNECTION_TYPE?;
    string? STATUS?;
    string? PAYLOAD_TYPE?;
    string? IDENTIFIER?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type TerminologyCapabilitiesTable record {|
    readonly string TERMINOLOGYCAPABILITIESTABLE_ID;
    time:Date? DATE;
    string? PUBLISHER;
    string? STATUS;
    string? JURISDICTION;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? CONTEXT_QUANTITY;
    string? CONTEXT;
    string? URL;
    string? CONTEXT_TYPE;
    string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type TerminologyCapabilitiesTableOptionalized record {|
    string TERMINOLOGYCAPABILITIESTABLE_ID?;
    time:Date? DATE?;
    string? PUBLISHER?;
    string? STATUS?;
    string? JURISDICTION?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT?;
    string? URL?;
    string? CONTEXT_TYPE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type TerminologyCapabilitiesTableTargetType typedesc<TerminologyCapabilitiesTableOptionalized>;

public type TerminologyCapabilitiesTableInsert TerminologyCapabilitiesTable;

public type TerminologyCapabilitiesTableUpdate record {|
    time:Date? DATE?;
    string? PUBLISHER?;
    string? STATUS?;
    string? JURISDICTION?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT?;
    string? URL?;
    string? CONTEXT_TYPE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ConditionTable record {|
    readonly string CONDITIONTABLE_ID;
    string? CLINICAL_STATUS;
    string? STAGE;
    string? ONSET_AGE;
    string? ONSET_INFO;
    string? EVIDENCE;
    time:Date? ONSET_DATE;
    string? BODY_SITE;
    string? VERIFICATION_STATUS;
    string? CODE;
    string? ABATEMENT_AGE;
    string? ABATEMENT_STRING;
    time:Date? RECORDED_DATE;
    string? CATEGORY;
    time:Date? ABATEMENT_DATE;
    string? IDENTIFIER;
    string? SEVERITY;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ConditionTableOptionalized record {|
    string CONDITIONTABLE_ID?;
    string? CLINICAL_STATUS?;
    string? STAGE?;
    string? ONSET_AGE?;
    string? ONSET_INFO?;
    string? EVIDENCE?;
    time:Date? ONSET_DATE?;
    string? BODY_SITE?;
    string? VERIFICATION_STATUS?;
    string? CODE?;
    string? ABATEMENT_AGE?;
    string? ABATEMENT_STRING?;
    time:Date? RECORDED_DATE?;
    string? CATEGORY?;
    time:Date? ABATEMENT_DATE?;
    string? IDENTIFIER?;
    string? SEVERITY?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ConditionTableTargetType typedesc<ConditionTableOptionalized>;

public type ConditionTableInsert ConditionTable;

public type ConditionTableUpdate record {|
    string? CLINICAL_STATUS?;
    string? STAGE?;
    string? ONSET_AGE?;
    string? ONSET_INFO?;
    string? EVIDENCE?;
    time:Date? ONSET_DATE?;
    string? BODY_SITE?;
    string? VERIFICATION_STATUS?;
    string? CODE?;
    string? ABATEMENT_AGE?;
    string? ABATEMENT_STRING?;
    time:Date? RECORDED_DATE?;
    string? CATEGORY?;
    time:Date? ABATEMENT_DATE?;
    string? IDENTIFIER?;
    string? SEVERITY?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CompositionTable record {|
    readonly string COMPOSITIONTABLE_ID;
    time:Date? DATE;
    string? STATUS;
    string? RELATED_ID;
    string? CATEGORY;
    time:Date? PERIOD;
    string? TITLE;
    string? IDENTIFIER;
    string? TYPE;
    string? CONTEXT;
    string? CONFIDENTIALITY;
    string? SECTION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CompositionTableOptionalized record {|
    string COMPOSITIONTABLE_ID?;
    time:Date? DATE?;
    string? STATUS?;
    string? RELATED_ID?;
    string? CATEGORY?;
    time:Date? PERIOD?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? CONTEXT?;
    string? CONFIDENTIALITY?;
    string? SECTION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CompositionTableTargetType typedesc<CompositionTableOptionalized>;

public type CompositionTableInsert CompositionTable;

public type CompositionTableUpdate record {|
    time:Date? DATE?;
    string? STATUS?;
    string? RELATED_ID?;
    string? CATEGORY?;
    time:Date? PERIOD?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? CONTEXT?;
    string? CONFIDENTIALITY?;
    string? SECTION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ContractTable record {|
    readonly string CONTRACTTABLE_ID;
    time:Date? ISSUED;
    string? STATUS;
    string? IDENTIFIER;
    string? INSTANTIATES;
    string? URL;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ContractTableOptionalized record {|
    string CONTRACTTABLE_ID?;
    time:Date? ISSUED?;
    string? STATUS?;
    string? IDENTIFIER?;
    string? INSTANTIATES?;
    string? URL?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ContractTableTargetType typedesc<ContractTableOptionalized>;

public type ContractTableInsert ContractTable;

public type ContractTableUpdate record {|
    time:Date? ISSUED?;
    string? STATUS?;
    string? IDENTIFIER?;
    string? INSTANTIATES?;
    string? URL?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ImmunizationTable record {|
    readonly string IMMUNIZATIONTABLE_ID;
    time:Date? DATE;
    string? VACCINE_CODE;
    string? STATUS;
    string? STATUS_REASON;
    string? SERIES;
    string? TARGET_DISEASE;
    string? REASON_CODE;
    time:Date? REACTION_DATE;
    string? IDENTIFIER;
    string? LOT_NUMBER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ImmunizationTableOptionalized record {|
    string IMMUNIZATIONTABLE_ID?;
    time:Date? DATE?;
    string? VACCINE_CODE?;
    string? STATUS?;
    string? STATUS_REASON?;
    string? SERIES?;
    string? TARGET_DISEASE?;
    string? REASON_CODE?;
    time:Date? REACTION_DATE?;
    string? IDENTIFIER?;
    string? LOT_NUMBER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ImmunizationTableTargetType typedesc<ImmunizationTableOptionalized>;

public type ImmunizationTableInsert ImmunizationTable;

public type ImmunizationTableUpdate record {|
    time:Date? DATE?;
    string? VACCINE_CODE?;
    string? STATUS?;
    string? STATUS_REASON?;
    string? SERIES?;
    string? TARGET_DISEASE?;
    string? REASON_CODE?;
    time:Date? REACTION_DATE?;
    string? IDENTIFIER?;
    string? LOT_NUMBER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicationDispenseTable record {|
    readonly string MEDICATIONDISPENSETABLE_ID;
    string? CODE;
    string? STATUS;
    time:Date? WHENHANDEDOVER;
    string? IDENTIFIER;
    string? TYPE;
    time:Date? WHENPREPARED;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicationDispenseTableOptionalized record {|
    string MEDICATIONDISPENSETABLE_ID?;
    string? CODE?;
    string? STATUS?;
    time:Date? WHENHANDEDOVER?;
    string? IDENTIFIER?;
    string? TYPE?;
    time:Date? WHENPREPARED?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicationDispenseTableTargetType typedesc<MedicationDispenseTableOptionalized>;

public type MedicationDispenseTableInsert MedicationDispenseTable;

public type MedicationDispenseTableUpdate record {|
    string? CODE?;
    string? STATUS?;
    time:Date? WHENHANDEDOVER?;
    string? IDENTIFIER?;
    string? TYPE?;
    time:Date? WHENPREPARED?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MolecularSequenceTable record {|
    readonly string MOLECULARSEQUENCETABLE_ID;
    string? CHROMOSOME;
    int? VARIANT_START;
    int? WINDOW_START;
    int? VARIANT_END;
    string? REFERENCESEQID;
    string? IDENTIFIER;
    int? WINDOW_END;
    string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MolecularSequenceTableOptionalized record {|
    string MOLECULARSEQUENCETABLE_ID?;
    string? CHROMOSOME?;
    int? VARIANT_START?;
    int? WINDOW_START?;
    int? VARIANT_END?;
    string? REFERENCESEQID?;
    string? IDENTIFIER?;
    int? WINDOW_END?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MolecularSequenceTableTargetType typedesc<MolecularSequenceTableOptionalized>;

public type MolecularSequenceTableInsert MolecularSequenceTable;

public type MolecularSequenceTableUpdate record {|
    string? CHROMOSOME?;
    int? VARIANT_START?;
    int? WINDOW_START?;
    int? VARIANT_END?;
    string? REFERENCESEQID?;
    string? IDENTIFIER?;
    int? WINDOW_END?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SearchParameterTable record {|
    readonly string SEARCHPARAMETERTABLE_ID;
    string? TARGET;
    string? PUBLISHER;
    string? JURISDICTION;
    string? CONTEXT;
    string? URL;
    string? NAME;
    string? BASE;
    time:Date? DATE;
    string? CODE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? CONTEXT_QUANTITY;
    string? TYPE;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SearchParameterTableOptionalized record {|
    string SEARCHPARAMETERTABLE_ID?;
    string? TARGET?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    string? BASE?;
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? CONTEXT_QUANTITY?;
    string? TYPE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SearchParameterTableTargetType typedesc<SearchParameterTableOptionalized>;

public type SearchParameterTableInsert SearchParameterTable;

public type SearchParameterTableUpdate record {|
    string? TARGET?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    string? BASE?;
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? CONTEXT_QUANTITY?;
    string? TYPE?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicationRequestTable record {|
    readonly string MEDICATIONREQUESTTABLE_ID;
    time:Date? DATE;
    string? CODE;
    string? STATUS;
    string? CATEGORY;
    string? INTENT;
    string? PRIORITY;
    string? INTENDED_PERFORMERTYPE;
    string? IDENTIFIER;
    time:Date? AUTHOREDON;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicationRequestTableOptionalized record {|
    string MEDICATIONREQUESTTABLE_ID?;
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? CATEGORY?;
    string? INTENT?;
    string? PRIORITY?;
    string? INTENDED_PERFORMERTYPE?;
    string? IDENTIFIER?;
    time:Date? AUTHOREDON?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicationRequestTableTargetType typedesc<MedicationRequestTableOptionalized>;

public type MedicationRequestTableInsert MedicationRequestTable;

public type MedicationRequestTableUpdate record {|
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? CATEGORY?;
    string? INTENT?;
    string? PRIORITY?;
    string? INTENDED_PERFORMERTYPE?;
    string? IDENTIFIER?;
    time:Date? AUTHOREDON?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EnrollmentRequestTable record {|
    readonly string ENROLLMENTREQUESTTABLE_ID;
    string? STATUS;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EnrollmentRequestTableOptionalized record {|
    string ENROLLMENTREQUESTTABLE_ID?;
    string? STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EnrollmentRequestTableTargetType typedesc<EnrollmentRequestTableOptionalized>;

public type EnrollmentRequestTableInsert EnrollmentRequestTable;

public type EnrollmentRequestTableUpdate record {|
    string? STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SpecimenDefinitionTable record {|
    readonly string SPECIMENDEFINITIONTABLE_ID;
    string? CONTAINER;
    string? IDENTIFIER;
    string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SpecimenDefinitionTableOptionalized record {|
    string SPECIMENDEFINITIONTABLE_ID?;
    string? CONTAINER?;
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SpecimenDefinitionTableTargetType typedesc<SpecimenDefinitionTableOptionalized>;

public type SpecimenDefinitionTableInsert SpecimenDefinitionTable;

public type SpecimenDefinitionTableUpdate record {|
    string? CONTAINER?;
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EventDefinitionTable record {|
    readonly string EVENTDEFINITIONTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    time:Date? EFFECTIVE;
    string? TOPIC;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EventDefinitionTableOptionalized record {|
    string EVENTDEFINITIONTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type EventDefinitionTableTargetType typedesc<EventDefinitionTableOptionalized>;

public type EventDefinitionTableInsert EventDefinitionTable;

public type EventDefinitionTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ImmunizationEvaluationTable record {|
    readonly string IMMUNIZATIONEVALUATIONTABLE_ID;
    time:Date? DATE;
    string? STATUS;
    string? TARGET_DISEASE;
    string? IDENTIFIER;
    string? DOSE_STATUS;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ImmunizationEvaluationTableOptionalized record {|
    string IMMUNIZATIONEVALUATIONTABLE_ID?;
    time:Date? DATE?;
    string? STATUS?;
    string? TARGET_DISEASE?;
    string? IDENTIFIER?;
    string? DOSE_STATUS?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ImmunizationEvaluationTableTargetType typedesc<ImmunizationEvaluationTableOptionalized>;

public type ImmunizationEvaluationTableInsert ImmunizationEvaluationTable;

public type ImmunizationEvaluationTableUpdate record {|
    time:Date? DATE?;
    string? STATUS?;
    string? TARGET_DISEASE?;
    string? IDENTIFIER?;
    string? DOSE_STATUS?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PaymentReconciliationTable record {|
    readonly string PAYMENTRECONCILIATIONTABLE_ID;
    time:Date? CREATED;
    string? STATUS;
    string? OUTCOME;
    string? IDENTIFIER;
    string? DISPOSITION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PaymentReconciliationTableOptionalized record {|
    string PAYMENTRECONCILIATIONTABLE_ID?;
    time:Date? CREATED?;
    string? STATUS?;
    string? OUTCOME?;
    string? IDENTIFIER?;
    string? DISPOSITION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PaymentReconciliationTableTargetType typedesc<PaymentReconciliationTableOptionalized>;

public type PaymentReconciliationTableInsert PaymentReconciliationTable;

public type PaymentReconciliationTableUpdate record {|
    time:Date? CREATED?;
    string? STATUS?;
    string? OUTCOME?;
    string? IDENTIFIER?;
    string? DISPOSITION?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MeasureTable record {|
    readonly string MEASURETABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    time:Date? EFFECTIVE;
    string? TOPIC;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MeasureTableOptionalized record {|
    string MEASURETABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MeasureTableTargetType typedesc<MeasureTableOptionalized>;

public type MeasureTableInsert MeasureTable;

public type MeasureTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ConceptMapTable record {|
    readonly string CONCEPTMAPTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    string? CONTEXT;
    string? URL;
    string? SOURCE_SYSTEM;
    string? NAME;
    time:Date? DATE;
    string? TARGET_SYSTEM;
    string? SOURCE_CODE;
    string? STATUS;
    string? DESCRIPTION;
    string? TARGET_CODE;
    string? PRODUCT;
    string? VERSION;
    string? TITLE;
    string? CONTEXT_QUANTITY;
    string? IDENTIFIER;
    string? DEPENDSON;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ConceptMapTableOptionalized record {|
    string CONCEPTMAPTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? CONTEXT?;
    string? URL?;
    string? SOURCE_SYSTEM?;
    string? NAME?;
    time:Date? DATE?;
    string? TARGET_SYSTEM?;
    string? SOURCE_CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? TARGET_CODE?;
    string? PRODUCT?;
    string? VERSION?;
    string? TITLE?;
    string? CONTEXT_QUANTITY?;
    string? IDENTIFIER?;
    string? DEPENDSON?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ConceptMapTableTargetType typedesc<ConceptMapTableOptionalized>;

public type ConceptMapTableInsert ConceptMapTable;

public type ConceptMapTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? CONTEXT?;
    string? URL?;
    string? SOURCE_SYSTEM?;
    string? NAME?;
    time:Date? DATE?;
    string? TARGET_SYSTEM?;
    string? SOURCE_CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? TARGET_CODE?;
    string? PRODUCT?;
    string? VERSION?;
    string? TITLE?;
    string? CONTEXT_QUANTITY?;
    string? IDENTIFIER?;
    string? DEPENDSON?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ResearchElementDefinitionTable record {|
    readonly string RESEARCHELEMENTDEFINITIONTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    time:Date? EFFECTIVE;
    string? TOPIC;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ResearchElementDefinitionTableOptionalized record {|
    string RESEARCHELEMENTDEFINITIONTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ResearchElementDefinitionTableTargetType typedesc<ResearchElementDefinitionTableOptionalized>;

public type ResearchElementDefinitionTableInsert ResearchElementDefinitionTable;

public type ResearchElementDefinitionTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? TOPIC?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type GuidanceResponseTable record {|
    readonly string GUIDANCERESPONSETABLE_ID;
    string? REQUEST;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type GuidanceResponseTableOptionalized record {|
    string GUIDANCERESPONSETABLE_ID?;
    string? REQUEST?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type GuidanceResponseTableTargetType typedesc<GuidanceResponseTableOptionalized>;

public type GuidanceResponseTableInsert GuidanceResponseTable;

public type GuidanceResponseTableUpdate record {|
    string? REQUEST?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type LinkageTable record {|
    readonly string LINKAGETABLE_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type LinkageTableOptionalized record {|
    string LINKAGETABLE_ID?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type LinkageTableTargetType typedesc<LinkageTableOptionalized>;

public type LinkageTableInsert LinkageTable;

public type LinkageTableUpdate record {|
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductTable record {|
    readonly string MEDICINALPRODUCTTABLE_ID;
    string? NAME_LANGUAGE;
    string? IDENTIFIER;
    string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductTableOptionalized record {|
    string MEDICINALPRODUCTTABLE_ID?;
    string? NAME_LANGUAGE?;
    string? IDENTIFIER?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductTableTargetType typedesc<MedicinalProductTableOptionalized>;

public type MedicinalProductTableInsert MedicinalProductTable;

public type MedicinalProductTableUpdate record {|
    string? NAME_LANGUAGE?;
    string? IDENTIFIER?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DeviceDefinitionTable record {|
    readonly string DEVICEDEFINITIONTABLE_ID;
    string? IDENTIFIER;
    string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DeviceDefinitionTableOptionalized record {|
    string DEVICEDEFINITIONTABLE_ID?;
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type DeviceDefinitionTableTargetType typedesc<DeviceDefinitionTableOptionalized>;

public type DeviceDefinitionTableInsert DeviceDefinitionTable;

public type DeviceDefinitionTableUpdate record {|
    string? IDENTIFIER?;
    string? TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CoverageEligibilityRequestTable record {|
    readonly string COVERAGEELIGIBILITYREQUESTTABLE_ID;
    time:Date? CREATED;
    string? STATUS;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CoverageEligibilityRequestTableOptionalized record {|
    string COVERAGEELIGIBILITYREQUESTTABLE_ID?;
    time:Date? CREATED?;
    string? STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CoverageEligibilityRequestTableTargetType typedesc<CoverageEligibilityRequestTableOptionalized>;

public type CoverageEligibilityRequestTableInsert CoverageEligibilityRequestTable;

public type CoverageEligibilityRequestTableUpdate record {|
    time:Date? CREATED?;
    string? STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PatientTable record {|
    readonly string PATIENTTABLE_ID;
    string? LANGUAGE;
    string? ADDRESS_COUNTRY;
    string? ADDRESS_POSTALCODE;
    string? ACTIVE;
    string? PHONE;
    string? DECEASED;
    time:Date? BIRTHDATE;
    string? ADDRESS_CITY;
    string? EMAIL;
    string? ADDRESS_STATE;
    string? TELECOM;
    string? NAME;
    string? FAMILY;
    string? ADDRESS_USE;
    string? GIVEN;
    string? ADDRESS;
    string? GENDER;
    string? PHONETIC;
    time:Date? DEATH_DATE;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PatientTableOptionalized record {|
    string PATIENTTABLE_ID?;
    string? LANGUAGE?;
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? ACTIVE?;
    string? PHONE?;
    string? DECEASED?;
    time:Date? BIRTHDATE?;
    string? ADDRESS_CITY?;
    string? EMAIL?;
    string? ADDRESS_STATE?;
    string? TELECOM?;
    string? NAME?;
    string? FAMILY?;
    string? ADDRESS_USE?;
    string? GIVEN?;
    string? ADDRESS?;
    string? GENDER?;
    string? PHONETIC?;
    time:Date? DEATH_DATE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type PatientTableTargetType typedesc<PatientTableOptionalized>;

public type PatientTableInsert PatientTable;

public type PatientTableUpdate record {|
    string? LANGUAGE?;
    string? ADDRESS_COUNTRY?;
    string? ADDRESS_POSTALCODE?;
    string? ACTIVE?;
    string? PHONE?;
    string? DECEASED?;
    time:Date? BIRTHDATE?;
    string? ADDRESS_CITY?;
    string? EMAIL?;
    string? ADDRESS_STATE?;
    string? TELECOM?;
    string? NAME?;
    string? FAMILY?;
    string? ADDRESS_USE?;
    string? GIVEN?;
    string? ADDRESS?;
    string? GENDER?;
    string? PHONETIC?;
    time:Date? DEATH_DATE?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CoverageTable record {|
    readonly string COVERAGETABLE_ID;
    string? STATUS;
    string? DEPENDENT;
    string? IDENTIFIER;
    string? CLASS_VALUE;
    string? TYPE;
    string? CLASS_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CoverageTableOptionalized record {|
    string COVERAGETABLE_ID?;
    string? STATUS?;
    string? DEPENDENT?;
    string? IDENTIFIER?;
    string? CLASS_VALUE?;
    string? TYPE?;
    string? CLASS_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type CoverageTableTargetType typedesc<CoverageTableOptionalized>;

public type CoverageTableInsert CoverageTable;

public type CoverageTableUpdate record {|
    string? STATUS?;
    string? DEPENDENT?;
    string? IDENTIFIER?;
    string? CLASS_VALUE?;
    string? TYPE?;
    string? CLASS_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SubstanceTable record {|
    readonly string SUBSTANCETABLE_ID;
    string? CONTAINER_IDENTIFIER;
    string? CODE;
    string? STATUS;
    string? QUANTITY;
    string? CATEGORY;
    time:Date? EXPIRY;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SubstanceTableOptionalized record {|
    string SUBSTANCETABLE_ID?;
    string? CONTAINER_IDENTIFIER?;
    string? CODE?;
    string? STATUS?;
    string? QUANTITY?;
    string? CATEGORY?;
    time:Date? EXPIRY?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type SubstanceTableTargetType typedesc<SubstanceTableOptionalized>;

public type SubstanceTableInsert SubstanceTable;

public type SubstanceTableUpdate record {|
    string? CONTAINER_IDENTIFIER?;
    string? CODE?;
    string? STATUS?;
    string? QUANTITY?;
    string? CATEGORY?;
    time:Date? EXPIRY?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ChargeItemDefinitionTable record {|
    readonly string CHARGEITEMDEFINITIONTABLE_ID;
    string? PUBLISHER;
    string? JURISDICTION;
    time:Date? EFFECTIVE;
    string? CONTEXT;
    string? URL;
    time:Date? DATE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ChargeItemDefinitionTableOptionalized record {|
    string CHARGEITEMDEFINITIONTABLE_ID?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? CONTEXT?;
    string? URL?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type ChargeItemDefinitionTableTargetType typedesc<ChargeItemDefinitionTableOptionalized>;

public type ChargeItemDefinitionTableInsert ChargeItemDefinitionTable;

public type ChargeItemDefinitionTableUpdate record {|
    string? PUBLISHER?;
    string? JURISDICTION?;
    time:Date? EFFECTIVE?;
    string? CONTEXT?;
    string? URL?;
    time:Date? DATE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductInteractionTable record {|
    readonly string MEDICINALPRODUCTINTERACTIONTABLE_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductInteractionTableOptionalized record {|
    string MEDICINALPRODUCTINTERACTIONTABLE_ID?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MedicinalProductInteractionTableTargetType typedesc<MedicinalProductInteractionTableOptionalized>;

public type MedicinalProductInteractionTableInsert MedicinalProductInteractionTable;

public type MedicinalProductInteractionTableUpdate record {|
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type AccountTable record {|
    readonly string ACCOUNTTABLE_ID;
    string? STATUS;
    time:Date? PERIOD;
    string? IDENTIFIER;
    string? TYPE;
    string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type AccountTableOptionalized record {|
    string ACCOUNTTABLE_ID?;
    string? STATUS?;
    time:Date? PERIOD?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type AccountTableTargetType typedesc<AccountTableOptionalized>;

public type AccountTableInsert AccountTable;

public type AccountTableUpdate record {|
    string? STATUS?;
    time:Date? PERIOD?;
    string? IDENTIFIER?;
    string? TYPE?;
    string? NAME?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MessageHeaderTable record {|
    readonly string MESSAGEHEADERTABLE_ID;
    string? CODE;
    string? SOURCE_URI;
    string? DESTINATION;
    string? DESTINATION_URI;
    string? SOURCE;
    string? RESPONSE_ID;
    string? EVENT;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MessageHeaderTableOptionalized record {|
    string MESSAGEHEADERTABLE_ID?;
    string? CODE?;
    string? SOURCE_URI?;
    string? DESTINATION?;
    string? DESTINATION_URI?;
    string? SOURCE?;
    string? RESPONSE_ID?;
    string? EVENT?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type MessageHeaderTableTargetType typedesc<MessageHeaderTableOptionalized>;

public type MessageHeaderTableInsert MessageHeaderTable;

public type MessageHeaderTableUpdate record {|
    string? CODE?;
    string? SOURCE_URI?;
    string? DESTINATION?;
    string? DESTINATION_URI?;
    string? SOURCE?;
    string? RESPONSE_ID?;
    string? EVENT?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type AuditEventTable record {|
    readonly string AUDITEVENTTABLE_ID;
    string? SUBTYPE;
    string? SITE;
    string? OUTCOME;
    string? ENTITY_ROLE;
    string? AGENT_NAME;
    string? ENTITY_TYPE;
    time:Date? DATE;
    string? POLICY;
    string? ALTID;
    string? ACTION;
    string? ADDRESS;
    string? TYPE;
    string? ENTITY_NAME;
    string? AGENT_ROLE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type AuditEventTableOptionalized record {|
    string AUDITEVENTTABLE_ID?;
    string? SUBTYPE?;
    string? SITE?;
    string? OUTCOME?;
    string? ENTITY_ROLE?;
    string? AGENT_NAME?;
    string? ENTITY_TYPE?;
    time:Date? DATE?;
    string? POLICY?;
    string? ALTID?;
    string? ACTION?;
    string? ADDRESS?;
    string? TYPE?;
    string? ENTITY_NAME?;
    string? AGENT_ROLE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type AuditEventTableTargetType typedesc<AuditEventTableOptionalized>;

public type AuditEventTableInsert AuditEventTable;

public type AuditEventTableUpdate record {|
    string? SUBTYPE?;
    string? SITE?;
    string? OUTCOME?;
    string? ENTITY_ROLE?;
    string? AGENT_NAME?;
    string? ENTITY_TYPE?;
    time:Date? DATE?;
    string? POLICY?;
    string? ALTID?;
    string? ACTION?;
    string? ADDRESS?;
    string? TYPE?;
    string? ENTITY_NAME?;
    string? AGENT_ROLE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type NutritionOrderTable record {|
    readonly string NUTRITIONORDERTABLE_ID;
    string? SUPPLEMENT;
    string? STATUS;
    time:Date? DATETIME;
    string? INSTANTIATES_URI;
    string? ADDITIVE;
    string? ORALDIET;
    string? IDENTIFIER;
    string? FORMULA;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type NutritionOrderTableOptionalized record {|
    string NUTRITIONORDERTABLE_ID?;
    string? SUPPLEMENT?;
    string? STATUS?;
    time:Date? DATETIME?;
    string? INSTANTIATES_URI?;
    string? ADDITIVE?;
    string? ORALDIET?;
    string? IDENTIFIER?;
    string? FORMULA?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type NutritionOrderTableTargetType typedesc<NutritionOrderTableOptionalized>;

public type NutritionOrderTableInsert NutritionOrderTable;

public type NutritionOrderTableUpdate record {|
    string? SUPPLEMENT?;
    string? STATUS?;
    time:Date? DATETIME?;
    string? INSTANTIATES_URI?;
    string? ADDITIVE?;
    string? ORALDIET?;
    string? IDENTIFIER?;
    string? FORMULA?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type QuestionnaireTable record {|
    readonly string QUESTIONNAIRETABLE_ID;
    string? DEFINITION;
    string? PUBLISHER;
    string? JURISDICTION;
    string? SUBJECT_TYPE;
    time:Date? EFFECTIVE;
    string? CONTEXT;
    string? URL;
    string? NAME;
    time:Date? DATE;
    string? CODE;
    string? STATUS;
    string? DESCRIPTION;
    string? VERSION;
    string? TITLE;
    string? IDENTIFIER;
    string? CONTEXT_QUANTITY;
    string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type QuestionnaireTableOptionalized record {|
    string QUESTIONNAIRETABLE_ID?;
    string? DEFINITION?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? SUBJECT_TYPE?;
    time:Date? EFFECTIVE?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type QuestionnaireTableTargetType typedesc<QuestionnaireTableOptionalized>;

public type QuestionnaireTableInsert QuestionnaireTable;

public type QuestionnaireTableUpdate record {|
    string? DEFINITION?;
    string? PUBLISHER?;
    string? JURISDICTION?;
    string? SUBJECT_TYPE?;
    time:Date? EFFECTIVE?;
    string? CONTEXT?;
    string? URL?;
    string? NAME?;
    time:Date? DATE?;
    string? CODE?;
    string? STATUS?;
    string? DESCRIPTION?;
    string? VERSION?;
    string? TITLE?;
    string? IDENTIFIER?;
    string? CONTEXT_QUANTITY?;
    string? CONTEXT_TYPE?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type AppointmentResponseTable record {|
    readonly string APPOINTMENTRESPONSETABLE_ID;
    string? PART_STATUS;
    string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type AppointmentResponseTableOptionalized record {|
    string APPOINTMENTRESPONSETABLE_ID?;
    string? PART_STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

public type AppointmentResponseTableTargetType typedesc<AppointmentResponseTableOptionalized>;

public type AppointmentResponseTableInsert AppointmentResponseTable;

public type AppointmentResponseTableUpdate record {|
    string? PART_STATUS?;
    string? IDENTIFIER?;
    int VERSION_ID?;
    time:Civil CREATED_AT?;
    time:Civil UPDATED_AT?;
    time:Civil LAST_UPDATED?;
    byte[] RESOURCE_JSON?;
|};

