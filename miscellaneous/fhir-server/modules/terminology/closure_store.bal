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

import ballerina_fhir_server.handlers;
import ballerina_fhir_server.utils;

import ballerina/sql;
import ballerina/time;
import ballerinax/java.jdbc;

// ------------------------------------------------------------
// $closure support 
// ------------------------------------------------------------
//
// This implementation stores closure contexts, seen concepts, and the generated
// ConceptMap response per version so clients can request replays.

public isolated function initClosure(jdbc:Client jdbcClient, string name) returns json|error {
    time:Civil now = time:utcToCivil(time:utcNow());
    string normalizedDb = handlers:dbType.toLowerAscii().trim();

    // Upsert context and reset version to 0
    sql:ParameterizedQuery upsertCtx;
    if normalizedDb == "h2" {
        upsertCtx = `MERGE INTO "ClosureContextTable" ("CLOSURECONTEXTTABLE_ID", "VERSION_ID", "CREATED_AT", "UPDATED_AT", "LAST_UPDATED")
                     KEY("CLOSURECONTEXTTABLE_ID")
                     VALUES (${name}, 0, ${now}, ${now}, ${now})`;
    } else {
        upsertCtx = `INSERT INTO "ClosureContextTable" ("CLOSURECONTEXTTABLE_ID", "VERSION_ID", "CREATED_AT", "UPDATED_AT", "LAST_UPDATED")
                     VALUES (${name}, 0, ${now}, ${now}, ${now})
                     ON CONFLICT ("CLOSURECONTEXTTABLE_ID")
                     DO UPDATE SET "VERSION_ID" = 0, "UPDATED_AT" = ${now}, "LAST_UPDATED" = ${now}`;
    }
    _ = check jdbcClient->execute(upsertCtx);

    // Clear old state
    _ = check jdbcClient->execute(`DELETE FROM "ClosureConceptTable" WHERE "CLOSURECONTEXTTABLE_ID" = ${name}`);
    _ = check jdbcClient->execute(`DELETE FROM "ClosureDeltaTable" WHERE "CLOSURECONTEXTTABLE_ID" = ${name}`);

    json conceptMap = buildClosureConceptMap(name, "0", string `Closure Table ${name} Creation`, now, []);
    string cmJson = conceptMap.toJsonString();
    _ = check jdbcClient->execute(`INSERT INTO "ClosureDeltaTable" ("CLOSURECONTEXTTABLE_ID", "VERSION_ID", "CONCEPTMAP_JSON", "CREATED_AT")
                                   VALUES (${name}, 0, ${cmJson}, ${now})`);
    return conceptMap;
}

public isolated function addToClosure(jdbc:Client jdbcClient, string name, map<json>[] concepts, string? lastVersion = ()) returns json|error {
    // Ensure context exists and get current version
    int|error currentVersion = jdbcClient->queryRow(`SELECT "VERSION_ID" FROM "ClosureContextTable" WHERE "CLOSURECONTEXTTABLE_ID" = ${name}`);
    if currentVersion is error {
        return error(string `invalid closure name \"${name}\"`);
    }

    // Replay mode: return the latest stored delta after requested version (best-effort)
    if lastVersion is string {
        int|error lv = int:fromString(lastVersion);
        if lv is int {
            anydata|error row = jdbcClient->queryRow(`SELECT "CONCEPTMAP_JSON" FROM "ClosureDeltaTable"
                                                      WHERE "CLOSURECONTEXTTABLE_ID" = ${name} AND "VERSION_ID" > ${lv}
                                                      ORDER BY "VERSION_ID" DESC LIMIT 1`);
            if row is map<anydata> && row["CONCEPTMAP_JSON"] is string {
                return check (<string>row["CONCEPTMAP_JSON"]).fromJsonString();
            }
        }
        // If no deltas exist, fall through and generate a new (empty) delta.
    }

    string normalizedDb = handlers:dbType.toLowerAscii().trim();
    time:Civil now = time:utcToCivil(time:utcNow());

    // Insert new concepts as "seen"
    foreach map<json> c in concepts {
        if !(c["system"] is string) || !(c["code"] is string) {
            continue;
        }
        string system = <string>c["system"];
        string code = <string>c["code"];
        sql:ParameterizedQuery ins;
        if normalizedDb == "h2" {
            ins = `MERGE INTO "ClosureConceptTable" ("CLOSURECONTEXTTABLE_ID", "SYSTEM", "CODE", "CREATED_AT")
                   KEY("CLOSURECONTEXTTABLE_ID", "SYSTEM", "CODE")
                   VALUES (${name}, ${system}, ${code}, ${now})`;
        } else {
            ins = `INSERT INTO "ClosureConceptTable" ("CLOSURECONTEXTTABLE_ID", "SYSTEM", "CODE", "CREATED_AT")
                   VALUES (${name}, ${system}, ${code}, ${now})
                   ON CONFLICT DO NOTHING`;
        }
        _ = check jdbcClient->execute(ins);
    }

    int newVersion = currentVersion + 1;
    _ = check jdbcClient->execute(`UPDATE "ClosureContextTable" SET "VERSION_ID" = ${newVersion}, "UPDATED_AT" = ${now}, "LAST_UPDATED" = ${now}
                                   WHERE "CLOSURECONTEXTTABLE_ID" = ${name}`);

    // Lightweight: we do not compute new mapping entries yet (group stays empty).
    json conceptMap = buildClosureConceptMap(name, newVersion.toString(), string `Updates for Closure Table ${name}`, now, []);
    string cmJson = conceptMap.toJsonString();
    _ = check jdbcClient->execute(`INSERT INTO "ClosureDeltaTable" ("CLOSURECONTEXTTABLE_ID", "VERSION_ID", "CONCEPTMAP_JSON", "CREATED_AT")
                                   VALUES (${name}, ${newVersion}, ${cmJson}, ${now})`);
    return conceptMap;
}

isolated function buildClosureConceptMap(string id, string version, string name, time:Civil now, json[] groups) returns json {
    return {
        "resourceType": "ConceptMap",
        "id": id,
        "version": version,
        "name": name,
        "status": "active",
        "experimental": true,
        "date": utils:formatTimestampISO8601(now),
        "group": groups
    };
}

