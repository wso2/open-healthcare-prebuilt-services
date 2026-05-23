package fhirpath_test

import (
	"testing"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/fhirpath"
)

// ─── Evaluate ────────────────────────────────────────────────────────────────

func TestEvaluate_SimplePath(t *testing.T) {
	r := map[string]any{
		"resourceType": "Patient",
		"id":           "p1",
	}
	got, err := fhirpath.Evaluate("Patient.id", r)
	assertNoErr(t, err)
	assertStrings(t, got, "p1")
}

func TestEvaluate_NestedPath(t *testing.T) {
	r := map[string]any{
		"name": []any{
			map[string]any{"family": "Smith", "given": []any{"John"}},
		},
	}
	got, err := fhirpath.Evaluate("Patient.name.family", r)
	assertNoErr(t, err)
	assertStrings(t, got, "Smith")
}

func TestEvaluate_ArrayFlattening(t *testing.T) {
	r := map[string]any{
		"name": []any{
			map[string]any{"family": "Smith"},
			map[string]any{"family": "Jones"},
		},
	}
	got, err := fhirpath.Evaluate("Patient.name.family", r)
	assertNoErr(t, err)
	if len(got) != 2 {
		t.Fatalf("want 2 results, got %d", len(got))
	}
}

func TestEvaluate_GivenArray(t *testing.T) {
	r := map[string]any{
		"name": []any{
			map[string]any{"given": []any{"John", "William"}},
		},
	}
	got, err := fhirpath.Evaluate("Patient.name.given", r)
	assertNoErr(t, err)
	if len(got) != 2 {
		t.Fatalf("want 2 given names, got %d", len(got))
	}
}

func TestEvaluate_Union(t *testing.T) {
	r := map[string]any{
		"name":    []any{map[string]any{"family": "Smith"}},
		"telecom": []any{map[string]any{"value": "555-1234"}},
	}
	got, err := fhirpath.Evaluate("Patient.name.family | Patient.telecom.value", r)
	assertNoErr(t, err)
	if len(got) != 2 {
		t.Fatalf("want 2 results from union, got %d: %v", len(got), got)
	}
}

func TestEvaluate_Where_Match(t *testing.T) {
	r := map[string]any{
		"name": []any{
			map[string]any{"use": "official", "family": "Smith"},
			map[string]any{"use": "nickname", "family": "Smithy"},
		},
	}
	got, err := fhirpath.Evaluate("Patient.name.where(use='official').family", r)
	assertNoErr(t, err)
	assertStrings(t, got, "Smith")
}

func TestEvaluate_Where_NotEqual(t *testing.T) {
	r := map[string]any{
		"name": []any{
			map[string]any{"use": "official", "family": "Smith"},
			map[string]any{"use": "nickname", "family": "Smithy"},
		},
	}
	got, err := fhirpath.Evaluate("Patient.name.where(use!='official').family", r)
	assertNoErr(t, err)
	assertStrings(t, got, "Smithy")
}

func TestEvaluate_Where_NoMatch(t *testing.T) {
	r := map[string]any{
		"name": []any{
			map[string]any{"use": "nickname", "family": "Smithy"},
		},
	}
	got, err := fhirpath.Evaluate("Patient.name.where(use='official').family", r)
	assertNoErr(t, err)
	if len(got) != 0 {
		t.Fatalf("want 0 results, got %d: %v", len(got), got)
	}
}

func TestEvaluate_Extension(t *testing.T) {
	r := map[string]any{
		"extension": []any{
			map[string]any{"url": "http://example.com/race", "valueCode": "2106-3"},
			map[string]any{"url": "http://example.com/other", "valueCode": "x"},
		},
	}
	got, err := fhirpath.Evaluate("Patient.extension('http://example.com/race')", r)
	assertNoErr(t, err)
	if len(got) != 1 {
		t.Fatalf("want 1 extension, got %d", len(got))
	}
}

func TestEvaluate_MissingField_ReturnsEmpty(t *testing.T) {
	r := map[string]any{"id": "p1"}
	got, err := fhirpath.Evaluate("Patient.birthDate", r)
	assertNoErr(t, err)
	if len(got) != 0 {
		t.Fatalf("want empty, got %v", got)
	}
}

func TestEvaluate_NoResourceTypePrefix(t *testing.T) {
	r := map[string]any{"status": "active"}
	got, err := fhirpath.Evaluate("status", r)
	assertNoErr(t, err)
	assertStrings(t, got, "active")
}

