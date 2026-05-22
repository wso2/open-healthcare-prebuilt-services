import ballerina_fhir_server.utils;

import ballerina/lang.regexp;
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/health.fhir.r4;
import ballerinax/java.jdbc;

configurable string baseUrl = "http://localhost:9090";

// ─── Row types ────────────────────────────────────────────────────────────────

type PgResourceRow record {|
    string  fhir_id;
    string  resource_json;
    int     version_id;
    time:Civil last_updated;
|};

type H2ResourceRow record {|
    string    fhir_id;
    string    resource_json;
    int       version_id;
    time:Civil last_updated;
|};

type CountRow  record {| int cnt; |};
type IdRow     record {| string fhir_id; |};

// ─── ReadMapper ───────────────────────────────────────────────────────────────

public class ReadMapper {

    public isolated function init() {}

    // ── Read single resource by ID ──────────────────────────────────────────

    public isolated function readResourceById(
        jdbc:Client? jdbcClient,
        string resourceType,
        string resourceId,
        string? sinceFilter = ()
    ) returns json|error {
        jdbc:Client jc = check utils:getValidatedJdbcClient(jdbcClient);

        sql:ParameterizedQuery q;
        string normalizedDbType = utils:dbType.toLowerAscii().trim();
        if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
            q = `SELECT fhir_id, CAST(resource_json AS TEXT) AS resource_json, version_id, last_updated
                 FROM resources
                 WHERE fhir_id = ${resourceId} AND resource_type = ${resourceType} AND is_deleted = FALSE`;
            if sinceFilter is string {
                string ts = regexp:replaceAll(re `T`, sinceFilter, " ");
                ts = regexp:replaceAll(re `Z$`, ts, "");
                q = sql:queryConcat(q, ` AND last_updated > ${ts}::timestamptz`);
            }
            PgResourceRow|sql:Error row = jc->queryRow(q);
            if row is sql:NoRowsError {
                return error(string `${resourceType}/${resourceId} not found`);
            }
            if row is sql:Error {
                return row;
            }
            return enrichMeta(row.resource_json, row.version_id, row.last_updated);
        } else {
            q = `SELECT "fhir_id", "resource_json", "version_id", "last_updated"
                 FROM "resources"
                 WHERE "fhir_id" = ${resourceId} AND "resource_type" = ${resourceType} AND "is_deleted" = FALSE`;
            if sinceFilter is string {
                string ts = regexp:replaceAll(re `T`, sinceFilter, " ");
                ts = regexp:replaceAll(re `Z$`, ts, "");
                q = sql:queryConcat(q, ` AND "last_updated" > ${ts}`);
            }
            H2ResourceRow|sql:Error row = jc->queryRow(q);
            if row is sql:NoRowsError {
                return error(string `${resourceType}/${resourceId} not found`);
            }
            if row is sql:Error {
                return row;
            }
            return enrichMeta(row.resource_json, row.version_id, row.last_updated);
        }
    }

    // ── Search resources ────────────────────────────────────────────────────

    public isolated function searchResources(
        jdbc:Client? jdbcClient,
        string resourceType,
        map<string[]> queryParams,
        r4:PaginationContext? paginationContext = ()
    ) returns json|error {
        jdbc:Client jc = check utils:getValidatedJdbcClient(jdbcClient);

        // Pagination
        int pageSize = 20;
        string[]? countParam = queryParams["_count"];
        if countParam is string[] && countParam.length() > 0 {
            int|error pc = int:fromString(countParam[0]);
            if pc is int && pc > 0 {
                pageSize = pc;
            }
        }
        int offset = 0;
        if paginationContext is r4:PaginationContext {
            offset = (paginationContext.page - 1) * pageSize;
        }

        boolean isPostgres = isPostgresDb();

        // Base query
        sql:ParameterizedQuery baseQ;
        if isPostgres {
            baseQ = `SELECT r.fhir_id, CAST(r.resource_json AS TEXT) AS resource_json, r.version_id, r.last_updated
                     FROM resources r
                     WHERE r.resource_type = ${resourceType} AND r.is_deleted = FALSE`;
        } else {
            baseQ = `SELECT r."fhir_id", r."resource_json", r."version_id", r."last_updated"
                     FROM "resources" r
                     WHERE r."resource_type" = ${resourceType} AND r."is_deleted" = FALSE`;
        }

        // Append one EXISTS clause per search parameter
        foreach var [rawKey, values] in queryParams.entries() {
            if values.length() == 0 { continue; }

            // Split param name from modifier (e.g. "name:exact" → ["name", "exact"])
            string paramName = rawKey;
            string modifier  = "";
            int? colonIdx = rawKey.indexOf(":");
            if colonIdx is int {
                paramName = rawKey.substring(0, colonIdx);
                modifier  = rawKey.substring(colonIdx + 1);
            }

            // ── Special / global params ───────────────────────────────────
            if paramName == "_id" {
                string idVal = values[0];
                if isPostgres {
                    baseQ = sql:queryConcat(baseQ, ` AND r.fhir_id = ${idVal}`);
                } else {
                    baseQ = sql:queryConcat(baseQ, ` AND r."fhir_id" = ${idVal}`);
                }
                continue;
            }
            if paramName == "_lastUpdated" {
                sql:ParameterizedQuery cond = buildLastUpdatedCond(values[0], isPostgres);
                baseQ = sql:queryConcat(baseQ, ` AND `, cond);
                continue;
            }
            if paramName == "_profile" {
                // Stored as uri param under the name "_profile"
                if isPostgres {
                    baseQ = sql:queryConcat(baseQ, ` AND EXISTS (SELECT 1 FROM sp_uri su WHERE su.resource_id = r.fhir_id AND su.resource_type = ${resourceType} AND su.param_name = '_profile' AND su.value = ${values[0]})`);
                } else {
                    baseQ = sql:queryConcat(baseQ, ` AND EXISTS (SELECT 1 FROM "sp_uri" su WHERE su."resource_id" = r."fhir_id" AND su."resource_type" = ${resourceType} AND su."param_name" = '_profile' AND su."value" = ${values[0]})`);
                }
                continue;
            }
            if paramName == "_tag" || paramName == "_security" {
                string[] tokenParts = regexp:split(re `\|`, values[0]);
                if isPostgres {
                    if tokenParts.length() == 2 {
                        baseQ = sql:queryConcat(baseQ, ` AND EXISTS (SELECT 1 FROM sp_token st WHERE st.resource_id = r.fhir_id AND st.resource_type = ${resourceType} AND st.param_name = ${paramName} AND st.system = ${tokenParts[0]} AND st.code = ${tokenParts[1]})`);
                    } else {
                        baseQ = sql:queryConcat(baseQ, ` AND EXISTS (SELECT 1 FROM sp_token st WHERE st.resource_id = r.fhir_id AND st.resource_type = ${resourceType} AND st.param_name = ${paramName} AND st.code = ${values[0]})`);
                    }
                } else {
                    if tokenParts.length() == 2 {
                        baseQ = sql:queryConcat(baseQ, ` AND EXISTS (SELECT 1 FROM "sp_token" st WHERE st."resource_id" = r."fhir_id" AND st."resource_type" = ${resourceType} AND st."param_name" = ${paramName} AND st."system" = ${tokenParts[0]} AND st."code" = ${tokenParts[1]})`);
                    } else {
                        baseQ = sql:queryConcat(baseQ, ` AND EXISTS (SELECT 1 FROM "sp_token" st WHERE st."resource_id" = r."fhir_id" AND st."resource_type" = ${resourceType} AND st."param_name" = ${paramName} AND st."code" = ${values[0]})`);
                    }
                }
                continue;
            }
            if paramName == "_text" || paramName == "_content" {
                if isPostgres {
                    baseQ = sql:queryConcat(baseQ, ` AND r.search_text @@ plainto_tsquery('english', ${values[0]})`);
                } else {
                    // H2 fallback: simple LIKE on resource_json clob
                    string likeVal = "%" + values[0] + "%";
                    baseQ = sql:queryConcat(baseQ, ` AND r."resource_json" LIKE ${likeVal}`);
                }
                continue;
            }
            if paramName.startsWith("_") {
                continue; // Other control params (_sort, _count, _include etc.) handled separately
            }

            // ── Standard search param ─────────────────────────────────────
            string?|error paramTypeResult = utils:getParamType(jc, resourceType, paramName);
            if paramTypeResult is error {
                log:printWarn(string `Failed to look up param type for ${resourceType}.${paramName}: ${paramTypeResult.message()}`);
                continue;
            }
            string? paramType = paramTypeResult;
            if paramType is () {
                log:printDebug(string `Unknown search param: ${resourceType}.${paramName}, skipping`);
                continue;
            }

            // :missing modifier — handled independently of type
            if modifier == "missing" {
                boolean missing = values[0] == "true";
                sql:ParameterizedQuery existsPart = buildExistsByType(paramName, paramType, resourceType, isPostgres, "r");
                if missing {
                    baseQ = sql:queryConcat(baseQ, ` AND NOT EXISTS (`, existsPart, `)`);
                } else {
                    baseQ = sql:queryConcat(baseQ, ` AND EXISTS (`, existsPart, `)`);
                }
                continue;
            }

            // OR: comma-separated values → multiple EXISTS conditions joined with OR
            string[] orValues = regexp:split(re `,`, values[0]);
            if orValues.length() > 1 {
                // Build the OR group separately so we can drop the entire AND
                // when no branch produces a valid condition — flipping `first`
                // before validating `orCond` would otherwise leak a leading
                // " OR " into the SQL.
                sql:ParameterizedQuery orGroup = ``;
                boolean first = true;
                foreach string orVal in orValues {
                    sql:ParameterizedQuery|error orCond = buildExistsCondition(paramName, paramType, modifier, [orVal], resourceType, isPostgres);
                    if orCond is error { continue; }
                    if first {
                        orGroup = sql:queryConcat(`EXISTS (`, orCond, `)`);
                        first = false;
                    } else {
                        orGroup = sql:queryConcat(orGroup, ` OR EXISTS (`, orCond, `)`);
                    }
                }
                if !first {
                    baseQ = sql:queryConcat(baseQ, ` AND (`, orGroup, `)`);
                }
            } else {
                sql:ParameterizedQuery|error cond = buildExistsCondition(paramName, paramType, modifier, values, resourceType, isPostgres);
                if cond is sql:ParameterizedQuery {
                    baseQ = sql:queryConcat(baseQ, ` AND EXISTS (`, cond, `)`);
                }
            }
        }

        // Ordering + pagination
        if isPostgres {
            baseQ = sql:queryConcat(baseQ, ` ORDER BY r.fhir_id LIMIT ${pageSize} OFFSET ${offset}`);
        } else {
            baseQ = sql:queryConcat(baseQ, ` ORDER BY r."fhir_id" LIMIT ${pageSize} OFFSET ${offset}`);
        }

        // Execute and assemble bundle
        stream<PgResourceRow, sql:Error?> rows = jc->query(baseQ);
        json[] entries = [];
        check from PgResourceRow row in rows
            do {
                json enriched = check enrichMeta(row.resource_json, row.version_id, row.last_updated);
                entries.push(buildBundleEntry(enriched, resourceType, row.fhir_id));
            };

        // _include / _revinclude
        string[]? includeParams  = queryParams["_include"];
        string[]? rIncludeParams = queryParams["_revinclude"];
        if includeParams is string[] {
            check appendIncludes(jc, entries, resourceType, includeParams, false, isPostgres);
        }
        if rIncludeParams is string[] {
            check appendIncludes(jc, entries, resourceType, rIncludeParams, true, isPostgres);
        }

        int total = check getResourceCount(jc, resourceType, queryParams, isPostgres);
        return buildBundle(entries, total, pageSize, offset, resourceType, queryParams);
    }

    // ── Read all resources (no search filters) ──────────────────────────────

    public isolated function readAllResources(
        jdbc:Client? jdbcClient,
        string resourceType,
        r4:PaginationContext? paginationContext = ()
    ) returns json|error {
        return self.searchResources(jdbcClient, resourceType, {}, paginationContext);
    }

    // ── Resource existence check ────────────────────────────────────────────

    public isolated function resourceExists(
        jdbc:Client? jdbcClient,
        string resourceType,
        string resourceId
    ) returns boolean|error {
        jdbc:Client jc = check utils:getValidatedJdbcClient(jdbcClient);
        sql:ParameterizedQuery q;
        if isPostgresDb() {
            q = `SELECT 1 AS cnt FROM resources WHERE fhir_id = ${resourceId} AND resource_type = ${resourceType} AND is_deleted = FALSE`;
        } else {
            q = `SELECT 1 AS cnt FROM "resources" WHERE "fhir_id" = ${resourceId} AND "resource_type" = ${resourceType} AND "is_deleted" = FALSE`;
        }
        CountRow|sql:Error row = jc->queryRow(q);
        return !(row is sql:NoRowsError) && !(row is sql:Error);
    }

    // ── Get count ───────────────────────────────────────────────────────────

    public isolated function getResourceCount(
        jdbc:Client? jdbcClient,
        string resourceType,
        map<string[]> queryParams = {}
    ) returns int|error {
        jdbc:Client jc = check utils:getValidatedJdbcClient(jdbcClient);
        return getResourceCount(jc, resourceType, queryParams, isPostgresDb());
    }

    // ── _include / _revinclude helpers ──────────────────────────────────────

    public isolated function readResourceReferences(
        jdbc:Client? jdbcClient,
        string resourceType,
        string resourceId,
        boolean reverse
    ) returns json[]|error {
        jdbc:Client jc = check utils:getValidatedJdbcClient(jdbcClient);
        return fetchReferences(jc, resourceType, resourceId, reverse, isPostgresDb());
    }
}

