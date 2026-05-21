// Type definitions for the FHIR server database layer.

// ─── Search parameter definition (loaded from search_param_definitions table) ─

public type SearchParamExpression record {|
    string SEARCH_PARAM_NAME;
    string SEARCH_PARAM_TYPE;
    string RESOURCE_NAME;
    string EXPRESSION;
|};

// ─── Per-type extracted search parameter values ───────────────────────────────
// One record type per sp_* table. Produced by search_param_extractor and
// consumed by the create / update mappers.

public type SpStringValue record {|
    string paramName;
    string valueExact;
    string valueLower;
|};

public type SpTokenValue record {|
    string paramName;
    string? system;
    string? code;
    string? display;
|};

public type SpDateValue record {|
    string paramName;
    string valueLow;   // ISO-8601 timestamp string
    string valueHigh;  // ISO-8601 timestamp string
    string valuePrecision; // YEAR | MONTH | DAY | SECOND
|};

public type SpNumberValue record {|
    string paramName;
    decimal value;
    decimal valueLow;
    decimal valueHigh;
|};

public type SpQuantityValue record {|
    string paramName;
    decimal value;
    decimal valueLow;
    decimal valueHigh;
    string? system;
    string? code;
    decimal? canonicalValue;
    string? canonicalUnits;
|};

public type SpUriValue record {|
    string paramName;
    string value;
|};

public type SpReferenceValue record {|
    string paramName;
    string? targetType;
    string? targetId;
    int? targetVersionId;
    string? targetUrl;
    string? identifierSystem;
    string? identifierValue;
    string? display;
|};

public type SpCoordsValue record {|
    string paramName;
    decimal latitude;
    decimal longitude;
|};

// Aggregates all extracted values for a single resource write operation.
public type ExtractedSearchParams record {|
    SpStringValue[]    strings    = [];
    SpTokenValue[]     tokens     = [];
    SpDateValue[]      dates      = [];
    SpNumberValue[]    numbers    = [];
    SpQuantityValue[]  quantities = [];
    SpUriValue[]       uris       = [];
    SpReferenceValue[] references = [];
    SpCoordsValue[]    coords     = [];
|};
