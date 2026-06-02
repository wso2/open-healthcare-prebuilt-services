package patch

import "testing"

func doc() map[string]any {
	return map[string]any{
		"resourceType": "Patient",
		"id":           "p1",
		"active":       true,
		"gender":       "female",
		"name":         []any{map[string]any{"family": "Smith", "given": []any{"Alice"}}},
	}
}

func TestJSONPatch_Replace(t *testing.T) {
	out, err := ApplyJSONPatch(doc(), []map[string]any{
		{"op": "replace", "path": "/gender", "value": "male"},
	})
	if err != nil {
		t.Fatal(err)
	}
	if out["gender"] != "male" {
		t.Errorf("gender: got %v", out["gender"])
	}
	if doc()["gender"] != "female" {
		t.Error("original must not be mutated")
	}
}

func TestJSONPatch_Add_Map(t *testing.T) {
	out, err := ApplyJSONPatch(doc(), []map[string]any{
		{"op": "add", "path": "/birthDate", "value": "1990-01-01"},
	})
	if err != nil {
		t.Fatal(err)
	}
	if out["birthDate"] != "1990-01-01" {
		t.Errorf("birthDate: got %v", out["birthDate"])
	}
}

func TestJSONPatch_Add_Array_Append(t *testing.T) {
	out, err := ApplyJSONPatch(doc(), []map[string]any{
		{"op": "add", "path": "/name/-", "value": map[string]any{"family": "Jones"}},
	})
	if err != nil {
		t.Fatal(err)
	}
	names, _ := out["name"].([]any)
	if len(names) != 2 {
		t.Fatalf("expected 2 names, got %d", len(names))
	}
}

func TestJSONPatch_Remove(t *testing.T) {
	out, err := ApplyJSONPatch(doc(), []map[string]any{
		{"op": "remove", "path": "/gender"},
	})
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := out["gender"]; ok {
		t.Error("gender should be removed")
	}
}

func TestJSONPatch_Move(t *testing.T) {
	out, err := ApplyJSONPatch(doc(), []map[string]any{
		{"op": "move", "from": "/gender", "path": "/sex"},
	})
	if err != nil {
		t.Fatal(err)
	}
	if out["sex"] != "female" {
		t.Errorf("sex: got %v", out["sex"])
	}
	if _, ok := out["gender"]; ok {
		t.Error("gender should be gone after move")
	}
}

func TestJSONPatch_Test_Pass(t *testing.T) {
	_, err := ApplyJSONPatch(doc(), []map[string]any{
		{"op": "test", "path": "/gender", "value": "female"},
	})
	if err != nil {
		t.Errorf("test should pass: %v", err)
	}
}

func TestJSONPatch_Test_Fail(t *testing.T) {
	_, err := ApplyJSONPatch(doc(), []map[string]any{
		{"op": "test", "path": "/gender", "value": "male"},
	})
	if err == nil {
		t.Error("test should fail when value doesn't match")
	}
}

func TestFHIRPatch_Replace(t *testing.T) {
	params := map[string]any{
		"resourceType": "Parameters",
		"parameter": []any{map[string]any{
			"name": "operation",
			"part": []any{
				map[string]any{"name": "type", "valueCode": "replace"},
				map[string]any{"name": "path", "valueString": "Patient.gender"},
				map[string]any{"name": "value", "valueString": "male"},
			},
		}},
	}
	out, err := ApplyFHIRPatch(doc(), params)
	if err != nil {
		t.Fatal(err)
	}
	if out["gender"] != "male" {
		t.Errorf("gender: got %v", out["gender"])
	}
}

func TestJSONPatch_RemoveOutOfRange(t *testing.T) {
	// Removing at index == len must error (not panic / out-of-range), while
	// adding at index == len appends. Regression for the parseIndex split.
	d := map[string]any{"resourceType": "Patient", "name": []any{map[string]any{"family": "Smith"}}}

	// remove at index 1 of a length-1 array → out of range error.
	if _, err := ApplyJSONPatch(d, []map[string]any{{"op": "remove", "path": "/name/1"}}); err == nil {
		t.Error("remove at index==len should error")
	}
	// get/test at index 1 → error.
	if _, err := ApplyJSONPatch(d, []map[string]any{{"op": "test", "path": "/name/1", "value": "x"}}); err == nil {
		t.Error("test at index==len should error")
	}
	// add at index 1 (==len) → append, succeeds.
	out, err := ApplyJSONPatch(d, []map[string]any{{"op": "add", "path": "/name/1", "value": map[string]any{"family": "Jones"}}})
	if err != nil {
		t.Fatalf("add at index==len should append, got %v", err)
	}
	if names, _ := out["name"].([]any); len(names) != 2 {
		t.Errorf("expected 2 names after append, got %d", len(names))
	}
}

func TestFHIRPatch_Move(t *testing.T) {
	params := map[string]any{
		"resourceType": "Parameters",
		"parameter": []any{map[string]any{
			"name": "operation",
			"part": []any{
				map[string]any{"name": "type", "valueCode": "move"},
				map[string]any{"name": "path", "valueString": "Patient.name"},
				map[string]any{"name": "source", "valueInteger": float64(0)},
				map[string]any{"name": "index", "valueInteger": float64(1)},
			},
		}},
	}
	d := map[string]any{
		"resourceType": "Patient",
		"id":           "p1",
		"name": []any{
			map[string]any{"family": "Smith"},
			map[string]any{"family": "Jones"},
		},
	}
	out, err := ApplyFHIRPatch(d, params)
	if err != nil {
		t.Fatal(err)
	}
	names, _ := out["name"].([]any)
	if len(names) != 2 {
		t.Fatalf("expected 2 names after move, got %d", len(names))
	}
	// After moving index 0 to index 1: [Jones, Smith]
	if n0, _ := names[0].(map[string]any); n0["family"] != "Jones" {
		t.Errorf("after move: names[0] should be Jones, got %v", n0["family"])
	}
}

func TestFHIRPatch_Insert(t *testing.T) {
	params := map[string]any{
		"resourceType": "Parameters",
		"parameter": []any{map[string]any{
			"name": "operation",
			"part": []any{
				map[string]any{"name": "type", "valueCode": "insert"},
				map[string]any{"name": "path", "valueString": "Patient.name"},
				map[string]any{"name": "index", "valueInteger": float64(0)},
				map[string]any{"name": "value", "valueHumanName": map[string]any{"family": "New"}},
			},
		}},
	}
	d := map[string]any{
		"resourceType": "Patient",
		"id":           "p1",
		"name":         []any{map[string]any{"family": "Smith"}},
	}
	out, err := ApplyFHIRPatch(d, params)
	if err != nil {
		t.Fatal(err)
	}
	names, _ := out["name"].([]any)
	if len(names) != 2 {
		t.Fatalf("expected 2 names after insert, got %d", len(names))
	}
	if n0, _ := names[0].(map[string]any); n0["family"] != "New" {
		t.Errorf("after insert at 0: names[0] should be New, got %v", n0["family"])
	}
}

func TestFHIRPatch_Delete(t *testing.T) {
	params := map[string]any{
		"resourceType": "Parameters",
		"parameter": []any{map[string]any{
			"name": "operation",
			"part": []any{
				map[string]any{"name": "type", "valueCode": "delete"},
				map[string]any{"name": "path", "valueString": "Patient.gender"},
			},
		}},
	}
	out, err := ApplyFHIRPatch(doc(), params)
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := out["gender"]; ok {
		t.Error("gender should be deleted")
	}
}
