import ballerina/os;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhirr4;
import ballerinax/health.fhir.r4;

configurable string base = os:getEnv("EPIC_FHIR_SERVER_URL");
configurable string tokenUrl = os:getEnv("EPIC_FHIR_SERVER_TOKEN_URL");
configurable string clientId = os:getEnv("EPIC_FHIR_APP_CLIENT_ID");
configurable string keyFile = os:getEnv("EPIC_FHIR_APP_PRIVATE_KEY_FILE");

fhir:FHIRConnectorConfig epicConfig = {
    baseURL: base,
    mimeType: fhir:FHIR_JSON,
    authConfig: {
        clientId: clientId,
        tokenEndpoint: tokenUrl,
        keyFile: keyFile
    }
};

final fhir:FHIRConnector fhirConnectorObj = check new (epicConfig);

public type Account international401:Account;

public type Contract international401:Contract;

public type Coverage international401:Coverage;

public type CoverageEligibilityRequest international401:CoverageEligibilityRequest;

public type CoverageEligibilityResponse international401:CoverageEligibilityResponse;

public type EnrollmentRequest international401:EnrollmentRequest;

public type EnrollmentResponse international401:EnrollmentResponse;

public type VisionPrescription international401:VisionPrescription;

public type Claim international401:Claim;

public type ClaimResponse international401:ClaimResponse;

public type PaymentNotice international401:PaymentNotice;

public type PaymentReconciliation international401:PaymentReconciliation;

public type ExplanationOfBenefit international401:ExplanationOfBenefit;

