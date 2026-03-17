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
// CodeSystem operations: $lookup, $subsumes
// ------------------------------------------------------------

public isolated function lookupCode(jdbc:Client jdbcClient, json? parametersJson = (), string? id = (), string? system = (), string? code = ()) returns json|error {
    log:printDebug("Starting lookupCode operation", system = system, code = code, id = id);
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
        return error("Missing required parameter: code");
    }

    json codesystemJson = check resolveCodeSystemForOperation(jdbcClient, parametersJson, id, sys);

    // Require local concept content
    ConceptNode? node = findConceptNode(codesystemJson, cd);
    if node is () {
        return error(string `Code not found in local CodeSystem: ${cd}`);
    }

    json[] outParams = [];
    if (codesystemJson is map<json>) {
        map<json> m = <map<json>>codesystemJson;
        if m["name"] is string {
            outParams.push({"name": "name", "valueString": <string>m["name"]});
        }
        if m["version"] is string {
            outParams.push({"name": "version", "valueString": <string>m["version"]});
        }
    }
    if node.display is string {
        outParams.push({"name": "display", "valueString": node.display});
    }
    if node.definition is string {
        outParams.push({"name": "definition", "valueString": node.definition});
    }

    return {"resourceType": "Parameters", "parameter": outParams};
}

public isolated function subsumes(jdbc:Client jdbcClient, json? parametersJson = (), string? id = (),
    string? system = (), string? codeA = (), string? codeB = ()) returns json|error {

    json params = parametersJson is () ? {"resourceType": "Parameters", "parameter": []} : <json>parametersJson;

    string? sys = system;
    if sys is () {
        sys = getParameterString(params, "system");
    }

    string? a = codeA;
    string? b = codeB;
    if a is () {
        a = getParameterString(params, "codeA");
    }
    if b is () {
        b = getParameterString(params, "codeB");
    }

    if a is () || b is () {
        return error("Missing required parameters: codeA and codeB");
    }

    json cs = check resolveCodeSystemForOperation(jdbcClient, parametersJson, id, sys);

    string out = check computeSubsumption(cs, a, b);
    return {"resourceType": "Parameters", "parameter": [{"name": "outcome", "valueCode": out}]};
}

// ------------------------------------------------------------
// Internals
// ------------------------------------------------------------

isolated function resolveCodeSystemForOperation(jdbc:Client jdbcClient, json? parametersJson, string? id, string? system) returns json|error {
    // 1) explicit id in URL path
    if id is string {
        return readResourceJsonById(jdbcClient, "CodeSystem", id);
    }

    // 2) system URL to find by URL column
    string? canonical = system;
    if canonical is () && parametersJson !is () {
        canonical = getParameterString(<json>parametersJson, "system");
    }
    if canonical is string {
        return readResourceJsonByColumn(jdbcClient, "CodeSystem", "URL", canonical);
    }
    return error("CodeSystem not specified (need id or system url)");
}

public isolated function isCodeInSystem(jdbc:Client jdbcClient, string systemUrl, string code) returns boolean|error {
    json cs = check resolveCodeSystemForOperation(jdbcClient, (), (), systemUrl);
    ConceptNode? node = findConceptNode(cs, code);
    if node is () {
        return false;
    }
    return true;
}

type ConceptNode record {|
    string code;
    string? display;
    string? definition;
    string[] children;
|};

isolated function computeSubsumption(json cs, string codeA, string codeB) returns string|error {
    if codeA == codeB {
        return "equivalent";
    }

    map<string[]> parentToChildren = buildHierarchy(cs);
    // Determine ancestry via DFS from A and B
    if isAncestor(parentToChildren, codeA, codeB, {}) {
        return "subsumes";
    }
    if isAncestor(parentToChildren, codeB, codeA, {}) {
        return "subsumed-by";
    }
    return "not-subsumed";
}

isolated function buildHierarchy(json cs) returns map<string[]> {
    map<string[]> out = {};
    if cs !is map<json> {
        return out;
    }
    json? conceptArr = (<map<json>>cs)["concept"];
    if !(conceptArr is json[]) {
        return out;
    }
    foreach json c in conceptArr {
        if c is map<json> {
            addConcept(out, c);
        }
    }
    return out;
}

isolated function addConcept(map<string[]> parentToChildren, map<json> conceptJson) {
    if !(conceptJson["code"] is string) {
        return;
    }
    string code = <string>conceptJson["code"];
    json? children = conceptJson["concept"];
    if children is json[] {
        string[] childCodes = [];
        foreach json child in children {
            if child is map<json> && child["code"] is string {
                childCodes.push(<string>child["code"]);
                addConcept(parentToChildren, child);
            }
        }
        if childCodes.length() > 0 {
            parentToChildren[code] = childCodes;
        }
    }
}

isolated function isAncestor(map<string[]> parentToChildren, string ancestor, string target, map<boolean> visited) returns boolean {
    if visited.hasKey(ancestor) {
        return false;
    }
    visited[ancestor] = true;
    if !parentToChildren.hasKey(ancestor) {
        return false;
    }
    string[] kids = parentToChildren.get(ancestor);
    foreach string k in kids {
        if k == target {
            return true;
        }
        if isAncestor(parentToChildren, k, target, visited) {
            return true;
        }
    }
    return false;
}

isolated function findConceptNode(json cs, string code) returns ConceptNode? {
    if cs !is map<json> {
        return ();
    }
    json? conceptArr = (<map<json>>cs)["concept"];
    if !(conceptArr is json[]) {
        return ();
    }
    foreach json c in conceptArr {
        if c is map<json> {
            ConceptNode? found = findConceptNodeRec(c, code);
            if found is ConceptNode {
                return found;
            }
        }
    }
    return ();
}

isolated function findConceptNodeRec(map<json> conceptJson, string code) returns ConceptNode? {
    if conceptJson["code"] is string && <string>conceptJson["code"] == code {
        string? display = conceptJson["display"] is string ? <string>conceptJson["display"] : ();
        string? definition = conceptJson["definition"] is string ? <string>conceptJson["definition"] : ();
        string[] children = [];
        json? arr = conceptJson["concept"];
        if arr is json[] {
            foreach json ch in arr {
                if ch is map<json> && ch["code"] is string {
                    children.push(<string>ch["code"]);
                }
            }
        }
        return {code, display, definition, children};
    }

    json? children = conceptJson["concept"];
    if children is json[] {
        foreach json child in children {
            if child is map<json> {
                ConceptNode? found = findConceptNodeRec(child, code);
                if found is ConceptNode {
                    return found;
                }
            }
        }
    }
    return ();
}

