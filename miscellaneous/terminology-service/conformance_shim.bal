// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;

# Bypasses the framework's strict per-parameter validation for an operation, so parameters not declared in the standard FHIR OperationDefinition (e.g. the "uuid" correlation parameter the HL7 tx-ecosystem test runner attaches to every $expand/$validate-code/$lookup/$subsumes request) are tolerated instead of being rejected with HTTP 400. For a POST, parses the payload and hands it back unchanged; for a GET, passes the raw query parameters through as operation search params. The service handlers (and filterSupportedExpansionParams) then take only the parameters they actually understand. This is a temporary shim (branch: api-conformance) to be removed once the server natively tolerates unknown operation parameters, or once the parameters are declared in the OperationDefinitions.
#
# + definition - The FHIR OperationDefinition for the operation being invoked
# + resourceType - The resource type the operation is invoked on
# + requestQueryParams - The raw GET query parameters, or `()` when the request is a POST
# + payload - The parsed POST body (Parameters or Bundle), or `()` when the request is a GET
# + return - The resolved search parameters or resource entity to hand to the operation, an `r4:FHIRError` if a POST payload is invalid, or `()`
isolated function lenientOperationPreProcessor(r4:FHIROperationDefinition definition, string resourceType,
        map<string[]?>? requestQueryParams, json|xml? payload)
        returns map<r4:RequestSearchParameter[]>|r4:FHIRResourceEntity|r4:FHIRError? {

    // POST invocation: a payload is present. Parse it and wrap it, skipping the
    // strict per-parameter validation the framework would otherwise perform.
    if payload != () {
        anydata|r4:FHIRParseError parsed = parser:parse(payload);
        if parsed is r4:FHIRParseError {
            return r4:createFHIRError(
                    "Invalid operation payload",
                    r4:ERROR,
                    r4:PROCESSING,
                    diagnostic = "Payload must be a valid FHIR Parameters or Bundle resource.",
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }
        return new r4:FHIRResourceEntity(parsed);
    }

    // GET invocation: build operation search parameters straight from the query
    // string without rejecting parameters the OperationDefinition does not list.
    map<r4:RequestSearchParameter[]> operationSearchParams = {};
    if requestQueryParams is map<string[]?> {
        foreach var [name, values] in requestQueryParams.entries() {
            if values is () {
                continue;
            }
            r4:RequestSearchParameter[] searchParams = [];
            foreach string value in values {
                searchParams.push({
                    name: name,
                    value: value,
                    'type: r4:STRING,
                    typedValue: {modifier: ()}
                });
            }
            operationSearchParams[name] = searchParams;
        }
    }
    return operationSearchParams;
}

# Pre-processor for the custom `$find-code` and `$closure` base (system-level) operations.
#
# Bypasses the framework's per-parameter allowlist the same way `lenientOperationPreProcessor`
# does (needed for `$find-code`'s GET query parameters: `property`/`system`/`filter`/`_count`/`_offset`),
# but keeps the exact "Empty request payload" / "Invalid request payload" error text the two
# operations' POST forms already commit to (asserted by existing tests), instead of the generic
# message the framework's own validation would produce.
#
# + definition - The FHIR OperationDefinition for the operation being invoked
# + resourceType - The resource type the operation is invoked on
# + requestQueryParams - The raw GET query parameters, or `()` when the request is a POST
# + payload - The raw POST body, or `()` when the request is a GET or the POST body is empty
# + return - The resolved search parameters or resource entity to hand to the operation, an `r4:FHIRError` if a POST payload is missing/invalid, or `()`
isolated function findCodeAndClosurePreProcessor(r4:FHIROperationDefinition definition, string resourceType,
        map<string[]?>? requestQueryParams, json|xml? payload)
        returns map<r4:RequestSearchParameter[]>|r4:FHIRResourceEntity|r4:FHIRError? {

    if requestQueryParams is map<string[]?> {
        // GET invocation: pass every query parameter straight through so the
        // operation handler can validate the ones it cares about itself.
        map<r4:RequestSearchParameter[]> operationSearchParams = {};
        foreach var [name, values] in requestQueryParams.entries() {
            if values is () {
                continue;
            }
            r4:RequestSearchParameter[] searchParams = [];
            foreach string value in values {
                searchParams.push({
                    name: name,
                    value: value,
                    'type: r4:STRING,
                    typedValue: {modifier: ()}
                });
            }
            operationSearchParams[name] = searchParams;
        }
        return operationSearchParams;
    }

    // POST invocation.
    if payload is () {
        return r4:createFHIRError("Empty request payload", r4:ERROR, r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if payload is xml {
        return r4:createFHIRError("Invalid request payload", r4:ERROR, r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:Parameters|error typedParams = payload.cloneWithType(r4:Parameters);
    if typedParams is error {
        return r4:createFHIRError("Invalid request payload", r4:ERROR, r4:INVALID_REQUIRED,
                cause = typedParams, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    return new r4:FHIRResourceEntity(typedParams);
}

