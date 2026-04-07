// import ballerina/http;
// import ballerina/log;
// import ballerina/url;

// configurable string hostname = "localhost";
// configurable int port = 9091;
// configurable string consentContextApiBaseUrl = "https://localhost:9443";
// configurable string consentContextApiPath = "/api/identity/auth/v1.1/data/OauthConsentKey";
// configurable string consentContextApiUsername = "";
// configurable string consentContextApiPassword = "";
// configurable string consentContextApiTrustStorePath = "";
// configurable string consentContextApiTrustStorePassword = "";
// configurable string consentAuthorizeRedirectUrl = "";

// listener http:Listener consentListener = new (port, config = {host: hostname});

// service / on consentListener {

//     resource function get consent(http:Request req) returns http:Response {
//         map<string[]> queryParams = req.getQueryParams();
//         string? sessionDataKeyConsent = getFirstValue(queryParams, "sessionDataKeyConsent");
//         string spId = getFirstValue(queryParams, "spId") ?: "";

//         if !(sessionDataKeyConsent is string) || sessionDataKeyConsent == "" {
//             return buildTextResponse(400, "Missing required query parameter: sessionDataKeyConsent");
//         }

//         json|error consentContext = fetchConsentContext(sessionDataKeyConsent);
//         if consentContext is error {
//             log:printError("Failed to load consent context", 'error = consentContext);
//             return buildTextResponse(502, "Failed to load consent context data");
//         }

//         string[] scopes = extractScopesFromContext(consentContext);
//         // todo drop invalid scopes
//         string user = extractUserFromContext(consentContext);
//         string page = renderConsentPage(sessionDataKeyConsent, spId, user, scopes, consentContext.toJsonString());

//         http:Response response = new;
//         response.setHeader("Content-Type", "text/html; charset=utf-8");
//         response.setPayload(page);
//         return response;
//     }

//     resource function post consent(http:Request req) returns http:Response {
//         string|error payload = req.getTextPayload();
//         if payload is error {
//             return buildTextResponse(400, "Invalid form payload");
//         }

//         map<string[]> form = parseFormUrlEncoded(payload);
//         string sessionDataKeyConsent = getFirstValue(form, "SessionDataKeyConsent") ?: "";
//         string consent = getFirstValue(form, "Consent") ?: "approve";
//         string hasApprovedAlways = getFirstValue(form, "hasApprovedAlways") ?: "false";
//         string userClaimsConsent = getFirstValue(form, "User_claims_consent") ?: "true";
//         string user = getFirstValue(form, "user") ?: "";
//         string spId = getFirstValue(form, "spId") ?: "";
//         string[] selectedScopes = form["scope"] ?: [];

//         if consentAuthorizeRedirectUrl == "" {
//             json result = {
//                 SessionDataKeyConsent: sessionDataKeyConsent,
//                 Consent: consent,
//                 hasApprovedAlways: hasApprovedAlways,
//                 User_claims_consent: userClaimsConsent,
//                 user: user,
//                 spId: spId,
//                 scopes: selectedScopes
//             };
//             http:Response response = new;
//             response.setHeader("Content-Type", "application/json");
//             response.setPayload(result);
//             return response;
//         }

//         // Forward session cookies from the browser request to the authorize POST
//         string cookieHeader = "";
//         string|http:HeaderNotFoundError cookieVal = req.getHeader("Cookie");
//         if cookieVal is string {
//             cookieHeader = cookieVal;
//         }
//         if cookieHeader == "" {
//             return buildTextResponse(400,
//                 "Missing session cookies in consent POST request. Ensure consent page is loaded over HTTPS so secure IS cookies are sent.");
//         }
//         if cookieHeader.indexOf("JSESSIONID=") is () || cookieHeader.indexOf("opbs=") is () {
//             return buildTextResponse(400,
//                 "Required IS session cookies are missing (JSESSIONID/opbs). Ensure consent page uses HTTPS and same host as IS.");
//         }
//         if user == "" {
//             return buildTextResponse(400,
//                 "Missing authenticated user in consent context. Unable to complete authorize POST.");
//         }

