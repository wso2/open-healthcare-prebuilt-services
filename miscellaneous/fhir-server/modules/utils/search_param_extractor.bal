import ballerina/lang.regexp;
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/health.fhir.r4utils.fhirpath;
import ballerinax/java.jdbc;

// ─── Cache ────────────────────────────────────────────────────────────────────

isolated map<SearchParamExpression[]> searchParamCache = {};

public isolated function getCachedAllSearchParamExpressions(string resourceType) returns SearchParamExpression[]? {
    lock {
        return searchParamCache[resourceType];
    }
}

public isolated function cacheAllSearchParamExpressions(string resourceType, SearchParamExpression[] exprs) {
    lock {
        searchParamCache[resourceType] = exprs.clone();
    }
}

public isolated function clearSearchParamCache() {
    lock {
        searchParamCache.removeAll();
    }
}

// ─── Definition lookup ────────────────────────────────────────────────────────

// Returns ALL search param definitions for the resource type (standard + custom).
public isolated function getAllSearchParamDefinitions(
    jdbc:Client jdbcClient,
    string resourceType
) returns SearchParamExpression[]|error {
    SearchParamExpression[]? cached = getCachedAllSearchParamExpressions(resourceType);
    if cached is SearchParamExpression[] {
        return cached;
    }

    type DefRow record {|string param_name; string param_type; string resource_type; string fhirpath_expr;|};
    sql:ParameterizedQuery q = `SELECT param_name AS param_name, param_type AS param_type,
        resource_type AS resource_type, fhirpath_expr AS fhirpath_expr
        FROM search_param_definitions WHERE resource_type = ${resourceType}`;
    stream<DefRow, sql:Error?> rows = jdbcClient->query(q);

    SearchParamExpression[] exprs = [];
    check from DefRow row in rows
        do {
            exprs.push({
                SEARCH_PARAM_NAME: row.param_name,
                SEARCH_PARAM_TYPE: row.param_type,
                RESOURCE_NAME: row.resource_type,
                EXPRESSION: row.fhirpath_expr
            });
        };

    cacheAllSearchParamExpressions(resourceType, exprs);
    return exprs;
}

// Returns only custom search param definitions.
public isolated function getCustomSearchParamExpressions(
    jdbc:Client jdbcClient,
    string resourceType
) returns SearchParamExpression[]|error {
    type DefRow record {|string param_name; string param_type; string resource_type; string fhirpath_expr;|};
    sql:ParameterizedQuery q = `SELECT param_name AS param_name, param_type AS param_type,
        resource_type AS resource_type, fhirpath_expr AS fhirpath_expr
        FROM search_param_definitions WHERE resource_type = ${resourceType} AND is_custom = TRUE`;
    stream<DefRow, sql:Error?> rows = jdbcClient->query(q);

    SearchParamExpression[] exprs = [];
    check from DefRow row in rows
        do {
            exprs.push({
                SEARCH_PARAM_NAME: row.param_name,
                SEARCH_PARAM_TYPE: row.param_type,
                RESOURCE_NAME: row.resource_type,
                EXPRESSION: row.fhirpath_expr
            });
        };
    return exprs;
}

// Returns the param_type for a single named search param.
public isolated function getParamType(
    jdbc:Client jdbcClient,
    string resourceType,
    string paramName
) returns string?|error {
    SearchParamExpression[]? cached = getCachedAllSearchParamExpressions(resourceType);
    if cached is SearchParamExpression[] {
        foreach SearchParamExpression e in cached {
            if e.SEARCH_PARAM_NAME == paramName {
                return e.SEARCH_PARAM_TYPE;
            }
        }
        return ();
    }
    type Row record {|string param_type;|};
    sql:ParameterizedQuery q = `SELECT param_type FROM search_param_definitions
        WHERE resource_type = ${resourceType} AND param_name = ${paramName} LIMIT 1`;
    Row|sql:Error row = jdbcClient->queryRow(q);
    if row is sql:NoRowsError {
        return ();
    }
    if row is sql:Error {
        return row;
    }
    return row.param_type;
}

// ─── Top-level extraction ─────────────────────────────────────────────────────

