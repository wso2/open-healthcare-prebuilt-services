import ballerina_fhir_server.mappers;
import ballerina_fhir_server.utils;

import ballerina/log;
import ballerinax/java.jdbc;

public class UpdateHandler {
    private mappers:UpdateMapper updateMapper;
    private HistoryHandler historyHandler;
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
        self.updateMapper = new mappers:UpdateMapper();
        self.historyHandler = new HistoryHandler(jdbcClient);
    }

    // Full resource replacement (PUT)
    public isolated function updateResourceWithTransaction(string resourceType, string resourceId, json resourceJson) returns string|error {
        jdbc:Client jc = check utils:getValidatedJdbcClient(self.jdbcClient);

        transaction {
            int newVersion = check self.updateMapper.mapToUpdate(jc, resourceType, resourceId, resourceJson);

            if resourceType == "SearchParameter" {
                check utils:syncSearchParameterToExpressions(self.jdbcClient, resourceJson);
            }

            check self.historyHandler.saveToHistory(resourceType, resourceId, newVersion, "PUT", resourceJson);

            check commit;
        } on fail error e {
            log:printError(string `Update transaction rolled back for ${resourceType}/${resourceId}: ${e.message()}`);
            return e;
        }

        log:printDebug(string `Successfully updated ${resourceType}/${resourceId}`);
        return resourceId;
    }

    // Partial update (PATCH — JSON merge patch)
    public isolated function patchResourceWithTransaction(string resourceType, string resourceId, json patchJson) returns json|error {
        jdbc:Client jc = check utils:getValidatedJdbcClient(self.jdbcClient);
        mappers:ReadMapper rm = new mappers:ReadMapper();
        json mergedResource = {};

        transaction {
            int newVersion = check self.updateMapper.mapToPatch(jc, resourceType, resourceId, patchJson);
            mergedResource = check rm.readResourceById(jc, resourceType, resourceId);

            if resourceType == "SearchParameter" {
                check utils:syncSearchParameterToExpressions(self.jdbcClient, mergedResource);
            }

            check self.historyHandler.saveToHistory(resourceType, resourceId, newVersion, "PUT", mergedResource);

            check commit;
        } on fail error e {
            log:printError(string `Patch transaction rolled back for ${resourceType}/${resourceId}: ${e.message()}`);
            return e;
        }

        log:printDebug(string `Successfully patched ${resourceType}/${resourceId}`);
        return mergedResource;
    }
}
