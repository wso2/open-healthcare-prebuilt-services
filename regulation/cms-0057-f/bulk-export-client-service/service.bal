import ballerina/file;
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
// under the License.
import ballerina/http;
import ballerina/log;
import ballerina/mime;
import ballerina/task;
import ballerina/uuid;
import ballerinax/health.fhir.r4.international401;

configurable BulkExportServerConfig sourceServerConfig = ?;
configurable BulkExportClientConfig clientServiceConfig = ?;
configurable TargetServerConfig targetServerConfig = ?;

http:OAuth2ClientCredentialsGrantConfig config = {
    tokenUrl: sourceServerConfig.tokenUrl,
    clientId: sourceServerConfig.clientId,
    clientSecret: sourceServerConfig.clientSecret,
    scopes: sourceServerConfig.scopes
};

isolated http:Client statusClient = check new (sourceServerConfig.baseUrl);

isolated service /bulk on new http:Listener(9099) {

    function init() returns error? {

        if clientServiceConfig.authEnabled {
            lock {
                statusClient = check new (sourceServerConfig.baseUrl, auth = config.clone());
            }
        } else {
            lock {
                statusClient = check new (sourceServerConfig.baseUrl);
            }
        }

        log:printInfo("Bulk export client Service is started...", port = clientServiceConfig.port);
    }

    // This function is responsible for exporting data in bulk.
    // It is an isolated resource function that handles the HTTP GET request for exporting data.
    // The exported data will be saved to the specified file path.
    //
    // @param _outputFormat - The output format of the exported data.
    // @param _since - The date and time from which the data should be exported.
    // @param _type - The type of the resource to be exported.
    //
    // @return The response indicating the success or failure of the export operation.
    isolated resource function get export(string? _outputFormat, string? _since, string? _type) returns json|error {

        // update config for status polling
        // initialize the status polling
        addExportTask addTaskFunction = addExportTasktoMemory;
        string taskId = uuid:createType1AsString();
        boolean isSuccess = false;
        http:Response|http:ClientError status;

        log:printInfo("Bulk exporting started. Sending Kick-off request.");

        do {

            lock {
                ExportTask exportTask = {id: taskId, lastStatus: "in-progress", pollingEvents: []};
                isSuccess = addTaskFunction(exportTasks, exportTask);
            }
            string queryString = populateQueryString(_outputFormat, _since, _type);
            // kick-off request to the bulk export server
            lock {
                status = statusClient->get(string `${sourceServerConfig.contextPath}/Patient/$export${queryString}`, {
                    Accept: "application/fhir+json",
                    Prefer: "respond-async"
                });
            }
            submitBackgroundJob(taskId, status);

            if isSuccess {
                log:printInfo("Export task persisted.", exportId = taskId);
            } else {
                log:printError("Error occurred while adding the export task to the memory.");
            }

        } on fail var e {
            log:printError("Error occurred while scheduling the status polling task.", e);
        }

        string message = string `Export task is successfully kicked-off. ExportId: ${taskId}
        To check the status, use: <BASE_URL>/trigger/status?exportId=${taskId}`;
        return createOpereationOutcome("information", "processing", message).toJson();

    }

    // This function is responsible for exporting data in bulk.
    // It is an isolated resource function that handles the HTTP POST request for exporting data.
    // The exported data will be saved to the specified file path.
    // 
    // @param payload - The payload containing the data to be exported.
    // @param _type - The types of the resource to be exported. Accept multiple values(comma seperated).
    //
    // @return The response indicating the success or failure of the export operation.
    isolated resource function post export(
            @http:Payload MatchedPatient[] matchedPatients,
            @http:Query string? _outputFormat,
            @http:Query string? _since,
            @http:Query string? _type) returns json|error {

        addExportTask addTaskFunction = addExportTasktoMemory;
        string taskId = uuid:createType1AsString();
        boolean isSuccess = false;
        http:Response|http:ClientError status;

        log:printInfo("Bulk exporting started. Sending Kick-off request.");
        do {

            lock {
                ExportTask exportTask = {id: taskId, lastStatus: "in-progress", pollingEvents: []};
                isSuccess = addTaskFunction(exportTasks, exportTask);
            }
            international401:Parameters parametersResource = populateParamsResource(matchedPatients, _outputFormat, _since, _type);
            // kick-off request to the bulk export server

            lock {
                status = statusClient->post(string `${sourceServerConfig.contextPath}/Patient/$export`, parametersResource.clone().toJson(),
                {
                    Accept: "application/fhir+json",
                    Prefer: "respond-async",
                    ContentType: "application/json"
                });
            }
            submitBackgroundJob(taskId, status);

            if isSuccess {
                log:printInfo("Export task persisted.", exportId = taskId);
            } else {
                log:printError("Error occurred while adding the export task to the memory.");
            }

        } on fail var e {
            log:printError("Error occurred while scheduling the status polling task.", e);
        }

        string message = string `Export task is successfully kicked-off. ExportId: ${taskId}
        To check the status, use: <BASE_URL>/trigger/status?exportId=${taskId}`;
        return createOpereationOutcome("information", "processing", message).toJson();

    }

    // Kick-off the export task for a specific group.
    // This function is responsible for kicking-off the export task for a specific group.
    // The export task will be persisted in the memory.
    //
    // @param group_id - The ID of the group.
    // @param _outputFormat - The output format of the exported data.
    // @param _since - The date and time from which the data should be exported.
    // @param _type - The type of the resource to be exported.
    //
    // @return The response indicating the success or failure of the export operation.
    isolated resource function get export/group/[string group_id](string? _outputFormat, string? _since, string? _type) returns json|error {

        // update config for status polling
        // initialize the status polling
        addExportTask addTaskFunction = addExportTasktoMemory;
        string taskId = uuid:createType1AsString();
        boolean isSuccess = false;
        http:Response|http:ClientError status;

        log:printInfo("Bulk exporting started. Sending Kick-off request.");

        do {

            lock {
                ExportTask exportTask = {id: taskId, lastStatus: "in-progress", pollingEvents: []};
                isSuccess = addTaskFunction(exportTasks, exportTask);
            }
            string queryString = populateQueryString(_outputFormat, _since, _type);
            // kick-off request to the bulk export server
            lock {
                status = statusClient->get(string `${sourceServerConfig.contextPath}/Group/${group_id}/$export${queryString}`, {
                    Accept: "application/fhir+json",
                    Prefer: "respond-async"
                });
            }
            submitBackgroundJob(taskId, status);

            if isSuccess {
                log:printInfo("Export task persisted.", exportId = taskId);
            } else {
                log:printError("Error occurred while adding the export task to the memory.");
            }

        } on fail var e {
            log:printError("Error occurred while scheduling the status polling task.", e);
        }

        string message = string `Export task is successfully kicked-off. ExportId: ${taskId}
        To check the status, use: <BASE_URL>/trigger/status?exportId=${taskId}`;
        return createOpereationOutcome("information", "processing", message).toJson();

    }

    // Get status of the export task.
    // This function is responsible for getting the status of the export task.
    // The status will be returned as a JSON object.
    //
    // @param exportId - The ID of the export task.
    //
    // @return The status of the export task.
    isolated resource function get status(string exportId) returns json|error {

        return getExportTaskFromMemory(exportId).toJson();

    }

    // Resource function to download a specific file.
    // This function is responsible for downloading a specific file from the bulk export server.
    // The downloaded file will be saved to the configured file path.
    //
    // @param location - The location of the file to be downloaded.
    isolated resource function get download(string location) returns http:STATUS_ACCEPTED|http:STATUS_INTERNAL_SERVER_ERROR {

        error? saveFileResult = saveFileInFS(location, "exportedData.json");
        if saveFileResult is error {
            log:printError("Error occurred while saving the file in the file system.");
            return http:STATUS_INTERNAL_SERVER_ERROR;
        }

        return http:STATUS_ACCEPTED;

    }
}

