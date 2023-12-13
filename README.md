## Overview
This repository comprises prebuilt healthcare-related services that are ready for immediate use. Users have the flexibility to deploy and run these services in their respective environments. Optionally, these services can be deployed in [Choreo](https://console.choreo.dev/home) as well. For further details, refer to the documentation of the individual services.

## Prerequisite
- Download and install [Ballerina Swan Lake](https://ballerina.io/downloads/) 2202.8.1 or above.

## Available Services
### Conformance
#### [Metadata Service](conformance/metadata-fhirr4-service/)
This service facilitates the exposure of a capability statement describing the current operational functionality of a FHIR server.

#### [SMART Configuration Service](conformance/smart-config-fhirr4-service/)
This service can be used to expose the discovery document containing authorization endpoint URLs and SMART-features supported by a FHIR server.

### Transformation
#### [HL7v2 to FHIR](transformation/v2-to-fhirr4-service/)
Transform HL7v2 messages into FHIR resources using this service.

#### [CCDA to FHIR](transformation/ccda-to-fhirr4-service/)
This service can be used to transform C-CDA messages into FHIR resources.

### EHR Related
#### EPIC Services
These services can be used to integrate with an Epic instance and expose Epic FHIR APIs.

- [Epic FHIR R4 Administration Service](ehr-connectivity/epic-fhirr4-administration-api-service/)
- [Epic FHIR R4 Clinical Service](ehr-connectivity/epic-fhirr4-clinical-api-service/)
- [Epic FHIR R4 Diagnostics Service](ehr-connectivity/epic-fhirr4-diagnostics-api-service/)
- [Epic FHIR R4 Financial Service](ehr-connectivity/epic-fhirr4-financial-api-service/)
- [Epic FHIR R4 Medications Service](ehr-connectivity/epic-fhirr4-medications-api-service/)
- [Epic FHIR R4 Workflow Service](ehr-connectivity/epic-fhirr4-workflow-api-service/)

### Miscellaneous
#### [Authorization Service](miscellaneous/authz-fhirr4-service/)
Apply basic patient and privileged user-based authorization policies for FHIR APIs using this service.

#### [Audit Service](miscellaneous/audit-service/)
Record audit events upon calling FHIR APIs using this service.

#### [FHIR Path Service](miscellaneous/fhirpath-service/)
Evaluate FHIR path expressions against a FHIR payload using this service.
