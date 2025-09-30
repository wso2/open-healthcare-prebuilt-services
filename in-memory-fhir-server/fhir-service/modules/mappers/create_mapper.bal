import ballerina_fhir_server.db_store;

import ballerina/io;
import ballerina/time;

public class CreateMapper {
    private json[] references;

    public isolated function init() {
        self.references = [];
    }

    // This function will map values to persist insert models
    public isolated function mapToInsertModel(db_store:Client persistClient, string resourceType, json resourceJson) returns record {|anydata...;|}|error? {
        FHIRMapper fhirMapper = new FHIRMapper();
        map<json> extractedValues = check fhirMapper.extractSearchParameters(persistClient, resourceType, resourceJson);
        self.references = fhirMapper.getReferences();

        match resourceType {
            "Appointment" => {
                io:println(extractedValues);

                db_store:AppointmentTableInsert appointmentInsert = {
                    APPOINTMENTTABLE_ID: check resourceJson.id,
                    DATE: extractedValues.hasKey("date") ? check time:civilFromString(extractedValues.get("date").toString()) : (),
                    SERVICE_CATEGORY: extractedValues.hasKey("service-category") ? extractedValues.get("service-category").toString() : "",
                    PART_STATUS: extractedValues.hasKey("part-status") ? extractedValues.get("part-status").toString() : "",
                    STATUS: extractedValues.hasKey("status") ? extractedValues.get("status").toString() : "",
                    APPOINTMENT_TYPE: extractedValues.hasKey("appointment-type") ? extractedValues.get("appointment-type").toString() : "",
                    REASON_CODE: extractedValues.hasKey("reason-code") ? extractedValues.get("reason-code").toString() : "",
                    SPECIALTY: extractedValues.hasKey("speciality") ? extractedValues.get("speciality").toString() : "",
                    IDENTIFIER: extractedValues.hasKey("identifier") ? extractedValues.get("identifier").toString() : "",
                    SERVICE_TYPE: extractedValues.hasKey("service-type") ? extractedValues.get("service-type").toString() : "",
                    VERSION_ID: 1,
                    CREATED_AT: time:utcToCivil(time:utcNow()),
                    UPDATED_AT: time:utcToCivil(time:utcNow()),
                    LAST_UPDATED: time:utcToCivil(time:utcNow()),
                    RESOURCE_JSON: resourceJson.toString().toBytes()
                };

                return appointmentInsert;
            }
        }

        return ();
    }

    public isolated function getReferences() returns json[] {
        return self.references;
    }
}
