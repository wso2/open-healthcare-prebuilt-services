import ballerina/test;
import ballerina/time;

@test:Config {
    enable: true
}
function testAddExportTaskToMemory() {
    map<ExportTask> testMap = {};
    ExportTask testTask = {
        id: "test-id",
        lastUpdated: time:utcNow(),
        lastStatus: "Pending",
        pollingEvents: []
    };

    boolean result = addExportTasktoMemory(testMap, testTask);
    test:assertTrue(result);
    test:assertTrue(testMap.hasKey("test-id"));
    test:assertEquals(testMap.get("test-id").id, "test-id");
    test:assertFalse(testMap.get("test-id").lastUpdated < testTask.lastUpdated);
}

@test:Config {
    enable: true
}
function testAddPollingEventToMemory() {
    ExportTask testTask = {
        id: "test-id",
        lastUpdated: time:utcNow(),
        lastStatus: "Pending",
        pollingEvents: []
    };
    map<ExportTask> testMap = {"test-id": testTask};

    PollingEvent testEvent = {
        id: "test-id",
        exportStatus: "In-progress"
    ,
        eventStatus: ""
    };

    boolean result = addPollingEventToMemory(testMap, testEvent);
    test:assertTrue(result);
    test:assertEquals(testMap.get("test-id").lastStatus, "In-progress");
    test:assertEquals(testMap.get("test-id").pollingEvents.length(), 1);
    test:assertEquals(testMap.get("test-id").pollingEvents[0], testEvent);
    test:assertFalse(testMap.get("test-id").lastUpdated < testTask.lastUpdated);
}

@test:Config {
    enable: true
}
function testUpdateExportTaskStatusInMemory() {
    ExportTask testTask = {
        id: "test-id",
        lastUpdated: time:utcNow(),
        lastStatus: "Pending",
        pollingEvents: []
    };
    map<ExportTask> testMap = {"test-id": testTask};

    boolean result = updateExportTaskStatusInMemory(testMap, "test-id", "Completed");
    test:assertTrue(result);
    test:assertEquals(testMap.get("test-id").lastStatus, "Completed");
    test:assertFalse(testMap.get("test-id").lastUpdated < testTask.lastUpdated);
}
