import ballerina/time;

// Kept only for callers that still reference these utilities directly.
// Table-name and column-name helpers from the old per-resource-table design
// have been removed; all DB access now goes through the resources / sp_* tables.

// ─── Date parsing ─────────────────────────────────────────────────────────────

public isolated function parseDateString(string dateStr) returns time:Date|error {
    // Accepts YYYY-MM-DD or YYYY-MM-DDThh:mm:ss[.sss][Z]
    string s = dateStr.trim();
    if s.length() < 10 {
        return error(string `Cannot parse date: ${dateStr}`);
    }
    string datePart = s.substring(0, 10);
    string[] parts = re`-`.split(datePart);
    if parts.length() != 3 {
        return error(string `Cannot parse date: ${dateStr}`);
    }
    int year  = check int:fromString(parts[0]);
    int month = check int:fromString(parts[1]);
    int day   = check int:fromString(parts[2]);
    return {year, month, day};
}