service / on new fhirr4:Listener(9090, accountApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Account/[string id](r4:FHIRContext fhirContext) returns Account|r4:FHIRError {
        Account|error fhirInteractionResult = executeFhirInteraction("Account", fhirContext, id, (), Account).ensureType(Account);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Account read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Account(r4:FHIRContext fhirContext) returns r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Account", fhirContext, (), (), Account).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Account search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Account(r4:FHIRContext fhirContext, international401:Account account) returns Account|r4:FHIRError {
        Account|error fhirInteractionResult = executeFhirInteraction("Account", fhirContext, (), account, Account).ensureType(Account);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Account create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9091, contractApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Contract/[string id](r4:FHIRContext fhirContext) returns Contract|r4:FHIRError {
        Contract|error fhirInteractionResult = executeFhirInteraction("Contract", fhirContext, id, (), Contract).ensureType(Contract);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Contract read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Contract(r4:FHIRContext fhirContext) returns r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Contract", fhirContext, (), (), Contract).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Contract search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Contract(r4:FHIRContext fhirContext, international401:Contract contract) returns Contract|r4:FHIRError {
        Contract|error fhirInteractionResult = executeFhirInteraction("Contract", fhirContext, (), contract, Contract).ensureType(Contract);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Contract create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9092, coverageApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Coverage/[string id](r4:FHIRContext fhirContext) returns Coverage|r4:FHIRError {
        Coverage|error fhirInteractionResult = executeFhirInteraction("Coverage", fhirContext, id, (), Coverage).ensureType(Coverage);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Coverage read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Coverage(r4:FHIRContext fhirContext) returns r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Coverage", fhirContext, (), (), Coverage).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Coverage search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Coverage(r4:FHIRContext fhirContext, international401:Coverage coverage) returns Coverage|r4:FHIRError {
        Coverage|error fhirInteractionResult = executeFhirInteraction("Coverage", fhirContext, (), coverage, Coverage).ensureType(Coverage);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Coverage create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9093, coverageEligibilityRequestApiConfig) { 

    // Read the current state of the resource.
    isolated resource function get fhir/r4/CoverageEligibilityRequest/[string id](r4:FHIRContext fhirContext) returns CoverageEligibilityRequest|r4:FHIRError {
        CoverageEligibilityRequest|error fhirInteractionResult = executeFhirInteraction("CoverageEligibilityRequest", fhirContext, id, (), CoverageEligibilityRequest).ensureType(CoverageEligibilityRequest);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the CoverageEligibilityRequest read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/CoverageEligibilityRequest(r4:FHIRContext fhirContext) returns r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("CoverageEligibilityRequest", fhirContext, (), (), CoverageEligibilityRequest).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the CoverageEligibilityRequest search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/CoverageEligibilityRequest(r4:FHIRContext fhirContext, international401:CoverageEligibilityRequest coverageEligibilityRequest) returns CoverageEligibilityRequest|r4:FHIRError {
        CoverageEligibilityRequest|error fhirInteractionResult = executeFhirInteraction("CoverageEligibilityRequest", fhirContext, (), coverageEligibilityRequest, CoverageEligibilityRequest).ensureType(CoverageEligibilityRequest);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the CoverageEligibilityRequest create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9094, coverageEligibilityResponseApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/CoverageEligibilityResponse/[string id](r4:FHIRContext fhirContext) returns CoverageEligibilityResponse|r4:FHIRError {
        CoverageEligibilityResponse|error fhirInteractionResult = executeFhirInteraction("CoverageEligibilityResponse", fhirContext, id, (), CoverageEligibilityResponse).ensureType(CoverageEligibilityResponse);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the CoverageEligibilityResponse read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/CoverageEligibilityResponse(r4:FHIRContext fhirContext) returns r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("CoverageEligibilityResponse", fhirContext, (), (), CoverageEligibilityResponse).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the CoverageEligibilityResponse search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/CoverageEligibilityResponse(r4:FHIRContext fhirContext, international401:CoverageEligibilityResponse coverageEligibilityResponse) returns CoverageEligibilityResponse|r4:FHIRError {
        CoverageEligibilityResponse|error fhirInteractionResult = executeFhirInteraction("CoverageEligibilityResponse", fhirContext, (), coverageEligibilityResponse, CoverageEligibilityResponse).ensureType(CoverageEligibilityResponse);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the CoverageEligibilityResponse create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
} 

service / on new fhirr4:Listener(9095, enrollmentRequestApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/EnrollmentRequest/[string id](r4:FHIRContext fhirContext) returns EnrollmentRequest|r4:FHIRError {
        EnrollmentRequest|error fhirInteractionResult = executeFhirInteraction("EnrollmentRequest", fhirContext, id, (), EnrollmentRequest).ensureType(EnrollmentRequest);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the EnrollmentRequest read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/EnrollmentRequest(r4:FHIRContext fhirContext) returns r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("EnrollmentRequest", fhirContext, (), (), EnrollmentRequest).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the EnrollmentRequest search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/EnrollmentRequest(r4:FHIRContext fhirContext, international401:EnrollmentRequest enrollmentRequest) returns EnrollmentRequest|r4:FHIRError {
        EnrollmentRequest|error fhirInteractionResult = executeFhirInteraction("EnrollmentRequest", fhirContext, (), enrollmentRequest, EnrollmentRequest).ensureType(EnrollmentRequest);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the EnrollmentRequest create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9096, enrollmentResponseApiConfig) { 

    // Read the current state of the resource.
    isolated resource function get fhir/r4/EnrollmentResponse/[string id](r4:FHIRContext fhirContext) returns EnrollmentResponse|r4:FHIRError {
        EnrollmentResponse|error fhirInteractionResult = executeFhirInteraction("EnrollmentResponse", fhirContext, id, (), EnrollmentResponse).ensureType(EnrollmentResponse);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the EnrollmentResponse read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/EnrollmentResponse(r4:FHIRContext fhirContext) returns r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("EnrollmentResponse", fhirContext, (), (), EnrollmentResponse).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the EnrollmentResponse search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/EnrollmentResponse(r4:FHIRContext fhirContext, international401:EnrollmentResponse enrollmentResponse) returns EnrollmentResponse|r4:FHIRError {
        EnrollmentResponse|error fhirInteractionResult = executeFhirInteraction("EnrollmentResponse", fhirContext, (), enrollmentResponse, EnrollmentResponse).ensureType(EnrollmentResponse);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the EnrollmentResponse create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9097, visionPrescriptionApiConfig) { 

    // Read the current state of the resource.
    isolated resource function get fhir/r4/VisionPrescription/[string id](r4:FHIRContext fhirContext) returns VisionPrescription|r4:FHIRError {
        VisionPrescription|error fhirInteractionResult = executeFhirInteraction("VisionPrescription", fhirContext, id, (), VisionPrescription).ensureType(VisionPrescription);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the VisionPrescription read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/VisionPrescription(r4:FHIRContext fhirContext) returns r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("VisionPrescription", fhirContext, (), (), VisionPrescription).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the VisionPrescription search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/VisionPrescription(r4:FHIRContext fhirContext, international401:VisionPrescription visionPrescription) returns VisionPrescription|r4:FHIRError {
        VisionPrescription|error fhirInteractionResult = executeFhirInteraction("VisionPrescription", fhirContext, (), visionPrescription, VisionPrescription).ensureType(VisionPrescription);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the VisionPrescription create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9098, claimApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/Claim/[string id](r4:FHIRContext fhirContext) returns Claim|r4:FHIRError {
        Claim|error fhirInteractionResult = executeFhirInteraction("Claim", fhirContext, id, (), Claim).ensureType(Claim);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Claim read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/Claim(r4:FHIRContext fhirContext) returns r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("Claim", fhirContext, (), (), Claim).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Claim search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/Claim(r4:FHIRContext fhirContext, international401:Claim claim) returns Claim|r4:FHIRError {
        Claim|error fhirInteractionResult = executeFhirInteraction("Claim", fhirContext, (), claim, Claim).ensureType(Claim);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the Claim create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9099, claimResponseApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/ClaimResponse/[string id](r4:FHIRContext fhirContext) returns ClaimResponse|r4:FHIRError {
        ClaimResponse|error fhirInteractionResult = executeFhirInteraction("ClaimResponse", fhirContext, id, (), ClaimResponse).ensureType(ClaimResponse);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the ClaimResponse read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/ClaimResponse(r4:FHIRContext fhirContext) returns r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("ClaimResponse", fhirContext, (), (), ClaimResponse).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the ClaimResponse search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/ClaimResponse(r4:FHIRContext fhirContext, international401:ClaimResponse claimResponse) returns ClaimResponse|r4:FHIRError {
        ClaimResponse|error fhirInteractionResult = executeFhirInteraction("ClaimResponse", fhirContext, (), claimResponse, ClaimResponse).ensureType(ClaimResponse);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the ClaimResponse create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }
}

service / on new fhirr4:Listener(9100, paymentNoticeApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/PaymentNotice/[string id](r4:FHIRContext fhirContext) returns PaymentNotice|r4:FHIRError {
        PaymentNotice|error fhirInteractionResult = executeFhirInteraction("PaymentNotice", fhirContext, id, (), PaymentNotice).ensureType(PaymentNotice);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the PaymentNotice read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/PaymentNotice(r4:FHIRContext fhirContext) returns r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("PaymentNotice", fhirContext, (), (), PaymentNotice).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the PaymentNotice search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/PaymentNotice(r4:FHIRContext fhirContext, international401:PaymentNotice paymentNotice) returns PaymentNotice|r4:FHIRError {
        PaymentNotice|error fhirInteractionResult = executeFhirInteraction("PaymentNotice", fhirContext, (), paymentNotice, PaymentNotice).ensureType(PaymentNotice);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the PaymentNotice create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    }    
}

service / on new fhirr4:Listener(9101, paymentReconciliationApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/PaymentReconciliation/[string id](r4:FHIRContext fhirContext) returns PaymentReconciliation|r4:FHIRError {
        PaymentReconciliation|error fhirInteractionResult = executeFhirInteraction("PaymentReconciliation", fhirContext, id, (), PaymentReconciliation).ensureType(PaymentReconciliation);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the PaymentReconciliation read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult;
    } 

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/PaymentReconciliation(r4:FHIRContext fhirContext) returns r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("PaymentReconciliation", fhirContext, (), (), PaymentReconciliation).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the PaymentReconciliation search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult; 
    } 

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/PaymentReconciliation(r4:FHIRContext fhirContext, international401:PaymentReconciliation paymentReconciliation) returns PaymentReconciliation|r4:FHIRError {
        PaymentReconciliation|error fhirInteractionResult = executeFhirInteraction("PaymentReconciliation", fhirContext, (), paymentReconciliation, PaymentReconciliation).ensureType(PaymentReconciliation);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the PaymentReconciliation create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult; 
    } 
}

service / on new fhirr4:Listener(9102, explanationOfBenefitApiConfig) {

    // Read the current state of the resource.
    isolated resource function get fhir/r4/ExplanationOfBenefit/[string id](r4:FHIRContext fhirContext) returns ExplanationOfBenefit|r4:FHIRError {
        ExplanationOfBenefit|error fhirInteractionResult = executeFhirInteraction("ExplanationOfBenefit", fhirContext, id, (), ExplanationOfBenefit).ensureType(ExplanationOfBenefit);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the ExplanationOfBenefit read interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult; 
    } 

    // Search for resources based on some filter criteria.
    isolated resource function get fhir/r4/ExplanationOfBenefit(r4:FHIRContext fhirContext) returns r4:Bundle|r4:FHIRError {
        r4:Bundle|error fhirInteractionResult = executeFhirInteraction("ExplanationOfBenefit", fhirContext, (), (), ExplanationOfBenefit).ensureType(r4:Bundle);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the ExplanationOfBenefit search interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult; 
    } 

    // Create a new resource with a server assigned id.
    isolated resource function post fhir/r4/ExplanationOfBenefit(r4:FHIRContext fhirContext, international401:ExplanationOfBenefit explanationOfBenefit) returns ExplanationOfBenefit|r4:FHIRError {
        ExplanationOfBenefit|error fhirInteractionResult = executeFhirInteraction("ExplanationOfBenefit", fhirContext, (), explanationOfBenefit, ExplanationOfBenefit).ensureType(ExplanationOfBenefit);
        if fhirInteractionResult is error {
            return r4:createFHIRError("Error occurred while executing the ExplanationOfBenefit create interaction.", r4:CODE_SEVERITY_ERROR,
                r4:TRANSIENT_EXCEPTION, cause = fhirInteractionResult);
        }
        return fhirInteractionResult; 
    } 
}
