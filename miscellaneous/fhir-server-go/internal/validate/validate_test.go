package validate

import "testing"

func minSD(resourceType string, elements []map[string]any) map[string]any {
	rawEls := make([]any, len(elements))
	for i, e := range elements {
		rawEls[i] = e
	}
	return map[string]any{
		"resourceType": "StructureDefinition",
		"type":         resourceType,
		"snapshot":     map[string]any{"element": rawEls},
	}
}

func hasError(issues []Issue, code string) bool {
	for _, i := range issues {
		if i.Severity == "error" && i.Code == code {
			return true
		}
	}
	return false
}

func TestValidate_RequiredPresent(t *testing.T) {
	sd := minSD("Patient", []map[string]any{
		{"path": "Patient", "min": float64(1), "max": "*"},
		{"path": "Patient.name", "min": float64(1), "max": "*"},
	})
	resource := map[string]any{"resourceType": "Patient", "name": []any{map[string]any{"family": "Smith"}}}
	if issues := AgainstProfile(resource, sd); len(issues) != 0 {
		t.Errorf("expected no issues, got %v", issues)
	}
}

func TestValidate_RequiredMissing(t *testing.T) {
	sd := minSD("Patient", []map[string]any{
		{"path": "Patient.name", "min": float64(1), "max": "*"},
	})
	resource := map[string]any{"resourceType": "Patient"}
	issues := AgainstProfile(resource, sd)
	if !hasError(issues, "required") {
		t.Errorf("expected required error, got %v", issues)
	}
}

func TestValidate_Forbidden(t *testing.T) {
	sd := minSD("Patient", []map[string]any{
		{"path": "Patient.multipleBirthBoolean", "min": float64(0), "max": "0"},
	})
	resource := map[string]any{"resourceType": "Patient", "multipleBirthBoolean": true}
	issues := AgainstProfile(resource, sd)
	if !hasError(issues, "structure") {
		t.Errorf("expected structure error for max=0, got %v", issues)
	}
}

func TestValidate_FixedValue(t *testing.T) {
	sd := minSD("Observation", []map[string]any{
		{"path": "Observation.status", "min": float64(1), "max": "1", "fixedCode": "final"},
	})
	valid := map[string]any{"resourceType": "Observation", "status": "final"}
	if issues := AgainstProfile(valid, sd); len(issues) != 0 {
		t.Errorf("expected no issues for correct fixed value, got %v", issues)
	}
	invalid := map[string]any{"resourceType": "Observation", "status": "preliminary"}
	if issues := AgainstProfile(invalid, sd); !hasError(issues, "value") {
		t.Errorf("expected value error for wrong fixed value, got %v", issues)
	}
}

func TestValidate_PatternValue(t *testing.T) {
	sd := minSD("Observation", []map[string]any{
		{"path": "Observation.category", "min": float64(0), "max": "*",
			"patternCodeableConcept": map[string]any{
				"coding": []any{map[string]any{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}},
			},
		},
	})
	valid := map[string]any{
		"resourceType": "Observation",
		"category": []any{map[string]any{
			"coding": []any{map[string]any{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}},
		}},
	}
	if issues := AgainstProfile(valid, sd); len(issues) != 0 {
		t.Errorf("expected no issues for matching pattern, got %v", issues)
	}
	invalid := map[string]any{
		"resourceType": "Observation",
		"category":     []any{map[string]any{"coding": []any{map[string]any{"code": "wrong"}}}},
	}
	if issues := AgainstProfile(invalid, sd); !hasError(issues, "value") {
		t.Errorf("expected value error for non-matching pattern, got %v", issues)
	}
}

func TestValidate_NoSnapshot(t *testing.T) {
	sd := map[string]any{"resourceType": "StructureDefinition", "type": "Patient"}
	if issues := AgainstProfile(map[string]any{"resourceType": "Patient"}, sd); len(issues) != 0 {
		t.Errorf("SD with no snapshot should pass (no constraints to check), got %v", issues)
	}
}
