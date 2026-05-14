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

import ballerina_fhir_server.mappers;
import ballerina_fhir_server.utils;

import ballerina/log;
import ballerina/sql;
import ballerinax/java.jdbc;

public class UpdateHandler {
    private mappers:UpdateMapper updateMapper;
    private HistoryHandler historyHandler;
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
        self.updateMapper = new mappers:UpdateMapper(jdbcClient);
        self.historyHandler = new HistoryHandler(jdbcClient);
    }

    public isolated function updateResourceWithTransaction(string resourceType, string resourceId, json resourceJson) returns string|error {
        string result;
        transaction {
            result = check self.persistUpdate(resourceType, resourceId, resourceJson);
            check commit;
        } on fail error e {
            log:printError(string `Update transaction failed for ${resourceType}/${resourceId}: ${e.message()}`);
            return e;
        }
        return result;
    }

    // Public entry point for PATCH.
    public isolated function patchResourceWithTransaction(string resourceType, string resourceId, json patchJson) returns json|error {
        json result;
        transaction {
            result = check self.persistPatch(resourceType, resourceId, patchJson);
            check commit;
        } on fail error e {
            log:printError(string `Patch transaction failed for ${resourceType}/${resourceId}: ${e.message()}`);
            return e;
        }
        return result;
    }

    public isolated function persistUpdate(string resourceType, string resourceId, json resourceJson) returns string|error {
        jdbc:Client jdbcConn = check utils:getValidatedJdbcClient(self.jdbcClient);

        // Check if resource exists
        boolean exists = check utils:resourceExists(self.jdbcClient, resourceType, resourceId);
        if !exists {
            log:printWarn(string `Update attempted on non-existent resource: ${resourceType}/${resourceId}`);
            return error(string `${resourceType}/${resourceId} not found`);
        }

        int currentVersion = check self.fetchCurrentVersion(resourceType, resourceId);
        int newVersion = currentVersion + 1;

        utils:TransactionContext refCtx = utils:newTransactionContext();
        refCtx.mainResourceId = resourceId;
        check utils:deleteReferencesBySource(self.jdbcClient, resourceType, resourceId, refCtx);

        log:printDebug(string `Mapping updated ${resourceType} to model (version ${newVersion})`);
        record {|anydata...;|}|error? updateModel = self.updateMapper.mapToUpdateModel(jdbcConn, resourceType, resourceJson, newVersion);
        if updateModel is () || updateModel is error {
            return updateModel is error ? updateModel : error("Failed to create update model");
        }

        json[] references = self.updateMapper.getReferences();

        check self.updateMainResource(resourceType, resourceId, updateModel);

        error? friResult = utils:upsertFhirResourceIndex(self.jdbcClient, resourceType, resourceId, newVersion);
        if friResult is error {
            log:printWarn(string `Failed to upsert FHIR_RESOURCE_INDEX for ${resourceType}/${resourceId}: ${friResult.message()} (non-fatal)`);
        }

        if resourceType == "SearchParameter" {
            check utils:syncSearchParameterToExpressions(self.jdbcClient, resourceJson);
            log:printInfo(string `Successfully synced updated SearchParameter/${resourceId} to expressions table`);
        }

        check self.historyHandler.saveToHistory(resourceType, resourceId, updateModel, "PUT");

        check utils:updateSearchParametersForResource(jdbcConn, resourceType, resourceId, resourceJson);

        error? refResult = utils:saveReferences(self.jdbcClient, references, resourceType, resourceId, refCtx);
        if refResult is error {
            string refMsg = refResult.message();
            if refMsg.includes("violates foreign key constraint") || refMsg.includes("FK_REFERENCES_TARGET") {
                return error(string `Unresolved reference: one or more TARGET resources referenced by ${resourceType}/${resourceId} do not exist. Ensure all referenced resources are created first.`);
            }
            return refResult;
        }

        log:printDebug(string `Successfully updated ${resourceType}/${resourceId}`);
        return resourceId;
    }

    public isolated function persistPatch(string resourceType, string resourceId, json patchJson) returns json|error {
        jdbc:Client jdbcConn = check utils:getValidatedJdbcClient(self.jdbcClient);

        json existingResource = check self.getResourceAsJson(resourceType, resourceId);

        json mergedResource = check self.applyPatch(existingResource, patchJson);

        utils:TransactionContext refCtx = utils:newTransactionContext();
        refCtx.mainResourceId = resourceId;
        check utils:deleteReferencesBySource(self.jdbcClient, resourceType, resourceId, refCtx);

        record {|anydata...;|}|error? updateModel = self.updateMapper.mapToUpdateModel(jdbcConn, resourceType, mergedResource);
        if updateModel is () || updateModel is error {
            return updateModel is error ? updateModel : error("Failed to create update model");
        }

        json[] references = self.updateMapper.getReferences();

        check self.updateMainResource(resourceType, resourceId, updateModel);

        int patchedVersion = 2;
        anydata patchedVersionField = updateModel["VERSION_ID"];
        if patchedVersionField is int {
            patchedVersion = patchedVersionField;
        }
        error? friResult = utils:upsertFhirResourceIndex(self.jdbcClient, resourceType, resourceId, patchedVersion);
        if friResult is error {
            log:printWarn(string `Failed to upsert FHIR_RESOURCE_INDEX for ${resourceType}/${resourceId}: ${friResult.message()} (non-fatal)`);
        }

        error? refResult = utils:saveReferences(self.jdbcClient, references, resourceType, resourceId, refCtx);
        if refResult is error {
            string refMsg = refResult.message();
            if refMsg.includes("violates foreign key constraint") || refMsg.includes("FK_REFERENCES_TARGET") {
                return error(string `Unresolved reference: one or more TARGET resources referenced by ${resourceType}/${resourceId} do not exist. Ensure all referenced resources are created first.`);
            }
            return refResult;
        }

        log:printDebug(string `Successfully patched ${resourceType}/${resourceId}`);
        return mergedResource;
    }

    private isolated function fetchCurrentVersion(string resourceType, string resourceId) returns int|error {
        jdbc:Client jdbcConn = check utils:getValidatedJdbcClient(self.jdbcClient);

        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);

        string sqlQuery = string `SELECT "VERSION_ID" FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        int|sql:Error result = jdbcConn->queryRow(query);
        if result is sql:Error {
            return error(string `Failed to read VERSION_ID for ${resourceType}/${resourceId}: ${result.message()}`);
        }
        return result;
    }

    private isolated function getResourceAsJson(string resourceType, string resourceId) returns json|error {

        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client not initialized");
        }

        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);

        string jsonString;
        string normalizedDbType = dbType.toLowerAscii().trim();
        if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
            string pgSql = string `SELECT CAST("RESOURCE_JSON" AS TEXT) AS "RESOURCE_JSON" FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
            log:printDebug("Fetching resource: " + resourceType + "/" + resourceId + " from table: " + tableName);
            sql:ParameterizedQuery pgQuery = new utils:RawSQLQuery(pgSql);
            stream<record {|string RESOURCE_JSON;|}, sql:Error?> pgStream = jdbcConn->query(pgQuery);
            record {|string RESOURCE_JSON;|}[] pgResults = check from var r in pgStream
                select r;
            if pgResults.length() == 0 {
                log:printDebug("Resource not found: " + resourceType + "/" + resourceId);
                return error(string `${resourceType}/${resourceId} not found`);
            }
            jsonString = pgResults[0].RESOURCE_JSON;
        } else {
            string sqlQuery = string `SELECT "RESOURCE_JSON" FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
            sql:ParameterizedQuery h2Query = new utils:RawSQLQuery(sqlQuery);
            log:printDebug("Fetching resource: " + resourceType + "/" + resourceId + " from table: " + tableName);
            stream<record {|byte[] RESOURCE_JSON;|}, sql:Error?> h2Stream = jdbcConn->query(h2Query);
            record {|byte[] RESOURCE_JSON;|}[] h2Results = check from var r in h2Stream
                select r;
            if h2Results.length() == 0 {
                return error(string `${resourceType}/${resourceId} not found`);
            }
            jsonString = check string:fromBytes(h2Results[0].RESOURCE_JSON);
        }

        json resourceJson = check jsonString.fromJsonString();

        return resourceJson;
    }

    private isolated function applyPatch(json existing, json patch) returns json|error {
        if !(existing is map<json>) {
            return error(string `Existing resource is not a JSON object: ${existing.toString()}`);
        }

        if !(patch is map<json>) {
            return error(string `Patch is not a JSON object: ${patch.toString()}`);
        }

        map<json> existingMap = <map<json>>existing;
        map<json> patchMap = <map<json>>patch;

        map<json> mergedMap = existingMap.clone();

        foreach var [key, value] in patchMap.entries() {
            mergedMap[key] = value;
        }

        return mergedMap;
    }

    private isolated function updateMainResource(string resourceType, string resourceId, record {|anydata...;|} updateModel) returns error? {

        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client not initialized");
        }

        string tableName = utils:getTableName(resourceType);
        string primaryKey = utils:getPrimaryKeyColumn(resourceType);

        string[] setClauses = [];
        foreach var [key, value] in updateModel.entries() {
            string formattedValue;
            if key == "DATE" {
                formattedValue = utils:formatDateValue(value);
            } else {
                formattedValue = utils:formatSqlValue(value);
            }
            setClauses.push(string `"${key}" = ${formattedValue}`);
        }

        if setClauses.length() == 0 {
            return error("No fields to update");
        }

        string setClause = string:'join(", ", ...setClauses);
        string sqlQuery = string `UPDATE "${tableName}" SET ${setClause} WHERE "${primaryKey}" = '${utils:escapeSql(resourceId)}'`;
        sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

        sql:ExecutionResult|sql:Error result = jdbcConn->execute(query);

        if result is sql:Error {
            return error(string `Failed to update ${resourceType}/${resourceId}: ${result.message()}`);
        }

        return;
    }
}
