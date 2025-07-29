import ballerina/http;
import ballerinax/health.fhir.r4;

public const string FHIR_SNOMED_FILE_NAME = "/snomed-codesystem.json";

public isolated function convert(string filePath, string? version) returns error? {
    return r4:createFHIRError(
                    "SNOMED upload is not implemented yet",
            r4:ERROR,
            r4:INVALID_REQUIRED,
            httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}
