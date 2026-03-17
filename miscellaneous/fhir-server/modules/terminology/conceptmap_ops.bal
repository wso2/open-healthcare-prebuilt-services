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

import ballerinax/java.jdbc;
import ballerina/log;

// ------------------------------------------------------------
// ConceptMap operations: $translate
// ($closure is wired separately via closure_store)
// ------------------------------------------------------------

public isolated function translate(jdbc:Client jdbcClient, json? parametersJson = (), string? id = (),
    string? system = (), string? code = (), string? targetSystem = ()) returns json|error {
    log:printDebug("Starting translate operation", system = system, code = code, targetSystem = targetSystem, id = id);
    json params = parametersJson is () ? {"resourceType": "Parameters", "parameter": []} : <json>parametersJson;

    string? sys = system;
    string? cd = code;
    map<json>? coding = getParameterCoding(params, "coding");
    if (sys is () || cd is ()) && coding is map<json> {
        if sys is () && coding["system"] is string {
            sys = <string>coding["system"];
        }
        if cd is () && coding["code"] is string {
            cd = <string>coding["code"];
        }
    }
    if sys is () {
        sys = getParameterString(params, "system");
    }
    if cd is () {
        cd = getParameterString(params, "code");
    }

    if cd is () {
        return error("Missing required parameter: code (or coding)");
    }

    json cm = check resolveConceptMapForOperation(jdbcClient, parametersJson, id);
    Translation? tr = findTranslation(cm, sys, cd, targetSystem);

    if tr is () {
        log:printDebug("No translation found", system = sys, code = cd, targetSystem = targetSystem, id = id);
        return {
            "resourceType": "Parameters",
            "parameter": [
                {"name": "result", "valueBoolean": false},
                {"name": "message", "valueString": "No translation found"}
            ]
        };
    }

    map<json> outCoding = {
        "system": tr.targetSystem,
        "code": tr.targetCode
    };
    if tr.targetDisplay is string {
        outCoding["display"] = tr.targetDisplay;
    }

    return {
        "resourceType": "Parameters",
        "parameter": [
            {"name": "result", "valueBoolean": true},
            {"name": "outcome", "valueCoding": outCoding}
        ]
    };
}

// ------------------------------------------------------------
// Internals
// ------------------------------------------------------------

type Translation record {|
    string targetSystem;
    string targetCode;
    string? targetDisplay;
|};

isolated function resolveConceptMapForOperation(jdbc:Client jdbcClient, json? parametersJson, string? id) returns json|error {
    // 1) explicit id in URL path
    if id is string {
        return readResourceJsonById(jdbcClient, "ConceptMap", id);
    }

    // 2) inline Parameters.conceptMap.resource (if present)
    if parametersJson !is () {
        map<json>? inline = getParameterResource(<json>parametersJson, "conceptMap");
        if inline is map<json> && inline["resourceType"] is string && <string>inline["resourceType"] == "ConceptMap" {
            return inline;
        }
    }

    return error("ConceptMap not specified (need id or inline Parameters.conceptMap)");
}

isolated function findTranslation(json conceptMap, string? sourceSystem, string sourceCode, string? targetSystemHint) returns Translation? {
    if conceptMap !is map<json> {
        return ();
    }
    json? groups = (<map<json>>conceptMap)["group"];
    if !(groups is json[]) {
        return ();
    }

    foreach json g in groups {
        if g !is map<json> {
            continue;
        }

        // Optional group-level system hints
        string? gSource = g["source"] is string ? <string>g["source"] : ();
        string? gTarget = g["target"] is string ? <string>g["target"] : ();

        if sourceSystem is string && gSource is string && sourceSystem != gSource {
            continue;
        }
        if targetSystemHint is string && gTarget is string && targetSystemHint != gTarget {
            continue;
        }

        json? elements = g["element"];
        if !(elements is json[]) {
            continue;
        }

        foreach json e in elements {
            if e !is map<json> {
                continue;
            }
            if !(e["code"] is string) {
                continue;
            }
            if <string>e["code"] != sourceCode {
                continue;
            }
            json? targets = e["target"];
            if !(targets is json[]) {
                continue;
            }
            foreach json t in targets {
                if t !is map<json> {
                    continue;
                }
                if !(t["code"] is string) {
                    continue;
                }
                string tgtCode = <string>t["code"];
                string tgtSystem = gTarget is string ? gTarget : (targetSystemHint is string ? targetSystemHint : "");
                if tgtSystem == "" {
                    // Without a target system, we can’t build a Coding reliably
                    continue;
                }
                string? tgtDisplay = t["display"] is string ? <string>t["display"] : ();
                return {targetSystem: tgtSystem, targetCode: tgtCode, targetDisplay: tgtDisplay};
            }
        }
    }
    return ();
}

