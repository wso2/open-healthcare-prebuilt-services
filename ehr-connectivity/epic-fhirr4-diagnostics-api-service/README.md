# Epic FHIR Diagnostics API Service

This pre-built service provides an API for diagnostics category of Epic FHIR resources. It is built using [Ballerina](https://ballerina.io/) and uses [Epic's FHIR API](https://fhir.epic.com/Documentation) to interact with Epic's electronic health record system.

## Prerequisites

To get started with this service, you'll need to have Ballerina (Refer compatibility to install the relevant version) installed on your machine. If you are trying out with the Epic FHIR Sandbox, you have to create an application and obtain an client key and public key of the Epic FHIR server in order to access their FHIR API. Refer more on app creation on Epic FHIR sandbox [refer](https://fhir.epic.com/Documentation?docId=oauth2&section=BackendOAuth2Guide).

### Setup and run

1. Clone this repository to your local machine and navigate to the pre-built service on Epic diagnostics API.

2. Set the following values from environment variables.
    - `EPIC_FHIR_SERVER_URL` - The URL of the Epic FHIR server.
    - `EPIC_FHIR_SERVER_TOKEN_URL` - The URL of the Epic FHIR server token endpoint.
    - `EPIC_FHIR_APP_CLIENT_ID` - The client ID of the Epic FHIR application.
    - `EPIC_FHIR_APP_PRIVATE_KEY_FILE` - File path for the private key file created for the Epic FHIR application.

3. Run the project.

    ```ballerina
    bal run
    ```

4. Invoke the APIs.

    Sample request for FHIR patient read:

    ```
    curl --location 'localhost:9090/fhir/r4/Patient/erXuFYUfucBZaryVksYEcMg3'
    ```

## API Reference

The following APIs are supported:

- `/fhir/r4/Observation`: [Observation API](http://hl7.org/fhir/R4/observation.html) : central element in healthcare, used to support diagnosis, monitor progress, determine baselines and patterns and even capture demographic characteristics.
- `/fhir/r4/DiagnosticReport`: [AllergyIntolerance API](http://hl7.org/fhir/R4/diagnosticreport.html) : set of information that is typically provided by a diagnostic service when investigations are complete. The information includes a mix of atomic results, text reports, images, and codes.

For more information about the data returned by these endpoints, see [Epic's FHIR API documentation](https://fhir.epic.com/Documentation).
