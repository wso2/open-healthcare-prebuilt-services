// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina_fhir_server.utils;

import ballerina/log;
import ballerina/sql;
import ballerinax/java.jdbc;

public class DeleteHandler {
    private HistoryHandler historyHandler;
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
        self.historyHandler = new HistoryHandler(jdbcClient);
    }

    public isolated function deleteResourceWithTransaction(string resourceType, string resourceId) returns boolean|error {
        boolean result;
        transaction {
            result = check self.persistDelete(resourceType, resourceId);
            check commit;
        } on fail error e {
            log:printError(string `Delete transaction failed for ${resourceType}/${resourceId}: ${e.message()}`);
            return e;
        }
        return result;
    }

    public isolated function persistDelete(string resourceType, string resourceId) returns boolean|error {
        boolean exists = check utils:resourceExists(self.jdbcClient, resourceType, resourceId);
        if !exists {
            log:printWarn(string `Delete attempted on non-existent resource: ${resourceType}/${resourceId}`);
            return error(string `${resourceType}/${resourceId} not found`);
        }

        record {|anydata...;|} snapshot = check self.fetchResourceForHistory(resourceType, resourceId);

        int versionId = check int:fromString(snapshot.get("VERSION_ID").toString());
        log:printDebug(string `Saving version ${versionId} of ${resourceType}/${resourceId} to history before deletion`);
        check self.historyHandler.saveToHistory(resourceType, resourceId, snapshot, "DELETE");

        utils:TransactionContext refCtx = utils:newTransactionContext();
        refCtx.mainResourceId = resourceId;
        check utils:deleteReferencesBySource(self.jdbcClient, resourceType, resourceId, refCtx);

        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is jdbc:Client {
            error? deleteSearchResult = utils:deleteSearchParametersForResource(jdbcConn, resourceType, resourceId);
            if deleteSearchResult is error {
                log:printWarn(string `Failed to delete search parameters for ${resourceType}/${resourceId}: ${deleteSearchResult.message()} (continuing)`);
            }
        }

        if resourceType == "SearchParameter" {
            error? syncResult = utils:removeSearchParameterById(self.jdbcClient, resourceId);
            if syncResult is error {
                log:printWarn(string `Failed to remove SearchParameter/${resourceId} from expressions: ${syncResult.message()} (continuing)`);
            } else {
                log:printInfo(string `Successfully removed SearchParameter/${resourceId} from expressions table`);
            }
        }

        check utils:deleteResource(self.jdbcClient, resourceType, resourceId);

        error? rtResult = utils:deleteFromResourceTable(self.jdbcClient, resourceType, resourceId);
        if rtResult is error {
            log:printWarn(string `Failed to remove ${resourceType}/${resourceId} from RESOURCE_TABLE: ${rtResult.message()} (non-fatal)`);
        }

        error? friResult = utils:markFhirResourceIndexDeleted(self.jdbcClient, resourceType, resourceId);
        if friResult is error {
            log:printWarn(string `Failed to mark FHIR_RESOURCE_INDEX deleted for ${resourceType}/${resourceId}: ${friResult.message()} (non-fatal)`);
        }

        log:printInfo(string `Successfully deleted ${resourceType}/${resourceId}`);
        return true;
    }

    // Read the row (with all columns) so we can write it to RESOURCE_HISTORY.
    private isolated function fetchResourceForHistory(string resourceType, string resourceId) returns record {|anydata...;|}|error {

        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client not initialized");
        }

        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);

        string sqlQuery = string `SELECT * FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        stream<record {|anydata...;|}, sql:Error?> resultStream = jdbcConn->query(query);

        record {|anydata...;|}[] results = check from var result in resultStream
            select result;

        if results.length() == 0 {
            return error(string `${resourceType}/${resourceId} not found for history snapshot`);
        }

        return results[0];
    }
}