//         string|error locationUri = postAuthorizeRequest(sessionDataKeyConsent, consent, hasApprovedAlways,
//             user, spId, selectedScopes, cookieHeader);
//         if locationUri is error {
//             log:printError("Authorize POST failed", 'error = locationUri);
//             return buildTextResponse(502, "Authorize request failed: " + locationUri.message());
//         }

//         http:Response redirect = new;
//         redirect.statusCode = 302;
//         redirect.setHeader("Location", locationUri);
//         return redirect;
//     }
// }

// function fetchConsentContext(string sessionDataKeyConsent) returns json|error {
//     if consentContextApiUsername == "" || consentContextApiPassword == "" {
//         return error("consentContextApiUsername or consentContextApiPassword is not configured");
//     }

//     if consentContextApiBaseUrl.startsWith("https://") &&
//         (consentContextApiTrustStorePath == "" || consentContextApiTrustStorePassword == "") {
//         return error("consentContextApiTrustStorePath or consentContextApiTrustStorePassword is not configured");
//     }

//     http:ClientConfiguration clientConfig = {
//         auth: {
//             username: consentContextApiUsername,
//             password: consentContextApiPassword
//         }
//     };

//     if consentContextApiBaseUrl.startsWith("https://") {
//         clientConfig.secureSocket = {
//             cert: {
//                 path: consentContextApiTrustStorePath,
//                 password: consentContextApiTrustStorePassword
//             }
//         };
//     }

//     http:Client contextClient = check new (consentContextApiBaseUrl, clientConfig);
//     string path = consentContextApiPath + "/" + getEncodedUri(sessionDataKeyConsent);

//     map<string|string[]> headers = {
//         accept: "application/json"
//     };

//     http:Response response = check contextClient->get(path, headers = headers);
//     if response.statusCode < 200 || response.statusCode >= 300 {
//         string body = check response.getTextPayload();
//         return error(string `Context API returned status ${response.statusCode}: ${body}`);
//     }

//     return check response.getJsonPayload();
// }

// function renderConsentPage(string sessionDataKeyConsent, string spId, string user, string[] scopes,
//     string contextJson) returns string {
//     string items = "";
//     string hiddenScopeInputs = "";
//     foreach string scope in scopes {
//         string escaped = escapeHtml(scope);
//         if scope.startsWith("OH_launch/") {
//             hiddenScopeInputs += string `<input type="hidden" name="scope" value="${escaped}" />`;
//             continue;
//         }
//         items += string `<label class="scope-item"><input type="checkbox" name="scope" value="${escaped}" checked> ${escaped}</label>`;
//     }
//     if items == "" {
//         items = "<p class=\"muted\">No selectable scopes found in context payload.</p>";
//     }

//     return string `<!doctype html>
// <html lang="en">
// <head>
//   <meta charset="UTF-8" />
//   <meta name="viewport" content="width=device-width, initial-scale=1.0" />
//   <title>Consent</title>
//   <style>
//     body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; background: #f6f8fb; }
//     .wrap { max-width: 860px; margin: 2rem auto; background: white; border-radius: 12px; padding: 1.25rem; box-shadow: 0 8px 24px rgba(0,0,0,.08); }
//     h1 { margin-top: 0; }
//     .meta { color: #374151; font-size: 0.92rem; }
//     .box { border: 1px solid #e5e7eb; border-radius: 8px; padding: .9rem; margin-top: 1rem; }
//     .scope-item { display: block; padding: .3rem 0; }
//     .actions { margin-top: 1rem; display: flex; gap: .6rem; }
//     button { border: 0; border-radius: 8px; padding: .65rem .95rem; cursor: pointer; }
//     .primary { background: #2563eb; color: #fff; }
//     .secondary { background: #e5e7eb; color: #111827; }
//     pre { white-space: pre-wrap; word-break: break-word; margin: 0; }
//     .muted { color: #6b7280; }
//   </style>
// </head>
// <body>
//   <div class="wrap">
//     <h1>Scope Consent</h1>
//     <div class="meta">SessionDataKeyConsent: ${escapeHtml(sessionDataKeyConsent)}<br/>SP ID: ${escapeHtml(spId)}</div>