// Extracts ALL search params for a resource and returns typed value buckets.
public isolated function extractAllSearchParams(
    jdbc:Client jdbcClient,
    string resourceType,
    json resourceJson
) returns ExtractedSearchParams|error {
    SearchParamExpression[] defs = check getAllSearchParamDefinitions(jdbcClient, resourceType);
    ExtractedSearchParams result = {};

    foreach SearchParamExpression def in defs {
        json[]|error rawValues = extractRawValues(resourceJson, def.EXPRESSION);
        if rawValues is error {
            log:printDebug(string `Extraction failed for ${def.SEARCH_PARAM_NAME}: ${rawValues.message()}`);
            continue;
        }

        foreach json raw in rawValues {
            if raw is () {
                continue;
            }
            classifyAndAppend(def.SEARCH_PARAM_NAME, def.SEARCH_PARAM_TYPE, raw, result);
        }
    }
    return result;
}

// ─── FHIRPath extraction ──────────────────────────────────────────────────────

isolated function extractRawValues(json resourceJson, string expression) returns json[]|error {
    if expression.includes(".where(") {
        return extractFromExtensionWhere(resourceJson, expression);
    }
    json|error result = fhirpath:getValuesFromFhirPath(resourceJson, expression);
    if result is error {
        return result;
    }
    if result is () {
        return [];
    }
    return result is json[] ? result : [result];
}

isolated function extractFromExtensionWhere(json resourceJson, string expression) returns json[]|error {
    int? whereStart = expression.indexOf(".where(url='");
    if whereStart is () {
        return error(string `Unsupported .where() expression: ${expression}`);
    }
    int urlStart = whereStart + ".where(url='".length();
    int? urlEnd = expression.indexOf("')", urlStart);
    if urlEnd is () {
        return error(string `Malformed .where() expression: ${expression}`);
    }
    string extensionUrl = expression.substring(urlStart, urlEnd);

    if !(resourceJson is map<json>) {
        return [];
    }
    json extField = (<map<json>>resourceJson)["extension"];
    if !(extField is json[]) {
        return [];
    }

    json[] results = [];
    foreach json ext in <json[]>extField {
        if !(ext is map<json>) {
            continue;
        }
        map<json> extMap = <map<json>>ext;
        json urlVal = extMap["url"];
        if urlVal is string && urlVal == extensionUrl {
            // Try each value[x] field
            string[] valueKeys = extMap.keys().filter(k => k.startsWith("value"));
            foreach string vk in valueKeys {
                json v = extMap[vk];
                if !(v is ()) {
                    results.push(v);
                }
            }
        }
    }
    return results;
}

// ─── Type routing ─────────────────────────────────────────────────────────────

isolated function classifyAndAppend(
    string paramName,
    string paramType,
    json raw,
    ExtractedSearchParams result
) {
    match paramType {
        "string" => {
            string? s = toStringValue(raw);
            if s is string && s.trim().length() > 0 {
                result.strings.push({paramName, valueExact: s, valueLower: s.toLowerAscii()});
            }
        }
        "token" => {
            SpTokenValue[] tokens = extractTokenValues(paramName, raw);
            foreach SpTokenValue t in tokens {
                result.tokens.push(t);
            }
        }
        "date" => {
            SpDateValue? d = parseDateValue(paramName, raw);
            if d is SpDateValue {
                result.dates.push(d);
            }
        }
        "number" => {
            SpNumberValue? n = parseNumberValue(paramName, raw);
            if n is SpNumberValue {
                result.numbers.push(n);
            }
        }
        "quantity" => {
            SpQuantityValue? q = parseQuantityValue(paramName, raw);
            if q is SpQuantityValue {
                result.quantities.push(q);
            }
        }
        "uri" => {
            string? u = toStringValue(raw);
            if u is string && u.trim().length() > 0 {
                result.uris.push({paramName, value: u});
            }
        }
        "reference" => {
            SpReferenceValue? ref = parseReferenceValue(paramName, raw);
            if ref is SpReferenceValue {
                result.references.push(ref);
            }
        }
        "special" => {
            SpCoordsValue? c = parseCoordsValue(paramName, raw);
            if c is SpCoordsValue {
                result.coords.push(c);
            }
        }
        // composite params are not individually indexed; they rely on their component params.
        _ => {
            log:printDebug(string `Unhandled param type '${paramType}' for ${paramName}`);
        }
    }
}

// ─── Token extraction ─────────────────────────────────────────────────────────

