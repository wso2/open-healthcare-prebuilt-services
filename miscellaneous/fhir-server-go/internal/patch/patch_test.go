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
