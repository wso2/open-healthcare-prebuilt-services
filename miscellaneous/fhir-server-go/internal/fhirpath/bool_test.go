package fhirpath

import "testing"

func TestEvaluateBool_Exists(t *testing.T) {
	r := map[string]any{"resourceType": "Patient", "id": "p1", "active": true}
	cases := []struct {
		expr string
		want bool
	}{
		{"active.exists()", true},
		{"gender.exists()", false},
		{"active.empty()", false},
		{"gender.empty()", true},
	}
	for _, tc := range cases {
		got, err := EvaluateBool(tc.expr, r)
		if err != nil {
			t.Errorf("%s: %v", tc.expr, err)
			continue
		}
		if got != tc.want {
			t.Errorf("%s: got %v, want %v", tc.expr, got, tc.want)
		}
	}
}

func TestEvaluateBool_Implies(t *testing.T) {
	r := map[string]any{"resourceType": "Patient", "id": "p1", "name": []any{map[string]any{"family": "Smith"}}}
	// name.exists() implies name.exists() — true
	ok, err := EvaluateBool("name.exists() implies name.exists()", r)
	if err != nil || !ok {
		t.Errorf("true implies true: got %v %v", ok, err)
	}
	// gender.exists() implies name.exists() — vacuously true (left is false)
	ok, err = EvaluateBool("gender.exists() implies name.exists()", r)
	if err != nil || !ok {
		t.Errorf("false implies true: got %v %v", ok, err)
	}
	// name.exists() implies gender.exists() — false (right is false)
	ok, err = EvaluateBool("name.exists() implies gender.exists()", r)
	if err != nil || ok {
		t.Errorf("true implies false: got %v %v", ok, err)
	}
}

func TestEvaluateBool_AndOr(t *testing.T) {
	r := map[string]any{"resourceType": "Patient", "id": "p1", "active": true, "name": []any{map[string]any{"family": "S"}}}
	ok, _ := EvaluateBool("active.exists() and name.exists()", r)
	if !ok {
		t.Error("true and true should be true")
	}
	ok, _ = EvaluateBool("gender.exists() or name.exists()", r)
	if !ok {
		t.Error("false or true should be true")
	}
	ok, _ = EvaluateBool("gender.exists() or birthDate.exists()", r)
	if ok {
		t.Error("false or false should be false")
	}
}

func TestEvaluateBool_Comparison(t *testing.T) {
	r := map[string]any{"resourceType": "Patient", "id": "p1"}
	// count() comparisons
	ok, _ := EvaluateBool("id.count() = 1", r)
	if !ok {
		t.Error("id.count()=1 should be true")
	}
	ok, _ = EvaluateBool("gender.count() > 0", r)
	if ok {
		t.Error("gender.count()>0 should be false (gender absent)")
	}
}

func TestEvaluateBool_Matches(t *testing.T) {
	r := map[string]any{"resourceType": "Patient", "id": "P12345"}
	ok, _ := EvaluateBool("id.matches('[A-Z][0-9]+')", r)
	if !ok {
		t.Error("id matching pattern should be true")
	}
}