// ─── Exists condition builders ────────────────────────────────────────────────

isolated function buildExistsCondition(
    string paramName,
    string paramType,
    string modifier,
    string[] values,
    string resourceType,
    boolean isPostgres
) returns sql:ParameterizedQuery|error {
    string v = values[0];
    match paramType {
        "string" => {
            return buildStringExists(paramName, modifier, v, resourceType, isPostgres);
        }
        "token" => {
            return buildTokenExists(paramName, modifier, v, resourceType, isPostgres);
        }
        "date" => {
            return buildDateExists(paramName, v, resourceType, isPostgres);
        }
        "reference" => {
            return buildReferenceExists(paramName, modifier, v, resourceType, isPostgres);
        }
        "uri" => {
            return buildUriExists(paramName, modifier, v, resourceType, isPostgres);
        }
        "number" => {
            return buildNumberExists(paramName, v, resourceType, isPostgres);
        }
        "quantity" => {
            return buildQuantityExists(paramName, v, resourceType, isPostgres);
        }
        _ => {
            // Fall back to string search
            return buildStringExists(paramName, modifier, v, resourceType, isPostgres);
        }
    }
}

// Returns an EXISTS subquery that checks whether any row exists for paramName
// (used for :missing modifier — does not filter by value).
isolated function buildExistsByType(
    string paramName,
    string paramType,
    string resourceType,
    boolean isPostgres,
    string alias
) returns sql:ParameterizedQuery {
    string tbl = spTableForType(paramType, isPostgres);
    string ridCol = isPostgres ? "resource_id" : string `"resource_id"`;
    string rtCol  = isPostgres ? "resource_type" : string `"resource_type"`;
    string pnCol  = isPostgres ? "param_name"  : string `"param_name"`;
    string ridRef = isPostgres ? string `${alias}.fhir_id` : string `${alias}."fhir_id"`;
    return `SELECT 1 FROM ${tbl} s WHERE s.${ridCol} = ${ridRef} AND s.${rtCol} = ${resourceType} AND s.${pnCol} = ${paramName}`;
}

