import ballerina_fhir_server.mappers;
import ballerina_fhir_server.utils;
import ballerina_fhir_server.utils as mapperUtils;

import ballerina/log;
import ballerina/sql;

import ballerinax/java.jdbc;

public class CreateHandler {
    private HistoryHandler historyHandler;
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
        self.historyHandler = new HistoryHandler(jdbcClient);
    }

    public isolated function saveResourceWithTransaction(string resourceType, json resourceJson) returns json|error {
        jdbc:Client validatedClient = check utils:getValidatedJdbcClient(self.jdbcClient);
        mappers:CreateMapper mapper = new mappers:CreateMapper(validatedClient);

        // Map resource to insert model — pure computation, no DB writes
        record {|anydata...;|}|error? insertModel = mapper.mapToInsertModel(
            validatedClient, resourceType, resourceJson
        );

        if insertModel is () {
            return error(string `Failed to create insert model for ${resourceType}`);
        }
        if insertModel is error {
            return insertModel;
        }

        json[] references = mapper.getReferences();
        json resourceWithId = mapper.getResourceJsonWithId();

        // All DB writes are wrapped in a single real database transaction.
        // On any failure the DB engine rolls back atomically — no manual
        // compensating deletes are needed.
        transaction {
            string resourceId = check self.saveMainResource(resourceType, insertModel, validatedClient);
            log:printDebug(string `Inserting ${resourceType}/${resourceId}`);

            check utils:saveToResourceTable(self.jdbcClient, resourceType, resourceId);

            if resourceType == "SearchParameter" {
                check utils:syncSearchParameterToExpressions(self.jdbcClient, resourceJson);
            }

            check self.historyHandler.saveToHistory(resourceType, resourceId, insertModel, "POST");
            check utils:extractSearchParametersForResource(validatedClient, resourceType, resourceId, resourceJson);
            check utils:saveReferences(self.jdbcClient, references, resourceType, resourceId);

            check commit;
        } on fail error e {
            log:printError(string `Create transaction rolled back for ${resourceType}: ${e.message()}`);
            return e;
        }

        log:printDebug(string `${resourceType} created successfully`);
        return resourceWithId;
    }

    private isolated function saveMainResource(string resourceType, record {|anydata...;|} insertModel, jdbc:Client jdbcClient) returns string|error {
        string tableName = mapperUtils:getTableName(resourceType);
        string primaryKeyColumn = mapperUtils:getPrimaryKeyColumn(resourceType);
        any resourceIdValue = insertModel[primaryKeyColumn];
        string resourceId = resourceIdValue is string ? resourceIdValue : resourceIdValue.toString();

        string[] columnNames = insertModel.keys();
        anydata[] columnValues = insertModel.toArray();

        string[] quotedColumnNames = from string colName in columnNames
                                     select string `"${colName}"`;
        string columnNamesStr = string:'join(", ", ...quotedColumnNames);

        string[] valueStrings = [];
        int index = 0;
        foreach any val in columnValues {
            string columnName = columnNames[index];
            if columnName == "DATE" {
                valueStrings.push(utils:formatDateValue(val));
            } else {
                valueStrings.push(utils:formatSqlValue(val));
            }
            index += 1;
        }

        string valuesStr = string:'join(", ", ...valueStrings);
        string completeQueryStr = "INSERT INTO \"" + tableName + "\"(" + columnNamesStr + ") VALUES (" + valuesStr + ")";

        utils:RawSQLQuery rawQuery = new(completeQueryStr);
        sql:ExecutionResult|error result = jdbcClient->execute(rawQuery);

        if result is error {
            string errMsg = result.message();
            string lowerMsg = errMsg.toLowerAscii();
            if lowerMsg.includes("duplicate") || lowerMsg.includes("unique") || lowerMsg.includes("primary key") {
                return error(string `Resource already exists: ${resourceType}/${resourceId}. Use PUT to update the resource.`);
            }
            return result;
        }

        return resourceId;
    }
}
