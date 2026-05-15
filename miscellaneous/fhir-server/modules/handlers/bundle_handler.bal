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

import ballerina/log;
import ballerina/uuid;
import ballerinax/java.jdbc;

public class BundleHandler {
    private final jdbc:Client? jdbcClient;
    private CreateHandler createHandler;
    private UpdateHandler updateHandler;
    private DeleteHandler deleteHandler;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.jdbcClient = jdbcClient;
        self.createHandler = new CreateHandler(jdbcClient);
        self.updateHandler = new UpdateHandler(jdbcClient);
        self.deleteHandler = new DeleteHandler(jdbcClient);
    }

    public isolated function processBundle(json bundleJson) returns json|error {
        log:printInfo("Processing FHIR bundle request"); 
        if !(bundleJson is map<json>) {
            return error("Bundle payload must be a JSON object");
        }
        map<json> bundleMap = <map<json>>bundleJson;

        json typeJson = bundleMap["type"];
        if !(typeJson is string) {
            return error("Bundle.type is required and must be a string");
        }
        string bundleType = <string>typeJson;
        if bundleType != "transaction" && bundleType != "batch" {
            return error(string `Bundle.type must be 'transaction' or 'batch', got '${bundleType}'`);
        }

        json entriesJson = bundleMap["entry"];
        if entriesJson !is () && !(entriesJson is json[]) {  
            return error("Bundle.entry must be an array");  
        }
        json[] entries = entriesJson is json[] ? <json[]>entriesJson : [];

        map<string> placeholderMap = check self.assignIdsForPosts(entries);
        json[] resolvedEntries = self.rewriteReferences(entries, placeholderMap);

        json[] responseEntries = [];
        if bundleType == "transaction" {
            log:printInfo(string `Processing bundle as transaction with ${entries.length()} entries`);
            transaction {
                foreach json entry in resolvedEntries {
                    json responseEntry = check self.processEntry(entry);
                    responseEntries.push(responseEntry);
                }
                check commit;
            } on fail error e {
                log:printError(string `Bundle transaction failed: ${e.message()}`);
                return e;
            }
        } else {
            foreach json entry in resolvedEntries {
                json|error responseEntry = self.processEntry(entry);
                if responseEntry is error {
                    log:printWarn(string `Bundle batch entry failed: ${responseEntry.message()}`);
                    responseEntries.push({
                        response: {
                            status: "400 Bad Request",
                            outcome: {
                                resourceType: "OperationOutcome",
                                issue: [
                                    {
                                        severity: "error",
                                        code: "processing",
                                        diagnostics: responseEntry.message()
                                    }
                                ]
                            }
                        }
                    });
                } else {
                    responseEntries.push(responseEntry);
                }
            }
        }

        return {
            resourceType: "Bundle",
            'type: bundleType + "-response",
            entry: responseEntries
        };
    }

    private isolated function assignIdsForPosts(json[] entries) returns map<string>|error {
        map<string> mapping = {};

        foreach json entry in entries {
            if !(entry is map<json>) {
                continue;
            }
            map<json> entryMap = <map<json>>entry;

            json fullUrlJson = entryMap["fullUrl"];
            if !(fullUrlJson is string) {
                continue;
            }
            string fullUrl = <string>fullUrlJson;
            if !fullUrl.startsWith("urn:uuid:") {
                continue;
            }

            json requestJson = entryMap["request"];
            string method = "";
            if requestJson is map<json> {
                json methodJson = (<map<json>>requestJson)["method"];
                if methodJson is string {
                    method = (<string>methodJson).toUpperAscii();
                }
            }
            if method != "POST" {
                continue;
            }

            json resourceJson = entryMap["resource"];
            if !(resourceJson is map<json>) {
                continue;
            }
            map<json> resourceMap = <map<json>>resourceJson;

            json resourceTypeJson = resourceMap["resourceType"];
            if !(resourceTypeJson is string) {
                return error(string `POST entry with fullUrl '${fullUrl}' missing resource.resourceType`);
            }
            string resourceType = <string>resourceTypeJson;

            string id;
            json idJson = resourceMap["id"];
            if idJson is string && idJson != "" {
                id = <string>idJson;
            } else {
                id = uuid:createType4AsString();
            }
            mapping[fullUrl] = string `${resourceType}/${id}`;
        }

        return mapping;
    }

    private isolated function rewriteReferences(json[] entries, map<string> placeholderMap) returns json[] {
        json[] rewritten = [];
        foreach json entry in entries {
            if !(entry is map<json>) {
                rewritten.push(entry);
                continue;
            }
            map<json> entryMap = (<map<json>>entry).clone();

            json fullUrlJson = entryMap["fullUrl"];
            if fullUrlJson is string {
                string fullUrl = <string>fullUrlJson;
                if placeholderMap.hasKey(fullUrl) {
                    string resolvedRef = placeholderMap.get(fullUrl);
                    int? slashIdx = resolvedRef.indexOf("/");
                    if slashIdx is int {
                        string resolvedId = resolvedRef.substring(slashIdx + 1);
                        json resourceJson = entryMap["resource"];
                        if resourceJson is map<json> {
                            map<json> resourceMap = (<map<json>>resourceJson).clone();
                            resourceMap["id"] = resolvedId;
                            entryMap["resource"] = resourceMap;
                        }
                    }
                }
            }

            json resourceJson2 = entryMap["resource"];
            if resourceJson2 is map<json> || resourceJson2 is json[] {
                entryMap["resource"] = self.replacePlaceholdersInJson(resourceJson2, placeholderMap);
            }

            rewritten.push(entryMap);
        }
        return rewritten;
    }

    private isolated function replacePlaceholdersInJson(json input, map<string> placeholderMap) returns json {
        if input is map<json> {
            map<json> result = {};
            foreach var [key, value] in input.entries() {
                if key == "reference" && value is string {
                    string ref = <string>value;
                    if placeholderMap.hasKey(ref) {
                        result[key] = placeholderMap.get(ref);
                        continue;
                    }
                }
                result[key] = self.replacePlaceholdersInJson(value, placeholderMap);
            }
            return result;
        }
        if input is json[] {
            json[] result = [];
            foreach json item in input {
                result.push(self.replacePlaceholdersInJson(item, placeholderMap));
            }
            return result;
        }
        return input;
    }

    private isolated function processEntry(json entry) returns json|error {
        if !(entry is map<json>) {
            return error("Bundle entry must be a JSON object");
        }
        map<json> entryMap = <map<json>>entry;

        json requestJson = entryMap["request"];
        if !(requestJson is map<json>) {
            return error("Bundle entry missing required 'request' element");
        }
        map<json> requestMap = <map<json>>requestJson;

        json methodJson = requestMap["method"];
        json urlJson = requestMap["url"];
        if !(methodJson is string) {
            return error("Bundle entry request.method must be a string");
        }
        if !(urlJson is string) {
            return error("Bundle entry request.url must be a string");
        }
        string method = (<string>methodJson).toUpperAscii();
        string url = <string>urlJson;
        json resourceJson = entryMap["resource"];

        string[] urlParts = re `/`.split(url);
        if urlParts.length() == 0 || urlParts[0] == "" {
            return error(string `Invalid Bundle entry URL: '${url}'`);
        }
        string resourceType = urlParts[0];

        if method == "POST" {
            json|error result = self.createHandler.persistResource(resourceType, resourceJson);
            if result is error {
                return result;
            }
            string createdId = "";
            if result is map<json> {
                json idJson = (<map<json>>result)["id"];
                if idJson is string {
                    createdId = <string>idJson;
                }
            }
            return {
                response: {
                    status: "201 Created",
                    location: string `${resourceType}/${createdId}`
                },
                'resource: result
            };
        }

        if urlParts.length() < 2 || urlParts[1] == "" {
            return error(string `${method} URL must be of the form 'ResourceType/id', got '${url}'`);
        }
        string id = urlParts[1];

        if method == "PUT" {
            string|error result = self.updateHandler.persistUpdate(resourceType, id, resourceJson);
            if result is error {
                return result;
            }
            return {
                response: {
                    status: "200 OK",
                    location: string `${resourceType}/${id}`
                },
                'resource: resourceJson
            };
        }
        if method == "PATCH" {
            json|error result = self.updateHandler.persistPatch(resourceType, id, resourceJson);
            if result is error {
                return result;
            }
            return {
                response: {
                    status: "200 OK",
                    location: string `${resourceType}/${id}`
                },
                'resource: result
            };
        }
        if method == "DELETE" {
            boolean|error result = self.deleteHandler.persistDelete(resourceType, id);
            if result is error {
                return result;
            }
            return {response: {status: "204 No Content"}};
        }

        return error(string `Unsupported Bundle entry method: ${method}`);
    }
}
