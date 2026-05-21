import ballerina_fhir_server.utils;

import ballerina/log;
import ballerina/time;
import ballerinax/java.jdbc;

public class CreateMapper {

    private string resourceId = "";
    private json resourceJsonWithId = {};

    public isolated function init() {
    }

    // Maps a FHIR resource JSON to the database and returns the assigned resource ID.
    // Inserts into: resources, sp_*, resource_history.
    // Called inside a transaction block in create_handler.bal.
    public isolated function mapToInsert(
        jdbc:Client jdbcClient,
        string resourceType,
        json resourceJson
    ) returns string|error {

        // Resolve resource ID
        string fhirId;
        if utils:useServerGeneratedIds {
            fhirId = utils:generateResourceId();
        } else {
            json|error clientId = resourceJson.id;
            if clientId is error || clientId.toString().trim().length() == 0 {
                return error("Resource must have an 'id' field when server-generated IDs are disabled");
            }
            fhirId = clientId.toString();
        }

        time:Civil now = time:utcToCivil(time:utcNow());
        string lastUpdatedIso = utils:formatTimestampISO8601(now);

        // Inject id + meta into resource JSON
        map<json> resMap = check resourceJson.cloneWithType();
        resMap["id"] = fhirId;
        map<json> meta = resMap["meta"] is map<json> ? <map<json>>resMap["meta"] : {};
        meta["versionId"] = "1";
        meta["lastUpdated"] = lastUpdatedIso;
        resMap["meta"] = meta;
        json finalJson = resMap.toJson();
        self.resourceJsonWithId = finalJson;
        self.resourceId = fhirId;

        string jsonStr = finalJson.toJsonString();
        string searchText = buildSearchText(finalJson);

        // Insert master resource row
        string normalizedDbType = utils:dbType.toLowerAscii().trim();
        if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
            _ = check jdbcClient->execute(`
                INSERT INTO resources (fhir_id, resource_type, version_id, last_updated, is_deleted, resource_json, search_text)
                VALUES (${fhirId}, ${resourceType}, 1, ${now}, FALSE,
                        ${jsonStr}::jsonb,
                        to_tsvector('english', ${searchText}))`);
        } else {
            _ = check jdbcClient->execute(`
                INSERT INTO "resources" ("fhir_id", "resource_type", "version_id", "last_updated", "is_deleted", "resource_json")
                VALUES (${fhirId}, ${resourceType}, 1, ${now}, FALSE, ${jsonStr})`);
        }

        // Extract and persist search index rows
        utils:ExtractedSearchParams params = check utils:extractAllSearchParams(jdbcClient, resourceType, finalJson);
        check utils:saveAllSearchParams(jdbcClient, fhirId, resourceType, params);

        log:printDebug(string `Created ${resourceType}/${fhirId}`);
        return fhirId;
    }

    public isolated function getResourceId() returns string {
        return self.resourceId;
    }

    public isolated function getResourceJsonWithId() returns json {
        return self.resourceJsonWithId;
    }
}

// Builds a plain-text string from narrative + key text fields for tsvector indexing.
isolated function buildSearchText(json resourceJson) returns string {
    if !(resourceJson is map<json>) {
        return "";
    }
    map<json> m = <map<json>>resourceJson;
    string[] parts = [];

    // Narrative text
    json textField = m["text"];
    if textField is map<json> {
        json div = (<map<json>>textField)["div"];
        if div is string {
            // Strip HTML tags
            string stripped = re`<[^>]*>`.replaceAll(div, " ");
            parts.push(stripped);
        }
    }

    // Common text fields present in many resource types
    foreach string key in ["name", "description", "title", "comment", "note"] {
        json v = m[key];
        if v is string {
            parts.push(v);
        }
    }

    return string:'join(" ", ...parts);
}
