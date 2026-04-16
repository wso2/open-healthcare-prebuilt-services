# Consent Web App

Standalone consent UI for SMART on FHIR OAuth scope authorization. Supports practitioner-initiated flows where a clinician selects a patient before approving scopes on behalf of that patient context.

## Flow

1. The service injects consent props (session key, scopes, user) into the React SPA at page load.
2. If the authenticated user has a `fhirUser` value containing `Practitioner`, the **Patient Picker** page is shown first.
3. After selecting a patient, the user proceeds to the **Consent** page to approve or deny the requested scopes.
4. On approval, the service persists approved scopes and redirects to the IS OAuth2 authorize endpoint.

## Endpoints

### `GET /consent?sessionDataKeyConsent=<key>&spId=<spId>`

Loads consent context from the IS identity API and renders the React SPA.

- Fetches scope and user data from:
  `{consentContextApiBaseUrl}{consentContextApiPath}/{sessionDataKeyConsent}`
- Injects `sessionDataKeyConsent`, `spId`, `user`, and `scopes` into the page as `window.__CONSENT_PROPS__`.

### `POST /consent`

Receives form submission from the consent UI.

| Field | Description |
|---|---|
| `SessionDataKeyConsent` | Consent session key |
| `Consent` | `approve` or `deny` |
| `hasApprovedAlways` | `true` or `false` |
| `User_claims_consent` | `true` |
| `user` | Authenticated username |
| `spId` | Service provider ID |
| `scope` | Repeated field — one per approved scope |
| `additionalContext` | JSON-stringified array of context strings (e.g. selected patient) |

On approval, persists approved scopes to the H2 database and redirects to `consentAuthorizeRedirectUrl`.  
If `consentAuthorizeRedirectUrl` is not set, returns the parsed form data as JSON (useful for testing).

### `GET /approved-scopes?sessionDataKeyConsent=<key>`

Returns the persisted approved scopes for a given consent session.

```json
{
  "sessionDataKeyConsent": "<key>",
  "scopes": ["patient/Observation.read", "launch/patient"]
}
```

### `GET /api/me?userId=<userId>`

Proxies a SCIM2 user lookup to the IS instance.

- Calls `GET {consentContextApiBaseUrl}/scim2/Users/{userId}`
- Returns the raw SCIM2 user object.
- Used by the UI to resolve the logged-in practitioner's display name and `fhirUser` attribute.

### `GET /api/patients`

Returns a list of patients from the IS SCIM2 directory.

- POSTs a search request to `{consentContextApiBaseUrl}/scim2/Users/.search` filtered by `fhirUser co Patient`.
- Returns the raw SCIM2 `ListResponse` (the UI maps `Resources[]` to patient records).

### `GET /assets/*`

Serves Vite build assets (JS, CSS) from the `uiDistPath` directory.

## Configuration

Edit `Config.toml`:

| Key | Description | Default |
|---|---|---|
| `hostname` | Bind address | `localhost` |
| `port` | Listen port | `9091` |
| `consentContextApiBaseUrl` | Base URL of the WSO2 IS instance | `https://localhost:9443` |
| `consentContextApiPath` | Path to the OauthConsentKey API | `/api/identity/auth/v1.1/data/OauthConsentKey` |
| `consentContextApiUsername` | IS admin username | — |
| `consentContextApiPassword` | IS admin password | — |
| `consentContextApiTrustStorePath` | Path to the IS client truststore (required for HTTPS) | — |
| `consentContextApiTrustStorePassword` | Truststore password (required for HTTPS) | — |
| `consentAuthorizeRedirectUrl` | IS OAuth2 authorize endpoint to redirect to after approval | — |
| `consentStoreDbUrl` | H2 JDBC URL for approved scope storage | `jdbc:h2:./resources/consent_scopes` |
| `uiDistPath` | Path to the React build output (`dist/`) | `resources/consent-ui` |

For local WSO2 IS, point `consentContextApiTrustStorePath` to the IS `client-truststore.p12` and set its password.

## Build the UI

```bash
cd ../consent-app
npm install
npm run build
```
`Post build script will copy the build artifacts to consent service distribution`

## Run

Build the consent web application.
```bash
cd consent-app
npm run build
cd ..
```

```bash
bal run
```

## Integrate with WSO2 IS 7.2.0

Add following config to `deployment.toml`

```toml
[oauth.endpoints.v2]
oidc_consent_page="http://localhost:9091/consent"
```
