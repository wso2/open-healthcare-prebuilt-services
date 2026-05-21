import ballerina_fhir_server.utils;

import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/java.jdbc;

public class UpdateMapper {

    public isolated function init() {}

    // Full replacement (PUT). Returns the new version ID.
    public isolated function mapToUpdate(
        jdbc:Client jdbcClient,
        string resourceType,
        string resourceId,
        json resourceJson
    ) returns int|error {
        return self.applyUpdate(jdbcClient, resourceType, resourceId, resourceJson);
    }

    // Partial update (PATCH). Merges patch into existing resource then calls applyUpdate.
    public isolated function mapToPatch(
        jdbc:Client jdbcClient,
        string resourceType,
        string resourceId,
        json patchJson
    ) returns int|error {
        // Fetch current resource JSON
        string current = check readCurrentJson(jdbcClient, resourceType, resourceId);
        json merged    = check mergeJson(current, patchJson);
        return self.applyUpdate(jdbcClient, resourceType, resourceId, merged);
    }

    private isolated function applyUpdate(
        jdbc:Client jdbcClient,
        string resourceType,
        string resourceId,
        json resourceJson
    ) returns int|error {
        // Atomically increment version_id and capture the new value
        int newVersion;
        boolean isPostgres = utils:dbType.toLowerAscii().trim() == "postgresql" || utils:dbType.toLowerAscii().trim() == "postgres";

        time:Civil now = time:utcToCivil(time:utcNow());
        string lastUpdatedIso = utils:formatTimestampISO8601(now);

        // Re-stamp meta
        map<json> resMap = check resourceJson.cloneWithType();
        resMap["id"] = resourceId;
        map<json> meta = resMap["meta"] is map<json> ? <map<json>>resMap["meta"] : {};
        meta["lastUpdated"] = lastUpdatedIso;
        resMap["meta"] = meta;

        // First get current version to derive next
        type VerRow record {| int version_id; |};
        sql:ParameterizedQuery verQ;
        if isPostgres {
            verQ = `SELECT version_id FROM resources WHERE fhir_id = ${resourceId} AND resource_type = ${resourceType}`;
        } else {
            verQ = `SELECT "version_id" FROM "resources" WHERE "fhir_id" = ${resourceId} AND "resource_type" = ${resourceType}`;
        }
        VerRow|error verRow = jdbcClient->queryRow(verQ);
        if verRow is error {
            return error(string `Resource not found: ${resourceType}/${resourceId}`);
        }
        newVersion = verRow.version_id + 1;
        meta["versionId"] = newVersion.toString();
        resMap["meta"] = meta;
        json finalJson = resMap.toJson();
        string jsonStr = finalJson.toJsonString();
        string searchText = buildUpdateSearchText(finalJson);

        // Update master row (atomic version bump)
        if isPostgres {
            _ = check jdbcClient->execute(`
                UPDATE resources
                SET version_id = ${newVersion}, last_updated = ${now},
                    resource_json = ${jsonStr}::jsonb,
                    search_text   = to_tsvector('english', ${searchText})
                WHERE fhir_id = ${resourceId} AND resource_type = ${resourceType}`);
        } else {
            _ = check jdbcClient->execute(`
                UPDATE "resources"
                SET "version_id" = ${newVersion}, "last_updated" = ${now}, "resource_json" = ${jsonStr}
                WHERE "fhir_id" = ${resourceId} AND "resource_type" = ${resourceType}`);
        }

        // Delete old search index rows and re-insert fresh ones
        check utils:deleteAllSearchParams(jdbcClient, resourceId, resourceType);
        utils:ExtractedSearchParams params = check utils:extractAllSearchParams(jdbcClient, resourceType, finalJson);
        check utils:saveAllSearchParams(jdbcClient, resourceId, resourceType, params);

        log:printDebug(string `Updated ${resourceType}/${resourceId} to version ${newVersion}`);
        return newVersion;
    }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

isolated function readCurrentJson(jdbc:Client jc, string resourceType, string resourceId) returns string|error {
    boolean isPostgres = utils:dbType.toLowerAscii().trim() == "postgresql" || utils:dbType.toLowerAscii().trim() == "postgres";
    type JsonRow record {| string resource_json; |};
    sql:ParameterizedQuery q;
    if isPostgres {
        q = `SELECT CAST(resource_json AS TEXT) AS resource_json FROM resources WHERE fhir_id = ${resourceId} AND resource_type = ${resourceType}`;
    } else {
        q = `SELECT "resource_json" FROM "resources" WHERE "fhir_id" = ${resourceId} AND "resource_type" = ${resourceType}`;
    }
    JsonRow|error row = jc->queryRow(q);
    if row is error {
        return error(string `${resourceType}/${resourceId} not found`);
    }
    return row.resource_json;
}

isolated function mergeJson(string baseStr, json patch) returns json|error {
    json base = check baseStr.fromJsonString();
    if !(base is map<json>) || !(patch is map<json>) {
        return patch;
    }
    map<json> result = <map<json>>base.clone();
    map<json> patchMap = <map<json>>patch;
    foreach var [k, v] in patchMap.entries() {
        if v is () {
            _ = result.remove(k);
        } else {
            result[k] = v;
        }
    }
    return result.toJson();
}

isolated function buildUpdateSearchText(json resourceJson) returns string {
    if !(resourceJson is map<json>) { return ""; }
    map<json> m = <map<json>>resourceJson;
    string[] parts = [];
    json textField = m["text"];
    if textField is map<json> {
        json div = (<map<json>>textField)["div"];
        if div is string {
            string stripped = re`<[^>]*>`.replaceAll(div, " ");
            parts.push(stripped);
        }
    }
    foreach string key in ["name", "description", "title", "comment", "note"] {
        json v = m[key];
        if v is string { parts.push(v); }
    }
    return string:'join(" ", ...parts);
}
