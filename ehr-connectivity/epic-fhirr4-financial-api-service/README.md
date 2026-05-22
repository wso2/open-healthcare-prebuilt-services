# Epic FHIR Financial API Service

This pre-built service provides an API for financial category of Epic FHIR resources. It is built using [Ballerina](https://ballerina.io/) and uses [Epic's FHIR API](https://fhir.epic.com/Documentation) to interact with Epic's electronic health record system.

## Prerequisites

To get started with this service, you'll need to have Ballerina (Refer compatibility to install the relevant version) installed on your machine. If you are trying out with the Epic FHIR Sandbox, you have to create an application and obtain an client key and public key of the Epic FHIR server in order to access their FHIR API. Refer more on app creation on Epic FHIR sandbox [refer](https://fhir.epic.com/Documentation?docId=oauth2&section=BackendOAuth2Guide).

### Setup and run

1. Clone this repository to your local machine and navigate to the pre-built service on Epic financial API.

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

- `/fhir/r4/Account`: [Account API](http://hl7.org/fhir/R4/account.html) : acts as a central record against which charges, payments, and adjustments are applied. It contains information about which parties are responsible for payment of the account.
- `/fhir/r4/Contract`: [Contract API](http://hl7.org/fhir/R4/contract.html) : allows for the instantiation of various types of legally enforceable agreements or policies as shareable, consumable, and executable artifacts as well as precursory content upon which instances may be based or derivative artifacts supporting management of their basal instance.
- `/fhir/r4/Coverage`: [Coverage API](http://hl7.org/fhir/R4/coverage.html) : intended to provide the high-level identifiers and descriptors of an insurance plan, typically the information which would appear on an insurance card, which may be used to pay, in part or in whole, for the provision of health care products and services.
- `/fhir/r4/CoverageEligibilityRequest`: [CoverageEligibilityRequest API](http://hl7.org/fhir/R4/coverageeligibilityrequest.html) : makes a request of an insurer asking them to provide, in the form of an CoverageEligibilityResponse, information regarding: (validation) whether the specified coverage(s) is valid and in-force; (discovery) what coverages the insurer has for the specified patient; (benefits) the benefits provided under the coverage; whether benefits exist under the specified coverage(s) for specified classes of services and products; and (auth-requirements) whether preauthorization is required, and if so what information may be required in that preauthorization, for the specified service classes or services.
- `/fhir/r4/CoverageEligibilityResponse`: [CoverageEligibilityResponse API](http://hl7.org/fhir/R4/coverageeligibilityresponse.html) : provides eligibility and plan details from the processing of an CoverageEligibilityRequest resource.
- `/fhir/r4/EnrollmentRequest`: [EnrollmentRequest API](http://hl7.org/fhir/R4/enrollmentrequest.html) : allows for the addition and removal of plan subscribers and their dependents to health insurance coverage.
- `/fhir/r4/EnrollmentResponse`: [EnrollmentResponse API](http://hl7.org/fhir/R4/enrollmentresponse.html) : provides enrollment and plan details from the processing of an EnrollmentRequest resource.
- `/fhir/r4/VisionPrescription`: [VisionPrescription API](http://hl7.org/fhir/R4/visionprescription.html) : intended to support the information requirements for a prescription for glasses and contact lenses for a patient. Corrective optical lenses are considered a controlled substance and therefore a prescription is typically required for the provision of patient-specific lenses.
- `/fhir/r4/Claim`: [Claim API](http://hl7.org/fhir/R4/claim.html) : used by providers and payors, insurers, to exchange the financial information, and supporting clinical information, regarding the provision of health care services with payors and for reporting to regulatory bodies and firms which provide data analytics.
- `/fhir/r4/ClaimResponse`: [ClaimResponse API](http://hl7.org/fhir/R4/claimresponse.html) : provides application level adjudication results, or an application level error, which are the result of processing a submitted Claim resource where that Claim may be the functional corollary of a Claim, Predetermination or a Preauthorization.
- `/fhir/r4/PaymentNotice`: [PaymentNotice API](http://hl7.org/fhir/R4/paymentnotice.html) : indicates the resource for which the payment has been indicated and reports the current status information of that payment.
- `/fhir/r4/PaymentReconciliation`: [PaymentReconciliation API](http://hl7.org/fhir/R4/paymentreconciliation.html) : provides the bulk payment details associated with a payment by the payor for receivable amounts, such as for goods and services rendered by a provider to patients covered by insurance plans offered by that payor. 
- `/fhir/r4/ExplanationOfBenefit`: [ExplanationOfBenefit API](http://hl7.org/fhir/R4/explanationofbenefit.html) : combines key information from a Claim, a ClaimResponse and optional Account information to inform a patient of the goods and services rendered by a provider and the settlement made under the patient's coverage in respect of that Claim.

For more information about the data returned by these endpoints, see [Epic's FHIR API documentation](https://fhir.epic.com/Documentation).
