import ballerina/http;
import ballerina/log;
import ballerina/task;
import ballerina/uuid;
import ballerinax/health.fhir.r4.international401;

configurable BulkExportServerConfig exportSeverConfig = ?;
configurable BulkExportClientConfig clientServiceConfig = ?;
configurable FtpServerConfig ftpServerConfig = ?;

http:OAuth2ClientCredentialsGrantConfig config = {
    tokenUrl: exportSeverConfig.tokenUrl,
    clientId: exportSeverConfig.clientId,
    clientSecret: exportSeverConfig.clientSecret,
    scopes: exportSeverConfig.scopes
};

isolated http:Client statusClient = check new (exportSeverConfig.baseUrl);

service /trigger on new http:Listener(clientServiceConfig.port) {

    function init() returns error? {

        if clientServiceConfig.authEnabled {
            lock {
                statusClient = check new (exportSeverConfig.baseUrl, auth = config.clone());
            }
        } else {
            lock {
                statusClient = check new (exportSeverConfig.baseUrl);
            }
        }

        log:printInfo("Bulk export client Service is started...", port = clientServiceConfig.port);
    }
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
                status = statusClient->get(string `${exportSeverConfig.contextPath}/Patient/$export${queryString}`, {
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
                status = statusClient->post(string `${exportSeverConfig.contextPath}/Patient/$export`, parametersResource.clone().toJson(),
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
                status = statusClient->get(string `${exportSeverConfig.contextPath}/Group/${group_id}/$export${queryString}`, {
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

    isolated resource function get status(string exportId) returns json|error {

        return getExportTaskFromMemory(exportId).toJson();

    }

    isolated resource function get download(string location) returns http:STATUS_ACCEPTED|http:STATUS_INTERNAL_SERVER_ERROR {

        error? saveFileResult = saveFileInFS(location, "exportedData.json");
        if saveFileResult is error {

        }

        return http:STATUS_ACCEPTED;

    }
}

isolated function submitBackgroundJob(string taskId, http:Response|http:ClientError status) {
    if status is http:Response {
        log:printDebug(status.statusCode.toBalString());

        // get the location of the status check
        do {
            string location = check status.getHeader("Content-location");
            task:JobId|() _ = check executeJob(new PollingTask(taskId, location), exportSeverConfig.defaultIntervalInSec);
            log:printDebug("Polling location recieved: " + location);
        } on fail var e {
            log:printError("Error occurred while getting the location or scheduling the Job", e);
            // if location is available, can retry the task
        }
    }
}
