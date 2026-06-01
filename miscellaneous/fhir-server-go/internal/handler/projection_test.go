package handler

import "testing"

func sampleResource() map[string]any {
	return map[string]any{
		"resourceType": "Patient",
		"id":           "p1",
		"meta":         map[string]any{"versionId": "1"},
		"text":         map[string]any{"status": "generated", "div": "<div/>"},
		"contained":    []any{map[string]any{"resourceType": "Observation"}},
		"name":         []any{map[string]any{"family": "Smith"}},
		"gender":       "female",
	}
}

func hasSubsettedTag(res map[string]any) bool {
	meta, _ := res["meta"].(map[string]any)
	tags, _ := meta["tag"].([]any)
	for _, t := range tags {
		if tm, ok := t.(map[string]any); ok && tm["code"] == "SUBSETTED" {
			return true
		}
	}
	return false
}

func TestApplyProjection_Elements(t *testing.T) {
	out := applyProjection(sampleResource(), "", []string{"name"})
	for _, k := range []string{"resourceType", "id", "meta", "name"} {
		if _, ok := out[k]; !ok {
			t.Errorf("expected element %q to be kept", k)
		}
	}
	if _, ok := out["gender"]; ok {
		t.Error("gender should be projected out")
	}
	if !hasSubsettedTag(out) {
		t.Error("projected resource must carry SUBSETTED tag")
	}
}

func TestApplyProjection_SummaryText(t *testing.T) {
	out := applyProjection(sampleResource(), "text", nil)
	for _, k := range []string{"resourceType", "id", "meta", "text"} {
		if _, ok := out[k]; !ok {
			t.Errorf("_summary=text must keep %q", k)
		}
	}
	if _, ok := out["name"]; ok {
		t.Error("_summary=text must drop non-narrative elements like name")
	}
}

func TestApplyProjection_SummaryData(t *testing.T) {
	out := applyProjection(sampleResource(), "data", nil)
	if _, ok := out["text"]; ok {
		t.Error("_summary=data must drop the narrative text")
	}
	if _, ok := out["name"]; !ok {
		t.Error("_summary=data must keep data elements like name")
	}
}

func TestApplyProjection_SummaryTrue_DropsTextAndContained(t *testing.T) {
	out := applyProjection(sampleResource(), "true", nil)
	if _, ok := out["text"]; ok {
		t.Error("_summary=true must drop text")
	}
	if _, ok := out["contained"]; ok {
		t.Error("_summary=true must drop contained")
	}
	if !hasSubsettedTag(out) {
		t.Error("_summary=true must carry SUBSETTED tag")
	}
}

func TestApplyProjection_FalseIsUntouched(t *testing.T) {
	in := sampleResource()
	out := applyProjection(in, "false", nil)
	if hasSubsettedTag(out) {
		t.Error("_summary=false must not tag SUBSETTED")
	}
	if _, ok := out["text"]; !ok {
		t.Error("_summary=false must keep everything")
	}
}

func TestProjectionFromParams(t *testing.T) {
	s, e := projectionFromParams(map[string][]string{
		"_summary":  {"data"},
		"_elements": {"name, gender ,"},
	})
	if s != "data" {
		t.Errorf("summary: got %q", s)
	}
	if len(e) != 2 || e[0] != "name" || e[1] != "gender" {
		t.Errorf("elements: got %v, want [name gender]", e)
	}
}
