# HL7v2 to FHIR

This tool transforms HL7v2 messages to FHIR resources. Data transformation conditions are taken from the [official HL7v2 to FHIR mappings page](https://build.fhir.org/ig/HL7/v2-to-fhir).

The pre-built Ballerina service for HL7 v2 to FHIR transformation is publicly available in [Github](https://github.com/wso2/open-healthcare-prebuilt-services/tree/main/transformation/v2-to-fhirr4-service) to use. You can use the pre-built service to host the transformation tool on your own environment or deploy on Choreo as a standard Ballerina service.

### Supported HL7v2 message versions are:

- hl7v23
- hl7v231
- hl7v24
- hl7v25
- hl7v251
- hl7v26
- hl7v27
- hl7v271
- hl7v28

These HL7v2 messages will be converted to **FHIR R4 (v4.0.1)** resources based on the HL7 specified mappings.

## How to Deploy HL7 v2 to FHIR tool in Choreo

1. Create Service Component
   - Fork/Download the pre-built Ballerina service for HL7-v2 to FHIR transformation from Github
   - Upload the project into a Github repository
   - Sign In to the Choreo and go to the developer console
   - Create a project to add the service component.
   - On the Components page, click Create on the Service card.
   - Enter a unique name and a description of the service.
   - Click **Next**
   - To allow Choreo to connect to your GitHub account, click **Authorize with GitHub**.
   - If you have not already connected your GitHub repository to Choreo, enter your GitHub credentials, and select the repository you created in the prerequisites section to install the Choreo GitHub App.
   - In the Connect Repository pane, enter the details of the repository created with V2 to FHIR pre-built service.
   - Click Create. Once the component creation is complete, you will see the component overview page.


|Note: You can make any customizations/changes to the downloaded Ballerina project in the local environment and continue on Choreo|
| :- |


2. Build and Deploy
   - In the left navigation click Deploy and navigate to the `Deploy` page.
   - In the `Deploy` page, click **Deploy Manually**.
   - In the `Configure & Deploy` pane that opens on the right, click the edit icon to edit the Endpoint.
   - Under `Network Visibility`, select `Public` and click **Update**.
   - Click **Deploy**.