isolated function spTableForType(string paramType, boolean isPostgres) returns string {
    string base = match paramType {
        "string"    => "sp_string"
        "token"     => "sp_token"
        "date"      => "sp_date"
        "number"    => "sp_number"
        "quantity"  => "sp_quantity"
        "uri"       => "sp_uri"
        "reference" => "sp_reference"
        _           => "sp_string"
    };
    return isPostgres ? base : string `"${base}"`;
}

// ── String ────────────────────────────────────────────────────────────────────

isolated function buildStringExists(
    string paramName,
    string modifier,
    string value,
    string resourceType,
    boolean isPostgres
) returns sql:ParameterizedQuery {
    if isPostgres {
        if modifier == "exact" {
            return `SELECT 1 FROM sp_string s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_exact = ${value}`;
        } else if modifier == "contains" {
            string likeVal = "%" + value.toLowerAscii() + "%";
            return `SELECT 1 FROM sp_string s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_lower LIKE ${likeVal}`;
        } else {
            string likeVal = value.toLowerAscii() + "%";
            return `SELECT 1 FROM sp_string s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_lower LIKE ${likeVal}`;
        }
    } else {
        if modifier == "exact" {
            return `SELECT 1 FROM "sp_string" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."value_exact" = ${value}`;
        } else {
            string likeVal = modifier == "contains"
                ? "%" + value.toLowerAscii() + "%"
                : value.toLowerAscii() + "%";
            return `SELECT 1 FROM "sp_string" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND LOWER(s."value_exact") LIKE ${likeVal}`;
        }
    }
}

