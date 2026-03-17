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

import ballerina/time;
import ballerina/io;
import ballerinax/java.jdbc;

// ------------------------------------------------------------
// ValueSet operations: $expand, $validate-code
// ------------------------------------------------------------

public isolated function expandValueSet(jdbc:Client jdbcClient, json? parametersJson = (), string? id = (), string? url = (),
    string? filter = (), int? offset = (), int? count = ()) returns json|error {

    json valuesetJson = check resolveValueSetForOperation(jdbcClient, parametersJson, id, url);

    // Build expansion concepts from compose.include[].concept[]
    Concept[] concepts = check extractComposeConcepts(valuesetJson);

    // Apply filter (on code/display)
    if filter is string && filter.length() > 0 {
        string f = filter.toLowerAscii();
        Concept[] filtered = [];
        foreach Concept c in concepts {
            string d = c.display is string ? <string>c.display : "";
            if c.code.toLowerAscii().includes(f) || d.toLowerAscii().includes(f) {
                filtered.push(c);
            }
        }
        concepts = filtered;
    }

    int off = offset is int ? offset : 0;
    int cnt = count is int ? count : concepts.length();
    if off < 0 {
        off = 0;
    }
    if cnt < 0 {
        cnt = 0;
    }

    Concept[] page = [];
    int idx = 0;
    foreach Concept c in concepts {
        if idx >= off && page.length() < cnt {
            page.push(c);
        }
        idx += 1;
    }

    // Create ValueSet response with expansion
    map<json> out = valuesetJson is map<json> ? (<map<json>>valuesetJson).clone() : {};
    time:Utc t = time:utcNow();
    string ts = time:utcToString(t);

    json[] contains = [];
    foreach Concept c in page {
        map<json> entry = {
            "system": c.system,
            "code": c.code
        };
        if c.display is string && c.display != "" {
            entry["display"] = c.display;
        }
        contains.push(entry);
    }

    map<json> expansion = {
        "timestamp": ts,
        "total": concepts.length(),
        "contains": contains
    };
    if off > 0 {
        expansion["offset"] = off;
    }
    out["expansion"] = expansion;
    return out;
}

public isolated function validateCodeInValueSet(jdbc:Client jdbcClient, json? parametersJson = (), string? id = (), string? url = (),
    string? system = (), string? code = (), string? display = ()) returns json|error {

    // Resolve code/system from Parameters if not explicitly provided
    json params = parametersJson is () ? {"resourceType": "Parameters", "parameter": []} : <json>parametersJson;
    string? sys = system;
    string? cd = code;
    string? disp = display;

    // valueCoding input
    map<json>? coding = getParameterCoding(params, "coding");
    if (sys is () || cd is ()) && coding is map<json> {
        if sys is () && coding["system"] is string {
            sys = <string>coding["system"];
        }
        if cd is () && coding["code"] is string {
            cd = <string>coding["code"];
        }
        if disp is () && coding["display"] is string {
            disp = <string>coding["display"];
        }
    }

    // codeableConcept input (use the first coding)
    if sys is () || cd is () {
        map<json>? ccCoding = getParameterCodeableConceptFirstCoding(params, "codeableConcept");
        if ccCoding is map<json> {
            if sys is () && ccCoding["system"] is string {
                sys = <string>ccCoding["system"];
            }
            if cd is () && ccCoding["code"] is string {
                cd = <string>ccCoding["code"];
            }
            if disp is () && ccCoding["display"] is string {
                disp = <string>ccCoding["display"];
            }
        }
    }

    if sys is () {
        sys = getParameterString(params, "system");
    }
    if cd is () {
        cd = getParameterString(params, "code");
    }
    if disp is () {
        disp = getParameterString(params, "display");
    }

    if sys is () || cd is () {
        return error("Missing required parameters: system and code");
    }

    json valuesetJson = check resolveValueSetForOperation(jdbcClient, parametersJson, id, url);
    Concept[] concepts = check extractComposeConcepts(valuesetJson);

    boolean ok = false;
    string? actualDisplay = ();
    foreach Concept c in concepts {
        if c.system == sys && c.code == cd {
            ok = true;
            actualDisplay = c.display;
            break;
        }
    }

    boolean systemIncluded = false;
    if !ok {
        string s = <string>sys;
        string c = <string>cd;
        systemIncluded = isSystemFullyIncluded(valuesetJson, s);
        if systemIncluded {
            boolean|error csOkOrErr = isCodeInSystem(jdbcClient, s, c);
            if csOkOrErr is error {
                return csOkOrErr;
            }
            boolean csOk = <boolean>csOkOrErr;
            if csOk {
                ok = true;
            }
        }
    }

    // #region agent log
    json debugLog = {
        sessionId: "8705e3",
        runId: "run1",
        hypothesisId: "A",
        location: "modules/terminology/valueset_ops.bal:validateCodeInValueSet",
        message: "validate-code evaluation",
        data: {
            id: id,
            url: url,
            system: sys,
            code: cd,
            display: disp,
            conceptCount: concepts.length(),
            ok: ok,
            systemIncluded: systemIncluded
        },
        timestamp: time:utcToString(time:utcNow())
    };
    string debugLine = debugLog.toJsonString() + "\n";
    checkpanic io:fileWriteString(
        "/Users/sameerag/WSO2/dev/repos/open-healthcare-choreo-accelerators/.cursor/debug-8705e3.log",
        debugLine);
    // #endregion

    json[] paramOut = [];
    paramOut.push({"name": "result", "valueBoolean": ok});
    if ok {
        if actualDisplay is string {
            paramOut.push({"name": "display", "valueString": actualDisplay});
        }
        if disp is string && actualDisplay is string && disp != "" && disp != actualDisplay {
            paramOut.push({"name": "message", "valueString": string `The display \"${disp}\" is incorrect`});
        }
    } else {
        paramOut.push({"name": "message", "valueString": "The concept is not in the specified value set"});
    }

    return {"resourceType": "Parameters", "parameter": paramOut};
}

