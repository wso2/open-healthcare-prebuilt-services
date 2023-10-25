# C-CDA to FHIR
This tool transforms C-CDA documents to FHIR format(as resources specified in USCore implementation guide). Data transformation conditions are taken from the [official C-CDA on FHIR page](https://hl7.org/fhir/us/ccda/).

The pre-built Ballerina service for C-CDA to FHIR transformation is publicly available in [Github](https://github.com/wso2/open-healthcare-prebuilt-services/tree/main/transformation/ccda-to-fhirr4-service) to use. You can use the pre-built service to host the transformation tool on your own environment or deploy on Choreo as a standard Ballerina service.

C-CDA on FHIR version 1.1.0 (`FHIR R4` - STU `Release 1.1`) is used for the transformation. 
### How to Deploy C-CDA to FHIR tool in Choreo

1. Create Service Component
   - Fork/Download the pre-built Ballerina service for C-CDA to FHIR transformation from Github
   - [Optional] Make any customizations/changes to the downloaded Ballerina project(in the local environment)
   - Upload the project into a Github repository
   - Sign In to the Choreo and go to the developer console
   - Create a project to add the service component.
   - On the `Components` page, click **Create** on the Service card.
   - Enter a unique name and a description of the service.
   - Click **Next**
   - To allow Choreo to connect to your GitHub account, click **Authorize with GitHub**.
   - If you have not already connected your GitHub repository to Choreo, enter your GitHub credentials, and select the repository you created in the prerequisites section to install the Choreo GitHub App.
   - In the Connect Repository pane, enter the details of the repository created with C-CDA to FHIR pre-built service.
   - Click **Create**. Once the component creation is complete, you will see the component `Overview` page.

|Note: You can make any customizations/changes to the downloaded Ballerina project in the local environment and continue on Choreo|
| :- |

2. Build and Deploy
   - In the left navigation click **Deploy** and navigate to the `Deploy` page.
   - In the `Deploy` page, click **Deploy Manually**.
   - In the `Configure & Deploy` pane that opens on the right, click the edit icon to edit the Endpoint.
   - Under `Network Visibility`, select `Public` and click **Update**.
   - Click **Deploy**.