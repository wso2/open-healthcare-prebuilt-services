# FHIR R4 Metadata Service

## Introduction
This service provides implementation of FHIR Metadata API. This implements 
[capabilities](https://www.hl7.org/fhir/http.html#capabilities) interaction, which is used to retrieve capability 
statement describing the server's current operational functionality by FHIR client applications. 

This FHIR server interaction returns Capability Statement ([CapabilityStatement](http://hl7.org/fhir/StructureDefinition/CapabilityStatement) 
FHIR resource) that specifies which resource types and interactions are supported by the FHIR server

```Supported FHIR version is 4.0.1.```

## Setup and run

1. Clone this repository to your local machine and navigate to the pre-built service on metadata-fhirr4-service.

2. Configure the Config.toml with relevant configurations mentioned in [Configurations](#configurations).

    Also, resource details need to be added as described in [Configurations](#resources).

3. Run the project.

    ```ballerina
    bal run
    ```

4. Invoke the API.

    Sample request for FHIR Capability Statement:

    ```
    curl 'http://<host>:<port>/fhir/r4/metadata'
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

### Steps to Deploy Metadata Prebuilt Service in Choreo
1. Create Service Component
    * Fork the pre-built Ballerina services repository (https://github.com/wso2/open-healthcare-prebuilt-services) to your Github organization.
    * Create a service component pointing to the `metadata-fhirr4-service`. Follow the official documentation to create and configure a service: https://wso2.com/choreo/docs/develop-components/develop-services/develop-a-ballerina-rest-api/#step-1-create-a-service-component.
    * Once the component creation is complete, you will see the component overview page.

2. Configure and Deploy

    Follow the official documentation to deploy the Metadata prebuilt service to your organization https://wso2.com/choreo/docs/develop-components/develop-services/develop-a-ballerina-rest-api/#step-2-build-and-deploy.

    FHIR Resource details need to be added as described in [Configurations/Resources](#resources).

    On deployment configurables mentioned in [Configurations/Configs](#configurations) needs to be configured in Choreo configurable editor.

## Configurations

### Configs

Following configurations need to be added in a `Config.toml` or in the Choreo configurations editor.

| Configuration                | Description                                                                                        |
|------------------------------|----------------------------------------------------------------------------------------------------|
| `version`                    | Business version of the capability statement <br/><br/>  eg: `0.1.7`                               |
| `name`                       | Name for this capability statement (computer friendly)  <br/><br/> eg: `WSO2OpenHealthcareFHIR`    | 
| `title`                      | Name for this capability statement (human friendly) <br/><br/> eg: `FHIR Server`                   | 
| `status`                     | `draft` / `active` / `retired` / `unknown` <br/><br/> eg: `active`                                 | 
| `experimental`               | For testing purposes, not real usage <br/><br/> eg: `true`                                         | 
| `date`                       | Date last changed <br/><br/> eg: `26-01-2023`                                                      | 
| `kind`                       | `instance` / `capability` / `requirements` <br/><br/> eg: `instance`                               | 
| `fhirVersion`                | FHIR Version the system supports <br/><br/> eg:  `4.0.1`                                           | 
| `format`                     | formats supported (`json`) <br/><br/> eg: `[json]`                                                 | 
| `patchFormat`                | Patch formats supported <br/><br/> eg: `[application/json-patch+json]`                             | 
| `implementationUrl`          | Base URL for the installation <br/><br/> eg: `https://choreoapis/dev/fhir_server/0.1.5`            |
| `implementationDescription`  | Describes this specific instance <br/><br/> eg: `WSO2 Open Healthcare FHIR`                        |  
| `interaction`                | The that operations are supported <br/><br/> eg: `[search-system, history-system]`                 | 
| `cors`                       | CORS Headers availability <br/><br/> eg: `true`                                                    |
| `discoveryEndpoint`          | The discovery endpoint for the server <br/><br/> eg: `https://api.asgardeo.io/t/<organization_name>/oauth2/token/.well-known/openid-configuration` |
| `tokenEndpoint`              | OPTIONAL: If not provided a discoveryEndpoint. <br/>OAUTH2 access token url <br/><br/> eg: `https://api.asgardeo.io/t/<organization_name>/oauth2/token`          | 
| `revocationEndpoint`         | OPTIONAL: If not provided a discoveryEndpoint. <br/>OAUTH2 access revoke url <br/><br/> eg: `https://api.asgardeo.io/t/<organization_name>/oauth2/revoke`        | 
| `authorizeEndpoint`          | OPTIONAL: If not provided a discoveryEndpoint. <br/>OAUTH2 access authorize url <br/><br/> eg: `https://api.asgardeo.io/t/<organization_name>/oauth2/authorize`  |

A sample `Config.toml` is consisting above configurations as below.

    ```
    ## server related configurables
    [configFHIRServer]
    version = "1.2.0"
    name = "WSO2OpenHealthcareFHIR"
    title = "FHIR Server"
    status = "active"
    experimental = true
    date = "2022-11-24"
    kind = "instance"
    fhirVersion = "4.0.1"
    format = ["json"]
    patchFormat = ["application/json-patch+json"]
    implementationUrl = "<FHIR_BASE_URL>"
    implementationDescription = "WSO2 Open Healthcare FHIR"

    ## server security related configurables
    [configRest]
    mode = "server"
    resourceFilePath = "resources/fhir_resources.json"
    interaction = ["search-system"]
    [configRest.security]
    cors = false
    discoveryEndpoint = "https://api.asgardeo.io/t/<organization_name>/oauth2/token/.well-known/openid-configuration"
    managementEndpoint = "https://api.asgardeo.io/t/<organization_name>/oauth2/manage"
    ```

### Resources

FHIR resource details need to be added in `/resources/fhir_resources.json`. A sample `fhir_resources.json` consisting of
`Patient` resource details, is as below.

```
[
    {
        "type": "Patient",
        "versioning": "versioned",
        "conditionalCreate": false,
        "conditionalRead": "not-supported",
        "conditionalUpdate": false,
        "conditionalDelete": "not-supported",
        "referencePolicies": ["resolves"],
        "searchRevIncludes": ["null"],
        "supportedProfiles": ["http://hl7.org/fhir/StructureDefinition/Patient"],
        "interaction": ["create", "delete", "update", "history-type", "search-type", "vread", "read"],
        "stringSearchParams": ["_lastUpdated", "_security", "_tag", "_source", "_profile"],
        "numberSearchParams": ["_id"]
    }
]    
```

When deploying on Choreo, Choreo's File Mount (https://wso2.com/choreo/docs/devops-and-ci-cd/manage-configurations-and-secrets/#apply-a-file-mount-to-your-container) can be used to mount the `fhir_resources.json`. The Mount Path should be provided as,

```
/resources/fhir_resources.json
```