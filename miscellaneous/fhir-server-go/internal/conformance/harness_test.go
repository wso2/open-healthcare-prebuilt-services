//go:build conformance

// Package conformance is the FHIR R4 repository acceptance gate. It exercises a
// running server purely over HTTP and asserts the behaviours the FHIR "RESTful
// API" specification (https://hl7.org/fhir/R4/http.html) requires of a
// repository — interaction semantics, search, bundles, conditional ops,
// concurrency, the CapabilityStatement, and error OperationOutcomes.
//
// It is IG-agnostic: it checks "is this a correct FHIR R4 repository", not
// conformance to any particular profile.
//
// By default it spins up a throwaway Postgres (testcontainers) and an in-process
// server. Set FHIR_BASE_URL to the base of a deployed server (the part ending in
// .../fhir/r4) to run the same suite against it:
//
//	go test -tags conformance ./internal/conformance/
//	FHIR_BASE_URL=https://host/fhir/r4 go test -tags conformance ./internal/conformance/
package conformance

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"sync/atomic"
	"testing"

	tcpostgres "github.com/testcontainers/testcontainers-go/modules/postgres"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/db"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/handler"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/searchparam"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/seed"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/store"
)

// base is the FHIR base URL (…/fhir/r4) shared by every test. client is reused.
var (
	base   string
	client = http.DefaultClient
	// uniq yields process-unique values so the suite is isolated even when run
	// against a shared, already-populated deployment.
	uniq int64
)

func nextID() string { return fmt.Sprintf("%d", atomic.AddInt64(&uniq, 1)) }

func TestMain(m *testing.M) {
	if u := os.Getenv("FHIR_BASE_URL"); u != "" {
		base = strings.TrimRight(u, "/")
		os.Exit(m.Run())
	}
	os.Exit(runWithContainer(m))
}

// runWithContainer brings up one Postgres + in-process server for the whole
// package, runs the suite, and tears everything down. Returns the test exit code.
func runWithContainer(m *testing.M) int {
	ctx := context.Background()
	pgc, err := tcpostgres.Run(ctx,
		"postgres:16-alpine",
		tcpostgres.WithDatabase("testdb"),
		tcpostgres.WithUsername("test"),
		tcpostgres.WithPassword("test"),
		tcpostgres.BasicWaitStrategies(),
	)
	if err != nil {
		fmt.Fprintln(os.Stderr, "start postgres:", err)
		return 1
	}
	defer func() { _ = pgc.Terminate(ctx) }()

	connStr, err := pgc.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		fmt.Fprintln(os.Stderr, "conn string:", err)
		return 1
	}
	pool, err := db.Connect(ctx, connStr)
	if err != nil {
		fmt.Fprintln(os.Stderr, "connect:", err)
		return 1
	}
	defer pool.Close()
	if err := db.Migrate(ctx, pool); err != nil {
		fmt.Fprintln(os.Stderr, "migrate:", err)
		return 1
	}
	if err := seed.SeedSearchParams(ctx, pool); err != nil {
		fmt.Fprintln(os.Stderr, "seed:", err)
		return 1
	}
	reg := searchparam.NewRegistry()
	if err := reg.Load(ctx, pool); err != nil {
		fmt.Fprintln(os.Stderr, "registry:", err)
		return 1
	}
	var ready atomic.Int32
	ready.Store(1)
	srv := httptest.NewServer(handler.NewRouter(store.New(pool, reg), pool, reg, "http://conformance/fhir/r4", &ready))
	defer srv.Close()
	base = srv.URL + "/fhir/r4"
	return m.Run()
}

// ─── HTTP helpers ───────────────────────────────────────────────────────────

