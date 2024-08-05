import ballerina/http;
import ballerina/log;
import ballerina/task;
import ballerina/uuid;

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

    isolated resource function get export(string params) returns json|error {

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
            // kick-off request to the bulk export server
            lock {
                status = statusClient->get(string `${exportSeverConfig.contextPath}/$export`, {
                    Accept: "application/fhir+json",
                    Prefer: "respond-async"
                });
            }
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