//     <form method="post" action="/consent">
//       <input type="hidden" name="SessionDataKeyConsent" value="${escapeHtml(sessionDataKeyConsent)}" />
//       <input type="hidden" name="spId" value="${escapeHtml(spId)}" />
//     <input type="hidden" name="user" value="${escapeHtml(user)}" />
//       <input type="hidden" name="Consent" value="approve" />
//       <input type="hidden" name="hasApprovedAlways" value="false" />
//       <input type="hidden" name="User_claims_consent" value="true" />
//             ${hiddenScopeInputs}

//       <div class="box">
//         <strong>Select scopes</strong>
//         ${items}
//       </div>

//       <div class="actions">
//         <button type="button" class="secondary" onclick="toggleAll(true)">Select all</button>
//         <button type="button" class="secondary" onclick="toggleAll(false)">Clear all</button>
//         <button type="submit" class="primary">Approve</button>
//       </div>
//     </form>

//     <div class="box">
//       <strong>Context payload</strong>
//       <pre>${escapeHtml(contextJson)}</pre>
//     </div>
//   </div>
//   <script>
//     function toggleAll(v) {
//       document.querySelectorAll('input[name="scope"]').forEach((el) => el.checked = v);
//     }
//   </script>
// </body>
// </html>`;
// }

// function postAuthorizeRequest(string sessionDataKeyConsent, string consent, string hasApprovedAlways,
//     string user, string spId, string[] selectedScopes, string cookieHeader) returns string|error {

//     http:ClientConfiguration clientConfig = {
//         followRedirects: {enabled: false}
//     };

//     if consentAuthorizeRedirectUrl.startsWith("https://") &&
//             consentContextApiTrustStorePath != "" && consentContextApiTrustStorePassword != "" {
//         clientConfig.secureSocket = {
//             cert: {
//                 path: consentContextApiTrustStorePath,
//                 password: consentContextApiTrustStorePassword
//             }
//         };
//     }

//     http:Client authorizeClient = check new (consentAuthorizeRedirectUrl, clientConfig);

//     // Build form-encoded body to match WSO2 authorize resume request.
//     string body = string `sessionDataKeyConsent=${getEncodedUri(sessionDataKeyConsent)}` +
//         string `&consent=${getEncodedUri(consent)}` +
//         string `&hasApprovedAlways=${getEncodedUri(hasApprovedAlways)}` +
//         string `&consent_custom_attribute="customAttr"` +
//         string `&user=${getEncodedUri(user)}`;

//     if selectedScopes.length() > 0 {
//         string approvedScopeList = string:'join(" ", ...selectedScopes);
//         body += string `&scope=${getEncodedUri(approvedScopeList)}`;
//     }

//     http:Request authorizeReq = new;
//     authorizeReq.setHeader("Content-Type", "application/x-www-form-urlencoded");
//     if cookieHeader != "" {
//         authorizeReq.setHeader("Cookie", cookieHeader);
//     }
//     authorizeReq.setPayload(body);

//     http:Response authorizeResp = check authorizeClient->post("", authorizeReq);

//     // Accept standard redirect responses from authorize endpoint.
//     if authorizeResp.statusCode == 301 || authorizeResp.statusCode == 302 || authorizeResp.statusCode == 303 ||
//             authorizeResp.statusCode == 307 || authorizeResp.statusCode == 308 {
//         string location = check authorizeResp.getHeader("Location");
//         return location;
//     }

//     // Non-redirect responses may legitimately have an empty entity.
//     string respBody = "";
//     string|error maybeBody = authorizeResp.getTextPayload();
//     if maybeBody is string {
//         respBody = maybeBody;
//     }
//     string message = respBody == "" ?
//         string `Authorize endpoint returned ${authorizeResp.statusCode} with empty response body` :
//         string `Authorize endpoint returned ${authorizeResp.statusCode}: ${respBody}`;
//     return error(message);
// }

// function extractUserFromContext(json context) returns string {
//     string[] keyCandidates = ["user", "userId", "username", "authenticatedUser", "loggedInUser"];
//     string? value = findStringByKeyCandidates(context, keyCandidates);
//     return value ?: "";
// }

