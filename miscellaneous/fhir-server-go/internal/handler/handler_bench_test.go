package handler_test

import (
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/handler"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/searchparam"
)

// BenchmarkMetadata_FullR4 measures the end-to-end /metadata response time
// against a registry pre-loaded with the full R4 base spec (~133 types).
// Used to confirm the dynamic resource-list derivation doesn't regress the
// CapabilityStatement endpoint vs the previous hardcoded 14-type slice.
func BenchmarkMetadata_FullR4(b *testing.B) {
	reg := searchparam.NewRegistry()
	for _, rt := range r4ResourceTypes {
		reg.Upsert(searchparam.Definition{
			ResourceType: rt,
			ParamName:    "code",
			ParamType:    "token",
			FHIRPath:     rt + ".code",
		})
	}

	var ready atomic.Int32
	ready.Store(1)
	h := handler.NewRouter(&mockStore{}, nil, reg, "http://localhost/fhir/r4", &ready)

	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		req := httptest.NewRequest(http.MethodGet, "/fhir/r4/metadata", nil)
		w := httptest.NewRecorder()
		h.ServeHTTP(w, req)
		if w.Code != http.StatusOK {
			b.Fatalf("unexpected status %d", w.Code)
		}
	}
}

// BenchmarkMetadata_NilRegistry establishes the floor cost: same handler with
// an empty resource list (registry == nil), so the delta vs FullR4 isolates
// the per-resource JSON-build cost rather than handler overhead.
func BenchmarkMetadata_NilRegistry(b *testing.B) {
	var ready atomic.Int32
	ready.Store(1)
	h := handler.NewRouter(&mockStore{}, nil, nil, "http://localhost/fhir/r4", &ready)

	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		req := httptest.NewRequest(http.MethodGet, "/fhir/r4/metadata", nil)
		w := httptest.NewRecorder()
		h.ServeHTTP(w, req)
		if w.Code != http.StatusOK {
			b.Fatalf("unexpected status %d", w.Code)
		}
	}
}

var r4ResourceTypes = []string{
	"Account", "ActivityDefinition", "AdverseEvent", "AllergyIntolerance", "Appointment",
	"AppointmentResponse", "AuditEvent", "Basic", "BodyStructure", "Bundle",
	"CapabilityStatement", "CarePlan", "CareTeam", "ChargeItem", "ChargeItemDefinition",
	"Claim", "ClaimResponse", "ClinicalImpression", "CodeSystem", "Communication",
	"CommunicationRequest", "CompartmentDefinition", "Composition", "ConceptMap", "Condition",
	"Consent", "Contract", "Coverage", "CoverageEligibilityRequest", "CoverageEligibilityResponse",
	"DetectedIssue", "Device", "DeviceDefinition", "DeviceMetric", "DeviceRequest",
	"DeviceUseStatement", "DiagnosticReport", "DocumentManifest", "DocumentReference", "Encounter",
	"Endpoint", "EnrollmentRequest", "EnrollmentResponse", "EpisodeOfCare", "EventDefinition",
	"Evidence", "EvidenceVariable", "ExampleScenario", "ExplanationOfBenefit", "FamilyMemberHistory",
	"Flag", "Goal", "GraphDefinition", "Group", "GuidanceResponse", "HealthcareService",
	"ImagingStudy", "Immunization", "ImmunizationEvaluation", "ImmunizationRecommendation",
	"ImplementationGuide", "InsurancePlan", "Invoice", "Library", "Linkage", "List", "Location",
	"Measure", "MeasureReport", "Media", "Medication", "MedicationAdministration",
	"MedicationDispense", "MedicationKnowledge", "MedicationRequest", "MedicationStatement",
	"MessageDefinition", "MessageHeader", "MolecularSequence", "NamingSystem", "NutritionOrder",
	"Observation", "OperationDefinition", "Organization", "OrganizationAffiliation", "Patient",
	"PaymentNotice", "PaymentReconciliation", "Person", "PlanDefinition", "Practitioner",
	"PractitionerRole", "Procedure", "Provenance", "Questionnaire", "QuestionnaireResponse",
	"RelatedPerson", "RequestGroup", "ResearchDefinition", "ResearchElementDefinition",
	"ResearchStudy", "ResearchSubject", "RiskAssessment", "Schedule", "SearchParameter",
	"ServiceRequest", "Slot", "Specimen", "SpecimenDefinition", "StructureDefinition",
	"StructureMap", "Subscription", "Substance", "SubstanceSpecification", "SupplyDelivery",
	"SupplyRequest", "Task", "TerminologyCapabilities", "TestReport", "TestScript", "ValueSet",
	"VerificationResult", "VisionPrescription",
}
