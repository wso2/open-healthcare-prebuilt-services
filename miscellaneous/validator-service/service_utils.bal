// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com).
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

import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.validator;

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
    }

    string[]? expression = detail.expression;
    if expression != () {
        issueBBE.expression = expression;
    }

    return issueBBE;
}