// ── Token ─────────────────────────────────────────────────────────────────────

isolated function buildTokenExists(
    string paramName,
    string modifier,
    string value,
    string resourceType,
    boolean isPostgres
) returns sql:ParameterizedQuery {
    if modifier == "text" {
        string likeVal = "%" + value.toLowerAscii() + "%";
        if isPostgres {
            return `SELECT 1 FROM sp_token s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND LOWER(s.display) LIKE ${likeVal}`;
        }
        return `SELECT 1 FROM "sp_token" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND LOWER(s."display") LIKE ${likeVal}`;
    }
    if modifier == "not" {
        // :not — resource must NOT have this token
        if isPostgres {
            return `SELECT 1 FROM sp_token s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.code != ${value}`;
        }
        return `SELECT 1 FROM "sp_token" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."code" != ${value}`;
    }

    // system|code splitting
    string[] parts = regexp:split(re `\|`, value);
    if parts.length() == 2 {
        string sys  = parts[0];
        string code = parts[1];
        if sys.length() == 0 {
            // |code — code only
            if isPostgres {
                return `SELECT 1 FROM sp_token s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.code = ${code}`;
            }
            return `SELECT 1 FROM "sp_token" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."code" = ${code}`;
        }
        if code.length() == 0 {
            // system| — system only
            if isPostgres {
                return `SELECT 1 FROM sp_token s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.system = ${sys}`;
            }
            return `SELECT 1 FROM "sp_token" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."system" = ${sys}`;
        }
        if isPostgres {
            return `SELECT 1 FROM sp_token s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.system = ${sys} AND s.code = ${code}`;
        }
        return `SELECT 1 FROM "sp_token" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."system" = ${sys} AND s."code" = ${code}`;
    }
    // No pipe — code only
    if isPostgres {
        return `SELECT 1 FROM sp_token s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.code = ${value}`;
    }
    return `SELECT 1 FROM "sp_token" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."code" = ${value}`;
}

