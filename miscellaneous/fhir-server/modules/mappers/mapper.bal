import ballerina_fhir_server.utils;
import ballerinax/java.jdbc;
import ballerina/sql;
import ballerina/log;
import ballerinax/health.fhir.r4utils.fhirpath;

type SearchParamRow record {int ID; string SEARCH_PARAM_NAME; string SEARCH_PARAM_TYPE; string RESOURCE_NAME; string EXPRESSION;};

public type SearchParamMapping record {|
    string paramName; // Database column
    string fhirPath; // FHIRPath expression (e.g., "Appointment.start")
    string paramType; // FHIR search param type (token, date, reference, etc.)
|};

// Resource Mapping Configs
public type ResourceMappingConfig record {|
    string resourceType;
    SearchParamMapping[] searchParams;
|};

public class FHIRMapper {
    private json[] references;

    isolated function init() {
        self.references = [];
    }

    // Load configuration for a specific resource type on demand
    private isolated function loadResourceConfig(jdbc:Client jdbcClient, string resourceType) returns ResourceMappingConfig|error? {
        SearchParamMapping[] searchParamMappings = [];
        utils:SearchParamExpression[]|error? searchParamsExprs = check self.getSearchParamExpressions(jdbcClient, resourceType);

        if (searchParamsExprs is utils:SearchParamExpression[]) {
            foreach utils:SearchParamExpression search_param_expr in searchParamsExprs {
                SearchParamMapping mapping = {
                    paramName: search_param_expr.SEARCH_PARAM_NAME,
                    paramType: search_param_expr.SEARCH_PARAM_TYPE,
                    fhirPath: search_param_expr.EXPRESSION
                };
                searchParamMappings.push(mapping);
            }
        }

        ResourceMappingConfig config = {
            resourceType: resourceType,
            searchParams: searchParamMappings
        };

        log:printDebug(string `Loaded ${config.searchParams.length()} search parameters for ${resourceType}`);
        return config;
    }

    public isolated function extractSearchParameters(jdbc:Client jdbcClient, string resourceType, json resourceJson) returns map<json>|error {
        ResourceMappingConfig|error? config = check self.loadResourceConfig(jdbcClient, resourceType);

        map<json> extractedParams = {};
        if (config is ResourceMappingConfig) {
            // Extract each search parameter using FHIRPath
            foreach SearchParamMapping paramMapping in config.searchParams {
                json|error extractedValue = self.extractSingleParameter(resourceJson, paramMapping);

                if extractedValue is error {
                    log:printDebug(string `Failed to extract ${paramMapping.paramName}: ${extractedValue.message()}`);
                    continue;
                }

                if (extractedValue is json[] && extractedValue.length() == 1) {
                    extractedValue = extractedValue[0];
                }

                if (extractedValue is json) {
                    extractedParams[paramMapping.paramName] = extractedValue;
                }

                if (paramMapping.paramType == "reference") {
                    map<json> refObj = {};
                    refObj[paramMapping.paramName] = check extractedValue;
                    self.references.push(refObj);
                }
            }
        }
        return extractedParams;
    }

    public isolated function getReferences() returns json[] {
        return self.references;
    }

    // Extract single parameter using FHIRPath
    private isolated function extractSingleParameter(json resourceJson, SearchParamMapping paramMapping) returns json|error {
        json|error result = fhirpath:getValuesFromFhirPath(resourceJson, paramMapping.fhirPath);
        return result;
    }

    private isolated function getSearchParamExpressions(jdbc:Client jdbcClient, string resourceName) returns utils:SearchParamExpression[]|error? {
        // Check the shared cache first to avoid a DB round-trip on every POST request
        utils:SearchParamExpression[]? cached = utils:getCachedAllSearchParamExpressions(resourceName);
        if cached is utils:SearchParamExpression[] {
            return cached;
        }

        sql:ParameterizedQuery pq = `SELECT "ID", "SEARCH_PARAM_NAME", "SEARCH_PARAM_TYPE", "RESOURCE_NAME", "EXPRESSION" FROM "SEARCH_PARAM_RES_EXPRESSIONS" WHERE "RESOURCE_NAME" = ${resourceName}`;
        stream<SearchParamRow, error?> result = jdbcClient->query(pq);

        utils:SearchParamExpression[] expressions = [];
        error? e = ();
        do {
            var next = result.next();
            while !(next is ()) {
                if (next is error) {
                    e = next;
                    break;
                } else {
                    SearchParamRow val = next.value;
                    utils:SearchParamExpression expr = {
                        SEARCH_PARAM_NAME: val.SEARCH_PARAM_NAME,
                        SEARCH_PARAM_TYPE: val.SEARCH_PARAM_TYPE,
                        RESOURCE_NAME: val.RESOURCE_NAME,
                        EXPRESSION: val.EXPRESSION
                    };
                    expressions.push(expr);
                }
                next = result.next();
            }
        } on fail error err {
            e = err;
        }
        if e is error {
            return e;
        }
        // Populate cache so subsequent requests are served from memory
        utils:cacheAllSearchParamExpressions(resourceName, expressions);
        return expressions;
    }
}