// ------------------------------------------------------------
// Internals
// ------------------------------------------------------------

type Concept record {|
    string system;
    string code;
    string? display;
|};

isolated function resolveValueSetForOperation(jdbc:Client jdbcClient, json? parametersJson, string? id, string? url) returns json|error {
    // 1) inline Parameters.valueSet.resource
    if !(parametersJson is ()) {
        map<json>? inlineVs = getParameterResource(<json>parametersJson, "valueSet");
        if inlineVs is map<json> && inlineVs["resourceType"] is string && <string>inlineVs["resourceType"] == "ValueSet" {
            return inlineVs;
        }
    }

    // 2) explicit id in URL path
    if id is string {
        return readResourceJsonById(jdbcClient, "ValueSet", id);
    }

    // 3) url input from query or Parameters.uri/url
    string? canonical = url;
    if canonical is () && parametersJson !is () {
        canonical = getParameterString(<json>parametersJson, "url");
        if canonical is () {
            canonical = getParameterString(<json>parametersJson, "uri");
        }
    }

    if canonical is string {
        // DB column is "URL" in schema
        json|error vs = readResourceJsonByColumn(jdbcClient, "ValueSet", "URL", canonical);
        return vs;
    }

    return error("ValueSet not specified (need id, url/uri, or inline Parameters.valueSet)");
}

isolated function extractComposeConcepts(json valuesetJson) returns Concept[]|error {
    // Preferred: ValueSet.compose.include[].system + include[].concept[]
    // Fallback: ValueSet.expansion.contains[] (for pre-expanded ValueSets like core HL7 ones)
    if valuesetJson !is map<json> {
        return error("Invalid ValueSet JSON");
    }

    map<json> m = <map<json>>valuesetJson;
    json? compose = m["compose"];
    Concept[] out = [];
    if compose is map<json> {
        json? includeArr = (<map<json>>compose)["include"];
        if includeArr is json[] {
            foreach json inc in includeArr {
                if inc !is map<json> {
                    continue;
                }
                string? system = inc["system"] is string ? <string>inc["system"] : ();
                if system is () {
                    // local-only implementation needs system to build contains entries
                    continue;
                }
                json? conceptArr = inc["concept"];
                if !(conceptArr is json[]) {
                    // We don’t support include.filter / include.valueSet composition yet.
                    continue;
                }
                foreach json c in conceptArr {
                    if c !is map<json> {
                        continue;
                    }
                    if !(c["code"] is string) {
                        continue;
                    }
                    string code = <string>c["code"];
                    string? display = c["display"] is string ? <string>c["display"] : ();
                    out.push({system, code, display});
                }
            }
        }
    }

    // Fallback: look at expansion.contains if compose/include concepts are not available
    if out.length() == 0 {
        json? expansion = m["expansion"];
        if expansion is map<json> {
            json? containsArr = expansion["contains"];
            if containsArr is json[] {
                foreach json c in containsArr {
                    if c !is map<json> {
                        continue;
                    }
                    if !(c["system"] is string && c["code"] is string) {
                        continue;
                    }
                    string system = <string>c["system"];
                    string code = <string>c["code"];
                    string? display = c["display"] is string ? <string>c["display"] : ();
                    out.push({system, code, display});
                }
            }
        }
    }

    if out.length() == 0 {
        return error("Unsupported ValueSet: no compose.include[].concept[] or expansion.contains[] content to expand");
    }

    return out;
}

isolated function isSystemFullyIncluded(json valuesetJson, string sys) returns boolean {
    if valuesetJson !is map<json> {
        return false;
    }
    map<json> m = <map<json>>valuesetJson;
    json? compose = m["compose"];
    if compose !is map<json> {
        return false;
    }
    json? includeArr = (<map<json>>compose)["include"];
    if !(includeArr is json[]) {
        return false;
    }
    foreach json inc in includeArr {
        if inc !is map<json> {
            continue;
        }
        if !(inc["system"] is string) {
            continue;
        }
        string incSystem = <string>inc["system"];
        if incSystem != sys {
            continue;
        }
        // Treat "whole system" includes (no concept/filter/valueSet) as including any code in that system.
        boolean hasConcept = inc["concept"] is json[];
        boolean hasFilter = inc["filter"] is json[];
        boolean hasVs = inc["valueSet"] is json[] || inc["valueSet"] is string;
        if !hasConcept && !hasFilter && !hasVs {
            return true;
        }
    }
    return false;
}

