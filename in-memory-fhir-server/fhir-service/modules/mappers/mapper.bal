import ballerina_fhir_server.db_store;

import ballerina/log;
import ballerina/persist;
import ballerinax/health.fhir.r4utils.fhirpath;

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
    private isolated function loadResourceConfig(db_store:Client persistClient, string resourceType) returns ResourceMappingConfig|error? {
        SearchParamMapping[] searchParamMappings = [];
        db_store:SEARCH_PARAM_RES_EXPRESSIONS[]|error? searchParamsExprs = check self.getSearchParamExpressions(persistClient, resourceType);

        if (searchParamsExprs is db_store:SEARCH_PARAM_RES_EXPRESSIONS[]) {
            foreach db_store:SEARCH_PARAM_RES_EXPRESSIONS search_param_expr in searchParamsExprs {
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

        log:printInfo(string `Loaded ${config.searchParams.length()} search parameters for ${resourceType}`);
        return config;
    }

    public isolated function extractSearchParameters(db_store:Client persistClient, string resourceType, json resourceJson) returns map<json>|error {
        ResourceMappingConfig|error? config = check self.loadResourceConfig(persistClient, resourceType);

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

    private isolated function getSearchParamExpressions(db_store:Client persistClient, string resourceName) returns db_store:SEARCH_PARAM_RES_EXPRESSIONS[]|error? {
        stream<db_store:SEARCH_PARAM_RES_EXPRESSIONS, persist:Error?> expressions = persistClient->/search_param_res_expressions;
        db_store:SEARCH_PARAM_RES_EXPRESSIONS[] filtered = check from var expression in expressions
            where expression.RESOURCE_NAME == resourceName
            select expression;
        return filtered;
    }
}
