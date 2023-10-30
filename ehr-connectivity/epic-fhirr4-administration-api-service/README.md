# Epic FHIR Administration API Service

This pre-built service provides an API for administering Epic FHIR resources. It is built using [Ballerina](https://ballerina.io/) and uses [Epic's FHIR API](https://fhir.epic.com/Documentation) to interact with Epic's electronic health record system.

## Prerequisites

To get started with this service, you'll need to have Ballerina (Refer compatibility to install the relevant version) installed on your machine. If you are trying out with the Epic FHIR Sandbox, you have to create an application and obtain an client key and public key of the Epic FHIR server in order to access their FHIR API. Refer more on app creation on Epic FHIR sandbox [refer](https://fhir.epic.com/Documentation?docId=oauth2&section=BackendOAuth2Guide).

### Setup and run

1. Clone this repository to your local machine and navigate to the pre-built service on Epic administration API.

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

- `/fhir/r4/Patient`: [Patient API](http://hl7.org/fhir/us/core/STU6.1/StructureDefinition-us-core-patient.html) : focuses on the demographic information necessary to support administrative, financial, or logistic purposes.
- `/fhir/r4/Practitioner`: [Practitioner API](http://hl7.org/fhir/us/core/STU6.1/StructureDefinition-us-core-practitioner.html) : covers data about providers of care or other health-related services.
- `/fhir/r4/PractitionerRole`: [PractitionerRole API](http://hl7.org/fhir/us/core/STU6.1/StructureDefinition-us-core-practitionerrole.html) : specific set of Roles/Locations/specialties/services that a practitioner may perform at an organization for a period of time.
- `/fhir/r4/RelatedPerson`: [RelatedPerson API](http://hl7.org/fhir/us/core/STU6.1/StructureDefinition-us-core-relatedperson.html) : holds data on an entity with a personal or professional relationship to the patient.
- `/fhir/r4/Organization`: [Organization API](http://hl7.org/fhir/us/core/STU6.1/StructureDefinition-us-core-organization.html) : formally or informally recognized grouping of people or organizations formed for the purpose of achieving some form of collective action.
- `/fhir/r4/Location`: [Location API](http://hl7.org/fhir/us/core/STU6.1/StructureDefinition-us-core-location.html) : defines details and position information for a physical place where resources and participants can be found.
- `/fhir/r4/Encounter`: [Encounter API](http://hl7.org/fhir/us/core/STU6.1/StructureDefinition-us-core-encounter.html) :  defines the setting where patient care takes place. This includes ambulatory, inpatient, emergency, home health, and virtual encounters.

For more information about the data returned by these endpoints, see [Epic's FHIR API documentation](https://fhir.epic.com/Documentation).
