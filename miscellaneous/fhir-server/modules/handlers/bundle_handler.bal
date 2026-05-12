import ballerina/log;
import ballerina/uuid;
import ballerinax/java.jdbc;

// WORK.md §5.3 / Phase 5 — Bundle transaction handler.
//
// FHIR `transaction` Bundles are the dominant ingest shape for Synthea
// (~100-300 entries each). Without this handler, every entry is a separate
// HTTP round-trip and a separate DB transaction → fsync amplification
// dominates throughput. Wrapping all entries from one Bundle inside a
// single Ballerina `transaction { ... check commit; }` amortizes fsync
// across the whole Bundle, and any per-entry failure rolls the whole
// thing back at the JDBC layer.
//
// Scope (intentional):
//   - Supports `Bundle.type = transaction` (atomic) and `batch` (best-effort).
//   - Dispatches POST / PUT / PATCH / DELETE to the existing handler core
//     methods (`persistResource` / `persistUpdate` / `persistPatch` /
//     `persistDelete`) — they don't open their own transaction blocks, so
//     they participate in the Bundle's transaction.
//   - Resolves `urn:uuid:` placeholder references for POST entries: every
//     POST with `fullUrl: "urn:uuid:X"` is given an id (the resource's own
//     id if present, else a fresh UUID), and every `reference: "urn:uuid:X"`
//     elsewhere in the Bundle is rewritten to `ResourceType/id` before any
//     DB work happens. This is the minimum needed to ingest Synthea bundles.
//
// Out of scope (deferred, will return 4xx if encountered):
//   - Conditional create / update / delete (`If-None-Exist`, search-URL).
//   - GET entries inside a transaction.
//   - Bundle re-ordering by entry type per FHIR §3.2.0.16.2; entries are
//     processed in the order received.
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
        json[] entries = entriesJson is json[] ? <json[]>entriesJson : [];

        // Mint ids for POST entries with urn:uuid: placeholders, then rewrite
        // any cross-entry references in resource bodies. Done once up front
        // so the inserts inside the transaction can use real ids.
        map<string> placeholderMap = check self.assignIdsForPosts(entries);
        json[] resolvedEntries = self.rewriteReferences(entries, placeholderMap);

        json[] responseEntries = [];
        if bundleType == "transaction" {
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
            // batch: each entry independent — failures don't affect siblings.
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

    // For every POST entry whose fullUrl is a urn:uuid: placeholder, decide
    // the id it will land at and remember it. Prefers the resource's own id
    // when present (so client-assigned ids round-trip), otherwise mints a
    // fresh v4 UUID. No DB writes here — pure planning.
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

    // Walk every entry and replace placeholder references with the real
    // ResourceType/id form. Also stamps the resolved id back into the POST
    // resource (so the create handler sees a concrete id) for any entry
    // whose fullUrl was minted above.
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

    // Recursively replace `"reference": "urn:uuid:X"` with the resolved
    // value. Walks maps and arrays; leaves scalars alone.
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

        // FHIR transaction urls have the shape "ResourceType" (POST) or
        // "ResourceType/id" (PUT / PATCH / DELETE / GET). Anything richer
        // (search-URL conditional refs, ?_format, etc.) we don't yet handle.
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