// ── Date ──────────────────────────────────────────────────────────────────────

// FHIR comparator prefixes → SQL operators on value_low / value_high.
// Both the stored value and the search value are ranges; we use intersection logic.
isolated function buildDateExists(
    string paramName,
    string rawValue,
    string resourceType,
    boolean isPostgres
) returns sql:ParameterizedQuery {
    [string, string] [prefix, dateStr] = extractComparatorPrefix(rawValue);
    [string, string, string] [searchLow, searchHigh, _] = utils:expandDateRange(dateStr);

    sql:ParameterizedQuery inner;
    if isPostgres {
        inner = match prefix {
            "eq"  => `SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_low <= ${searchHigh}::timestamptz AND s.value_high >= ${searchLow}::timestamptz`
            "ne"  => `SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND NOT (s.value_low <= ${searchHigh}::timestamptz AND s.value_high >= ${searchLow}::timestamptz)`
            "gt"  => `SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_low > ${searchHigh}::timestamptz`
            "lt"  => `SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_high < ${searchLow}::timestamptz`
            "ge"  => `SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_high >= ${searchLow}::timestamptz`
            "le"  => `SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_low <= ${searchHigh}::timestamptz`
            "sa"  => `SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_low > ${searchHigh}::timestamptz`
            "eb"  => `SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_high < ${searchLow}::timestamptz`
            _     => `SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_low <= ${searchHigh}::timestamptz AND s.value_high >= ${searchLow}::timestamptz`
        };
    } else {
        string slFmt = utils:formatTimestampForDb(searchLow);
        string shFmt = utils:formatTimestampForDb(searchHigh);
        inner = match prefix {
            "gt" => `SELECT 1 FROM "sp_date" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."value_low" > ${shFmt}`
            "lt" => `SELECT 1 FROM "sp_date" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."value_high" < ${slFmt}`
            "ge" => `SELECT 1 FROM "sp_date" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."value_high" >= ${slFmt}`
            "le" => `SELECT 1 FROM "sp_date" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."value_low" <= ${shFmt}`
            _    => `SELECT 1 FROM "sp_date" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."value_low" <= ${shFmt} AND s."value_high" >= ${slFmt}`
        };
    }
    return inner;
}

// ── Number ────────────────────────────────────────────────────────────────────

isolated function buildNumberExists(
    string paramName,
    string rawValue,
    string resourceType,
    boolean isPostgres
) returns sql:ParameterizedQuery|error {
    [string, string] [prefix, numStr] = extractComparatorPrefix(rawValue);
    decimal|error parsed = decimal:fromString(numStr);
    if parsed is error { return parsed; }
    decimal v = parsed;

    if isPostgres {
        return match prefix {
            "gt" => `SELECT 1 FROM sp_number s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_high > ${v}`
            "lt" => `SELECT 1 FROM sp_number s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_low < ${v}`
            "ge" => `SELECT 1 FROM sp_number s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_high >= ${v}`
            "le" => `SELECT 1 FROM sp_number s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_low <= ${v}`
            "ne" => `SELECT 1 FROM sp_number s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND NOT (s.value_low <= ${v} AND s.value_high >= ${v})`
            _    => `SELECT 1 FROM sp_number s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_low <= ${v} AND s.value_high >= ${v}`
        };
    } else {
        return match prefix {
            "gt" => `SELECT 1 FROM "sp_number" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."value_high" > ${v}`
            "lt" => `SELECT 1 FROM "sp_number" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."value_low" < ${v}`
            _    => `SELECT 1 FROM "sp_number" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."value_low" <= ${v} AND s."value_high" >= ${v}`
        };
    }
}

// ── Quantity ──────────────────────────────────────────────────────────────────

