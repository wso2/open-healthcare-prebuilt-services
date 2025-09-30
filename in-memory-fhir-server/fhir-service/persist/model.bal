import ballerina/persist as _;
import ballerinax/persist.sql;
import ballerina/time;

public type SEARCH_PARAM_RES_EXPRESSIONS record {|
    @sql:Generated
    readonly int ID;
    string SEARCH_PARAM_NAME;
    string SEARCH_PARAM_TYPE;
    string RESOURCE_NAME;
    string EXPRESSION;
|};

public type REFERENCES record {|
    @sql:Generated
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

public type TestScriptTable record {|
    readonly string TESTSCRIPTTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TESTSCRIPT_CAPABILITY;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type TestReportTable record {|
    readonly string TESTREPORTTABLE_ID;
    time:Date? ISSUED;
    @sql:Varchar {length: 512}
	string? PARTICIPANT;
    @sql:Varchar {length: 512}
	string? TESTER;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? RESULT;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type RelatedPersonTable record {|
    readonly string RELATEDPERSONTABLE_ID;
    @sql:Varchar {length: 512}
	string? ADDRESS_COUNTRY;
    @sql:Varchar {length: 512}
	string? ADDRESS_POSTALCODE;
    @sql:Varchar {length: 2048}
	string? ACTIVE;
    @sql:Varchar {length: 2048}
	string? PHONE;
    time:Date? BIRTHDATE;
    @sql:Varchar {length: 512}
	string? ADDRESS_CITY;
    @sql:Varchar {length: 2048}
	string? EMAIL;
    @sql:Varchar {length: 512}
	string? ADDRESS_STATE;
    @sql:Varchar {length: 2048}
	string? TELECOM;
    @sql:Varchar {length: 512}
	string? NAME;
    @sql:Varchar {length: 2048}
	string? ADDRESS_USE;
    @sql:Varchar {length: 512}
	string? ADDRESS;
    @sql:Varchar {length: 2048}
	string? GENDER;
    @sql:Varchar {length: 512}
	string? PHONETIC;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? RELATIONSHIP;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EvidenceVariableTable record {|
    readonly string EVIDENCEVARIABLETABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? TOPIC;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ValueSetTable record {|
    readonly string VALUESETTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 512}
	string? EXPANSION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? REFERENCE;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DocumentManifestTable record {|
    readonly string DOCUMENTMANIFESTTABLE_ID;
    time:Date? CREATED;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? RELATED_ID;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 512}
	string? SOURCE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ImmunizationRecommendationTable record {|
    readonly string IMMUNIZATIONRECOMMENDATIONTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? TARGET_DISEASE;
    @sql:Varchar {length: 2048}
	string? VACCINE_TYPE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DeviceMetricTable record {|
    readonly string DEVICEMETRICTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type LocationTable record {|
    readonly string LOCATIONTABLE_ID;
    @sql:Varchar {length: 512}
	string? ADDRESS_COUNTRY;
    @sql:Varchar {length: 512}
	string? ADDRESS_POSTALCODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? ADDRESS_USE;
    @sql:Varchar {length: 512}
	string? ADDRESS;
    @sql:Varchar {length: 2048}
	string? OPERATIONAL_STATUS;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? ADDRESS_CITY;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 512}
	string? ADDRESS_STATE;
    @sql:Varchar {length: 512}
	string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ExplanationOfBenefitTable record {|
    readonly string EXPLANATIONOFBENEFITTABLE_ID;
    time:Date? CREATED;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? DISPOSITION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type FlagTable record {|
    readonly string FLAGTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicationStatementTable record {|
    readonly string MEDICATIONSTATEMENTTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type InsurancePlanTable record {|
    readonly string INSURANCEPLANTABLE_ID;
    @sql:Varchar {length: 512}
	string? ADDRESS_COUNTRY;
    @sql:Varchar {length: 512}
	string? ADDRESS_POSTALCODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? ADDRESS_USE;
    @sql:Varchar {length: 512}
	string? ADDRESS;
    @sql:Varchar {length: 512}
	string? PHONETIC;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? ADDRESS_CITY;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 512}
	string? ADDRESS_STATE;
    @sql:Varchar {length: 512}
	string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductContraindicationTable record {|
    readonly string MEDICINALPRODUCTCONTRAINDICATIONTABLE_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ClaimResponseTable record {|
    readonly string CLAIMRESPONSETABLE_ID;
    time:Date? CREATED;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? OUTCOME;
    @sql:Varchar {length: 2048}
	string? USE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    time:Date? PAYMENT_DATE;
    @sql:Varchar {length: 512}
	string? DISPOSITION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductAuthorizationTable record {|
    readonly string MEDICINALPRODUCTAUTHORIZATIONTABLE_ID;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? COUNTRY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ImagingStudyTable record {|
    readonly string IMAGINGSTUDYTABLE_ID;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? DICOM_CLASS;
    @sql:Varchar {length: 2048}
	string? SERIES;
    @sql:Varchar {length: 2048}
	string? MODALITY;
    time:Date? STARTED;
    @sql:Varchar {length: 2048}
	string? BODYSITE;
    @sql:Varchar {length: 2048}
	string? INSTANCE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? REASON;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PractitionerRoleTable record {|
    readonly string PRACTITIONERROLETABLE_ID;
    @sql:Varchar {length: 2048}
	string? ROLE;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? ACTIVE;
    @sql:Varchar {length: 2048}
	string? PHONE;
    @sql:Varchar {length: 2048}
	string? SPECIALTY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? EMAIL;
    @sql:Varchar {length: 2048}
	string? TELECOM;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type GroupTable record {|
    readonly string GROUPTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CHARACTERISTIC;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? EXCLUDE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? VALUE;
    @sql:Varchar {length: 2048}
	string? ACTUAL;
    @sql:Varchar {length: 2048}
	string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PersonTable record {|
    readonly string PERSONTABLE_ID;
    @sql:Varchar {length: 512}
	string? ADDRESS_COUNTRY;
    @sql:Varchar {length: 512}
	string? ADDRESS_POSTALCODE;
    @sql:Varchar {length: 2048}
	string? PHONE;
    time:Date? BIRTHDATE;
    @sql:Varchar {length: 512}
	string? ADDRESS_CITY;
    @sql:Varchar {length: 2048}
	string? EMAIL;
    @sql:Varchar {length: 512}
	string? ADDRESS_STATE;
    @sql:Varchar {length: 2048}
	string? TELECOM;
    @sql:Varchar {length: 512}
	string? NAME;
    @sql:Varchar {length: 2048}
	string? ADDRESS_USE;
    @sql:Varchar {length: 512}
	string? ADDRESS;
    @sql:Varchar {length: 2048}
	string? GENDER;
    @sql:Varchar {length: 512}
	string? PHONETIC;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PractitionerTable record {|
    readonly string PRACTITIONERTABLE_ID;
    @sql:Varchar {length: 512}
	string? ADDRESS_COUNTRY;
    @sql:Varchar {length: 512}
	string? ADDRESS_POSTALCODE;
    @sql:Varchar {length: 2048}
	string? ACTIVE;
    @sql:Varchar {length: 2048}
	string? PHONE;
    @sql:Varchar {length: 512}
	string? ADDRESS_CITY;
    @sql:Varchar {length: 2048}
	string? EMAIL;
    @sql:Varchar {length: 512}
	string? ADDRESS_STATE;
    @sql:Varchar {length: 2048}
	string? TELECOM;
    @sql:Varchar {length: 512}
	string? NAME;
    @sql:Varchar {length: 512}
	string? FAMILY;
    @sql:Varchar {length: 2048}
	string? ADDRESS_USE;
    @sql:Varchar {length: 512}
	string? GIVEN;
    @sql:Varchar {length: 512}
	string? ADDRESS;
    @sql:Varchar {length: 2048}
	string? GENDER;
    @sql:Varchar {length: 512}
	string? PHONETIC;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? COMMUNICATION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ActivityDefinitionTable record {|
    readonly string ACTIVITYDEFINITIONTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? TOPIC;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EvidenceTable record {|
    readonly string EVIDENCETABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? TOPIC;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DeviceTable record {|
    readonly string DEVICETABLE_ID;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? UDI_DI;
    @sql:Varchar {length: 512}
	string? UDI_CARRIER;
    @sql:Varchar {length: 512}
	string? DEVICE_NAME;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? MODEL;
    @sql:Varchar {length: 512}
	string? MANUFACTURER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 512}
	string? URL;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type FamilyMemberHistoryTable record {|
    readonly string FAMILYMEMBERHISTORYTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? INSTANTIATES_URI;
    @sql:Varchar {length: 2048}
	string? SEX;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? RELATIONSHIP;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type AdverseEventTable record {|
    readonly string ADVERSEEVENTTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? SERIOUSNESS;
    @sql:Varchar {length: 2048}
	string? ACTUALITY;
    @sql:Varchar {length: 2048}
	string? SEVERITY;
    @sql:Varchar {length: 2048}
	string? EVENT;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SupplyRequestTable record {|
    readonly string SUPPLYREQUESTTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ExampleScenarioTable record {|
    readonly string EXAMPLESCENARIOTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    @sql:Varchar {length: 512}
	string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type InvoiceTable record {|
    readonly string INVOICETABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? TOTALNET;
    @sql:Varchar {length: 2048}
	string? PARTICIPANT_ROLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 2048}
	string? TOTALGROSS;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type QuestionnaireResponseTable record {|
    readonly string QUESTIONNAIRERESPONSETABLE_ID;
    @sql:Varchar {length: 2048}
	string? STATUS;
    time:Date? AUTHORED;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ObservationTable record {|
    readonly string OBSERVATIONTABLE_ID;
    @sql:Varchar {length: 2048}
	string? COMPONENT_CODE;
    @sql:Varchar {length: 2048}
	string? VALUE_QUANTITY;
    @sql:Varchar {length: 2048}
	string? COMBO_CODE;
    time:Date? VALUE_DATE;
    time:Date? DATE;
    @sql:Varchar {length: 512}
	string? VALUE_STRING;
    @sql:Varchar {length: 2048}
	string? COMBO_DATA_ABSENT_REASON;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? COMBO_VALUE_QUANTITY;
    @sql:Varchar {length: 2048}
	string? VALUE_CONCEPT;
    @sql:Varchar {length: 2048}
	string? METHOD;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? COMPONENT_DATA_ABSENT_REASON;
    @sql:Varchar {length: 2048}
	string? DATA_ABSENT_REASON;
    @sql:Varchar {length: 2048}
	string? COMPONENT_VALUE_QUANTITY;
    @sql:Varchar {length: 2048}
	string? COMPONENT_VALUE_CONCEPT;
    @sql:Varchar {length: 2048}
	string? COMBO_VALUE_CONCEPT;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EffectEvidenceSynthesisTable record {|
    readonly string EFFECTEVIDENCESYNTHESISTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type OperationDefinitionTable record {|
    readonly string OPERATIONDEFINITIONTABLE_ID;
    @sql:Varchar {length: 2048}
	string? SYSTEM;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 2048}
	string? INSTANCE;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? KIND;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MeasureReportTable record {|
    readonly string MEASUREREPORTTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    time:Date? PERIOD;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SupplyDeliveryTable record {|
    readonly string SUPPLYDELIVERYTABLE_ID;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ServiceRequestTable record {|
    readonly string SERVICEREQUESTTABLE_ID;
    @sql:Varchar {length: 2048}
	string? REQUISITION;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    time:Date? OCCURRENCE;
    @sql:Varchar {length: 512}
	string? INSTANTIATES_URI;
    @sql:Varchar {length: 2048}
	string? PERFORMER_TYPE;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? INTENT;
    time:Date? AUTHORED;
    @sql:Varchar {length: 2048}
	string? PRIORITY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? BODY_SITE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type BasicTable record {|
    readonly string BASICTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CODE;
    time:Date? CREATED;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SubscriptionTable record {|
    readonly string SUBSCRIPTIONTABLE_ID;
    @sql:Varchar {length: 512}
	string? CRITERIA;
    @sql:Varchar {length: 2048}
	string? CONTACT;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? PAYLOAD;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 512}
	string? URL;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EnrollmentResponseTable record {|
    readonly string ENROLLMENTRESPONSETABLE_ID;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DeviceRequestTable record {|
    readonly string DEVICEREQUESTTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CODE;
    time:Date? EVENT_DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? INSTANTIATES_URI;
    time:Date? AUTHORED_ON;
    @sql:Varchar {length: 2048}
	string? INTENT;
    @sql:Varchar {length: 2048}
	string? GROUP_IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type AppointmentTable record {|
    readonly string APPOINTMENTTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? SERVICE_CATEGORY;
    @sql:Varchar {length: 2048}
	string? PART_STATUS;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? APPOINTMENT_TYPE;
    @sql:Varchar {length: 2048}
	string? REASON_CODE;
    @sql:Varchar {length: 2048}
	string? SPECIALTY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? SERVICE_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type NamingSystemTable record {|
    readonly string NAMINGSYSTEMTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 512}
	string? RESPONSIBLE;
    @sql:Varchar {length: 512}
	string? CONTACT;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 512}
	string? VALUE;
    @sql:Varchar {length: 2048}
	string? ID_TYPE;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 2048}
	string? TELECOM;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    time:Date? PERIOD;
    @sql:Varchar {length: 2048}
	string? KIND;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type StructureDefinitionTable record {|
    readonly string STRUCTUREDEFINITIONTABLE_ID;
    @sql:Varchar {length: 2048}
	string? PATH;
    @sql:Varchar {length: 2048}
	string? DERIVATION;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 2048}
	string? BASE_PATH;
    @sql:Varchar {length: 2048}
	string? EXPERIMENTAL;
    @sql:Varchar {length: 2048}
	string? KEYWORD;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 2048}
	string? ABSTRACT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? KIND;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 2048}
	string? EXT_CONTEXT;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? TYPE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ClinicalImpressionTable record {|
    readonly string CLINICALIMPRESSIONTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? FINDING_CODE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CommunicationTable record {|
    readonly string COMMUNICATIONTABLE_ID;
    time:Date? RECEIVED;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? MEDIUM;
    @sql:Varchar {length: 512}
	string? INSTANTIATES_URI;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    time:Date? SENT;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type OrganizationTable record {|
    readonly string ORGANIZATIONTABLE_ID;
    @sql:Varchar {length: 512}
	string? ADDRESS_COUNTRY;
    @sql:Varchar {length: 512}
	string? ADDRESS_POSTALCODE;
    @sql:Varchar {length: 2048}
	string? ADDRESS_USE;
    @sql:Varchar {length: 2048}
	string? ACTIVE;
    @sql:Varchar {length: 512}
	string? ADDRESS;
    @sql:Varchar {length: 512}
	string? PHONETIC;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? ADDRESS_CITY;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 512}
	string? ADDRESS_STATE;
    @sql:Varchar {length: 512}
	string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CoverageEligibilityResponseTable record {|
    readonly string COVERAGEELIGIBILITYRESPONSETABLE_ID;
    time:Date? CREATED;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? OUTCOME;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? DISPOSITION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ResearchStudyTable record {|
    readonly string RESEARCHSTUDYTABLE_ID;
    @sql:Varchar {length: 2048}
	string? LOCATION;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? FOCUS;
    @sql:Varchar {length: 2048}
	string? KEYWORD;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type BundleTable record {|
    readonly string BUNDLETABLE_ID;
    time:Date? TIMESTAMP;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EncounterTable record {|
    readonly string ENCOUNTERTABLE_ID;
    @sql:Varchar {length: 2048}
	string? PARTICIPANT_TYPE;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? LENGTH;
    @sql:Varchar {length: 2048}
	string? REASON_CODE;
    @sql:Varchar {length: 2048}
	string? SPECIAL_ARRANGEMENT;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CLASS;
    @sql:Varchar {length: 2048}
	string? TYPE;
    time:Date? LOCATION_PERIOD;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type RiskAssessmentTable record {|
    readonly string RISKASSESSMENTTABLE_ID;
    time:Date? DATE;
    int? PROBABILITY;
    @sql:Varchar {length: 2048}
	string? METHOD;
    @sql:Varchar {length: 2048}
	string? RISK;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ListTable record {|
    readonly string LISTTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 512}
	string? NOTES;
    @sql:Varchar {length: 2048}
	string? EMPTY_REASON;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type OrganizationAffiliationTable record {|
    readonly string ORGANIZATIONAFFILIATIONTABLE_ID;
    @sql:Varchar {length: 2048}
	string? ROLE;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? ACTIVE;
    @sql:Varchar {length: 2048}
	string? PHONE;
    @sql:Varchar {length: 2048}
	string? SPECIALTY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? EMAIL;
    @sql:Varchar {length: 2048}
	string? TELECOM;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ChargeItemTable record {|
    readonly string CHARGEITEMTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CODE;
    int? FACTOR_OVERRIDE;
    @sql:Varchar {length: 2048}
	string? QUANTITY;
    time:Date? OCCURRENCE;
    @sql:Varchar {length: 2048}
	string? PRICE_OVERRIDE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    time:Date? ENTERED_DATE;
    @sql:Varchar {length: 2048}
	string? PERFORMER_FUNCTION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicationKnowledgeTable record {|
    readonly string MEDICATIONKNOWLEDGETABLE_ID;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? SOURCE_COST;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? MONITORING_PROGRAM_NAME;
    @sql:Varchar {length: 2048}
	string? CLASSIFICATION_TYPE;
    @sql:Varchar {length: 2048}
	string? CLASSIFICATION;
    @sql:Varchar {length: 2048}
	string? DOSEFORM;
    @sql:Varchar {length: 2048}
	string? MONOGRAPH_TYPE;
    @sql:Varchar {length: 2048}
	string? MONITORING_PROGRAM_TYPE;
    @sql:Varchar {length: 2048}
	string? INGREDIENT_CODE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PlanDefinitionTable record {|
    readonly string PLANDEFINITIONTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? TOPIC;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CarePlanTable record {|
    readonly string CAREPLANTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? INSTANTIATES_URI;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? INTENT;
    time:Date? ACTIVITY_DATE;
    @sql:Varchar {length: 2048}
	string? ACTIVITY_CODE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type VisionPrescriptionTable record {|
    readonly string VISIONPRESCRIPTIONTABLE_ID;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    time:Date? DATEWRITTEN;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EpisodeOfCareTable record {|
    readonly string EPISODEOFCARETABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CareTeamTable record {|
    readonly string CARETEAMTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicationAdministrationTable record {|
    readonly string MEDICATIONADMINISTRATIONTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? REASON_NOT_GIVEN;
    time:Date? EFFECTIVE_TIME;
    @sql:Varchar {length: 2048}
	string? REASON_GIVEN;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ConsentTable record {|
    readonly string CONSENTTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? SECURITY_LABEL;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? ACTION;
    @sql:Varchar {length: 2048}
	string? SCOPE;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    time:Date? PERIOD;
    @sql:Varchar {length: 2048}
	string? PURPOSE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DetectedIssueTable record {|
    readonly string DETECTEDISSUETABLE_ID;
    @sql:Varchar {length: 2048}
	string? CODE;
    time:Date? IDENTIFIED;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SubstanceSpecificationTable record {|
    readonly string SUBSTANCESPECIFICATIONTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CODE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type AllergyIntoleranceTable record {|
    readonly string ALLERGYINTOLERANCETABLE_ID;
    @sql:Varchar {length: 2048}
	string? ROUTE;
    time:Date? LAST_DATE;
    @sql:Varchar {length: 2048}
	string? MANIFESTATION;
    @sql:Varchar {length: 2048}
	string? CLINICAL_STATUS;
    @sql:Varchar {length: 2048}
	string? VERIFICATION_STATUS;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? CRITICALITY;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 2048}
	string? SEVERITY;
    time:Date? ONSET;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductIndicationTable record {|
    readonly string MEDICINALPRODUCTINDICATIONTABLE_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductPharmaceuticalTable record {|
    readonly string MEDICINALPRODUCTPHARMACEUTICALTABLE_ID;
    @sql:Varchar {length: 2048}
	string? ROUTE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TARGET_SPECIES;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SlotTable record {|
    readonly string SLOTTABLE_ID;
    @sql:Varchar {length: 2048}
	string? SERVICE_CATEGORY;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? APPOINTMENT_TYPE;
    @sql:Varchar {length: 2048}
	string? SPECIALTY;
    time:Date? START;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? SERVICE_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type VerificationResultTable record {|
    readonly string VERIFICATIONRESULTTABLE_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SpecimenTable record {|
    readonly string SPECIMENTABLE_ID;
    time:Date? COLLECTED;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? ACCESSION;
    @sql:Varchar {length: 2048}
	string? CONTAINER;
    @sql:Varchar {length: 2048}
	string? BODYSITE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 2048}
	string? CONTAINER_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ResearchSubjectTable record {|
    readonly string RESEARCHSUBJECTTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicationTable record {|
    readonly string MEDICATIONTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    time:Date? EXPIRATION_DATE;
    @sql:Varchar {length: 2048}
	string? FORM;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? LOT_NUMBER;
    @sql:Varchar {length: 2048}
	string? INGREDIENT_CODE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ResearchDefinitionTable record {|
    readonly string RESEARCHDEFINITIONTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? TOPIC;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type HealthcareServiceTable record {|
    readonly string HEALTHCARESERVICETABLE_ID;
    @sql:Varchar {length: 2048}
	string? SERVICE_CATEGORY;
    @sql:Varchar {length: 2048}
	string? CHARACTERISTIC;
    @sql:Varchar {length: 2048}
	string? ACTIVE;
    @sql:Varchar {length: 2048}
	string? SPECIALTY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? SERVICE_TYPE;
    @sql:Varchar {length: 2048}
	string? PROGRAM;
    @sql:Varchar {length: 512}
	string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PaymentNoticeTable record {|
    readonly string PAYMENTNOTICETABLE_ID;
    time:Date? CREATED;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? PAYMENT_STATUS;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ProvenanceTable record {|
    readonly string PROVENANCETABLE_ID;
    time:Date? RECORDED;
    time:Date? WHEN;
    @sql:Varchar {length: 2048}
	string? AGENT_TYPE;
    @sql:Varchar {length: 2048}
	string? SIGNATURE_TYPE;
    @sql:Varchar {length: 2048}
	string? AGENT_ROLE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type GraphDefinitionTable record {|
    readonly string GRAPHDEFINITIONTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 2048}
	string? START;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    @sql:Varchar {length: 512}
	string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MediaTable record {|
    readonly string MEDIATABLE_ID;
    @sql:Varchar {length: 2048}
	string? SITE;
    time:Date? CREATED;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? MODALITY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 2048}
	string? VIEW;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type BodyStructureTable record {|
    readonly string BODYSTRUCTURETABLE_ID;
    @sql:Varchar {length: 2048}
	string? LOCATION;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? MORPHOLOGY;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DiagnosticReportTable record {|
    readonly string DIAGNOSTICREPORTTABLE_ID;
    time:Date? DATE;
    time:Date? ISSUED;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? CONCLUSION;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type GoalTable record {|
    readonly string GOALTABLE_ID;
    time:Date? TARGET_DATE;
    @sql:Varchar {length: 2048}
	string? ACHIEVEMENT_STATUS;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? LIFECYCLE_STATUS;
    time:Date? START_DATE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CapabilityStatementTable record {|
    readonly string CAPABILITYSTATEMENTTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 2048}
	string? FORMAT;
    @sql:Varchar {length: 2048}
	string? MODE;
    @sql:Varchar {length: 2048}
	string? SECURITY_SERVICE;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? SOFTWARE;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? FHIRVERSION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? RESOURCE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DeviceUseStatementTable record {|
    readonly string DEVICEUSESTATEMENTTABLE_ID;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ScheduleTable record {|
    readonly string SCHEDULETABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? SERVICE_CATEGORY;
    @sql:Varchar {length: 2048}
	string? ACTIVE;
    @sql:Varchar {length: 2048}
	string? SPECIALTY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? SERVICE_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductPackagedTable record {|
    readonly string MEDICINALPRODUCTPACKAGEDTABLE_ID;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ProcedureTable record {|
    readonly string PROCEDURETABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? INSTANTIATES_URI;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? REASON_CODE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type LibraryTable record {|
    readonly string LIBRARYTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? TOPIC;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? CONTENT_TYPE;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CodeSystemTable record {|
    readonly string CODESYSTEMTABLE_ID;
    @sql:Varchar {length: 2048}
	string? LANGUAGE;
    @sql:Varchar {length: 512}
	string? SYSTEM;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 2048}
	string? CONTENT_MODE;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CommunicationRequestTable record {|
    readonly string COMMUNICATIONREQUESTTABLE_ID;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? MEDIUM;
    time:Date? OCCURRENCE;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    time:Date? AUTHORED;
    @sql:Varchar {length: 2048}
	string? PRIORITY;
    @sql:Varchar {length: 2048}
	string? GROUP_IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DocumentReferenceTable record {|
    readonly string DOCUMENTREFERENCETABLE_ID;
    @sql:Varchar {length: 2048}
	string? LANGUAGE;
    @sql:Varchar {length: 512}
	string? LOCATION;
    @sql:Varchar {length: 2048}
	string? CONTENTTYPE;
    @sql:Varchar {length: 2048}
	string? RELATION;
    @sql:Varchar {length: 2048}
	string? FORMAT;
    @sql:Varchar {length: 2048}
	string? FACILITY;
    @sql:Varchar {length: 2048}
	string? EVENT;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? SECURITY_LABEL;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    time:Date? PERIOD;
    @sql:Varchar {length: 2048}
	string? SETTING;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type RequestGroupTable record {|
    readonly string REQUESTGROUPTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? INSTANTIATES_URI;
    @sql:Varchar {length: 2048}
	string? INTENT;
    time:Date? AUTHORED;
    @sql:Varchar {length: 2048}
	string? PRIORITY;
    @sql:Varchar {length: 2048}
	string? GROUP_IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ClaimTable record {|
    readonly string CLAIMTABLE_ID;
    time:Date? CREATED;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? USE;
    @sql:Varchar {length: 2048}
	string? PRIORITY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MessageDefinitionTable record {|
    readonly string MESSAGEDEFINITIONTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 2048}
	string? FOCUS;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 2048}
	string? EVENT;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type RiskEvidenceSynthesisTable record {|
    readonly string RISKEVIDENCESYNTHESISTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type TaskTable record {|
    readonly string TASKTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? BUSINESS_STATUS;
    time:Date? PERIOD;
    time:Date? AUTHORED_ON;
    @sql:Varchar {length: 2048}
	string? INTENT;
    @sql:Varchar {length: 2048}
	string? PRIORITY;
    @sql:Varchar {length: 2048}
	string? GROUP_IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? PERFORMER;
    time:Date? MODIFIED;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ImplementationGuideTable record {|
    readonly string IMPLEMENTATIONGUIDETABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 2048}
	string? EXPERIMENTAL;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type StructureMapTable record {|
    readonly string STRUCTUREMAPTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductUndesirableEffectTable record {|
    readonly string MEDICINALPRODUCTUNDESIRABLEEFFECTTABLE_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CompartmentDefinitionTable record {|
    readonly string COMPARTMENTDEFINITIONTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 2048}
	string? RESOURCE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    @sql:Varchar {length: 512}
	string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EndpointTable record {|
    readonly string ENDPOINTTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CONNECTION_TYPE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? PAYLOAD_TYPE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type TerminologyCapabilitiesTable record {|
    readonly string TERMINOLOGYCAPABILITIESTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    @sql:Varchar {length: 512}
	string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ConditionTable record {|
    readonly string CONDITIONTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CLINICAL_STATUS;
    @sql:Varchar {length: 2048}
	string? STAGE;
    @sql:Varchar {length: 2048}
	string? ONSET_AGE;
    @sql:Varchar {length: 512}
	string? ONSET_INFO;
    @sql:Varchar {length: 2048}
	string? EVIDENCE;
    time:Date? ONSET_DATE;
    @sql:Varchar {length: 2048}
	string? BODY_SITE;
    @sql:Varchar {length: 2048}
	string? VERIFICATION_STATUS;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? ABATEMENT_AGE;
    @sql:Varchar {length: 512}
	string? ABATEMENT_STRING;
    time:Date? RECORDED_DATE;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    time:Date? ABATEMENT_DATE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? SEVERITY;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CompositionTable record {|
    readonly string COMPOSITIONTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? RELATED_ID;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    time:Date? PERIOD;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 2048}
	string? CONFIDENTIALITY;
    @sql:Varchar {length: 2048}
	string? SECTION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ContractTable record {|
    readonly string CONTRACTTABLE_ID;
    time:Date? ISSUED;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? INSTANTIATES;
    @sql:Varchar {length: 512}
	string? URL;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ImmunizationTable record {|
    readonly string IMMUNIZATIONTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? VACCINE_CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? STATUS_REASON;
    @sql:Varchar {length: 512}
	string? SERIES;
    @sql:Varchar {length: 2048}
	string? TARGET_DISEASE;
    @sql:Varchar {length: 2048}
	string? REASON_CODE;
    time:Date? REACTION_DATE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? LOT_NUMBER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicationDispenseTable record {|
    readonly string MEDICATIONDISPENSETABLE_ID;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    time:Date? WHENHANDEDOVER;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    time:Date? WHENPREPARED;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MolecularSequenceTable record {|
    readonly string MOLECULARSEQUENCETABLE_ID;
    @sql:Varchar {length: 2048}
	string? CHROMOSOME;
    int? VARIANT_START;
    int? WINDOW_START;
    int? VARIANT_END;
    @sql:Varchar {length: 2048}
	string? REFERENCESEQID;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int? WINDOW_END;
    @sql:Varchar {length: 2048}
	string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SearchParameterTable record {|
    readonly string SEARCHPARAMETERTABLE_ID;
    @sql:Varchar {length: 2048}
	string? TARGET;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    @sql:Varchar {length: 2048}
	string? BASE;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicationRequestTable record {|
    readonly string MEDICATIONREQUESTTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    @sql:Varchar {length: 2048}
	string? INTENT;
    @sql:Varchar {length: 2048}
	string? PRIORITY;
    @sql:Varchar {length: 2048}
	string? INTENDED_PERFORMERTYPE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    time:Date? AUTHOREDON;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EnrollmentRequestTable record {|
    readonly string ENROLLMENTREQUESTTABLE_ID;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SpecimenDefinitionTable record {|
    readonly string SPECIMENDEFINITIONTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CONTAINER;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type EventDefinitionTable record {|
    readonly string EVENTDEFINITIONTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? TOPIC;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ImmunizationEvaluationTable record {|
    readonly string IMMUNIZATIONEVALUATIONTABLE_ID;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? TARGET_DISEASE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? DOSE_STATUS;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PaymentReconciliationTable record {|
    readonly string PAYMENTRECONCILIATIONTABLE_ID;
    time:Date? CREATED;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? OUTCOME;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? DISPOSITION;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MeasureTable record {|
    readonly string MEASURETABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? TOPIC;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ConceptMapTable record {|
    readonly string CONCEPTMAPTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? SOURCE_SYSTEM;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 512}
	string? TARGET_SYSTEM;
    @sql:Varchar {length: 2048}
	string? SOURCE_CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? TARGET_CODE;
    @sql:Varchar {length: 512}
	string? PRODUCT;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? DEPENDSON;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ResearchElementDefinitionTable record {|
    readonly string RESEARCHELEMENTDEFINITIONTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? TOPIC;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type GuidanceResponseTable record {|
    readonly string GUIDANCERESPONSETABLE_ID;
    @sql:Varchar {length: 2048}
	string? REQUEST;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type LinkageTable record {|
    readonly string LINKAGETABLE_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductTable record {|
    readonly string MEDICINALPRODUCTTABLE_ID;
    @sql:Varchar {length: 2048}
	string? NAME_LANGUAGE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type DeviceDefinitionTable record {|
    readonly string DEVICEDEFINITIONTABLE_ID;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CoverageEligibilityRequestTable record {|
    readonly string COVERAGEELIGIBILITYREQUESTTABLE_ID;
    time:Date? CREATED;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type PatientTable record {|
    readonly string PATIENTTABLE_ID;
    @sql:Varchar {length: 2048}
	string? LANGUAGE;
    @sql:Varchar {length: 512}
	string? ADDRESS_COUNTRY;
    @sql:Varchar {length: 512}
	string? ADDRESS_POSTALCODE;
    @sql:Varchar {length: 2048}
	string? ACTIVE;
    @sql:Varchar {length: 2048}
	string? PHONE;
    @sql:Varchar {length: 2048}
	string? DECEASED;
    time:Date? BIRTHDATE;
    @sql:Varchar {length: 512}
	string? ADDRESS_CITY;
    @sql:Varchar {length: 2048}
	string? EMAIL;
    @sql:Varchar {length: 512}
	string? ADDRESS_STATE;
    @sql:Varchar {length: 2048}
	string? TELECOM;
    @sql:Varchar {length: 512}
	string? NAME;
    @sql:Varchar {length: 512}
	string? FAMILY;
    @sql:Varchar {length: 2048}
	string? ADDRESS_USE;
    @sql:Varchar {length: 512}
	string? GIVEN;
    @sql:Varchar {length: 512}
	string? ADDRESS;
    @sql:Varchar {length: 2048}
	string? GENDER;
    @sql:Varchar {length: 512}
	string? PHONETIC;
    time:Date? DEATH_DATE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type CoverageTable record {|
    readonly string COVERAGETABLE_ID;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DEPENDENT;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 512}
	string? CLASS_VALUE;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 2048}
	string? CLASS_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type SubstanceTable record {|
    readonly string SUBSTANCETABLE_ID;
    @sql:Varchar {length: 2048}
	string? CONTAINER_IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 2048}
	string? QUANTITY;
    @sql:Varchar {length: 2048}
	string? CATEGORY;
    time:Date? EXPIRY;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type ChargeItemDefinitionTable record {|
    readonly string CHARGEITEMDEFINITIONTABLE_ID;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MedicinalProductInteractionTable record {|
    readonly string MEDICINALPRODUCTINTERACTIONTABLE_ID;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type AccountTable record {|
    readonly string ACCOUNTTABLE_ID;
    @sql:Varchar {length: 2048}
	string? STATUS;
    time:Date? PERIOD;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 512}
	string? NAME;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type MessageHeaderTable record {|
    readonly string MESSAGEHEADERTABLE_ID;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 512}
	string? SOURCE_URI;
    @sql:Varchar {length: 512}
	string? DESTINATION;
    @sql:Varchar {length: 512}
	string? DESTINATION_URI;
    @sql:Varchar {length: 512}
	string? SOURCE;
    @sql:Varchar {length: 2048}
	string? RESPONSE_ID;
    @sql:Varchar {length: 2048}
	string? EVENT;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type AuditEventTable record {|
    readonly string AUDITEVENTTABLE_ID;
    @sql:Varchar {length: 2048}
	string? SUBTYPE;
    @sql:Varchar {length: 2048}
	string? SITE;
    @sql:Varchar {length: 2048}
	string? OUTCOME;
    @sql:Varchar {length: 2048}
	string? ENTITY_ROLE;
    @sql:Varchar {length: 512}
	string? AGENT_NAME;
    @sql:Varchar {length: 2048}
	string? ENTITY_TYPE;
    time:Date? DATE;
    @sql:Varchar {length: 512}
	string? POLICY;
    @sql:Varchar {length: 2048}
	string? ALTID;
    @sql:Varchar {length: 2048}
	string? ACTION;
    @sql:Varchar {length: 512}
	string? ADDRESS;
    @sql:Varchar {length: 2048}
	string? TYPE;
    @sql:Varchar {length: 512}
	string? ENTITY_NAME;
    @sql:Varchar {length: 2048}
	string? AGENT_ROLE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type NutritionOrderTable record {|
    readonly string NUTRITIONORDERTABLE_ID;
    @sql:Varchar {length: 2048}
	string? SUPPLEMENT;
    @sql:Varchar {length: 2048}
	string? STATUS;
    time:Date? DATETIME;
    @sql:Varchar {length: 512}
	string? INSTANTIATES_URI;
    @sql:Varchar {length: 2048}
	string? ADDITIVE;
    @sql:Varchar {length: 2048}
	string? ORALDIET;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? FORMULA;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type QuestionnaireTable record {|
    readonly string QUESTIONNAIRETABLE_ID;
    @sql:Varchar {length: 512}
	string? DEFINITION;
    @sql:Varchar {length: 512}
	string? PUBLISHER;
    @sql:Varchar {length: 2048}
	string? JURISDICTION;
    @sql:Varchar {length: 2048}
	string? SUBJECT_TYPE;
    time:Date? EFFECTIVE;
    @sql:Varchar {length: 2048}
	string? CONTEXT;
    @sql:Varchar {length: 512}
	string? URL;
    @sql:Varchar {length: 512}
	string? NAME;
    time:Date? DATE;
    @sql:Varchar {length: 2048}
	string? CODE;
    @sql:Varchar {length: 2048}
	string? STATUS;
    @sql:Varchar {length: 512}
	string? DESCRIPTION;
    @sql:Varchar {length: 2048}
	string? VERSION;
    @sql:Varchar {length: 512}
	string? TITLE;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    @sql:Varchar {length: 2048}
	string? CONTEXT_QUANTITY;
    @sql:Varchar {length: 2048}
	string? CONTEXT_TYPE;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};

public type AppointmentResponseTable record {|
    readonly string APPOINTMENTRESPONSETABLE_ID;
    @sql:Varchar {length: 2048}
	string? PART_STATUS;
    @sql:Varchar {length: 2048}
	string? IDENTIFIER;
    int VERSION_ID;
    time:Civil CREATED_AT;
    time:Civil UPDATED_AT;
    time:Civil LAST_UPDATED;
    byte[] RESOURCE_JSON;
|};
