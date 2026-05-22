# C-CDA to FHIR Service

## Introduction

This service transforms C-CDA to FHIR resources. Data transformation conditions are taken from the official C-CDA to FHIR mappings page (http://hl7.org/fhir/us/ccda/2023May/) and based on the feedback received from the users.

You do not have to write code from scratch but reuse these existing services when implementing your FHIR services. You can deploy the pre-built service on your own environment or deploy on Choreo as a standard Ballerina service.

```Supported FHIR version is 4.0.1.```

This pre-built service exposes following CCDA-to-FHIR transformations.

1) C-CDA Allergy Intolerance Observation to FHIR Allergy Intolerance.
2) C-CDA Problem observation to FHIR Condition.
3) C-CDA Results to FHIR Diagnostic Report.
4) C-CDA Immunization Activity to FHIR Immunization.
5) C-CDA Medication Activity to FHIR Medication.
6) C-CDA Patient Role Header to FHIR Patient.
7) C-CDA Author Header to FHIR Practitioner.
8) C-CDA Procedure Activity to FHIR Procedure.

## Setup and run

1.Clone this repository to your local machine and navigate to the pre-built service on `ccda-to-fhirr4-service`.

2. Run the project.

    ```ballerina
    bal run
    ```

4. Invoke the API.

    Sample request format:

    ```
    curl 'http://<host>:<port>/transform' \ 
    --header 'Content-Type: application/xml' \
    --data-raw '<ClinicalDocument/>'
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

### Steps to Deploy C-CDA to FHIR prebuilt service in Choreo
1. Create Service Component
    * Fork the pre-built Ballerina services repository (https://github.com/wso2/open-healthcare-prebuilt-services) to your Github organization.
    * Create a service component pointing to the `ccda-to-fhirr4-service`. Follow the official documentation to create and configure a service: https://wso2.com/choreo/docs/develop-components/develop-services/develop-a-ballerina-rest-api/#step-1-create-a-service-component. 

    * Once the component creation is complete, you will see the component overview page.

2. Build and Deploy

    Follow the official documentation to deploy the C-CDA to FHIR service to your organization https://wso2.com/choreo/docs/develop-components/develop-services/develop-a-ballerina-rest-api/#step-2-build-and-deploy.