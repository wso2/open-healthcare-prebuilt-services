// Package terminology provides a lightweight client for FHIR terminology
// operations used by the repository layer (ValueSet $expand for :in/:not-in).
//
// Set FHIR_TERMINOLOGY_URL in the environment (or via config) to point at a
// running terminology server (e.g. https://tx.fhir.org/r4 for sandbox use).
// If the URL is empty, :in/:not-in searches return UnsupportedParamError.
package terminology

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sync"
	"time"
)

func bytesReader(b []byte) io.Reader { return bytes.NewReader(b) }

// Client calls a FHIR terminology server for ValueSet expansion.
type Client struct {
	baseURL string
	http    *http.Client
	mu      sync.RWMutex
	cache   map[string]cachedExpansion
}

type cachedExpansion struct {
	codes []CodeEntry
	at    time.Time
}

// CodeEntry is one code in a ValueSet expansion.
type CodeEntry struct {
	System string
	Code   string
}

const cacheTTL = 5 * time.Minute

// New creates a client pointing at baseURL (the FHIR base, e.g. https://tx.fhir.org/r4).
// Returns nil if baseURL is empty.
func New(baseURL string) *Client {
	if baseURL == "" {
		return nil
	}
	return &Client{
		baseURL: baseURL,
		http:    &http.Client{Timeout: 10 * time.Second},
		cache:   make(map[string]cachedExpansion),
	}
}

// Expand returns the codes in a ValueSet identified by vsURL. Results are
// cached for cacheTTL to avoid hammering the terminology server on each search.
func (c *Client) Expand(ctx context.Context, vsURL string) ([]CodeEntry, error) {
	c.mu.RLock()
	if cached, ok := c.cache[vsURL]; ok && time.Since(cached.at) < cacheTTL {
		c.mu.RUnlock()
		return cached.codes, nil
	}
	c.mu.RUnlock()

	codes, err := c.expand(ctx, vsURL)
	if err != nil {
		return nil, err
	}

	c.mu.Lock()
	c.cache[vsURL] = cachedExpansion{codes: codes, at: time.Now()}
	c.mu.Unlock()
	return codes, nil
}

// ExpandFilter expands an ad-hoc ValueSet that includes the codes from system
// selected by a filter (e.g. op="is-a" for descendants, op="generalizes" for
// ancestors of value). Used by token :below / :above. Results cached by
// (system, op, value).
func (c *Client) ExpandFilter(ctx context.Context, system, op, value string) ([]CodeEntry, error) {
	key := system + "|" + op + "|" + value
	c.mu.RLock()
	if cached, ok := c.cache[key]; ok && time.Since(cached.at) < cacheTTL {
		c.mu.RUnlock()
		return cached.codes, nil
	}
	c.mu.RUnlock()

	vs := map[string]any{
		"resourceType": "ValueSet",
		"compose": map[string]any{
			"include": []any{map[string]any{
				"system": system,
				"filter": []any{map[string]any{
					"property": "concept",
					"op":       op,
					"value":    value,
				}},
			}},
		},
	}
	body, err := json.Marshal(map[string]any{
		"resourceType": "Parameters",
		"parameter":    []any{map[string]any{"name": "valueSet", "resource": vs}},
	})
	if err != nil {
		return nil, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/ValueSet/$expand", bytesReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/fhir+json")
	req.Header.Set("Accept", "application/fhir+json")
	resp, err := c.http.Do(req)
	if err != nil {
		return nil, fmt.Errorf("terminology $expand filter %s %s %s: %w", system, op, value, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("terminology $expand filter: HTTP %d: %s", resp.StatusCode, string(b))
	}
	codes, err := parseExpansion(resp.Body)
	if err != nil {
		return nil, err
	}
	c.mu.Lock()
	c.cache[key] = cachedExpansion{codes: codes, at: time.Now()}
	c.mu.Unlock()
	return codes, nil
}

func (c *Client) expand(ctx context.Context, vsURL string) ([]CodeEntry, error) {
	reqURL := c.baseURL + "/ValueSet/$expand?url=" + url.QueryEscape(vsURL)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/fhir+json")

	resp, err := c.http.Do(req)
	if err != nil {
		return nil, fmt.Errorf("terminology $expand %s: %w", vsURL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("terminology $expand %s: HTTP %d: %s", vsURL, resp.StatusCode, string(body))
	}

	return parseExpansion(resp.Body)
}

// parseExpansion reads a ValueSet $expand response body and returns its codes.
func parseExpansion(r io.Reader) ([]CodeEntry, error) {
	var vs map[string]any
	if err := json.NewDecoder(r).Decode(&vs); err != nil {
		return nil, fmt.Errorf("terminology $expand parse: %w", err)
	}
	expansion, _ := vs["expansion"].(map[string]any)
	if expansion == nil {
		return nil, fmt.Errorf("ValueSet $expand response has no expansion")
	}
	contains, _ := expansion["contains"].([]any)
	var out []CodeEntry
	for _, raw := range contains {
		c, _ := raw.(map[string]any)
		if c == nil {
			continue
		}
		system, _ := c["system"].(string)
		code, _ := c["code"].(string)
		if code != "" {
			out = append(out, CodeEntry{System: system, Code: code})
		}
	}
	return out, nil
}
