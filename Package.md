This project can be used to connect to Cerner EHR.

## Cerner FHIR API

This project can be used for exposing Cerner as managed API. The project uses the [FHIR client connector](https://central.ballerina.io/wso2healthcare/healthcare.clients.fhirr4) to connect to the Cerner endpoint. The support for authenticating to Cerner has also been added to the project. It is sufficient to only configure this project.


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

| Configuration     | Description                                                                                 |
|-------------------|---------------------------------------------------------------------------------------------|
| `base`            | Cerner base URL                                                                             |
| `tokenUrl`        | Cerner's token endpoint                                                                     |
| `clientId`        | Client ID of the system account registered with Cerner                                      |
| `clientSecret`    | Client secret of the system account registered with Cerner                                  |
| `scopes`          | Comma-seperated list of scopes                                                              |
| `customDomain`    | URL that should replace the Cerner base URL in the responses, if URL-rewrite is enabled     |
