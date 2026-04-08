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
import ballerina/io;
import ballerina/log;
import ballerina/url;
import ballerinax/h2.driver as _;
import ballerinax/java.jdbc;

configurable string hostname = "localhost";
configurable int port = 9091;
configurable string consentContextApiBaseUrl = "https://localhost:9443";
configurable string consentContextApiPath = "/api/identity/auth/v1.1/data/OauthConsentKey";
configurable string consentContextApiUsername = "";
configurable string consentContextApiPassword = "";
configurable string consentContextApiTrustStorePath = "";
configurable string consentContextApiTrustStorePassword = "";
configurable string consentAuthorizeRedirectUrl = "";
configurable string consentStoreDbUrl = "jdbc:h2:./resources/consent_scopes";
configurable string consentStoreDbUser = "sa";
configurable string consentStoreDbPassword = "";

// Path to the Vite build output (dist/) folder
configurable string uiDistPath = "resources/consent-ui";

final jdbc:Client consentStoreDbClient = checkpanic new (
    url = consentStoreDbUrl,
    user = consentStoreDbUser,
    password = consentStoreDbPassword
);

function init() returns error? {
    log:printInfo("Initializing consent service on " + hostname + ":" + port.toString());
    check initConsentScopeStore();
}

listener http:Listener consentListener = new (port, config = {host: hostname});