isolated service /file on new http:Listener(8099) {

    // Resource function to fetch the exported files.
    //
    // @param req - The HTTP request.
    // @param exportId - The ID of the export task.
    // @param resourceType - The type of the resource to be exported.
    //
    // @return The response containing the downloaded file.
    isolated resource function get fetch(http:Request req, string exportId, string resourceType) returns @http:Payload {mediaType: "gzip"} http:Response|error? {

        log:printInfo("Downloading file for member: " + exportId + " and resource type: " + resourceType);
        string filePath = clientServiceConfig.targetDirectory + file:pathSeparator + exportId + file:pathSeparator + resourceType + "-exported.ndjson";

        mime:Entity entity = new;
        entity.setFileAsEntityBody(filePath);

        http:Response response = new;
        response.setEntity(entity);
        error? contentType = response.setContentType("gzip");
        if contentType is error {
            log:printError("Error occurred while setting the content type: ");
        }
        return response;

    }

}

isolated function submitBackgroundJob(string taskId, http:Response|http:ClientError status) {
    if status is http:Response {
        log:printDebug(status.statusCode.toBalString());

        // get the location of the status check
        do {
            string location = check status.getHeader("Content-location");
            task:JobId|() _ = check executeJob(new PollingTask(taskId, location), sourceServerConfig.defaultIntervalInSec);
            log:printDebug("Polling location recieved: " + location);
        } on fail var e {
            log:printError("Error occurred while getting the location or scheduling the Job", e);
            // if location is available, can retry the task
        }
    } else {
        log:printError("Error occurred while sending the kick-off request to the bulk export server.", status);
    }
}
