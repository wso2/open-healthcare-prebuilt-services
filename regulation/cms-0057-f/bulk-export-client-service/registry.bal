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

# Function types to interact with the storage impl.

type getExportTask function (string exportId) returns ExportTask;

type getPollingEvents function (string exportId) returns [PollingEvent];

type addExportTask isolated function (map<ExportTask> taskMap, ExportTask exportTask) returns boolean;

type addPollingEvent isolated function (map<ExportTask> taskMap, PollingEvent pollingEvent) returns boolean;

type updateExportTaskStatus function (map<ExportTask> taskMap, string exportTaskId, string newStatus) returns boolean;