// hreq issues method+path (path is relative to base) with an optional JSON body
// and flat key/value headers. The caller closes resp.Body.
func hreq(t *testing.T, method, path string, body any, headers ...string) *http.Response {
	t.Helper()
	var r io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			t.Fatalf("marshal: %v", err)
		}
		r = bytes.NewReader(b)
	}
	req, err := http.NewRequest(method, base+path, r)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	for i := 0; i+1 < len(headers); i += 2 {
		req.Header.Set(headers[i], headers[i+1])
	}
	if body != nil && req.Header.Get("Content-Type") == "" {
		req.Header.Set("Content-Type", "application/fhir+json")
	}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("%s %s: %v", method, path, err)
	}
	return resp
}

// jbody decodes and closes a JSON response body.
func jbody(t *testing.T, resp *http.Response) map[string]any {
	t.Helper()
	defer resp.Body.Close()
	var m map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&m); err != nil {
		t.Fatalf("decode (status %d): %v", resp.StatusCode, err)
	}
	return m
}

func wantStatus(t *testing.T, resp *http.Response, want int) {
	t.Helper()
	if resp.StatusCode != want {
		b, _ := io.ReadAll(resp.Body)
		resp.Body.Close()
		t.Fatalf("status: got %d, want %d; body: %s", resp.StatusCode, want, string(b))
	}
}

// createPatient creates a Patient carrying a unique identifier and returns
// (id, identifierValue).
func createPatient(t *testing.T, extra map[string]any) (string, string) {
	t.Helper()
	idv := "conf-" + nextID()
	body := map[string]any{
		"resourceType": "Patient",
		"identifier":   []any{map[string]any{"system": "urn:conformance", "value": idv}},
	}
	for k, v := range extra {
		body[k] = v
	}
	resp := hreq(t, http.MethodPost, "/Patient", body)
	wantStatus(t, resp, http.StatusCreated)
	created := jbody(t, resp)
	id, _ := created["id"].(string)
	if id == "" {
		t.Fatal("create: server did not assign an id")
	}
	return id, idv
}

func isOperationOutcome(m map[string]any) bool {
	return m["resourceType"] == "OperationOutcome"
}

// postRaw sends a raw (possibly malformed) body so error paths can be exercised.
func postRaw(t *testing.T, path, body, contentType string) *http.Response {
	t.Helper()
	req, err := http.NewRequest(http.MethodPost, base+path, strings.NewReader(body))
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	req.Header.Set("Content-Type", contentType)
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("post raw: %v", err)
	}
	return resp
}

// ─── Bundle accessors ─────────────────────────────────────────────────────────

func entries(bundle map[string]any) []map[string]any {
	raw, _ := bundle["entry"].([]any)
	out := make([]map[string]any, 0, len(raw))
	for _, e := range raw {
		if m, ok := e.(map[string]any); ok {
			out = append(out, m)
		}
	}
	return out
}

func entryResource(e map[string]any) map[string]any {
	r, _ := e["resource"].(map[string]any)
	return r
}

func firstEntry(bundle map[string]any) map[string]any {
	es := entries(bundle)
	if len(es) == 0 {
		return nil
	}
	return entryResource(es[0])
}

func firstEntryID(bundle map[string]any) string {
	if r := firstEntry(bundle); r != nil {
		id, _ := r["id"].(string)
		return id
	}
	return ""
}

// familyOrder returns the family name of each match entry in Bundle order.
func familyOrder(bundle map[string]any) []string {
	var out []string
	for _, e := range entries(bundle) {
		r := entryResource(e)
		names, _ := r["name"].([]any)
		if len(names) == 0 {
			continue
		}
		if n, ok := names[0].(map[string]any); ok {
			if fam, ok := n["family"].(string); ok {
				out = append(out, fam)
			}
		}
	}
	return out
}

func hasSubsetted(res map[string]any) bool {
	meta, _ := res["meta"].(map[string]any)
	tags, _ := meta["tag"].([]any)
	for _, tg := range tags {
		if tm, ok := tg.(map[string]any); ok && tm["code"] == "SUBSETTED" {
			return true
		}
	}
	return false
}

func contains(ss []string, s string) bool {
	for _, v := range ss {
		if v == s {
			return true
		}
	}
	return false
}
