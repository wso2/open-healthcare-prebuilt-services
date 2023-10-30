# Epic FHIR Medications API Service

This pre-built service provides an API for medications category of Epic FHIR resources. It is built using [Ballerina](https://ballerina.io/) and uses [Epic's FHIR API](https://fhir.epic.com/Documentation) to interact with Epic's electronic health record system.

## Prerequisites

To get started with this service, you'll need to have Ballerina (Refer compatibility to install the relevant version) installed on your machine. If you are trying out with the Epic FHIR Sandbox, you have to create an application and obtain an client key and public key of the Epic FHIR server in order to access their FHIR API. Refer more on app creation on Epic FHIR sandbox [refer](https://fhir.epic.com/Documentation?docId=oauth2&section=BackendOAuth2Guide).

### Setup and run

1. Clone this repository to your local machine and navigate to the pre-built service on Epic medications API.

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

- `/fhir/r4/Immunization`: [Immunization API](https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-immunization.html) : covers the recording of current and historical administration of vaccines to patients across all healthcare disciplines in all care settings and all regions.
- `/fhir/r4/Medication`: [Medication API](https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-medication.html) : representing medications in the majority of healthcare settings is a matter of identifying an item from a list and then conveying a reference for the item selected either into a patient-related resource or to other applications.
- `/fhir/r4/MedicationRequest`: [MedicationRequest API](https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-medicationrequest.html) : covers all type of orders for medications for a patient. This includes inpatient medication orders as well as community orders.
- `/fhir/r4/MedicationStatement`: [MedicationStatement API](https://www.hl7.org/fhir/medicationstatement.html) : record of a medication that is being consumed by a patient. A MedicationStatement may indicate that the patient may be taking the medication now or has taken the medication in the past or will be taking the medication in the future.

For more information about the data returned by these endpoints, see [Epic's FHIR API documentation](https://fhir.epic.com/Documentation).
