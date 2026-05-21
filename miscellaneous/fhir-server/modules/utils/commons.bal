import ballerina/lang.regexp;
import ballerina/sql;
import ballerina/time;
import ballerina/uuid;
import ballerinax/java.jdbc;

// ─── Config ───────────────────────────────────────────────────────────────────

public configurable boolean useServerGeneratedIds = false;
public configurable string  dbType                = "h2";

// ─── Constants ────────────────────────────────────────────────────────────────

const string JDBC_NOT_INITIALIZED = "JDBC Client is not initialized";

// ─── Connection helpers ───────────────────────────────────────────────────────

public isolated function getValidatedJdbcClient(jdbc:Client? jdbcClient) returns jdbc:Client|error {
    if jdbcClient is () {
        return error(JDBC_NOT_INITIALIZED);
    }
    return jdbcClient;
}

// ─── ID generation ────────────────────────────────────────────────────────────

public isolated function generateResourceId() returns string {
    string fullUuid = uuid:createType1AsString();
    return regexp:replaceAll(re `-`, fullUuid, "");
}

// ─── Timestamp formatting ─────────────────────────────────────────────────────

public isolated function formatTimestampISO8601(time:Civil ts) returns string {
    decimal seconds = ts.second ?: 0.0d;
    int wholeSec = <int>seconds;
    if wholeSec >= 60 { wholeSec = 59; }
    return string `${ts.year}-${padZero(ts.month)}-${padZero(ts.day)}T${padZero(ts.hour)}:${padZero(ts.minute)}:${padZero(wholeSec)}.000Z`;
}

public isolated function formatTimestamp(time:Civil ts) returns string {
    decimal seconds = ts.second ?: 0.0d;
    int wholeSec = <int>seconds;
    if wholeSec >= 60 { wholeSec = 59; }
    return string `${ts.year}-${padZero(ts.month)}-${padZero(ts.day)} ${padZero(ts.hour)}:${padZero(ts.minute)}:${padZero(wholeSec)}`;
}

public isolated function padZero(int v) returns string {
    return v < 10 ? string `0${v}` : v.toString();
}

// ─── SQL escaping (legacy; prefer parameterised queries) ──────────────────────

public isolated function escapeSql(string value) returns string {
    return regexp:replaceAll(re `'`, value, "''");
}

// ─── RawSQLQuery (kept for any remaining raw-SQL callsites) ───────────────────

public class RawSQLQuery {
    *sql:ParameterizedQuery;
    public final string[] & readonly strings;
    public final sql:Value[] & readonly insertions;

    public isolated function init(string sqlQuery) {
        self.strings     = [sqlQuery].cloneReadOnly();
        self.insertions  = [].cloneReadOnly();
    }
}
