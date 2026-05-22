# Epic FHIR Workflow API Service

This pre-built service provides an API for workflow category of Epic FHIR resources. It is built using [Ballerina](https://ballerina.io/) and uses [Epic's FHIR API](https://fhir.epic.com/Documentation) to interact with Epic's electronic health record system.

## Prerequisites

To get started with this service, you'll need to have Ballerina (Refer compatibility to install the relevant version) installed on your machine. If you are trying out with the Epic FHIR Sandbox, you have to create an application and obtain an client key and public key of the Epic FHIR server in order to access their FHIR API. Refer more on app creation on Epic FHIR sandbox [refer](https://fhir.epic.com/Documentation?docId=oauth2&section=BackendOAuth2Guide).

### Setup and run

1. Clone this repository to your local machine and navigate to the pre-built service on Epic workflow API.

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

- `/fhir/r4/Schedule`: [Schedule API](http://hl7.org/fhir/R4/schedule.html) : provides a container for time-slots that can be booked using an appointment. It provides the window of time (period) that slots are defined for and what type of appointments can be booked.
- `/fhir/r4/Slot`: [Slot API](http://hl7.org/fhir/R4/slot.html) : used to provide time-slots that can be booked using an appointment. They do not provide any information about appointments that are available, just the time, and optionally what the time can be used for. These are effectively spaces of free/busy time.
- `/fhir/r4/Appointment`: [Appointment API](http://hl7.org/fhir/R4/appointment.html) : used to provide information about a planned meeting that may be in the future or past. The resource only describes a single meeting, a series of repeating visits would require multiple appointment resources to be created for each instance.
- `/fhir/r4/AppointmentResponse`: [AppointmentResponse API](http://hl7.org/fhir/R4/appointmentresponse.html) : used to provide information about a planned meeting that may be in the future or past. They may be for a single meeting or for a series of repeating visits. Examples include a scheduled surgery, a follow-up for a clinical visit, a scheduled conference call between clinicians to discuss a case, the reservation of a piece of diagnostic equipment for a particular use, etc.
- `/fhir/r4/ServiceRequest`: [ServiceRequest API](http://hl7.org/fhir/R4/servicerequest.html) : record of a request for a procedure or diagnostic or other service to be planned, proposed, or performed, as distinguished by the ServiceRequest.intent field value, with or on a patient.

For more information about the data returned by these endpoints, see [Epic's FHIR API documentation](https://fhir.epic.com/Documentation).
