# Cerner FHIR Workflow API Service

This pre-built service exposes APIs for workflow category of Cerner FHIR resources. It is built using [Ballerina](https://ballerina.io/) and uses [Cerner's FHIR API](https://docs.oracle.com/en/industries/health/millennium-platform-apis/mfrap/r4_overview.html) to interact with Cerner's electronic health record system.

## Prerequisites

To get started with this service, you'll need to have Ballerina (Refer compatibility to install the relevant version) installed on your machine. If you are trying out with the Cerner FHIR Sandbox, you have to create an application and obtain an client key and public key of the Cerner FHIR server in order to access their FHIR API. Refer more on app creation on Cerner FHIR sandbox [refer](https://engineering.cerner.com/smart-on-fhir-tutorial/#registration). You have to register a [cerner care account](https://cernercare.com/accounts/create) to access the sandbox and create an application.

### Setup and run

1. Clone this repository to your local machine and navigate to the pre-built service on Cerner workflow API.

2. Set the following values in [Config.toml file](https://ballerina.io/learn/provide-values-to-configurable-variables/#provide-via-configuration-files) to do necessary configurations to point to the Cerner FHIR server. The following is a sample configuration structure.

```toml
baseServerHost = "http://localhost:9090"
cernerUrl = "https://fhir-ehr-code.cerner.com/r4/ec2458f2-1e24-41c8-b71b-0e701af7583d"
tokenUrl = "https://authorization.cerner.com/tenants/ec2458f2-1e24-41c8-b71b-0e701af7583d/protocols/oauth2/profiles/smart-v1/token"
clientId = "xxxxxxxxxxxxxxxx"
clientSecret = "xxxxxxxxxxxxxxxx"
scopes = ["system/Appointment.read", "system/Appointment.write"]
```


| Field | Description |
|-------|-------------|
| `baseServerHost` | Base service host of the proxy service|
| `cernerUrl`| Cerner FHIR server url |
| `tokenUrl`| Cerner FHIR server token endpoint url |
| `clientId`| Client ID of the Cerner FHIR application |
| `clientSecret`| Client secret of the Cerner FHIR application |
| `scopes`| Scopes required to access the Cerner FHIR API

> **Note:** If you deploy this to [Choreo](https://wso2.com/choreo/), you can apply configurations through the [config editor](https://wso2.com/choreo/docs/devops-and-ci-cd/manage-configurations-and-secrets/#manage-ballerina-configurables) in the Choreo console. For more information, see [Deploy in Choreo](#optional-deploy-in-choreo).    

3. Run the project.

    ```ballerina
    bal run
    ```

4. Invoke the APIs.

    Sample request for FHIR patient read:

    ```
    curl --location 'localhost:9090/fhir/r4/Patient/erXuFYUfucBZaryVksYEcMg3'
    ```

## [Optional] Deploy in Choreo

WSO2’s Choreo (https://wso2.com/choreo/) is an internal developer platform that redefines how you create digital experiences. Choreo empowers you to seamlessly design, develop, deploy, and govern your cloud native applications, unlocking innovation while reducing time-to-market. You can deploy the healthcare prebuilt services in Choreo as explained below. 

### Prerequisites

If you are signing in to the Choreo Console for the first time, create an organization as follows:

1. Go to https://console.choreo.dev/, and sign in using your preferred method.
2. Enter a unique organization name. For example, Stark Industries.
3. Read and accept the privacy policy and terms of use.
4. Click Create.
This creates the organization and opens the Project Home page of the default project created for you.

### Steps to Deploy Cerner FHIR pre-built services in Choreo
1. Create Service Component
    * Follow the official documentation to create and configure a service: https://wso2.com/choreo/docs/develop-components/develop-services/develop-a-ballerina-rest-api/#step-1-create-a-service-component. Fill **Provide Repository URL** as "https://github.com/wso2/open-healthcare-prebuilt-services" and select the folder path: ehr-connectivity/cerner-fhirr4-workflow-api-service. 

    * Click Create. Once the component creation is complete, you will see the component overview page.

2. Build and Deploy
Follow the official documentation to deploy the Cerner FHIR service to your organization https://wso2.com/choreo/docs/develop-components/develop-services/develop-a-ballerina-rest-api/#step-2-build-and-deploy.    

## API Reference

The following APIs are supported:

- `/fhir/r4/Schedule`: [Schedule API](http://hl7.org/fhir/R4/schedule.html) : provides a container for time-slots that can be booked using an appointment. It provides the window of time (period) that slots are defined for and what type of appointments can be booked.
- `/fhir/r4/Slot`: [Slot API](http://hl7.org/fhir/R4/slot.html) : used to provide time-slots that can be booked using an appointment. They do not provide any information about appointments that are available, just the time, and optionally what the time can be used for. These are effectively spaces of free/busy time.
- `/fhir/r4/Appointment`: [Appointment API](http://hl7.org/fhir/R4/appointment.html) : used to provide information about a planned meeting that may be in the future or past. The resource only describes a single meeting, a series of repeating visits would require multiple appointment resources to be created for each instance.
- `/fhir/r4/AppointmentResponse`: [AppointmentResponse API](http://hl7.org/fhir/R4/appointmentresponse.html) : used to provide information about a planned meeting that may be in the future or past. They may be for a single meeting or for a series of repeating visits. Examples include a scheduled surgery, a follow-up for a clinical visit, a scheduled conference call between clinicians to discuss a case, the reservation of a piece of diagnostic equipment for a particular use, etc.
- `/fhir/r4/ServiceRequest`: [ServiceRequest API](http://hl7.org/fhir/R4/servicerequest.html) : record of a request for a procedure or diagnostic or other service to be planned, proposed, or performed, as distinguished by the ServiceRequest.intent field value, with or on a patient.

For more information about the data returned by these endpoints, see [Cerner's FHIR API documentation](https://docs.oracle.com/en/industries/health/millennium-platform-apis/mfrap/r4_overview.html).
