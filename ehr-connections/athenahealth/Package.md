This project can be used to connect to Athena EHR.

## AthenaHealth FHIR API

This project can be used for exposing Athena as managed API. The project uses the [FHIR client connector](https://central.ballerina.io/wso2healthcare/healthcare.clients.fhirr4) to connect to the Athena endpoint. The support for authenticating to Athena has also been added to the project. It is sufficient to only configure this project.


### Compatibility
|                     | Version                   |
|---------------------|---------------------------|
| FHIR                | R4                        |

## Using the API

### Setup and run on Choreo

1. Perform steps 1 & 2 as mentioned above.

2. Push the project to a new Github repository.

3. Follow instructions to [connect the project repository to Choreo](https://wso2.com/choreo/docs/tutorials/connect-your-existing-ballerina-project-to-choreo/)

4. Deploy API by following [instructions to deploy](https://wso2.com/choreo/docs/tutorials/create-your-first-rest-api/#step-2-deploy) and [test](https://wso2.com/choreo/docs/tutorials/create-your-first-rest-api/#step-3-test)

5. Invoke the API.

    Sample URL to retrieve a patient by ID:

    `https://<domain>/<component>/<version>/Patient/123456`


### Configuring the project

Create a file `Config.toml` in the project's root directory and add the following configurations.

| Configuration     | Description                                                                                             |
|-------------------|---------------------------------------------------------------------------------------------------------|
| `base`            | Athena base URL                                                                                         |
| `tokenUrl`        | Athena's token endpoint                                                                                 |
| `clientId`        | Client ID of the application registered with Athena                                                     |
| `clientSecret`    | Client secret of the application registered with Athena                                                 |
| `scopes`          | Comma-seperated list of scopes                                                                          |
| `customDomain`    | URL that should replace the Athena base URL in the responses, if URL-rewrite interceptor is engaged     |