// function findStringByKeyCandidates(json node, string[] keyCandidates) returns string? {
//     if node is map<json> {
//         foreach string key in keyCandidates {
//             json? candidate = node[key];
//             if candidate is string && candidate != "" {
//                 return candidate;
//             }
//         }
//         foreach var [_, value] in node.entries() {
//             string? found = findStringByKeyCandidates(value, keyCandidates);
//             if found is string {
//                 return found;
//             }
//         }
//     } else if node is json[] {
//         foreach json item in node {
//             string? found = findStringByKeyCandidates(item, keyCandidates);
//             if found is string {
//                 return found;
//             }
//         }
//     }
//     return ();
// }

// function parseFormUrlEncoded(string payload) returns map<string[]> {
//     map<string[]> values = {};
//     if payload == "" {
//         return values;
//     }

//     string[] pairs = re `&`.split(payload);
//     foreach string pair in pairs {
//         int? idx = pair.indexOf("=");
//         string keyPart = idx is int ? pair.substring(0, idx) : pair;
//         string valuePart = idx is int ? pair.substring(idx + 1) : "";

//         string key = decodeFormComponent(keyPart);
//         string value = decodeFormComponent(valuePart);

//         string[] existing = values[key] ?: [];
//         existing.push(value);
//         values[key] = existing;
//     }

//     return values;
// }

// function decodeFormComponent(string value) returns string {
//     string withSpaces = re `\+`.replace(value, " ");
//     string|error decoded = url:decode(withSpaces, "UTF8");
//     if decoded is string {
//         return decoded;
//     }
//     return withSpaces;
// }

// function getFirstValue(map<string[]> values, string key) returns string? {
//     string[]? entries = values[key];
//     if entries is string[] && entries.length() > 0 {
//         return entries[0];
//     }
//     return ();
// }

// function extractScopesFromContext(json context) returns string[] {
//     string[] collected = [];
//     collectScopes(context, collected);

//     string launchScope = extractLaunchScopeFromSpQueryParams(context);
//     if launchScope != "" {
//         addUniqueScope(collected, launchScope);
//     }

//     return collected;
// }

// function extractLaunchScopeFromSpQueryParams(json context) returns string {
//     string[] keyCandidates = ["spQueryParams", "spqueryparams", "sp_query_params"];
//     string? spQueryParams = findStringByKeyCandidates(context, keyCandidates);
//     if !(spQueryParams is string) || spQueryParams == "" {
//         return "";
//     }

//     map<string[]> queryParams = parseFormUrlEncoded(spQueryParams);
//     string launchId = getFirstValue(queryParams, "launch") ?: "";
//     if launchId == "" {
//         return "";
//     }

//     return string `OH_launch/${launchId}`;
// }

// function collectScopes(json node, string[] collected) {
//     if node is map<json> {
//         foreach var [k, v] in node.entries() {
//             if k == "scope" || k == "scopes" || k == "requestedScopes" {
//                 if v is string {
//                     foreach string s in re `\s+`.split(v.trim()) {
//                         if s != "" {
//                             addUniqueScope(collected, s);
//                         }
//                     }
//                 } else if v is json[] {
//                     foreach json item in v {
//                         if item is string {
//                             addUniqueScope(collected, item);
//                         }
//                     }
//                 }
//             }
//             collectScopes(v, collected);
//         }
//     } else if node is json[] {
//         foreach json item in node {
//             collectScopes(item, collected);
//         }
//     }
// }

// function addUniqueScope(string[] scopes, string scope) {
//     if scope != "" && scopes.indexOf(scope) is () {
//         scopes.push(scope);
//     }
// }

// function escapeHtml(string value) returns string {
//     string escaped = re `&`.replace(value, "&amp;");
//     escaped = re `<`.replace(escaped, "&lt;");
//     escaped = re `>`.replace(escaped, "&gt;");
//     escaped = re `"`.replace(escaped, "&quot;");
//     return re `'`.replace(escaped, "&#39;");
// }

// function getEncodedUri(anydata value) returns string {
//     string|error encoded = url:encode(value.toString(), "UTF8");
//     if encoded is string {
//         return encoded;
//     }
//     return value.toString();
// }

// function buildTextResponse(int statusCode, string message) returns http:Response {
//     http:Response res = new;
//     res.statusCode = statusCode;
//     res.setHeader("Content-Type", "text/plain; charset=utf-8");
//     res.setPayload(message);
//     return res;
// }
