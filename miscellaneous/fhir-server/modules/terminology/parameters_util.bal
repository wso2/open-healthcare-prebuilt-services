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

// Utilities to read common operation inputs from a Parameters resource (as JSON).

public isolated function getParameterString(json params, string name) returns string? {
    if params !is map<json> {
        return ();
    }
    json? arr = (<map<json>>params)["parameter"];
    if !(arr is json[]) {
        return ();
    }
    foreach json p in arr {
        if p !is map<json> {
            continue;
        }
        if p["name"] is string && <string>p["name"] == name {
            // Common value[x] keys we care about
            foreach string key in ["valueString", "valueUri", "valueCode", "valueId"] {
                if p[key] is string {
                    return <string>p[key];
                }
            }
        }
    }
    return ();
}

public isolated function getParameterCoding(json params, string name) returns map<json>? {
    if params !is map<json> {
        return ();
    }
    json? arr = (<map<json>>params)["parameter"];
    if !(arr is json[]) {
        return ();
    }
    foreach json p in arr {
        if p !is map<json> {
            continue;
        }
        if p["name"] is string && <string>p["name"] == name {
            json? vc = p["valueCoding"];
            if vc is map<json> {
                return vc;
            }
        }
    }
    return ();
}

public isolated function getParameterResource(json params, string name) returns map<json>? {
    if params !is map<json> {
        return ();
    }
    json? arr = (<map<json>>params)["parameter"];
    if !(arr is json[]) {
        return ();
    }
    foreach json p in arr {
        if p !is map<json> {
            continue;
        }
        if p["name"] is string && <string>p["name"] == name {
            json? r = p["resource"];
            if r is map<json> {
                return r;
            }
        }
    }
    return ();
}

public isolated function getParameterCodings(json params, string name) returns map<json>[] {
    map<json>[] out = [];
    if params !is map<json> {
        return out;
    }
    json? arr = (<map<json>>params)["parameter"];
    if !(arr is json[]) {
        return out;
    }
    foreach json p in arr {
        if p !is map<json> {
            continue;
        }
        if p["name"] is string && <string>p["name"] == name {
            json? vc = p["valueCoding"];
            if vc is map<json> {
                out.push(vc);
            }
        }
    }
    return out;
}

public isolated function getParameterCodeableConceptFirstCoding(json params, string name) returns map<json>? {
    if params !is map<json> {
        return ();
    }
    json? arr = (<map<json>>params)["parameter"];
    if !(arr is json[]) {
        return ();
    }
    foreach json p in arr {
        if p !is map<json> {
            continue;
        }
        if p["name"] is string && <string>p["name"] == name {
            json? cc = p["valueCodeableConcept"];
            if cc !is map<json> {
                continue;
            }
            json? codings = (<map<json>>cc)["coding"];
            if !(codings is json[]) {
                continue;
            }
            foreach json c in codings {
                if c is map<json> {
                    return c;
                }
            }
        }
    }
    return ();
}


