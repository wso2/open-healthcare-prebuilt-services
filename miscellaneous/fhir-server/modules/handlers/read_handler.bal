import ballerina_fhir_server.mappers;
import ballerina_fhir_server.utils;

import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/health.fhir.r4;
import ballerinax/java.jdbc;

public class ReadHandler {
    private mappers:ReadMapper readMapper;

    public isolated function init() {
        self.readMapper = new mappers:ReadMapper();
    }

    public isolated function readResource(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns json|error {
        log:printDebug(string `Reading ${resourceType}/${resourceId}`);
        return self.readMapper.readResourceById(jdbcClient, resourceType, resourceId);
    }

    public isolated function searchResources(jdbc:Client? jdbcClient, string resourceType, map<string[]> queryParams, r4:PaginationContext? paginationContext = ()) returns json|error {
        log:printDebug(string `Searching ${resourceType} with ${queryParams.keys().length()} query parameter(s)`);
        return self.readMapper.searchResources(jdbcClient, resourceType, queryParams, paginationContext);
    }

    public isolated function readAllResources(jdbc:Client? jdbcClient, string resourceType, int? 'limit = ()) returns json|error {
        log:printDebug(string `Reading all ${resourceType} resources`);
        map<string[]> params = {};
        if 'limit is int {
            params["_count"] = ['limit.toString()];
        }
        return self.readMapper.searchResources(jdbcClient, resourceType, params);
    }

    public isolated function checkResourceExists(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns boolean|error {
        return self.readMapper.resourceExists(jdbcClient, resourceType, resourceId);
    }

    public isolated function getResourceCount(jdbc:Client? jdbcClient, string resourceType) returns int|error {
        return self.readMapper.getResourceCount(jdbcClient, resourceType);
    }

    public isolated function getResourceMetadata(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns record {|anydata...;|}|error {
        jdbc:Client jc = check utils:getValidatedJdbcClient(jdbcClient);
        boolean isPostgres = isPostgresDb();
        type MetaRow record {| string fhir_id; int version_id; time:Civil last_updated; |};
        sql:ParameterizedQuery q;
        if isPostgres {
            q = `SELECT fhir_id, version_id, last_updated FROM resources WHERE fhir_id = ${resourceId} AND resource_type = ${resourceType} AND is_deleted = FALSE`;
        } else {
            q = `SELECT "fhir_id", "version_id", "last_updated" FROM "resources" WHERE "fhir_id" = ${resourceId} AND "resource_type" = ${resourceType} AND "is_deleted" = FALSE`;
        }
        MetaRow|sql:Error row = jc->queryRow(q);
        if row is sql:NoRowsError {
            return error(string `${resourceType}/${resourceId} not found`);
        }
        if row is sql:Error { return row; }
        return {id: row.fhir_id, versionId: row.version_id, lastUpdated: utils:formatTimestampISO8601(row.last_updated)};
    }

    // Forward references: resources this resource points to (via sp_reference)
    public isolated function readReferences(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns json[]|error {
        return self.readMapper.readResourceReferences(jdbcClient, resourceType, resourceId, false);
    }

    // Read resource plus its forward references
    public isolated function readResourceWithReferences(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns json|error {
        json resourceJson = check self.readResource(jdbcClient, resourceType, resourceId);
        json[] references = check self.readReferences(jdbcClient, resourceType, resourceId);
        return {"resource": resourceJson, "references": references};
    }

    // Forward includes: resources that this resource references (for $everything / bulk export)
    public isolated function fetchAllReferencedResources(
        jdbc:Client? jdbcClient,
        string sourceResourceType,
        string sourceResourceId,
        string? sinceFilter = (),
        string[]? typeFilter = ()
    ) returns json[]|error {
        json[] results = check self.readMapper.readResourceReferences(jdbcClient, sourceResourceType, sourceResourceId, false);
        return filterResults(results, sinceFilter, typeFilter);
    }

    // Reverse includes: resources that reference this resource (for $everything / bulk export)
    public isolated function fetchAllReferencingResources(
        jdbc:Client? jdbcClient,
        string targetResourceType,
        string targetResourceId,
        string? sinceFilter = (),
        string[]? typeFilter = ()
    ) returns json[]|error {
        json[] results = check self.readMapper.readResourceReferences(jdbcClient, targetResourceType, targetResourceId, true);
        return filterResults(results, sinceFilter, typeFilter);
    }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

isolated function isPostgresDb() returns boolean {
    string n = utils:dbType.toLowerAscii().trim();
    return n == "postgresql" || n == "postgres";
}

isolated function filterResults(json[] entries, string? sinceFilter, string[]? typeFilter) returns json[]|error {
    if sinceFilter is () && typeFilter is () {
        return entries;
    }
    json[] filtered = [];
    foreach json entry in entries {
        if !(entry is map<json>) { continue; }
        map<json> entryMap = <map<json>>entry;
        json? resourceJson = entryMap["resource"];
        if !(resourceJson is map<json>) { continue; }
        map<json> resource = <map<json>>resourceJson;

        // typeFilter: check resourceType
        if typeFilter is string[] {
            json? rt = resource["resourceType"];
            if rt is string && !typeFilter.some(t => t == rt) {
                continue;
            }
        }

        // sinceFilter: check meta.lastUpdated
        if sinceFilter is string {
            json? metaJson = resource["meta"];
            if !(metaJson is map<json>) { continue; }
            json? luJson = (<map<json>>metaJson)["lastUpdated"];
            if !(luJson is string) { continue; }
            // Simple lexicographic comparison works for ISO-8601 timestamps
            if luJson <= sinceFilter {
                continue;
            }
        }

        filtered.push(entry);
    }
    return filtered;
}
