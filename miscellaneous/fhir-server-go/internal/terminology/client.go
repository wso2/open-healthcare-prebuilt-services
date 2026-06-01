// Package terminology provides a lightweight client for FHIR terminology
// operations used by the repository layer (ValueSet $expand for :in/:not-in).
//
// Set FHIR_TERMINOLOGY_URL in the environment (or via config) to point at a
// running terminology server (e.g. https://tx.fhir.org/r4 for sandbox use).
// If the URL is empty, :in/:not-in searches return UnsupportedParamError.
package terminology

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sync"
	"time"
)

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

	var vs map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&vs); err != nil {
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