isolated function buildQuantityExists(
    string paramName,
    string rawValue,
    string resourceType,
    boolean isPostgres
) returns sql:ParameterizedQuery|error {
    // Format: [prefix]value[|system|code]
    [string, string] [prefix, rest] = extractComparatorPrefix(rawValue);
    string[] qParts = regexp:split(re `\|`, rest);
    decimal|error parsedVal = decimal:fromString(qParts[0]);
    if parsedVal is error { return parsedVal; }
    decimal v = parsedVal;

    string? sys  = qParts.length() > 1 && qParts[1].length() > 0 ? qParts[1] : ();
    string? code = qParts.length() > 2 && qParts[2].length() > 0 ? qParts[2] : ();

    if isPostgres {
        if sys is string && code is string {
            return match prefix {
                "gt" => `SELECT 1 FROM sp_quantity s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.system = ${sys} AND s.code = ${code} AND s.value_high > ${v}`
                "lt" => `SELECT 1 FROM sp_quantity s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.system = ${sys} AND s.code = ${code} AND s.value_low < ${v}`
                _    => `SELECT 1 FROM sp_quantity s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.system = ${sys} AND s.code = ${code} AND s.value_low <= ${v} AND s.value_high >= ${v}`
            };
        }
        return match prefix {
            "gt" => `SELECT 1 FROM sp_quantity s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_high > ${v}`
            "lt" => `SELECT 1 FROM sp_quantity s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_low < ${v}`
            _    => `SELECT 1 FROM sp_quantity s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value_low <= ${v} AND s.value_high >= ${v}`
        };
    } else {
        return `SELECT 1 FROM "sp_quantity" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."value_low" <= ${v} AND s."value_high" >= ${v}`;
    }
}

// ── Reference ─────────────────────────────────────────────────────────────────

isolated function buildReferenceExists(
    string paramName,
    string modifier,
    string value,
    string resourceType,
    boolean isPostgres
) returns sql:ParameterizedQuery {
    if modifier == "identifier" {
        string[] idParts = regexp:split(re `\|`, value);
        string sys = idParts.length() == 2 ? idParts[0] : "";
        string val = idParts.length() == 2 ? idParts[1] : idParts[0];
        if isPostgres {
            return `SELECT 1 FROM sp_reference s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.identifier_system = ${sys} AND s.identifier_value = ${val}`;
        }
        return `SELECT 1 FROM "sp_reference" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."identifier_system" = ${sys} AND s."identifier_value" = ${val}`;
    }

    if value.includes("/") {
        string[] parts = regexp:split(re `/`, value);
        string targetType = parts[0];
        string targetId   = parts.length() > 1 ? parts[1] : "";
        if isPostgres {
            return `SELECT 1 FROM sp_reference s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.target_type = ${targetType} AND s.target_id = ${targetId}`;
        }
        return `SELECT 1 FROM "sp_reference" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."target_type" = ${targetType} AND s."target_id" = ${targetId}`;
    }
    // Type-restricted modifier e.g. subject:Patient=123
    if modifier.length() > 0 {
        if isPostgres {
            return `SELECT 1 FROM sp_reference s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.target_type = ${modifier} AND s.target_id = ${value}`;
        }
        return `SELECT 1 FROM "sp_reference" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."target_type" = ${modifier} AND s."target_id" = ${value}`;
    }
    if isPostgres {
        return `SELECT 1 FROM sp_reference s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.target_id = ${value}`;
    }
    return `SELECT 1 FROM "sp_reference" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."target_id" = ${value}`;
}

// ── URI ───────────────────────────────────────────────────────────────────────

isolated function buildUriExists(
    string paramName,
    string modifier,
    string value,
    string resourceType,
    boolean isPostgres
) returns sql:ParameterizedQuery {
    if modifier == "below" {
        string likeVal = value + "%";
        if isPostgres {
            return `SELECT 1 FROM sp_uri s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value LIKE ${likeVal}`;
        }
        return `SELECT 1 FROM "sp_uri" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."value" LIKE ${likeVal}`;
    }
    if isPostgres {
        return `SELECT 1 FROM sp_uri s WHERE s.resource_id = r.fhir_id AND s.resource_type = ${resourceType} AND s.param_name = ${paramName} AND s.value = ${value}`;
    }
    return `SELECT 1 FROM "sp_uri" s WHERE s."resource_id" = r."fhir_id" AND s."resource_type" = ${resourceType} AND s."param_name" = ${paramName} AND s."value" = ${value}`;
}

// ─── _lastUpdated condition ───────────────────────────────────────────────────

