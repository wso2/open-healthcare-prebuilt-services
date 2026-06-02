package patch

import "testing"

func TestXMLPatch_Replace(t *testing.T) {
	doc := map[string]any{"resourceType": "Patient", "id": "p1", "gender": "female"}
	diff := `<diff xmlns="http://hl7.org/fhir">
	  <replace sel="/f:Patient/f:gender/@value">male</replace>
	</diff>`
	out, err := ApplyXMLPatch(doc, []byte(diff))
	if err != nil {
		t.Fatal(err)
	}
	if out["gender"] != "male" {
		t.Errorf("gender: got %v, want male", out["gender"])
	}
}

func TestXMLPatch_Remove(t *testing.T) {
	doc := map[string]any{"resourceType": "Patient", "id": "p1", "gender": "female", "active": true}
	diff := `<diff><remove sel="/f:Patient/f:active"/></diff>`
	out, err := ApplyXMLPatch(doc, []byte(diff))
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := out["active"]; ok {
		t.Error("active should be removed")
	}
	if out["gender"] != "female" {
		t.Error("gender should survive")
	}
}

func TestXMLPatch_AddElement(t *testing.T) {
	doc := map[string]any{"resourceType": "Patient", "id": "p1"}
	diff := `<diff><add sel="/f:Patient" type="element"><birthDate value="1990-01-01"/></add></diff>`
	out, err := ApplyXMLPatch(doc, []byte(diff))
	if err != nil {
		t.Fatal(err)
	}
	if out["birthDate"] != "1990-01-01" {
		t.Errorf("birthDate: got %v, want 1990-01-01", out["birthDate"])
	}
}

func TestXMLPatch_IndexedPath(t *testing.T) {
	doc := map[string]any{
		"resourceType": "Patient", "id": "p1",
		"name": []any{
			map[string]any{"family": "Smith"},
			map[string]any{"family": "Jones"},
		},
	}
	// Replace the family of the SECOND name (1-based index 2).
	diff := `<diff><replace sel="/f:Patient/f:name[2]/f:family/@value">Brown</replace></diff>`
	out, err := ApplyXMLPatch(doc, []byte(diff))
	if err != nil {
		t.Fatal(err)
	}
	names, _ := out["name"].([]any)
	n1, _ := names[1].(map[string]any)
	if n1["family"] != "Brown" {
		t.Errorf("name[1].family: got %v, want Brown", n1["family"])
	}
	n0, _ := names[0].(map[string]any)
	if n0["family"] != "Smith" {
		t.Error("name[0] should be unchanged")
	}
}

func TestXPathToPointer(t *testing.T) {
	cases := map[string]string{
		"/f:Patient/f:gender/@value":             "/gender",
		"/f:Patient/f:active":                    "/active",
		"/f:Patient/f:name[1]/f:family/@value":   "/name/0/family",
		"/f:Observation/f:code/f:coding[2]/f:code/@value": "/code/coding/1/code",
	}
	for sel, want := range cases {
		got, err := xpathToPointer(sel)
		if err != nil {
			t.Errorf("%s: %v", sel, err)
			continue
		}
		if got != want {
			t.Errorf("%s: got %q, want %q", sel, got, want)
		}
	}
}
