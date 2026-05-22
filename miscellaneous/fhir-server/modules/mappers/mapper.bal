import ballerina_fhir_server.utils;
import ballerinax/java.jdbc;
import ballerina/log;
import ballerinax/health.fhir.r4utils.fhirpath;

public type SearchParamMapping record {|
    string paramName;
    string fhirPath;
    string paramType;
|};

public type ResourceMappingConfig record {|
    string resourceType;
    SearchParamMapping[] searchParams;
|};

// FHIRMapper is a base utility for FHIRPath-based extraction.
// New code should use search_param_extractor.bal directly.
public class FHIRMapper {
    private json[] references;

    isolated function init() {
        self.references = [];
    }

    private isolated function loadResourceConfig(jdbc:Client jdbcClient, string resourceType) returns ResourceMappingConfig|error? {
        utils:SearchParamExpression[]|error exprs = utils:getAllSearchParamDefinitions(jdbcClient, resourceType);
        if exprs is error { return exprs; }

        SearchParamMapping[] searchParamMappings = [];
        foreach utils:SearchParamExpression e in exprs {
            searchParamMappings.push({
                paramName: e.SEARCH_PARAM_NAME,
                paramType: e.SEARCH_PARAM_TYPE,
                fhirPath: e.EXPRESSION
            });
        }

        log:printDebug(string `Loaded ${searchParamMappings.length()} search parameters for ${resourceType}`);
        return {resourceType, searchParams: searchParamMappings};
    }

    public isolated function extractSearchParameters(jdbc:Client jdbcClient, string resourceType, json resourceJson) returns map<json>|error {
        // Reset accumulated references so getReferences() does not leak across calls.
        self.references = [];
        ResourceMappingConfig|error? config = check self.loadResourceConfig(jdbcClient, resourceType);
        map<json> extractedParams = {};
        if config is ResourceMappingConfig {
            foreach SearchParamMapping paramMapping in config.searchParams {
                json|error extractedValue = fhirpath:getValuesFromFhirPath(resourceJson, paramMapping.fhirPath);
                if extractedValue is error {
                    log:printDebug(string `Failed to extract ${paramMapping.paramName}: ${extractedValue.message()}`);
                    continue;
                }
                if extractedValue is json[] && extractedValue.length() == 1 {
                    extractedValue = extractedValue[0];
                }
                if extractedValue is json {
                    extractedParams[paramMapping.paramName] = extractedValue;
                }
                if paramMapping.paramType == "reference" {
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
}
