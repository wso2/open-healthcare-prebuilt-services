// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations

import ballerina/http;
import ballerina/log;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.validator;

// Configure the array below if you want to allow only specific origins
configurable string[] CORS_ALLOWED_ORIGINS = ["*"];

service http:Service / on new http:Listener(9090) {

    @http:ResourceConfig {
        cors: {
            allowOrigins: CORS_ALLOWED_ORIGINS,
            allowCredentials: true
        }
    }

    isolated resource function post validate(@http:Payload json message) returns http:Response {

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

        //When validation is Successful, creates an OperationOutcome with a single
        //custom FHIRIssueDetail and returns it.
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
