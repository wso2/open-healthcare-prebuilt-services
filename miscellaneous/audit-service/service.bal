import ballerina/http;
import thishani/health.fhir.r4.international401;
import nirmalfernando/health.fhir.r4.terminology;
import thishani/health.fhir.r4;
import ballerina/io;

service / on new http:Listener(9090) {
    resource function post audits(@http:Payload InternalAuditEvent audit) returns InternalAuditEvent {
        international401:AuditEvent auditEvent = toFhirAuditEvent(audit);
        // todo: handle log rotation
        io:println(auditEvent.toJson());
        io:Error? result = io:fileWriteJson(string `./audit-logs/fhir-audit.log`, auditEvent.toJson());
        if (result is io:Error) {
            // todo: keep track of failed audit events in an inmemory buffer and retry to write
            io:println("Error writing to audit log file.");
        }
        return audit;
    }
}

function toFhirAuditEvent(InternalAuditEvent internalAuditEvent) returns international401:AuditEvent => {
    'type: getCoding("http://hl7.org/fhir/resource-types", internalAuditEvent.typeCode),
    subtype: [getCoding("http://hl7.org/fhir/restful-interaction", internalAuditEvent.subTypeCode)],
    action: internalAuditEvent.actionCode,
    outcome: internalAuditEvent.outcomeCode,
    recorded: internalAuditEvent.recordedTime,
    agent: [getAgent(internalAuditEvent.agentType, internalAuditEvent.agentName, internalAuditEvent.agentIsRequestor)],
    entity: [getEntity(internalAuditEvent.entityType, internalAuditEvent.entityRole, internalAuditEvent.entityWhatReference)],
    'source: {
        observer: {
            display: internalAuditEvent.sourceObserverName
        },
        'type: [getCoding("http://hl7.org/fhir/relationship", internalAuditEvent.sourceObserverType)]
    }
};

function getCoding(string system, string code) returns r4:Coding {
    r4:Coding|r4:FHIRError fhirCode = terminology:createCoding(system, code);
    if (fhirCode is r4:FHIRError) {
        return {
            system: system,
            code: code,
            display: "Unknown"
        };
    }
    return fhirCode;
};

function getAgent(string 'type, string name, boolean isRequestor) returns international401:AuditEventAgent {
    international401:AuditEventAgent agent = {
        'type: {
            coding:
            [getCoding("http://hl7.org/fhir/ValueSet/audit-event-participant-role", 'type)]
        },
        who: {
            display: name
        },
        requestor: isRequestor
    };
    return agent;
};

function getEntity(string 'type, string role, string whatReference) returns international401:AuditEventEntity {
    international401:AuditEventEntity entity = {
        'type: getCoding("http://terminology.hl7.org/CodeSystem/audit-entity-type", 'type),
        role: getCoding("http://terminology.hl7.org/CodeSystem/object-role", role),
        what: {
            reference: whatReference
        }
    };
    return entity;
};
