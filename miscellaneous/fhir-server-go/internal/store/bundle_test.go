package store

import (
	"reflect"
	"testing"
)

func TestParseEntryURL(t *testing.T) {
	const base = "http://test-server/fhir/r4"
	cases := []struct {
		name    string
		raw     string
		wantRT  string
		wantID  string
		wantVer string
		wantErr bool
	}{
		{"type only", "Patient", "Patient", "", "", false},
		{"type and id", "Patient/123", "Patient", "123", "", false},
		{"search query", "Patient?name=smith", "Patient", "", "", false},
		{"vread", "Patient/123/_history/2", "Patient", "123", "2", false},
		{"absolute under base", base + "/Observation/abc", "Observation", "abc", "", false},
		// An absolute URL pointing at a different server is rejected; we used to
		// silently strip scheme+host, but that risked operating on the wrong
		// resource if a bundle entry pointed at another server.
		{"absolute other host", "http://other/Patient/9", "", "", "", true},
		{"leading slash", "/Patient/5", "Patient", "5", "", false},
		{"empty", "", "", "", "", true},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			rt, id, ver, _, errMsg := parseEntryURL(base, c.raw)
			if c.wantErr {
				if errMsg == "" {
					t.Fatalf("expected error for %q", c.raw)
				}
				return
			}
			if errMsg != "" {
				t.Fatalf("unexpected error for %q: %s", c.raw, errMsg)
			}
			if rt != c.wantRT || id != c.wantID || ver != c.wantVer {
				t.Errorf("parseEntryURL(%q) = (%q,%q,%q), want (%q,%q,%q)",
					c.raw, rt, id, ver, c.wantRT, c.wantID, c.wantVer)
			}
		})
	}
}

func TestParseEntryURL_Query(t *testing.T) {
	_, _, _, q, errMsg := parseEntryURL("", "Patient?name=smith&gender=male")
	if errMsg != "" {
		t.Fatalf("unexpected error: %s", errMsg)
	}
	if q.Get("name") != "smith" || q.Get("gender") != "male" {
		t.Errorf("query not parsed: %v", q)
	}
}

func TestRewriteReferences(t *testing.T) {
	refMap := map[string]string{
		"urn:uuid:patient-1": "Patient/p1",
		"urn:uuid:org-1":     "Organization/o1",
	}
	resource := map[string]any{
		"resourceType": "Observation",
		"subject":      map[string]any{"reference": "urn:uuid:patient-1"},
		"performer": []any{
			map[string]any{"reference": "urn:uuid:org-1"},
			map[string]any{"reference": "Practitioner/keep-me"},
		},
		"note": map[string]any{
			"author": map[string]any{"reference": "urn:uuid:patient-1"},
		},
	}

	rewriteReferences(resource, refMap)

	if got := resource["subject"].(map[string]any)["reference"]; got != "Patient/p1" {
		t.Errorf("subject.reference = %v, want Patient/p1", got)
	}
	perf := resource["performer"].([]any)
	if got := perf[0].(map[string]any)["reference"]; got != "Organization/o1" {
		t.Errorf("performer[0].reference = %v, want Organization/o1", got)
	}
	if got := perf[1].(map[string]any)["reference"]; got != "Practitioner/keep-me" {
		t.Errorf("performer[1].reference = %v, should be untouched", got)
	}
	if got := resource["note"].(map[string]any)["author"].(map[string]any)["reference"]; got != "Patient/p1" {
		t.Errorf("nested note.author.reference = %v, want Patient/p1", got)
	}
}

func TestMethodOrder(t *testing.T) {
	// DELETE < POST < PUT < PATCH < GET
	got := []int{
		methodOrder("DELETE"),
		methodOrder("POST"),
		methodOrder("PUT"),
		methodOrder("PATCH"),
		methodOrder("GET"),
	}
	want := []int{0, 1, 2, 3, 4}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("methodOrder ordering = %v, want %v", got, want)
	}
}

func TestParseETagVersion(t *testing.T) {
	cases := map[string]struct {
		want int
		ok   bool
	}{
		`W/"3"`: {3, true},
		`"5"`:   {5, true},
		`7`:     {7, true},
		`W/"x"`: {0, false},
		``:      {0, false},
	}
	for in, exp := range cases {
		v, ok := parseETagVersion(in)
		if v != exp.want || ok != exp.ok {
			t.Errorf("parseETagVersion(%q) = (%d,%v), want (%d,%v)", in, v, ok, exp.want, exp.ok)
		}
	}
}