isolated function extractTokenValues(string paramName, json raw) returns SpTokenValue[] {
    SpTokenValue[] out = [];

    if raw is string {
        out.push({paramName, system: (), code: raw, display: ()});
        return out;
    }
    if raw is boolean {
        out.push({paramName, system: (), code: raw.toString(), display: ()});
        return out;
    }
    if !(raw is map<json>) {
        return out;
    }
    map<json> m = <map<json>>raw;

    // CodeableConcept: { coding: [{system, code, display}], text }
    json codingField = m["coding"];
    if codingField is json[] {
        foreach json c in <json[]>codingField {
            if c is map<json> {
                map<json> cm = <map<json>>c;
                out.push({
                    paramName,
                    system:  cm["system"]  is string ? <string>cm["system"]  : (),
                    code:    cm["code"]    is string ? <string>cm["code"]    : (),
                    display: cm["display"] is string ? <string>cm["display"] : ()
                });
            }
        }
        // Also index the text as a display-only token
        json textField = m["text"];
        if textField is string {
            out.push({paramName, system: (), code: (), display: <string>textField});
        }
        return out;
    }

    // Coding: { system, code, display }
    if m.hasKey("system") || m.hasKey("code") {
        out.push({
            paramName,
            system:  m["system"]  is string ? <string>m["system"]  : (),
            code:    m["code"]    is string ? <string>m["code"]    : (),
            display: m["display"] is string ? <string>m["display"] : ()
        });
        return out;
    }

    // Identifier: { system, value }
    if m.hasKey("value") {
        out.push({
            paramName,
            system:  m["system"] is string ? <string>m["system"] : (),
            code:    m["value"]  is string ? <string>m["value"]  : (),
            display: ()
        });
        return out;
    }

    // ContactPoint / code element stored as a map with a "use" key
    json useField = m["use"];
    if useField is string {
        out.push({paramName, system: (), code: <string>useField, display: ()});
    }

    return out;
}

// ─── Date parsing ─────────────────────────────────────────────────────────────

isolated function parseDateValue(string paramName, json raw) returns SpDateValue? {
    string dateStr = "";
    if raw is string {
        dateStr = raw;
    } else if raw is map<json> {
        // Period: { start, end }
        map<json> m = <map<json>>raw;
        string lowStr  = m["start"] is string ? <string>m["start"] : "";
        string highStr = m["end"]   is string ? <string>m["end"]   : lowStr;
        if lowStr == "" {
            return ();
        }
        [string, string, string] [low, high, prec] = expandDateRange(lowStr);
        [string, _, _] [_, highExpanded, _] = highStr != lowStr ? expandDateRange(highStr) : [low, high, prec];
        return {paramName, valueLow: low, valueHigh: highExpanded, valuePrecision: prec};
    } else {
        return ();
    }

    if dateStr.trim().length() == 0 {
        return ();
    }
    [string, string, string] [low, high, prec] = expandDateRange(dateStr);
    return {paramName, valueLow: low, valueHigh: high, valuePrecision: prec};
}

// Expands a partial FHIR date string to an [isoLow, isoHigh, precision] triple.
public isolated function expandDateRange(string dateStr) returns [string, string, string] {
    string s = dateStr.trim();
    // Strip trailing Z / offset for length checks; we keep it in the output
    int len = s.length();

    if len == 4 {
        // YYYY → full year
        return [string `${s}-01-01T00:00:00Z`, string `${s}-12-31T23:59:59Z`, "YEAR"];
    }
    if len == 7 {
        // YYYY-MM → full month
        int year = checkpanic int:fromString(s.substring(0, 4));
        int month = checkpanic int:fromString(s.substring(5, 7));
        int lastDay = daysInMonth(year, month);
        string mm = month < 10 ? string `0${month}` : month.toString();
        string dd = lastDay < 10 ? string `0${lastDay}` : lastDay.toString();
        return [string `${s}-01T00:00:00Z`, string `${s.substring(0,7)}-${dd}T23:59:59Z`, "MONTH"];
    }
    if len == 10 {
        // YYYY-MM-DD
        return [string `${s}T00:00:00Z`, string `${s}T23:59:59Z`, "DAY"];
    }
    // Full datetime — return as-is for both low and high
    return [s, s, "SECOND"];
}

