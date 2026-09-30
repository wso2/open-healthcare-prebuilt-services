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
import ballerina/http;
import ballerina/persist;
import ballerina/sql;
import ballerinax/health.fhir.r4;
import ballerinax/persist.sql as psql;

type ConceptMapRow record {|
    int conceptMapId;
    string id;
    string? url;
    string? 'version;
    string? name;
    string? title;
    string status;
    string? sourceUri;
    string? targetUri;
    byte[] conceptMap;
|};

# Resolves the source ValueSet URI of a ConceptMap, since `source[x]` is a choice type (uri or canonical) - either can carry the scope findConceptMaps searches by.
#
# + cm - The ConceptMap to inspect
# + return - The source URI or canonical value, or `()` if neither is set
isolated function conceptMapSourceUri(r4:ConceptMap cm) returns string? {
    return cm.sourceUri ?: cm.sourceCanonical;
}

# Resolves the target ValueSet URI of a ConceptMap, since `target[x]` is a choice type (uri or canonical) - either can carry the scope findConceptMaps searches by.
#
# + cm - The ConceptMap to inspect
# + return - The target URI or canonical value, or `()` if neither is set
isolated function conceptMapTargetUri(r4:ConceptMap cm) returns string? {
    return cm.targetUri ?: cm.targetCanonical;
}

