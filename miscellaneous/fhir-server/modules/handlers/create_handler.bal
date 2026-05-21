import ballerina_fhir_server.mappers;
import ballerina_fhir_server.utils;

import ballerina/log;
import ballerinax/java.jdbc;

public class CreateHandler {
    private HistoryHandler historyHandler;
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
        self.historyHandler = new HistoryHandler(jdbcClient);
    }

    public isolated function saveResourceWithTransaction(string resourceType, json resourceJson) returns json|error {
        jdbc:Client jc = check utils:getValidatedJdbcClient(self.jdbcClient);
        mappers:CreateMapper mapper = new mappers:CreateMapper();

        transaction {
            string resourceId = check mapper.mapToInsert(jc, resourceType, resourceJson);

            if resourceType == "SearchParameter" {
                check utils:syncSearchParameterToExpressions(self.jdbcClient, resourceJson);
            }

            check self.historyHandler.saveToHistory(
                resourceType, resourceId, 1, "POST", mapper.getResourceJsonWithId()
            );

            check commit;
        } on fail error e {
            log:printError(string `Create transaction rolled back for ${resourceType}: ${e.message()}`);
            return e;
        }

        log:printDebug(string `${resourceType} created successfully`);
        return mapper.getResourceJsonWithId();
    }
}
