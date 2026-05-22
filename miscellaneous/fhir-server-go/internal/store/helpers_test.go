// Tests for pure helper functions in the store package (no DB required).
package store

import (
	"encoding/json"
	"testing"
	"time"
)

// ─── mergePatch ───────────────────────────────────────────────────────────────

func TestMergePatch_AddField(t *testing.T) {
	target := map[string]any{"a": 1}
	patch := map[string]any{"b": 2}
	got := mergePatch(target, patch)
	if got["a"] != 1 || got["b"] != 2 {
		t.Fatalf("unexpected result: %v", got)
	}
}

func TestMergePatch_OverwriteField(t *testing.T) {
	target := map[string]any{"a": "old"}
	patch := map[string]any{"a": "new"}
	got := mergePatch(target, patch)
	if got["a"] != "new" {
		t.Fatalf("expected 'new', got %v", got["a"])
	}
}

func TestMergePatch_DeleteFieldWithNull(t *testing.T) {
	target := map[string]any{"a": 1, "b": 2}
	patch := map[string]any{"b": nil}
	got := mergePatch(target, patch)
	if _, ok := got["b"]; ok {
		t.Fatal("field 'b' should have been deleted")
	}
	if got["a"] != 1 {
		t.Fatal("field 'a' should be unchanged")
	}
}

func TestMergePatch_NestedMerge(t *testing.T) {
	target := map[string]any{"meta": map[string]any{"versionId": "1", "tag": []any{"x"}}}
	patch := map[string]any{"meta": map[string]any{"versionId": "2"}}
	got := mergePatch(target, patch)
	meta := got["meta"].(map[string]any)
	if meta["versionId"] != "2" {
		t.Fatalf("expected versionId=2, got %v", meta["versionId"])
	}
	// tag should survive (not deleted by nested patch)
	if meta["tag"] == nil {
		t.Fatal("nested field 'tag' should survive merge")
	}
}

func TestMergePatch_NestedDelete(t *testing.T) {
	target := map[string]any{"meta": map[string]any{"versionId": "1", "source": "abc"}}
	patch := map[string]any{"meta": map[string]any{"source": nil}}
	got := mergePatch(target, patch)
	meta := got["meta"].(map[string]any)
	if _, ok := meta["source"]; ok {
		t.Fatal("'source' should have been deleted from nested map")
	}
}

func TestMergePatch_PatchReplaceNonMapWithMap(t *testing.T) {
	// When patch value is a map but target value is not a map, patch wins outright
	target := map[string]any{"x": "string"}
	patch := map[string]any{"x": map[string]any{"nested": true}}
	got := mergePatch(target, patch)
	if _, ok := got["x"].(map[string]any); !ok {
		t.Fatalf("expected map, got %T", got["x"])
	}
}

func TestMergePatch_DoesNotMutateTarget(t *testing.T) {
	target := map[string]any{"a": 1}
	patch := map[string]any{"b": 2}
	mergePatch(target, patch)
	if _, ok := target["b"]; ok {
		t.Fatal("mergePatch must not mutate target")
	}
}

// ─── setMeta ──────────────────────────────────────────────────────────────────

func TestSetMeta_SetsVersionAndLastUpdated(t *testing.T) {
	now := time.Date(2024, 1, 15, 10, 30, 0, 0, time.UTC)
	body := map[string]any{"id": "p1"}
	result := setMeta(body, 3, now)

	meta := result["meta"].(map[string]any)
	if meta["versionId"] != "3" {
		t.Fatalf("expected versionId='3', got %v", meta["versionId"])
	}
	if meta["lastUpdated"] != "2024-01-15T10:30:00Z" {
		t.Fatalf("unexpected lastUpdated: %v", meta["lastUpdated"])
	}
}

func TestSetMeta_PreservesExistingMetaFields(t *testing.T) {
	body := map[string]any{
		"meta": map[string]any{"profile": []any{"http://example.com/p"}},
	}
	result := setMeta(body, 1, time.Now())
	meta := result["meta"].(map[string]any)
	if meta["profile"] == nil {
		t.Fatal("existing profile field should be preserved")
	}
}

func TestSetMeta_CreatesMetaIfAbsent(t *testing.T) {
	body := map[string]any{"id": "x"}
	result := setMeta(body, 1, time.Now())
	if result["meta"] == nil {
		t.Fatal("meta should be created when absent")
	}
}

// ─── unmarshalWithMeta ────────────────────────────────────────────────────────

func TestUnmarshalWithMeta_RoundTrip(t *testing.T) {
	original := map[string]any{"resourceType": "Patient", "id": "p1"}
	raw, _ := json.Marshal(original)
	now := time.Now().UTC()

	got, err := unmarshalWithMeta(raw, 2, now)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got["id"] != "p1" {
		t.Fatalf("id mismatch: %v", got["id"])
	}
	meta := got["meta"].(map[string]any)
	if meta["versionId"] != "2" {
		t.Fatalf("versionId mismatch: %v", meta["versionId"])
	}
}

// ─── splitModifier ────────────────────────────────────────────────────────────

func TestSplitModifier_NoModifier(t *testing.T) {
	param, modifier := splitModifier("name")
	if param != "name" || modifier != "" {
		t.Fatalf("got (%q, %q)", param, modifier)
	}
}

