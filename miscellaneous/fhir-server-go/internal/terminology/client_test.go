package terminology_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/terminology"
)

func TestClient_Expand(t *testing.T) {
	// Minimal $expand response.
	expansion := map[string]any{
		"resourceType": "ValueSet",
		"expansion": map[string]any{
			"total": 2,
			"contains": []any{
				map[string]any{"system": "http://loinc.org", "code": "8480-6"},
				map[string]any{"system": "http://loinc.org", "code": "8867-4"},
			},
		},
	}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/ValueSet/$expand" {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		w.Header().Set("Content-Type", "application/fhir+json")
		json.NewEncoder(w).Encode(expansion)
	}))
	defer srv.Close()

	c := terminology.New(srv.URL)
	codes, err := c.Expand(context.Background(), "http://example.org/vs/bp")
	if err != nil {
		t.Fatal(err)
	}
	if len(codes) != 2 {
		t.Fatalf("expected 2 codes, got %d", len(codes))
	}
	if codes[0].System != "http://loinc.org" || codes[0].Code != "8480-6" {
		t.Errorf("codes[0]: got %+v", codes[0])
	}
}

func TestClient_NilWhenEmpty(t *testing.T) {
	if c := terminology.New(""); c != nil {
		t.Error("New(\"\") should return nil")
	}
}
