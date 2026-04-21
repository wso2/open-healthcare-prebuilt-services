// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina_fhir_server.utils;

import ballerina/sql;
import ballerinax/java.jdbc;
import ballerina/log;

// Minimal repository helpers for terminology operations.
// This module intentionally avoids implementing full external terminology support;
// it only works with locally stored FHIR resources in the DB.

public isolated function readResourceJsonById(jdbc:Client jdbcClient, string resourceType, string id) returns json|error {
    log:printDebug("Reading resource JSON by ID", resourceType = resourceType, id = id);
    string tableName = utils:getTableName(resourceType);
    string primaryKey = utils:getPrimaryKeyColumn(resourceType);
    string normalizedDbType = utils:dbType.toLowerAscii().trim();
    string resourceJsonString;
    if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
        string pgSql = string `SELECT CAST("RESOURCE_JSON" AS TEXT) AS "RESOURCE_JSON" FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(id)}'`;
        stream<record {|string RESOURCE_JSON;|}, sql:Error?> pgStream = jdbcClient->query(new utils:RawSQLQuery(pgSql));
        record {|string RESOURCE_JSON;|}[] pgResults = check from var r in pgStream select r;
        if pgResults.length() == 0 {
            return error(string `${resourceType}/${id} not found`);
        }
        resourceJsonString = pgResults[0].RESOURCE_JSON;
    } else {
        string sqlQuery = string `SELECT "RESOURCE_JSON" FROM "${tableName}" WHERE "${primaryKey}" = '${utils:escapeSql(id)}'`;
        stream<record {|byte[] RESOURCE_JSON;|}, sql:Error?> resultStream = jdbcClient->query(new utils:RawSQLQuery(sqlQuery));
        record {|byte[] RESOURCE_JSON;|}[] results = check from var result in resultStream select result;
        if results.length() == 0 {
            return error(string `${resourceType}/${id} not found`);
        }
        resourceJsonString = check string:fromBytes(results[0].RESOURCE_JSON);
    }
    return check resourceJsonString.fromJsonString();
}

public isolated function readResourceJsonByColumn(jdbc:Client jdbcClient, string resourceType, string columnName, string value) returns json|error {
    string tableName = utils:getTableName(resourceType);
    string safeColumn = check getWhitelistedColumnName(resourceType, columnName);
    string normalizedDbType = utils:dbType.toLowerAscii().trim();
    string resourceJsonString;
    if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
        string pgSql = string `SELECT CAST("RESOURCE_JSON" AS TEXT) AS "RESOURCE_JSON" FROM "${tableName}" WHERE "${safeColumn}" = '${utils:escapeSql(value)}' LIMIT 1`;
        stream<record {|string RESOURCE_JSON;|}, sql:Error?> pgStream = jdbcClient->query(new utils:RawSQLQuery(pgSql));
        record {|string RESOURCE_JSON;|}[] pgResults = check from var r in pgStream select r;
        if pgResults.length() == 0 {
            return error(string `${resourceType} not found for ${columnName}=${value}`);
        }
        resourceJsonString = pgResults[0].RESOURCE_JSON;
    } else {
        string sqlQuery = string `SELECT "RESOURCE_JSON" FROM "${tableName}" WHERE "${safeColumn}" = '${utils:escapeSql(value)}' LIMIT 1`;
        stream<record {|byte[] RESOURCE_JSON;|}, sql:Error?> resultStream = jdbcClient->query(new utils:RawSQLQuery(sqlQuery));
        record {|byte[] RESOURCE_JSON;|}[] results = check from var result in resultStream select result;
        if results.length() == 0 {
            return error(string `${resourceType} not found for ${columnName}=${value}`);
        }
        resourceJsonString = check string:fromBytes(results[0].RESOURCE_JSON);
    }
    return check resourceJsonString.fromJsonString();
}

public isolated function tryReadResourceJsonByColumn(jdbc:Client jdbcClient, string resourceType, string columnName, string value) returns json|error? {
    json|error r = readResourceJsonByColumn(jdbcClient, resourceType, columnName, value);
    if r is error {
        return ();
    }
    return r;
}

isolated function getWhitelistedColumnName(string resourceType, string columnName) returns string|error {
    // Prevent SQL injection via identifier interpolation.
    // Only allow known-safe DB columns used by terminology ops.
    string c = columnName.toUpperAscii();
    if c == "URL" || c == "ID" {
        return c;
    }
    return error(string `Unsupported column name: ${columnName} for resourceType ${resourceType}`);
}