service / on consentListener {

    resource function get consent(http:Request req) returns http:Response {
        map<string[]> queryParams = req.getQueryParams();
        string? sessionDataKeyConsent = getFirstValue(queryParams, "sessionDataKeyConsent");
        string spId = getFirstValue(queryParams, "spId") ?: "";

        if !(sessionDataKeyConsent is string) || sessionDataKeyConsent == "" {
            return buildTextResponse(400, "Missing required query parameter: sessionDataKeyConsent");
        }

        json|error consentContext = fetchConsentContext(sessionDataKeyConsent);
        if consentContext is error {
            log:printError("Failed to load consent context", 'error = consentContext);
            return buildTextResponse(502, "Failed to load consent context data");
        }

        string[] scopes = extractScopesFromContext(consentContext);
        string user = extractUserFromContext(consentContext);

        string|error html = io:fileReadString(uiDistPath + "/index.html");
        if html is error {
            log:printError("Failed to read React app index.html", 'error = html);
            return buildTextResponse(500, "UI build not found. Run 'npm run build' and copy dist/ to " + uiDistPath);
        }

        json consentProps = {
            sessionDataKeyConsent,
            spId,
            user,
            scopes,
            contextJson: consentContext.toJsonString()
        };
        string consentPropsJson = escapeForScriptTag(consentProps.toJsonString());
        string injectedScript = string `<script id="consent-props" type="application/json">${consentPropsJson}</script>` +
            string `<script>window.__CONSENT_PROPS__=JSON.parse(document.getElementById("consent-props")?.textContent||"{}");</script>`;

        string finalHtml = re`</body>`.replaceAll(html, injectedScript + "</body>");

        http:Response response = new;
        response.setHeader("Content-Type", "text/html; charset=utf-8");
        response.setPayload(finalHtml);
        return response;
    }

    resource function get approved\-scopes(http:Request req) returns http:Response {
        map<string[]> queryParams = req.getQueryParams();
        string sessionDataKeyConsent = getFirstValue(queryParams, "sessionDataKeyConsent") ?: "";
        if sessionDataKeyConsent == "" {
            return buildTextResponse(400, "Missing required query parameter: sessionDataKeyConsent");
        }

        string[]|error approvedScopes = getApprovedScopesByConsentKey(sessionDataKeyConsent);
        if approvedScopes is error {
            log:printError("Failed to load approved scopes", 'error = approvedScopes,
                sessionDataKeyConsent = sessionDataKeyConsent);
            return buildTextResponse(500, "Failed to load approved scopes");
        }

        http:Response response = new;
        response.setHeader("Content-Type", "application/json");
        response.setPayload({
            sessionDataKeyConsent,
            scopes: approvedScopes
        });
        return response;
    }

    // Serve Vite static assets (JS/CSS chunks)
    resource function get assets/[string... parts](http:Caller caller) returns error? {
        if parts.length() == 0 {
            check caller->respond(buildTextResponse(404, "Asset not found"));
            return;
        }

        string assetsBasePath = normalizePath(uiDistPath + "/assets");
        string requestedRelativePath = string:'join("/", ...parts);
        string candidatePath = normalizePath(assetsBasePath + "/" + requestedRelativePath);

        boolean isWithinAssetsDir = candidatePath == assetsBasePath ||
            candidatePath.startsWith(assetsBasePath + "/");
        if !isWithinAssetsDir {
            check caller->respond(buildTextResponse(404, "Asset not found"));
            return;
        }

        byte[]|error content = io:fileReadBytes(candidatePath);
        if content is error {
            http:Response res = buildTextResponse(404, "Asset not found");
            check caller->respond(res);
            return;
        }

        http:Response response = new;
        response.setBinaryPayload(content, getMimeType(parts[parts.length() - 1]));
        check caller->respond(response);
    }

    resource function post consent(http:Request req) returns http:Response {
        string|error payload = req.getTextPayload();
        if payload is error {
            return buildTextResponse(400, "Invalid form payload");
        }

        map<string[]> form = parseFormUrlEncoded(payload);
        string sessionDataKeyConsent = getFirstValue(form, "SessionDataKeyConsent") ?: "";
        string consent = getFirstValue(form, "Consent") ?: "approve";
        string hasApprovedAlways = getFirstValue(form, "hasApprovedAlways") ?: "false";
        string userClaimsConsent = getFirstValue(form, "User_claims_consent") ?: "true";
        string user = getFirstValue(form, "user") ?: "";
        string spId = getFirstValue(form, "spId") ?: "";
        string[] selectedScopes = form["scope"] ?: [];

        if consentAuthorizeRedirectUrl == "" {
            json result = {
                SessionDataKeyConsent: sessionDataKeyConsent,
                Consent: consent,
                hasApprovedAlways: hasApprovedAlways,
                User_claims_consent: userClaimsConsent,
                user: user,
                spId: spId,
                scopes: selectedScopes
            };
            http:Response response = new;
            response.setHeader("Content-Type", "application/json");
            response.setPayload(result);
            return response;
        }

        if consent != "deny" {
            log:printDebug("Storing approved scopes for consent", sessionDataKeyConsent = sessionDataKeyConsent, 
                scopeCount = selectedScopes.length());
            error? storeErr = storeApprovedScopesByConsentKey(sessionDataKeyConsent, selectedScopes);
            if storeErr is error {
                log:printError("Failed to persist approved scopes", 'error = storeErr,
                    sessionDataKeyConsent = sessionDataKeyConsent);
                return buildTextResponse(500, "Failed to store approved scopes");
            }
        }

        string cookieHeader = "";
        string|http:HeaderNotFoundError cookieVal = req.getHeader("Cookie");
        if cookieVal is string {
            cookieHeader = cookieVal;
        }
        if cookieHeader == "" {
            return buildTextResponse(400, "Missing session cookies. Ensure consent page is loaded over HTTPS.");
        }

        boolean hasJSessionId = cookieHeader.indexOf("JSESSIONID=") is int;
        boolean hasOpbs = cookieHeader.indexOf("opbs=") is int;
        boolean hasCommonAuthId = cookieHeader.indexOf("commonAuthId=") is int;
        if !hasJSessionId && !hasOpbs && !hasCommonAuthId {
            return buildTextResponse(400,
                "No recognizable IS session cookie found (expected one of JSESSIONID/opbs/commonAuthId).");
        }
        if !hasJSessionId || !hasOpbs {
            log:printWarn("Some IS session cookies are missing in browser request; continuing with available cookies",
                hasJSessionId = hasJSessionId, hasOpbs = hasOpbs, hasCommonAuthId = hasCommonAuthId);
        }
        if consent != "deny" && user == "" {
            return buildTextResponse(400, "Missing authenticated user in consent context.");
        }

        string|error locationUri = postAuthorizeRequest(sessionDataKeyConsent, consent, hasApprovedAlways,
            user, spId, selectedScopes, cookieHeader);
        if locationUri is error {
            log:printError("Authorize POST failed", 'error = locationUri);
            return buildTextResponse(502, "Authorize request failed: " + locationUri.message());
        }

        http:Response redirect = new;
        redirect.statusCode = 302;
        redirect.setHeader("Location", locationUri);
        return redirect;
    }
}

// ─── HTTP helpers ──────────────────────────────────────────────────────────────

function fetchConsentContext(string sessionDataKeyConsent) returns json|error {
    if consentContextApiUsername == "" || consentContextApiPassword == "" {
        return error("consentContextApiUsername or consentContextApiPassword is not configured");
    }
    if consentContextApiBaseUrl.startsWith("https://") &&
        (consentContextApiTrustStorePath == "" || consentContextApiTrustStorePassword == "") {
        return error("consentContextApiTrustStorePath or consentContextApiTrustStorePassword is not configured");
    }

    http:ClientConfiguration clientConfig = {
        auth: {username: consentContextApiUsername, password: consentContextApiPassword}
    };
    if consentContextApiBaseUrl.startsWith("https://") {
        clientConfig.secureSocket = {
            cert: {path: consentContextApiTrustStorePath, password: consentContextApiTrustStorePassword}
        };
    }

    http:Client contextClient = check new (consentContextApiBaseUrl, clientConfig);
    string path = consentContextApiPath + "/" + getEncodedUri(sessionDataKeyConsent);
    http:Response response = check contextClient->get(path, headers = {accept: "application/json"});

    if response.statusCode < 200 || response.statusCode >= 300 {
        string body = check response.getTextPayload();
        return error(string `Context API returned status ${response.statusCode}: ${body}`);
    }
    return check response.getJsonPayload();
}

function postAuthorizeRequest(string sessionDataKeyConsent, string consent, string hasApprovedAlways,
    string user, string spId, string[] selectedScopes, string cookieHeader) returns string|error {

    http:ClientConfiguration clientConfig = {followRedirects: {enabled: false}};
    if consentAuthorizeRedirectUrl.startsWith("https://") &&
            consentContextApiTrustStorePath != "" && consentContextApiTrustStorePassword != "" {
        clientConfig.secureSocket = {
            cert: {
                path: consentContextApiTrustStorePath,
                password: consentContextApiTrustStorePassword
            }
        };
    }

    http:Client authorizeClient = check new (consentAuthorizeRedirectUrl, clientConfig);

    string body = string `sessionDataKeyConsent=${getEncodedUri(sessionDataKeyConsent)}` +
        string `&consent=${getEncodedUri(consent)}` +
        string `&hasApprovedAlways=${getEncodedUri(hasApprovedAlways)}` +
        string `&consent_custom_attribute="customAttr"` +
        string `&user=${getEncodedUri(user)}`;

    if selectedScopes.length() > 0 {
        body += string `&scope=${getEncodedUri(string:'join(" ", ...selectedScopes))}`;
    }

    http:Request authorizeReq = new;
    authorizeReq.setHeader("Content-Type", "application/x-www-form-urlencoded");
    authorizeReq.setHeader("Cookie", cookieHeader);
    authorizeReq.setPayload(body);

    http:Response authorizeResp = check authorizeClient->post("", authorizeReq);

    if authorizeResp.statusCode == 301 || authorizeResp.statusCode == 302 ||
            authorizeResp.statusCode == 303 || authorizeResp.statusCode == 307 ||
            authorizeResp.statusCode == 308 {
        return check authorizeResp.getHeader("Location");
    }

    string respBody = "";
    string|error maybeBody = authorizeResp.getTextPayload();
    if maybeBody is string { respBody = maybeBody; }
    return error(respBody == "" ?
        string `Authorize endpoint returned ${authorizeResp.statusCode} with empty body` :
        string `Authorize endpoint returned ${authorizeResp.statusCode}: ${respBody}`);
}

function initConsentScopeStore() returns error? {
    _ = check consentStoreDbClient->execute(`
        CREATE TABLE IF NOT EXISTS CONSENT_APPROVED_SCOPES (
            SESSION_DATA_KEY_CONSENT VARCHAR(255) PRIMARY KEY,
            APPROVED_SCOPES CLOB NOT NULL
        )
    `);
}

function storeApprovedScopesByConsentKey(string sessionDataKeyConsent, string[] scopes) returns error? {
    string[] approvedScopes = [];
    foreach string scope in scopes {
        if scope != "" {
            addUniqueScope(approvedScopes, scope);
        }
    }

    string approvedScopeValue = string:'join(" ", ...approvedScopes);
    _ = check consentStoreDbClient->execute(`
        MERGE INTO CONSENT_APPROVED_SCOPES
        (SESSION_DATA_KEY_CONSENT, APPROVED_SCOPES)
        KEY (SESSION_DATA_KEY_CONSENT)
        VALUES (${sessionDataKeyConsent}, ${approvedScopeValue})
    `);
}

function getApprovedScopesByConsentKey(string sessionDataKeyConsent) returns string[]|error {
    stream<record {|string APPROVED_SCOPES;|}, error?> resultStream = consentStoreDbClient->query(`
        SELECT APPROVED_SCOPES
        FROM CONSENT_APPROVED_SCOPES
        WHERE SESSION_DATA_KEY_CONSENT = ${sessionDataKeyConsent}
    `);
    record {|record {|string APPROVED_SCOPES;|} value;|}|error? nextRecord = resultStream.next();
    check resultStream.close();

    if nextRecord is record {|record {|string APPROVED_SCOPES;|} value;|} {
        string approvedScopesStr = nextRecord.value.APPROVED_SCOPES.trim();
        if approvedScopesStr == "" {
            return [];
        }
        return re `\s+`.split(approvedScopesStr);
    }

    return [];
}

// ─── Context extraction ────────────────────────────────────────────────────────

function extractUserFromContext(json context) returns string {
    string[] keyCandidates = ["user", "userId", "username", "authenticatedUser", "loggedInUser"];
    return findStringByKeyCandidates(context, keyCandidates) ?: "";
}

function extractScopesFromContext(json context) returns string[] {
    string[] collected = [];
    collectScopes(context, collected);
    string launchScope = extractLaunchScopeFromSpQueryParams(context);
    if launchScope != "" {
        addUniqueScope(collected, launchScope);
    }
    return collected;
}

function extractLaunchScopeFromSpQueryParams(json context) returns string {
    string? spQueryParams = findStringByKeyCandidates(context,
        ["spQueryParams", "spqueryparams", "sp_query_params"]);
    if !(spQueryParams is string) || spQueryParams == "" { return ""; }
    string launchId = getFirstValue(parseFormUrlEncoded(spQueryParams), "launch") ?: "";
    return launchId == "" ? "" : string `OH_launch/${launchId}`;
}

function collectScopes(json node, string[] collected) {
    if node is map<json> {
        foreach var [k, v] in node.entries() {
            if k == "scope" || k == "scopes" || k == "requestedScopes" {
                if v is string {
                    foreach string s in re `\s+`.split(v.trim()) {
                        if s != "" { addUniqueScope(collected, s); }
                    }
                } else if v is json[] {
                    foreach json item in v {
                        if item is string { addUniqueScope(collected, item); }
                    }
                }
            }
            collectScopes(v, collected);
        }
    } else if node is json[] {
        foreach json item in node { collectScopes(item, collected); }
    }
}

function findStringByKeyCandidates(json node, string[] keyCandidates) returns string? {
    if node is map<json> {
        foreach string key in keyCandidates {
            json? candidate = node[key];
            if candidate is string && candidate != "" { return candidate; }
        }
        foreach var [_, value] in node.entries() {
            string? found = findStringByKeyCandidates(value, keyCandidates);
            if found is string { return found; }
        }
    } else if node is json[] {
        foreach json item in node {
            string? found = findStringByKeyCandidates(item, keyCandidates);
            if found is string { return found; }
        }
    }
    return ();
}

function addUniqueScope(string[] scopes, string scope) {
    if scope != "" && scopes.indexOf(scope) is () { scopes.push(scope); }
}

// ─── Utility ──────────────────────────────────────────────────────────────────

function parseFormUrlEncoded(string payload) returns map<string[]> {
    map<string[]> values = {};
    if payload == "" { return values; }
    foreach string pair in re `&`.split(payload) {
        int? idx = pair.indexOf("=");
        string key = decodeFormComponent(idx is int ? pair.substring(0, idx) : pair);
        string value = decodeFormComponent(idx is int ? pair.substring(idx + 1) : "");
        string[] existing = values[key] ?: [];
        existing.push(value);
        values[key] = existing;
    }
    return values;
}

function decodeFormComponent(string value) returns string {
    string withSpaces = re `\+`.replace(value, " ");
    string|error decoded = url:decode(withSpaces, "UTF8");
    return decoded is string ? decoded : withSpaces;
}

function getFirstValue(map<string[]> values, string key) returns string? {
    string[]? entries = values[key];
    return (entries is string[] && entries.length() > 0) ? entries[0] : ();
}

function getMimeType(string filename) returns string {
    if filename.endsWith(".js") { return "application/javascript"; }
    if filename.endsWith(".css") { return "text/css"; }
    if filename.endsWith(".svg") { return "image/svg+xml"; }
    if filename.endsWith(".png") { return "image/png"; }
    if filename.endsWith(".ico") { return "image/x-icon"; }
    return "application/octet-stream";
}

function escapeJson(string value) returns string {
    string escaped = re `\\`.replaceAll(value, "\\\\");
    escaped = re `"`.replaceAll(escaped, "\\\"");
    escaped = re `\n`.replaceAll(escaped, "\\n");
    escaped = re `\r`.replaceAll(escaped, "\\r");
    escaped = re `\t`.replaceAll(escaped, "\\t");
    return escaped;
}

function escapeForScriptTag(string value) returns string {
    string escaped = re `</script`.replaceAll(value, "<\\/script");
    escaped = re `<`.replaceAll(escaped, "\\u003c");
    escaped = re `&`.replaceAll(escaped, "\\u0026");
    return escaped;
}

function getEncodedUri(anydata value) returns string {
    string|error encoded = url:encode(value.toString(), "UTF8");
    return encoded is string ? encoded : value.toString();
}

function normalizePath(string inputPath) returns string {
    boolean isAbsolute = inputPath.startsWith("/");
    string[] normalizedSegments = [];
    foreach string segment in re `[\\/]`.split(inputPath) {
        if segment == "" || segment == "." {
            continue;
        }
        if segment == ".." {
            if normalizedSegments.length() > 0 {
                _ = normalizedSegments.pop();
            }
            continue;
        }
        normalizedSegments.push(segment);
    }

    string normalizedPath = string:'join("/", ...normalizedSegments);
    if isAbsolute {
        return "/" + normalizedPath;
    }
    return normalizedPath == "" ? "." : normalizedPath;
}

function buildTextResponse(int statusCode, string message) returns http:Response {
    http:Response res = new;
    res.statusCode = statusCode;
    res.setHeader("Content-Type", "text/plain; charset=utf-8");
    res.setPayload(message);
    return res;
}
