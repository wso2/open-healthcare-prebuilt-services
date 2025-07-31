# FHIR Validation API Service

This service is a Ballerina-based API designed to validate FHIR (Fast Healthcare Interoperability Resources) messages. It uses the ballerinax/health.fhir.r4 and ballerinax/health.fhir.r4.validator libraries for FHIR R4 validation.

## Prerequisites
To get started with this service, you'll need to have Ballerina (Refer compatibility to install the relevant version) installed on your machine. 

### Setup and run

1. Clone this repository to your local machine and navigate to the validator-service directory.

2. Set the following values from environment variables.

- `CORS_ALLOWED_ORIGINS` - An array of strings, where each string is a URL that is allowed to access the API (To allow your URL to access the pre-built service, include it in this array).

3. (Optional) To enable FHIR terminology validation, create a `Config.toml` file in the project root directory and set the following configuration as shown below:

```toml
[ballerinax.health.fhir.r4.validator.terminologyConfig]
isTerminologyValidationEnabled=true                     # Enable terminology validation, set to false to disable
terminologyServiceApi="http://localhost:9089/fhir/r4"   # The base URL of your FHIR R4 terminology service used for validation (update this to match your service endpoint)
tokenUrl=""                                             # Replace with the your token URL
clientId=""                                             # Replace with the your client ID
clientSecret=""                                         # Replace with the your client secret
```

4. Run the project.

```ballerina
bal run
```

5. Invoke the APIs.

Sample request for FHIR patient read:

```bash
curl -X POST -H "Content-Type: application/json" -d '{
  "resourceType": "Patient",
  "id": "example",
  "text": {
    "status": "generated",
    "div": ""
  },
}' http://localhost:9090/validate
```

## API Reference

#### POST /validate

This endpoint accepts a JSON payload containing a FHIR message and validates it.

#### Request

The request body should contain a JSON representation of a FHIR message.

#### Response

The HTTP status code of the response will be 200 if the validation is successful, and 400 if it fails.

The response will be a JSON representation of an `OperationOutcome` FHIR resource. This resource contains a list of issues that were found during the validation process.

If the validation is successful, the `OperationOutcome` will contain a single issue with severity "information" and code "informational", and a diagnostic message "Validation Successful".

If the validation fails, the `OperationOutcome` will contain one or more issues detailing the validation errors.