isolated function buildLastUpdatedCond(string rawValue, boolean isPostgres) returns sql:ParameterizedQuery {
    [string, string] [prefix, dateStr] = extractComparatorPrefix(rawValue);
    [string, string, string] [searchLow, searchHigh, _] = utils:expandDateRange(dateStr);
    if isPostgres {
        return match prefix {
            "gt" => `r.last_updated > ${searchHigh}::timestamptz`
            "lt" => `r.last_updated < ${searchLow}::timestamptz`
            "ge" => `r.last_updated >= ${searchLow}::timestamptz`
            "le" => `r.last_updated <= ${searchHigh}::timestamptz`
            "ne" => `NOT (r.last_updated >= ${searchLow}::timestamptz AND r.last_updated <= ${searchHigh}::timestamptz)`
            _    => `r.last_updated >= ${searchLow}::timestamptz AND r.last_updated <= ${searchHigh}::timestamptz`
        };
    } else {
        string slFmt = utils:formatTimestampForDb(searchLow);
        string shFmt = utils:formatTimestampForDb(searchHigh);
        return match prefix {
            "gt" => `r."last_updated" > ${shFmt}`
            "lt" => `r."last_updated" < ${slFmt}`
            _    => `r."last_updated" >= ${slFmt} AND r."last_updated" <= ${shFmt}`
        };
    }
}

// ─── Count query ──────────────────────────────────────────────────────────────

isolated function getResourceCount(
    jdbc:Client jc,
    string resourceType,
    map<string[]> queryParams,
    boolean isPostgres
) returns int|error {
    sql:ParameterizedQuery q;
    if isPostgres {
        q = `SELECT COUNT(*) AS cnt FROM resources r WHERE r.resource_type = ${resourceType} AND r.is_deleted = FALSE`;
    } else {
        q = `SELECT COUNT(*) AS cnt FROM "resources" r WHERE r."resource_type" = ${resourceType} AND r."is_deleted" = FALSE`;
    }
    // Reuse same WHERE logic (simplified — no pagination). Keep underscore
    // params aligned with searchResources so total matches the page contents.
    final string[] countableUnderscore = ["_id", "_lastUpdated", "_profile", "_tag", "_security", "_text", "_content"];
    foreach var [rawKey, values] in queryParams.entries() {
        if values.length() == 0 { continue; }
        if rawKey.startsWith("_") && countableUnderscore.indexOf(rawKey) is () { continue; }
        string paramName = rawKey;
        string modifier  = "";
        int? colonIdx = rawKey.indexOf(":");
        if colonIdx is int {
            paramName = rawKey.substring(0, colonIdx);
            modifier  = rawKey.substring(colonIdx + 1);
        }
        string?|error pt = utils:getParamType(jc, resourceType, paramName);
        if pt is error || pt is () { continue; }
        sql:ParameterizedQuery|error cond = buildExistsCondition(paramName, pt, modifier, values, resourceType, isPostgres);
        if cond is sql:ParameterizedQuery {
            q = sql:queryConcat(q, ` AND EXISTS (`, cond, `)`);
        }
    }
    CountRow|sql:Error row = jc->queryRow(q);
    if row is sql:Error {
        return row;
    }
    return row.cnt;
}

// ─── _include / _revinclude ───────────────────────────────────────────────────

isolated function appendIncludes(
    jdbc:Client jc,
    json[] entries,
    string sourceType,
    string[] includeSpecs,
    boolean reverse,
    boolean isPostgres
) returns error? {
    // Collect IDs from already-matched resources
    string[] sourceIds = [];
    foreach json entry in entries {
        if entry is map<json> {
            json res = (<map<json>>entry)["resource"];
            if res is map<json> {
                json id = (<map<json>>res)["id"];
                if id is string { sourceIds.push(id); }
            }
        }
    }
    if sourceIds.length() == 0 { return; }

    foreach string spec in includeSpecs {
        // Format: SourceType:paramName[:targetType]
        string[] parts = regexp:split(re `:`, spec);
        if parts.length() < 2 { continue; }
        string paramName   = parts[1];
        string? targetType = parts.length() >= 3 ? parts[2] : ();

        foreach string srcId in sourceIds {
            json[] included = check fetchReferences(jc, sourceType, srcId, reverse, isPostgres);
            foreach json inc in included {
                entries.push(inc);
            }
        }
    }
}

