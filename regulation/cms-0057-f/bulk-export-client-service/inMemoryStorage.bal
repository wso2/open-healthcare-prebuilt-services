import ballerina/time;

//This file represents the in-memory storage of the export tasks and polling events.

final isolated map<ExportTask> exportTasks = {};

isolated function addExportTasktoMemory(map<ExportTask> taskMap, ExportTask exportTask) returns boolean {
    // add the export task to the memory
    exportTask.lastUpdated = time:utcNow();
    lock {
        taskMap[exportTask.id] = exportTask;
    }
    return true;
}

isolated function addPollingEventToMemory(map<ExportTask> taskMap, PollingEvent pollingEvent) returns boolean {
    // add the polling event to the memory
    ExportTask exportTask = taskMap.get(pollingEvent.id);
    exportTask.lastUpdated = time:utcNow();
    exportTask.lastStatus = pollingEvent.exportStatus ?: "In-progress";
    lock {
        taskMap.get(pollingEvent.id).pollingEvents.push(pollingEvent);
    }
    return true;
}

isolated function updateExportTaskStatusInMemory(map<ExportTask> taskMap, string exportTaskId, string newStatus) returns boolean {

    ExportTask exportTask = taskMap.get(exportTaskId);
    exportTask.lastUpdated = time:utcNow();
    exportTask.lastStatus = newStatus;
    return true;
}

isolated function getExportTaskFromMemory(string exportId) returns ExportTask {
    // get the export task from the memory
    ExportTask exportTask;
    lock {
        exportTask = exportTasks.get(exportId).clone();
    }
    return exportTask;
}
