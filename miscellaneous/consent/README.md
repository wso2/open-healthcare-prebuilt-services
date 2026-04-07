# Consent Web App

Standalone consent UI app for OAuth scope selection.

## Endpoints

- `GET /consent?sessionDataKeyConsent=<key>&spId=<spId>`
  - Loads consent context from external API:
    - `https://localhost:9443/api/identity/auth/v1.1/data/OauthConsentKey/{sessionDataKeyConsent}`
  - Uses HTTP Basic Auth
  - Renders scope selection page

- `POST /consent`
  - Sends required parameters:
    - `SessionDataKeyConsent`
    - `Consent=approve`
    - `hasApprovedAlways=false`
    - `User_claims_consent=true`
  - Includes selected scopes (`scope`) and optional `spId`
  - Redirects to `consentAuthorizeRedirectUrl` (default: `https://localhost:9443/oauth2/authorize`)

## Configure

Edit [Config.toml](Config.toml):

- `consentContextApiBaseUrl`
- `consentContextApiPath`
- `consentContextApiUsername`
- `consentContextApiPassword`
- `consentContextApiTrustStorePath` (required for https)
- `consentContextApiTrustStorePassword` (required for https)
- `consentAuthorizeRedirectUrl` (optional)

For local WSO2 IS, you can point truststore to the IS client truststore file (for example, `client-truststore.p12`) and use its password.

## Run

```bash
bal run
```

Open:

`http://localhost:9091/consent?sessionDataKeyConsent=<value>&spId=<value>`