isolated function fetchReferences(
    jdbc:Client jc,
    string resourceType,
    string resourceId,
    boolean reverse,
    boolean isPostgres
) returns json[]|error {
    sql:ParameterizedQuery q;
    if !reverse {
        // _include: fetch resources that this resource points to
        if isPostgres {
            q = `SELECT DISTINCT r.fhir_id, CAST(r.resource_json AS TEXT) AS resource_json, r.version_id, r.last_updated
                 FROM sp_reference sr
                 JOIN resources r ON r.fhir_id = sr.target_id AND r.resource_type = sr.target_type
                 WHERE sr.resource_id = ${resourceId} AND sr.resource_type = ${resourceType} AND r.is_deleted = FALSE`;
        } else {
            q = `SELECT DISTINCT r."fhir_id", r."resource_json", r."version_id", r."last_updated"
                 FROM "sp_reference" sr
                 JOIN "resources" r ON r."fhir_id" = sr."target_id" AND r."resource_type" = sr."target_type"
                 WHERE sr."resource_id" = ${resourceId} AND sr."resource_type" = ${resourceType} AND r."is_deleted" = FALSE`;
        }
    } else {
        // _revinclude: fetch resources that point to this resource
        if isPostgres {
            q = `SELECT DISTINCT r.fhir_id, CAST(r.resource_json AS TEXT) AS resource_json, r.version_id, r.last_updated
                 FROM sp_reference sr
                 JOIN resources r ON r.fhir_id = sr.resource_id AND r.resource_type = sr.resource_type
                 WHERE sr.target_id = ${resourceId} AND sr.target_type = ${resourceType} AND r.is_deleted = FALSE`;
        } else {
            q = `SELECT DISTINCT r."fhir_id", r."resource_json", r."version_id", r."last_updated"
                 FROM "sp_reference" sr
                 JOIN "resources" r ON r."fhir_id" = sr."resource_id" AND r."resource_type" = sr."resource_type"
                 WHERE sr."target_id" = ${resourceId} AND sr."target_type" = ${resourceType} AND r."is_deleted" = FALSE`;
        }
    }

    stream<PgResourceRow, sql:Error?> rows = jc->query(q);
    json[] results = [];
    check from PgResourceRow row in rows
        do {
            json enriched = check enrichMeta(row.resource_json, row.version_id, row.last_updated);
            // Derive resourceType from the JSON itself
            string rtype = "";
            if enriched is map<json> {
                json rt = (<map<json>>enriched)["resourceType"];
                if rt is string { rtype = rt; }
            }
            results.push(buildBundleEntry(enriched, rtype, row.fhir_id));
        };
    return results;
}

// ─── Bundle assembly ──────────────────────────────────────────────────────────

isolated function buildBundle(
    json[] entries,
    int total,
    int pageSize,
    int offset,
    string resourceType,
    map<string[]> queryParams
) returns json {
    int page = offset / pageSize + 1;
    string selfLink = buildSearchUrl(resourceType, queryParams, page, pageSize);
    json bundle = {
        resourceType: "Bundle",
        'type: "searchset",
        total: total,
        link: [
            {relation: "self", url: selfLink},
            {relation: "first", url: buildSearchUrl(resourceType, queryParams, 1, pageSize)}
        ],
        entry: entries
    };
    return bundle;
}

isolated function buildBundleEntry(json resource, string resourceType, string fhirId) returns json {
    return {
        fullUrl: string `${baseUrl}/${resourceType}/${fhirId}`,
        resource: resource,
        search: {mode: "match"}
    };
}

isolated function buildSearchUrl(string resourceType, map<string[]> params, int page, int pageSize) returns string {
    string url = string `${baseUrl}/${resourceType}?_page=${page}&_count=${pageSize}`;
    foreach var [k, vs] in params.entries() {
        if k == "_page" || k == "_count" { continue; }
        foreach string v in vs {
            url = url + string `&${k}=${v}`;
        }
    }
    return url;
}

// ─── Meta enrichment ─────────────────────────────────────────────────────────

isolated function enrichMeta(string jsonStr, int versionId, time:Civil lastUpdated) returns json|error {
    json res = check jsonStr.fromJsonString();
    if !(res is map<json>) { return res; }
    map<json> m = <map<json>>res;
    map<json> meta = m["meta"] is map<json> ? <map<json>>m["meta"] : {};
    meta["versionId"]   = versionId.toString();
    meta["lastUpdated"] = utils:formatTimestampISO8601(lastUpdated);
    m["meta"] = meta;
    return m;
}

// ─── Comparator prefix parser ─────────────────────────────────────────────────

isolated function extractComparatorPrefix(string raw) returns [string, string] {
    string[] prefixes = ["eq","ne","gt","lt","ge","le","sa","eb","ap"];
    foreach string p in prefixes {
        if raw.startsWith(p) && raw.length() > 2 {
            return [p, raw.substring(2)];
        }
    }
    return ["eq", raw];
}

// ─── DB type helper ───────────────────────────────────────────────────────────

isolated function isPostgresDb() returns boolean {
    string n = utils:dbType.toLowerAscii().trim();
    return n == "postgresql" || n == "postgres";
}