# Persists a ConceptMap to the store, backing `TerminologySource.addConceptMap`. Mirrors the storage shape used by addCodeSystem/addValueSet, saving the full resource as a blob plus queryable columns.
#
# + conceptMap - The ConceptMap to store
# + return - An `r4:FHIRError` if serialization or the insert fails, `()` otherwise
isolated function storeConceptMap(r4:ConceptMap conceptMap) returns r4:FHIRError? {
    byte[]|r4:FHIRError bytes = conceptMapToByte(conceptMap);
    if bytes is r4:FHIRError {
        return bytes;
    }

    sql:ParameterizedQuery query = sql:queryConcat(
            `INSERT INTO `, escapeToQuery("conceptmaps"),
            ` (`, escapeToQuery("id"), `, `, escapeToQuery("url"), `, `, escapeToQuery("version"), `, `,
            escapeToQuery("name"), `, `, escapeToQuery("title"), `, `, escapeToQuery("status"), `, `,
            escapeToQuery("sourceUri"), `, `, escapeToQuery("targetUri"), `, `, escapeToQuery("conceptMap"), `)`,
            ` VALUES (${conceptMap.id ?: ""}, ${conceptMap.url}, ${conceptMap.'version ?: ""}, ${conceptMap.name}, `,
            `${conceptMap.title}, ${conceptMap.status}, ${conceptMapSourceUri(conceptMap)}, `,
            `${conceptMapTargetUri(conceptMap)}, ${bytes})`);
    psql:ExecutionResult|persist:Error result = sClient->executeNativeSQL(query);
    if result is persist:Error {
        // terminology:addConceptMap checks (url, version) for an existing entry
        // before calling this function, but that check-then-insert isn't atomic.
        // idx_conceptmaps_url_version (unique) closes the race: a concurrent
        // duplicate create trips the constraint here instead of silently
        // inserting a second row, so it's reported the same way as the
        // pre-check duplicate rather than as a generic 500.
        if isUniqueConstraintViolation(result) {
            return r4:createFHIRError(
                    "Duplicate entry",
                    r4:ERROR,
                    r4:PROCESSING_DUPLICATE,
                    diagnostic = string `Already there is a ConceptMap exists in the registry with the URL: ${conceptMap.url.toString()} and version: ${conceptMap.'version.toString()}`,
                    errorType = r4:PROCESSING_ERROR,
                    cause = result,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }
        return r4:createFHIRError(
                "Error while adding ConceptMap, " + result.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = result,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
}

# Detects whether a `persist:Error` from an INSERT was caused by a unique-index/constraint violation, so callers can distinguish it from other DB failures. Matched by message substring since the SQL error code isn't surfaced through `persist:Error`, covering both the H2 ("Unique index or primary key violation") and PostgreSQL ("duplicate key value violates unique constraint") wording.
#
# + err - The error returned by `executeNativeSQL`
# + return - `true` if the error looks like a unique-constraint violation
isolated function isUniqueConstraintViolation(persist:Error err) returns boolean {
    string message = err.message().toLowerAscii();
    return message.includes("unique") || message.includes("duplicate");
}

# Finds candidate ConceptMaps for a given source (and optionally target) ValueSet scope, backing `TerminologySource.findConceptMaps`. The terminology library's translate() uses this to narrow candidates before performing the actual code matching itself.
#
# + sourceValueSetUri - The source ValueSet URI or canonical to match against
# + targetValueSetUri - The target ValueSet URI or canonical to match against, or `()` to match on source alone
# + return - The matching ConceptMaps, or an `r4:FHIRError` if the query fails
isolated function findStoredConceptMaps(r4:uri sourceValueSetUri, r4:uri? targetValueSetUri) returns r4:ConceptMap[]|r4:FHIRError {
    sql:ParameterizedQuery query;
    if targetValueSetUri is r4:uri {
        query = sql:queryConcat(
                `SELECT * FROM `, escapeToQuery("conceptmaps"),
                ` WHERE `, escapeToQuery("sourceUri"), ` = ${sourceValueSetUri}`,
                ` AND `, escapeToQuery("targetUri"), ` = ${targetValueSetUri}`);
    } else {
        query = sql:queryConcat(
                `SELECT * FROM `, escapeToQuery("conceptmaps"),
                ` WHERE `, escapeToQuery("sourceUri"), ` = ${sourceValueSetUri}`);
    }
    return queryStoredConceptMaps(query);
}

# Looks up a single ConceptMap by its canonical URL and optional version, backing `TerminologySource.getConceptMap`.
#
# + url - The canonical URL of the ConceptMap
# + conceptMapVersion - The specific version to match, or `()` to match by URL alone
# + return - The matching ConceptMap, or an `r4:FHIRError` if none is found or the query fails
isolated function getStoredConceptMapByUrl(r4:uri url, string? conceptMapVersion) returns r4:ConceptMap|r4:FHIRError {
    sql:ParameterizedQuery query;
    if conceptMapVersion is string {
        query = sql:queryConcat(
                `SELECT * FROM `, escapeToQuery("conceptmaps"),
                ` WHERE `, escapeToQuery("url"), ` = ${url} AND `, escapeToQuery("version"), ` = ${conceptMapVersion}`);
    } else {
        // Several versions of the same ConceptMap can be stored; without an
        // explicit version, resolve deterministically to the latest one -
        // matching getStoreCodeSystemByURL/getStoreValueSetByURL's own
        // versionless handling - rather than whatever row the DB returns first.
        query = sql:queryConcat(
                `SELECT * FROM `, escapeToQuery("conceptmaps"), ` WHERE `, escapeToQuery("url"), ` = ${url}`,
                ` ORDER BY `, escapeToQuery("version"), ` DESC LIMIT 1`);
    }
    r4:ConceptMap[]|r4:FHIRError results = queryStoredConceptMaps(query);
    if results is r4:FHIRError {
        return results;
    }
    if results.length() == 0 {
        return r4:createFHIRError(
                "ConceptMap not found: " + url,
                r4:ERROR,
                r4:PROCESSING_NOT_FOUND,
                cause = error("No ConceptMap found for url " + url),
                httpStatusCode = http:STATUS_NOT_FOUND);
    }
    return results[0];
}

# Checks whether a ConceptMap with the given URL and version is already stored, backing `TerminologySource.isConceptMapExist`.
#
# + url - The canonical URL of the ConceptMap
# + conceptMapVersion - The version to match
# + return - `true` if a matching ConceptMap exists, `false` otherwise
isolated function storedConceptMapExists(r4:uri url, string conceptMapVersion) returns boolean {
    sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT 1 FROM `, escapeToQuery("conceptmaps"),
            ` WHERE `, escapeToQuery("url"), ` = ${url} AND `, escapeToQuery("version"), ` = ${conceptMapVersion} LIMIT 1`);
    stream<record {}, persist:Error?> resultStream = sClient->queryNativeSQL(query);
    record {}[]|error rows = from record {} r in resultStream
        select r;
    return rows is error ? false : rows.length() > 0;
}

# Searches stored ConceptMaps by the common search parameters (_id, url, name, status), backing `TerminologySource.searchConceptMap`. Returns every stored ConceptMap when none of the parameters are given.
#
# + params - The request search parameters, keyed by parameter name
# + offset - The number of matching rows to skip, or `()` for no offset
# + count - The maximum number of rows to return, or `()` for no limit
# + return - The matching ConceptMaps, or an `r4:FHIRError` if the query fails
isolated function searchStoredConceptMaps(map<r4:RequestSearchParameter[]> params, int? offset, int? count) returns r4:ConceptMap[]|r4:FHIRError {
    sql:ParameterizedQuery[] conditions = [];

    r4:RequestSearchParameter[]? idParam = params["_id"];
    if idParam is r4:RequestSearchParameter[] && idParam.length() > 0 {
        conditions.push(sql:queryConcat(escapeToQuery("id"), ` = ${idParam[0].value}`));
    }
    r4:RequestSearchParameter[]? urlParam = params["url"];
    if urlParam is r4:RequestSearchParameter[] && urlParam.length() > 0 {
        conditions.push(sql:queryConcat(escapeToQuery("url"), ` = ${urlParam[0].value}`));
    }
    r4:RequestSearchParameter[]? nameParam = params["name"];
    if nameParam is r4:RequestSearchParameter[] && nameParam.length() > 0 {
        conditions.push(sql:queryConcat(escapeToQuery("name"), ` = ${nameParam[0].value}`));
    }
    r4:RequestSearchParameter[]? statusParam = params["status"];
    if statusParam is r4:RequestSearchParameter[] && statusParam.length() > 0 {
        conditions.push(sql:queryConcat(escapeToQuery("status"), ` = ${statusParam[0].value}`));
    }

    sql:ParameterizedQuery query = sql:queryConcat(`SELECT * FROM `, escapeToQuery("conceptmaps"));
    if conditions.length() > 0 {
        sql:ParameterizedQuery[] whereFragments = [` WHERE `];
        boolean first = true;
        foreach var cond in conditions {
            if !first {
                whereFragments.push(` AND `);
            }
            whereFragments.push(cond);
            first = false;
        }
        query = sql:queryConcat(query, sql:queryConcat(...whereFragments));
    }
    if count is int {
        query = sql:queryConcat(query, getLimitClause(count, offset ?: 0));
    }

    return queryStoredConceptMaps(query);
}

# Runs a query against the conceptmaps table and decodes each row's stored blob back into a ConceptMap. Shared by all the lookup/search functions above. A row that fails to decode is silently skipped rather than failing the whole call.
#
# + query - The parameterized SQL query to run against the conceptmaps table
# + return - The decoded ConceptMaps, or an `r4:FHIRError` if the query itself fails
isolated function queryStoredConceptMaps(sql:ParameterizedQuery query) returns r4:ConceptMap[]|r4:FHIRError {
    stream<ConceptMapRow, persist:Error?> resultStream = sClient->queryNativeSQL(query);
    ConceptMapRow[]|error rows = from ConceptMapRow row in resultStream
        select row;
    if rows is error {
        return r4:createFHIRError(
                "Error while searching for ConceptMap: " + rows.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = rows,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }

    r4:ConceptMap[] results = [];
    foreach ConceptMapRow row in rows {
        r4:ConceptMap|error cm = byteToConceptMap(row.conceptMap);
        if cm is r4:ConceptMap {
            results.push(cm);
        }
    }
    return results;
}

