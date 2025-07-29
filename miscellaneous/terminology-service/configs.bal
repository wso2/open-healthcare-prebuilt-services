import ballerinax/health.fhir.r4.terminology;

//Constants
const TYPE_HEADER = "x-terminology-type";
const ZIP_FILE_NAME = "/terminology.zip";
const ZIP_FILE_EXTRACTION_PATH = "/extracted";
const FHIR_PACKAGE_PATH = "/hl7.terminology.r4/package";
const TEMPORARY_FILES_DIRECTORY_NAME = "temp_files";

// enums
enum SearchCodeProperties {
    DISPLAY = terminology:DISPLAY,
    DEFINITION = terminology:DEFINITION
};

enum ContentType {
    FHIR_JSON = "application/fhir+json",
    FHIR_XML = "application/fhir+xml",
    JSON = "application/json",
    XML = "application/xml",
    ZIP = "application/zip"
}

enum TerminologyType {
    SNOMED = "SNOMED",
    LOINC = "LOINC",
    ICD10 = "ICD10",
    RXNORM = "RXNORM",
    FHIR = "FHIR"
}

// Configurable Parameters
configurable string db_type = "postgresql";
