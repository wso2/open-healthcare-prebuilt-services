import ballerina/http;
import ballerina/test;
import ballerinax/health.fhir.r4.international401;

http:Client testClient = check new ("http://localhost:9093");

// Test functions
@test:Config {}
function testSendingAuditEvent1() {
    InternalAuditEvent auditEvent = {"typeCode": "rest", "subTypeCode": "READ", "actionCode": "R", "outcomeCode": "0", "recordedTime": "2023-10-23T17:36:35.395477Z", "agentType": "", "agentName": "Unknown", "agentIsRequestor": true, "sourceObserverName": "", "sourceObserverType": "3", "entityType": "2", "entityRole": "1", "entityWhatReference": ""};
    international401:AuditEvent|error response = testClient->/audits.post(auditEvent);
    test:assertEquals(response is international401:AuditEvent, true);
}