func TestEvaluate_EmptyExpression_Error(t *testing.T) {
	r := map[string]any{}
	_, err := fhirpath.Evaluate("", r)
	if err == nil {
		t.Fatal("expected error for empty expression")
	}
}

func TestEvaluate_DeepNested(t *testing.T) {
	r := map[string]any{
		"component": []any{
			map[string]any{
				"code": map[string]any{
					"coding": []any{
						map[string]any{"system": "http://loinc.org", "code": "8480-6"},
					},
				},
			},
		},
	}
	got, err := fhirpath.Evaluate("Observation.component.code.coding.code", r)
	assertNoErr(t, err)
	assertStrings(t, got, "8480-6")
}

func TestEvaluate_Telecom_System(t *testing.T) {
	r := map[string]any{
		"telecom": []any{
			map[string]any{"system": "phone", "value": "555-1234"},
			map[string]any{"system": "email", "value": "a@b.com"},
		},
	}
	got, err := fhirpath.Evaluate("Patient.telecom.where(system='phone').value", r)
	assertNoErr(t, err)
	assertStrings(t, got, "555-1234")
}

func TestEvaluate_Identifier_Value(t *testing.T) {
	r := map[string]any{
		"identifier": []any{
			map[string]any{"system": "http://example.org/mrn", "value": "MRN-001"},
		},
	}
	got, err := fhirpath.Evaluate("Patient.identifier.value", r)
	assertNoErr(t, err)
	assertStrings(t, got, "MRN-001")
}

// ─── EvaluatePolymorphic ──────────────────────────────────────────────────────

func TestEvaluatePolymorphic_ValueQuantity(t *testing.T) {
	r := map[string]any{
		"valueQuantity": map[string]any{
			"value":  98.6,
			"unit":   "degF",
			"system": "http://unitsofmeasure.org",
		},
	}
	got, err := fhirpath.EvaluatePolymorphic("Observation.value.ofType(Quantity)", r)
	assertNoErr(t, err)
	if len(got) == 0 {
		t.Fatal("expected valueQuantity match")
	}
}

func TestEvaluatePolymorphic_ValueCodeableConcept(t *testing.T) {
	r := map[string]any{
		"valueCodeableConcept": map[string]any{
			"coding": []any{
				map[string]any{"system": "http://snomed.info/sct", "code": "404684003"},
			},
		},
	}
	got, err := fhirpath.EvaluatePolymorphic("Observation.value.ofType(CodeableConcept).coding.code", r)
	assertNoErr(t, err)
	assertStrings(t, got, "404684003")
}

func TestEvaluatePolymorphic_NoOfType_PassThrough(t *testing.T) {
	r := map[string]any{"status": "final"}
	got, err := fhirpath.EvaluatePolymorphic("Observation.status", r)
	assertNoErr(t, err)
	assertStrings(t, got, "final")
}

func TestEvaluatePolymorphic_MultipleOfType(t *testing.T) {
	// onset.ofType(dateTime) in Condition → onsetDateTime
	r := map[string]any{
		"onsetDateTime": "2023-01-15",
	}
	got, err := fhirpath.EvaluatePolymorphic("Condition.onset.ofType(dateTime)", r)
	assertNoErr(t, err)
	assertStrings(t, got, "2023-01-15")
}

func TestEvaluatePolymorphic_EffectivePeriod(t *testing.T) {
	r := map[string]any{
		"effectivePeriod": map[string]any{
			"start": "2023-01-01",
			"end":   "2023-12-31",
		},
	}
	got, err := fhirpath.EvaluatePolymorphic("Observation.effective.ofType(Period).start", r)
	assertNoErr(t, err)
	assertStrings(t, got, "2023-01-01")
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

func assertNoErr(t *testing.T, err error) {
	t.Helper()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func assertStrings(t *testing.T, got []any, want ...string) {
	t.Helper()
	if len(got) != len(want) {
		t.Fatalf("len mismatch: got %d (%v), want %d (%v)", len(got), got, len(want), want)
	}
	for i, w := range want {
		s, ok := got[i].(string)
		if !ok {
			t.Fatalf("[%d] expected string, got %T: %v", i, got[i], got[i])
		}
		if s != w {
			t.Fatalf("[%d] got %q, want %q", i, s, w)
		}
	}
}
