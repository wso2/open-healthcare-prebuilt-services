import ballerina/http;
import ballerina/log;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.validator;

configurable string[] CORS_ALLOWED_ORIGINS = ?;

# FHIR validation error details record.
#
# + issues - FHIR issues
public type FHIRValidationErrorDetail record {
    *r4:FHIRErrorDetail;
    [validator:FHIRValidationIssueDetail, validator:FHIRValidationIssueDetail...] issues;
};

isolated function issueDetailToOperationOutcomeIssue(r4:FHIRIssueDetail detail) returns r4:OperationOutcomeIssue {

    r4:OperationOutcomeIssue issueBBE = {
        severity: detail.severity,
        code: detail.code
    };

    (r4:CodeableConcept)? details = detail.details;
    if details != () {
        issueBBE.details = details;
    }

    string? diagnostic = detail.diagnostic;
    if diagnostic != () {
        issueBBE.diagnostics = string `${diagnostic}`;
    } else {
        issueBBE.diagnostics = "";
    }

    string[]? expression = detail.expression;
    if expression != () {
        issueBBE.expression = expression;
    }

    return issueBBE;
}

service http:Service / on new http:Listener(9090) {

    @http:ResourceConfig {
        cors: {
            allowOrigins: CORS_ALLOWED_ORIGINS,
            allowCredentials: true
        }
    }

    resource function post validate(@http:Payload json message) returns http:Response {

        var validationResult = validator:validate(message);

        if validationResult is error {

            //Gets the fhir error from the validate function, extracts the detailedErrors array, and creates
            //a FHIRIssueDetail for each detailed error in the detailedErrors array.
            FHIRValidationErrorDetail & readonly detail = <FHIRValidationErrorDetail & readonly>validationResult.detail();
            validator:FHIRValidationIssueDetail issues = detail.issues[0];
            r4:FHIRIssueDetail[] issueArray = [];
            string[]? errorInIssue = issues.detailedErrors;
            if (errorInIssue != ()) {
                foreach var i in 0 ..< errorInIssue.length() {
                    r4:FHIRIssueDetail issue = {
                            severity: issues.severity,
                            code: issues.code,
                            diagnostic: errorInIssue[i],
                            expression: issues.expression,
                            details: ()
                        };
                    issueArray.push(issue);
                }
            }

            //Then, creates an OperationOutcomeIssue for each FHIRIssueDetail and adds them to an OperationOutcome.
            r4:OperationOutcomeIssue[] opIssueArray = [];
            foreach var i in 0 ..< issueArray.length() {
                r4:OperationOutcomeIssue opIssue = issueDetailToOperationOutcomeIssue(issueArray[i]);
                opIssueArray.push(opIssue);
            }
            r4:OperationOutcome opOutcome = {
                issue: opIssueArray
            };

            log:printDebug(opOutcome.toJsonString());

            http:Response response = new;
            response.statusCode = 400;
            response.setPayload(opOutcome.toJson());
            return response;

        }

        log:printDebug("Validation successful");
        r4:FHIRIssueDetail issue = {
                    severity: <r4:Severity>"information",
                    code: <r4:IssueType>"informational",
                    diagnostic: "Validation Successful",
                    expression: (),
                    details: ()
            };

        r4:OperationOutcomeIssue opIssue = issueDetailToOperationOutcomeIssue(issue);
        r4:OperationOutcome opOutcome = {
                issue: [opIssue]
        };
        http:Response response = new;
        response.statusCode = 200;
        response.setPayload(opOutcome.toJson());
        return response;
    }
}
