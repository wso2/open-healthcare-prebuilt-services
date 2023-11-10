// Holds the information needed to form an audit event based on the FHIR AuditEvent resource
// http://hl7.org/fhir/R4/auditevent.html
type InternalAuditEvent record {|
    // Value Set http://hl7.org/fhir/ValueSet/audit-event-type
    string typeCode = "rest";
    // Value Set http://hl7.org/fhir/ValueSet/audit-event-sub-type 
    string subTypeCode;
    // Value Set http://hl7.org/fhir/ValueSet/audit-event-action
    string actionCode;
    // Value Set http://hl7.org/fhir/ValueSet/audit-event-outcome 
    string outcomeCode;
    string recordedTime;
    // actor involved in the event
    // Value Set http://hl7.org/fhir/ValueSet/participation-role-type
    string agentType;
    string agentName;
    boolean agentIsRequestor;
    // source of the event
    string sourceObserverName;
    // Value Set http://hl7.org/fhir/R4/valueset-audit-source-type.html
    string sourceObserverType;
    // Value Set http://hl7.org/fhir/ValueSet/audit-entity-type
    string entityType;
    // Value Set http://hl7.org/fhir/ValueSet/object-role
    string entityRole;
    // Requested relative path - eg.: "Patient/example/_history/1"
    string entityWhatReference;

|};
