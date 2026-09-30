// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

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
// under the License.
import ballerina/http;
import ballerina/log;
import ballerinax/health.fhir.r4;

# Response error interceptor to handle errors thrown by fhir preproccessors
public isolated service class FHIRResponseErrorInterceptor {
    *http:ResponseErrorInterceptor;

    isolated remote function interceptResponseError(error err) returns http:NotFound|http:BadRequest|http:UnsupportedMediaType
            |http:NotAcceptable|http:Unauthorized|http:NotImplemented|http:MethodNotAllowed|http:InternalServerError {
        log:printDebug("Execute: FHIR Response Error Interceptor");
        if err is r4:FHIRError {
            match err.detail().httpStatusCode {
                http:STATUS_NOT_FOUND => {
                    http:NotFound notFound = {
                        body: r4:handleErrorResponse(err),
                        mediaType: r4:FHIR_MIME_TYPE_JSON
                    };
                    return notFound;
                }
                http:STATUS_BAD_REQUEST => {
                    http:BadRequest badRequest = {
                        body: r4:handleErrorResponse(err),
                        mediaType: r4:FHIR_MIME_TYPE_JSON
                    };
                    return badRequest;
                }
                http:STATUS_UNSUPPORTED_MEDIA_TYPE => {
                    http:UnsupportedMediaType unsupportedMediaType = {
                        body: r4:handleErrorResponse(err),
                        mediaType: r4:FHIR_MIME_TYPE_JSON
                    };
                    return unsupportedMediaType;
                }
                http:STATUS_NOT_ACCEPTABLE => {
                    http:NotAcceptable notAcceptable = {
                        body: r4:handleErrorResponse(err),
                        mediaType: r4:FHIR_MIME_TYPE_JSON
                    };
                    return notAcceptable;
                }
                http:STATUS_UNAUTHORIZED => {
                    http:Unauthorized unauthorized = {
                        body: r4:handleErrorResponse(err),
                        mediaType: r4:FHIR_MIME_TYPE_JSON
                    };
                    return unauthorized;
                }
                http:STATUS_NOT_IMPLEMENTED => {
                    http:NotImplemented notImplemented = {
                        body: r4:handleErrorResponse(err),
                        mediaType: r4:FHIR_MIME_TYPE_JSON
                    };
                    return notImplemented;
                }
                http:STATUS_METHOD_NOT_ALLOWED => {
                    http:MethodNotAllowed methodNotAllowed = {
                        body: r4:handleErrorResponse(err),
                        mediaType: r4:FHIR_MIME_TYPE_JSON
                    };
                    return methodNotAllowed;
                }
                _ => {
                    http:InternalServerError internalServerError = {
                        body: r4:handleErrorResponse(err),
                        mediaType: r4:FHIR_MIME_TYPE_JSON
                    };
                    return internalServerError;
                }
            }
        }
        http:InternalServerError internalServerError = {
            body: r4:handleErrorResponse(err),
            mediaType: r4:FHIR_MIME_TYPE_JSON
        };
        return internalServerError;
    }
}
