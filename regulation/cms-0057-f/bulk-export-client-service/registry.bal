import ballerina/time;

# Use to keep track of each polling event.
#
# + id - Id of the associated export task  
# + eventStatus - whether the polling event is success or failed  
# + exportStatus - status recieved from the export server  
# + progress - progress of the export task
public type PollingEvent record {|

    string id;
    string eventStatus;
    string exportStatus?;
    string progress?;

|};

# Use to keep track of ongoing/completed exports.
#
# + id - task ID (generated internally)  
# + lastUpdated - timestamp of the last polling event  
# + lastStatus - export status recieved from the last polling event  
# + pollingEvents - array of polling events
public type ExportTask record {|

    string id;
    time:Utc lastUpdated?;
    string lastStatus;
    PollingEvent[] pollingEvents;

|};

type getExportTask function (string exportId) returns ExportTask;

type getPollingEvents function (string exportId) returns [PollingEvent];

type addExportTask isolated function (map<ExportTask> taskMap, ExportTask exportTask) returns boolean;

type addPollingEvent isolated function (map<ExportTask> taskMap, PollingEvent pollingEvent) returns boolean;