isolated function daysInMonth(int year, int month) returns int {
    int[] days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if month == 2 && ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) {
        return 29;
    }
    return days[month - 1];
}

// ─── Number parsing ───────────────────────────────────────────────────────────

isolated function parseNumberValue(string paramName, json raw) returns SpNumberValue? {
    decimal? d = toDecimalValue(raw);
    if d is () {
        return ();
    }
    // Derive implicit precision range from significant figures (FHIR eq semantics).
    [decimal, decimal] [lo, hi] = implicitRange(d);
    return {paramName, value: d, valueLow: lo, valueHigh: hi};
}

// ─── Quantity parsing ─────────────────────────────────────────────────────────

isolated function parseQuantityValue(string paramName, json raw) returns SpQuantityValue? {
    if !(raw is map<json>) {
        return ();
    }
    map<json> m = <map<json>>raw;
    decimal? v = toDecimalValue(m["value"]);
    if v is () {
        return ();
    }
    [decimal, decimal] [lo, hi] = implicitRange(v);
    string? sys  = m["system"] is string ? <string>m["system"] : ();
    string? code = m["code"]   is string ? <string>m["code"]   : ();
    return {
        paramName,
        value:          v,
        valueLow:       lo,
        valueHigh:      hi,
        system:         sys,
        code:           code,
        canonicalValue: (),   // UCUM canonicalisation is a future enhancement
        canonicalUnits: ()
    };
}

// ─── Reference parsing ────────────────────────────────────────────────────────

isolated function parseReferenceValue(string paramName, json raw) returns SpReferenceValue? {
    if raw is string {
        return splitReference(paramName, raw, ());
    }
    if !(raw is map<json>) {
        return ();
    }
    map<json> m = <map<json>>raw;
    json refField = m["reference"];
    string? display = m["display"] is string ? <string>m["display"] : ();

    if refField is string {
        return splitReference(paramName, refField, display);
    }
    // identifier-only reference
    json idField = m["identifier"];
    if idField is map<json> {
        map<json> idm = <map<json>>idField;
        return {
            paramName,
            targetType:       (),
            targetId:         (),
            targetVersionId:  (),
            targetUrl:        (),
            identifierSystem: idm["system"] is string ? <string>idm["system"] : (),
            identifierValue:  idm["value"]  is string ? <string>idm["value"]  : (),
            display:          display
        };
    }
    return ();
}

isolated function splitReference(string paramName, string refStr, string? display) returns SpReferenceValue {
    // Absolute URL
    if refStr.startsWith("http://") || refStr.startsWith("https://") {
        string[] parts = regexp:split(re `/`, refStr);
        string targetType = parts.length() >= 2 ? parts[parts.length() - 2] : "";
        string targetId   = parts.length() >= 1 ? parts[parts.length() - 1] : "";
        return {
            paramName,
            targetType:       targetType.length() > 0 ? targetType : (),
            targetId:         targetId.length() > 0 ? targetId : (),
            targetVersionId:  (),
            targetUrl:        refStr,
            identifierSystem: (),
            identifierValue:  (),
            display:          display
        };
    }
    // Relative: ResourceType/id or ResourceType/id/_history/vid
    string[] parts = regexp:split(re `/`, refStr);
    string? targetType = parts.length() >= 1 ? parts[0] : ();
    string? targetId   = parts.length() >= 2 ? parts[1] : ();
    int? targetVersion = ();
    if parts.length() >= 4 && parts[2] == "_history" {
        targetVersion = int:fromString(parts[3]) is int ? checkpanic int:fromString(parts[3]) : ();
    }
    return {
        paramName,
        targetType:       targetType,
        targetId:         targetId,
        targetVersionId:  targetVersion,
        targetUrl:        (),
        identifierSystem: (),
        identifierValue:  (),
        display:          display
    };
}

// ─── Coords parsing ───────────────────────────────────────────────────────────

isolated function parseCoordsValue(string paramName, json raw) returns SpCoordsValue? {
    if !(raw is map<json>) {
        return ();
    }
    map<json> m = <map<json>>raw;
    decimal? lat = toDecimalValue(m["latitude"]);
    decimal? lng = toDecimalValue(m["longitude"]);
    if lat is () || lng is () {
        return ();
    }
    return {paramName, latitude: lat, longitude: lng};
}

