import ballerina/io;
import ballerinax/health.fhir.r4;

// Function to read the LOINC CSV file
isolated function readLoincCsv(string path) returns LoincConcept[]|error {
    LoincConcept[]|io:Error content = io:fileReadCsv(path);
    return content;
}

// Function to export the combined CodeSystem resource to a JSON file
isolated function exportCodeSystem(LoincConcept[] concepts, string? 'version, string jsonFilePath) returns error? {
    r4:CodeSystem codeSystem;
    codeSystem = check createCodeSystemResource(concepts, 'version);

    check io:fileWriteString(jsonFilePath, codeSystem.toJson().toJsonString());
}

public isolated function convert(string filePath, string? version) returns error? {
    LoincConcept[] loincData = check readLoincCsv(filePath + LOINC_CSV_FILE_PATH);
    check exportCodeSystem(loincData, version, filePath + FHIR_LOINC_FILE_NAME);
}