func TestSplitModifier_WithModifier(t *testing.T) {
	param, modifier := splitModifier("name:exact")
	if param != "name" || modifier != "exact" {
		t.Fatalf("got (%q, %q)", param, modifier)
	}
}

func TestSplitModifier_MissingModifier(t *testing.T) {
	param, modifier := splitModifier("_id:missing")
	if param != "_id" || modifier != "missing" {
		t.Fatalf("got (%q, %q)", param, modifier)
	}
}

// ─── extractComparatorPrefix ──────────────────────────────────────────────────

func TestExtractComparatorPrefix_NoPrefix(t *testing.T) {
	prefix, rest := extractComparatorPrefix("2024-01-01")
	if prefix != "eq" || rest != "2024-01-01" {
		t.Fatalf("got (%q, %q)", prefix, rest)
	}
}

func TestExtractComparatorPrefix_GT(t *testing.T) {
	prefix, rest := extractComparatorPrefix("gt2024-01-01")
	if prefix != "gt" || rest != "2024-01-01" {
		t.Fatalf("got (%q, %q)", prefix, rest)
	}
}

func TestExtractComparatorPrefix_LE(t *testing.T) {
	prefix, rest := extractComparatorPrefix("le100")
	if prefix != "le" || rest != "100" {
		t.Fatalf("got (%q, %q)", prefix, rest)
	}
}

func TestExtractComparatorPrefix_NE(t *testing.T) {
	prefix, rest := extractComparatorPrefix("ne2024")
	if prefix != "ne" || rest != "2024" {
		t.Fatalf("got (%q, %q)", prefix, rest)
	}
}

func TestExtractComparatorPrefix_ShortString_NoPrefix(t *testing.T) {
	// "gt" alone — len is 2, so no prefix stripped (must be len > 2)
	prefix, rest := extractComparatorPrefix("gt")
	if prefix != "eq" || rest != "gt" {
		t.Fatalf("got (%q, %q)", prefix, rest)
	}
}

// ─── looksLikeDate ────────────────────────────────────────────────────────────

func TestLooksLikeDate(t *testing.T) {
	cases := []struct {
		input string
		want  bool
	}{
		{"2024", true},
		{"2024-01", true},
		{"2024-01-15", true},
		{"2024-01-15T10:00:00Z", true},
		{"gt2024-01-01", true},
		{"le2023", true},
		{"Smith", false},
		{"active", false},
		{"100", false},
		{"", false},
	}
	for _, c := range cases {
		got := looksLikeDate(c.input)
		if got != c.want {
			t.Errorf("looksLikeDate(%q) = %v, want %v", c.input, got, c.want)
		}
	}
}

// ─── looksLikeNumber ──────────────────────────────────────────────────────────

func TestLooksLikeNumber(t *testing.T) {
	cases := []struct {
		input string
		want  bool
	}{
		{"42", true},
		{"3.14", true},
		{"gt100", true},
		{"-1.5", true},
		{"Smith", false},
		{"2024-01-01", false},
		{"active|code", false},
	}
	for _, c := range cases {
		got := looksLikeNumber(c.input)
		if got != c.want {
			t.Errorf("looksLikeNumber(%q) = %v, want %v", c.input, got, c.want)
		}
	}
}

// ─── expandDateStringForSearch ────────────────────────────────────────────────

func TestExpandDateStringForSearch_Year(t *testing.T) {
	low, high, err := expandDateStringForSearch("2024")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if low.Year() != 2024 || low.Month() != 1 || low.Day() != 1 {
		t.Fatalf("low = %v", low)
	}
	if high.Year() != 2024 || high.Month() != 12 || high.Day() != 31 {
		t.Fatalf("high = %v", high)
	}
}

func TestExpandDateStringForSearch_YearMonth(t *testing.T) {
	low, high, err := expandDateStringForSearch("2024-02")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if low.Month() != 2 || low.Day() != 1 {
		t.Fatalf("low = %v", low)
	}
	// Feb 2024 — leap year, so 29 days
	if high.Month() != 2 || high.Day() != 29 {
		t.Fatalf("high = %v", high)
	}
}

func TestExpandDateStringForSearch_Date(t *testing.T) {
	low, high, err := expandDateStringForSearch("2024-01-15")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !low.Equal(time.Date(2024, 1, 15, 0, 0, 0, 0, time.UTC)) {
		t.Fatalf("low = %v", low)
	}
	if !high.Equal(time.Date(2024, 1, 15, 23, 59, 59, 0, time.UTC)) {
		t.Fatalf("high = %v", high)
	}
}

func TestExpandDateStringForSearch_RFC3339(t *testing.T) {
	low, high, err := expandDateStringForSearch("2024-01-15T10:30:00Z")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	// Instant: low == high
	if !low.Equal(high) {
		t.Fatalf("low (%v) != high (%v) for instant", low, high)
	}
}

func TestExpandDateStringForSearch_InvalidDate(t *testing.T) {
	_, _, err := expandDateStringForSearch("not-a-date")
	if err == nil {
		t.Fatal("expected error for invalid date string")
	}
}

// ─── NotFoundError ────────────────────────────────────────────────────────────

func TestNotFoundError_Message(t *testing.T) {
	err := NotFoundError{ResourceType: "Patient", ResourceID: "p1"}
	want := "Patient/p1 not found"
	if err.Error() != want {
		t.Fatalf("got %q, want %q", err.Error(), want)
	}
}