// ─── Database persistence ─────────────────────────────────────────────────────

// Inserts all extracted search param rows for a resource.
public isolated function saveAllSearchParams(
    jdbc:Client jdbcClient,
    string fhirId,
    string resourceType,
    ExtractedSearchParams params
) returns error? {
    check saveStringParams(jdbcClient, fhirId, resourceType, params.strings);
    check saveTokenParams(jdbcClient, fhirId, resourceType, params.tokens);
    check saveDateParams(jdbcClient, fhirId, resourceType, params.dates);
    check saveNumberParams(jdbcClient, fhirId, resourceType, params.numbers);
    check saveQuantityParams(jdbcClient, fhirId, resourceType, params.quantities);
    check saveUriParams(jdbcClient, fhirId, resourceType, params.uris);
    check saveReferenceParams(jdbcClient, fhirId, resourceType, params.references);
    check saveCoordsParams(jdbcClient, fhirId, resourceType, params.coords);
}

// Deletes all search param rows for a resource (called before re-indexing on update).
public isolated function deleteAllSearchParams(
    jdbc:Client jdbcClient,
    string fhirId,
    string resourceType
) returns error? {
    _ = check jdbcClient->execute(`DELETE FROM sp_string    WHERE resource_id = ${fhirId} AND resource_type = ${resourceType}`);
    _ = check jdbcClient->execute(`DELETE FROM sp_token     WHERE resource_id = ${fhirId} AND resource_type = ${resourceType}`);
    _ = check jdbcClient->execute(`DELETE FROM sp_date      WHERE resource_id = ${fhirId} AND resource_type = ${resourceType}`);
    _ = check jdbcClient->execute(`DELETE FROM sp_number    WHERE resource_id = ${fhirId} AND resource_type = ${resourceType}`);
    _ = check jdbcClient->execute(`DELETE FROM sp_quantity  WHERE resource_id = ${fhirId} AND resource_type = ${resourceType}`);
    _ = check jdbcClient->execute(`DELETE FROM sp_uri       WHERE resource_id = ${fhirId} AND resource_type = ${resourceType}`);
    _ = check jdbcClient->execute(`DELETE FROM sp_reference WHERE resource_id = ${fhirId} AND resource_type = ${resourceType}`);
    _ = check jdbcClient->execute(`DELETE FROM sp_coords    WHERE resource_id = ${fhirId} AND resource_type = ${resourceType}`);
}

isolated function saveStringParams(jdbc:Client c, string id, string rtype, SpStringValue[] rows) returns error? {
    if rows.length() == 0 { return; }
    sql:ParameterizedQuery[] qs = [];
    foreach SpStringValue r in rows {
        qs.push(`INSERT INTO sp_string (resource_id, resource_type, param_name, value_exact, value_lower)
                 VALUES (${id}, ${rtype}, ${r.paramName}, ${r.valueExact}, ${r.valueLower})`);
    }
    _ = check c->batchExecute(qs);
}

isolated function saveTokenParams(jdbc:Client c, string id, string rtype, SpTokenValue[] rows) returns error? {
    if rows.length() == 0 { return; }
    sql:ParameterizedQuery[] qs = [];
    foreach SpTokenValue r in rows {
        qs.push(`INSERT INTO sp_token (resource_id, resource_type, param_name, system, code, display)
                 VALUES (${id}, ${rtype}, ${r.paramName}, ${r.system}, ${r.code}, ${r.display})`);
    }
    _ = check c->batchExecute(qs);
}

isolated function saveDateParams(jdbc:Client c, string id, string rtype, SpDateValue[] rows) returns error? {
    if rows.length() == 0 { return; }
    sql:ParameterizedQuery[] qs = [];
    foreach SpDateValue r in rows {
        qs.push(`INSERT INTO sp_date (resource_id, resource_type, param_name, value_low, value_high, value_precision)
                 VALUES (${id}, ${rtype}, ${r.paramName}, ${r.valueLow}::timestamptz, ${r.valueHigh}::timestamptz, ${r.valuePrecision})`);
    }
    _ = check c->batchExecute(qs);
}

isolated function saveNumberParams(jdbc:Client c, string id, string rtype, SpNumberValue[] rows) returns error? {
    if rows.length() == 0 { return; }
    sql:ParameterizedQuery[] qs = [];
    foreach SpNumberValue r in rows {
        qs.push(`INSERT INTO sp_number (resource_id, resource_type, param_name, value, value_low, value_high)
                 VALUES (${id}, ${rtype}, ${r.paramName}, ${r.value}, ${r.valueLow}, ${r.valueHigh})`);
    }
    _ = check c->batchExecute(qs);
}

isolated function saveQuantityParams(jdbc:Client c, string id, string rtype, SpQuantityValue[] rows) returns error? {
    if rows.length() == 0 { return; }
    sql:ParameterizedQuery[] qs = [];
    foreach SpQuantityValue r in rows {
        qs.push(`INSERT INTO sp_quantity (resource_id, resource_type, param_name, value, value_low, value_high, system, code, canonical_value, canonical_units)
                 VALUES (${id}, ${rtype}, ${r.paramName}, ${r.value}, ${r.valueLow}, ${r.valueHigh}, ${r.system}, ${r.code}, ${r.canonicalValue}, ${r.canonicalUnits})`);
    }
    _ = check c->batchExecute(qs);
}

isolated function saveUriParams(jdbc:Client c, string id, string rtype, SpUriValue[] rows) returns error? {
    if rows.length() == 0 { return; }
    sql:ParameterizedQuery[] qs = [];
    foreach SpUriValue r in rows {
        qs.push(`INSERT INTO sp_uri (resource_id, resource_type, param_name, value)
                 VALUES (${id}, ${rtype}, ${r.paramName}, ${r.value})`);
    }
    _ = check c->batchExecute(qs);
}

isolated function saveReferenceParams(jdbc:Client c, string id, string rtype, SpReferenceValue[] rows) returns error? {
    if rows.length() == 0 { return; }
    sql:ParameterizedQuery[] qs = [];
    foreach SpReferenceValue r in rows {
        qs.push(`INSERT INTO sp_reference (resource_id, resource_type, param_name, target_type, target_id, target_version_id, target_url, identifier_system, identifier_value, display)
                 VALUES (${id}, ${rtype}, ${r.paramName}, ${r.targetType}, ${r.targetId}, ${r.targetVersionId}, ${r.targetUrl}, ${r.identifierSystem}, ${r.identifierValue}, ${r.display})`);
    }
    _ = check c->batchExecute(qs);
}

isolated function saveCoordsParams(jdbc:Client c, string id, string rtype, SpCoordsValue[] rows) returns error? {
    if rows.length() == 0 { return; }
    sql:ParameterizedQuery[] qs = [];
    foreach SpCoordsValue r in rows {
        qs.push(`INSERT INTO sp_coords (resource_id, resource_type, param_name, latitude, longitude)
                 VALUES (${id}, ${rtype}, ${r.paramName}, ${r.latitude}, ${r.longitude})`);
    }
    _ = check c->batchExecute(qs);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

isolated function toStringValue(json v) returns string? {
    if v is string { return v; }
    if v is int|float|decimal { return v.toString(); }
    if v is boolean { return v.toString(); }
    return ();
}

isolated function toDecimalValue(json v) returns decimal? {
    if v is decimal { return v; }
    if v is int     { return <decimal>v; }
    if v is float   { return <decimal>v; }
    if v is string  {
        decimal|error d = decimal:fromString(v);
        return d is decimal ? d : ();
    }
    return ();
}

// Derives the implicit precision range for FHIR number/quantity eq semantics.
// e.g. 100  (3 sig figs) → [99.5,  100.5)
//      5.40 (3 sig figs) → [5.395, 5.405)
isolated function implicitRange(decimal v) returns [decimal, decimal] {
    // half-unit-in-last-place precision
    string s = v.toString();
    int dotIdx = s.indexOf(".");
    int decimalPlaces = dotIdx is int ? (s.length() - dotIdx - 1) : 0;
    decimal half = 0.5d / (10.0d.pow(decimalPlaces));
    return [v - half, v + half];
}

// Expose time utilities used by H2 date param inserts (no ::timestamptz cast).
public isolated function formatTimestampForDb(string iso) returns string {
    // Strip trailing Z and replace T with space for H2 TIMESTAMP literals
    string s = regexp:replaceAll(re `Z$`, iso, "");
    return regexp:replaceAll(re `T`, s, " ");
}
