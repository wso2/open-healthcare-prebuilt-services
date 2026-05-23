// Package fhirpath implements a targeted FHIRPath evaluator covering the
// subset of expressions used in FHIR R4 search parameter definitions.
//
// Supported constructs:
//   - Path traversal:    Patient.name.family
//   - Union:             Patient.name | Patient.telecom
//   - ofType():          Observation.value.ofType(Quantity)
//   - where():           Patient.name.where(use='official')
//   - exists():          Patient.name.exists()
//   - Implicit flattening of arrays at every step
package fhirpath

import (
	"fmt"
	"strings"
)

// Evaluate evaluates a FHIRPath expression against a FHIR resource (as
// map[string]any decoded from JSON) and returns all matched leaf values.
//
// Union alternatives (|) are evaluated independently and their results merged.
// Within each alternative the nodes form a chain: output of one node is the
// input to the next (FHIRPath implicit iteration semantics).
func Evaluate(expr string, resource map[string]any) ([]any, error) {
	expr = strings.TrimSpace(expr)
	chains, err := parse(expr)
	if err != nil {
		return nil, err
	}
	var results []any
	for _, chain := range chains {
		// Start each chain with the resource as the single input.
		current := []any{resource}
		for _, n := range chain {
			next, err := evalNode(n, current)
			if err != nil {
				return nil, err
			}
			current = next
		}
		results = append(results, current...)
	}
	return results, nil
}

// ─── AST ─────────────────────────────────────────────────────────────────────

type nodeKind int

const (
	kindPath      nodeKind = iota // foo.bar.baz
	kindOfType                    // .ofType(X)
	kindWhere                     // .where(key='val')
	kindExists                    // .exists()
	kindExtension                 // .extension('url')
)

type node struct {
	kind     nodeKind
	field    string // for kindPath
	typeName string // for kindOfType
	whereKey string // for kindWhere
	whereVal string // for kindWhere
	extURL   string // for kindExtension
	children []node
}

// ─── Parser ───────────────────────────────────────────────────────────────────

// parse splits a union expression and returns one node-chain per alternative.
// Each chain is evaluated sequentially; results across chains are unioned.
func parse(expr string) ([][]node, error) {
	parts := splitUnion(expr)
	var chains [][]node
	for _, p := range parts {
		chain, err := parseChain(strings.TrimSpace(p))
		if err != nil {
			return nil, err
		}
		chains = append(chains, chain)
	}
	return chains, nil
}

// splitUnion splits on | but not inside parentheses.
func splitUnion(expr string) []string {
	var parts []string
	depth := 0
	start := 0
	for i := 0; i < len(expr); i++ {
		switch expr[i] {
		case '(':
			depth++
		case ')':
			depth--
		case '|':
			if depth == 0 {
				parts = append(parts, strings.TrimSpace(expr[start:i]))
				start = i + 1
			}
		}
	}
	parts = append(parts, strings.TrimSpace(expr[start:]))
	return parts
}

// parseChain parses a single (non-union) expression into a sequence of nodes
// that will be evaluated left-to-right.
func parseChain(expr string) ([]node, error) {
	// Tokenise by splitting on dots, but keep function-call args intact.
	tokens := tokenise(expr)
	if len(tokens) == 0 {
		return nil, fmt.Errorf("empty expression")
	}

	// Strip leading resource type (first segment with capital letter) — the
	// evaluator is called with the resource already, so "Patient.name" and
	// "name" are equivalent when applied to a Patient.
	if len(tokens) > 0 && isResourceType(tokens[0]) {
		tokens = tokens[1:]
	}

	var nodes []node
	for _, tok := range tokens {
		n, err := parseToken(tok)
		if err != nil {
			return nil, err
		}
		nodes = append(nodes, n)
	}
	return nodes, nil
}

// tokenise splits a dot-path expression into tokens, keeping parenthesised
// argument groups together.
func tokenise(expr string) []string {
	var tokens []string
	depth := 0
	start := 0
	for i := 0; i < len(expr); i++ {
		switch expr[i] {
		case '(':
			depth++
		case ')':
			depth--
		case '.':
			if depth == 0 && i > start {
				tokens = append(tokens, expr[start:i])
				start = i + 1
			}
		}
	}
	if start < len(expr) {
		tokens = append(tokens, expr[start:])
	}
	return tokens
}

func parseToken(tok string) (node, error) {
	tok = strings.TrimSpace(tok)

	if strings.HasPrefix(tok, "ofType(") && strings.HasSuffix(tok, ")") {
		return node{kind: kindOfType, typeName: tok[7 : len(tok)-1]}, nil
	}

	if strings.HasPrefix(tok, "where(") && strings.HasSuffix(tok, ")") {
		inner := tok[6 : len(tok)-1]
		return parseWhere(inner)
	}

	if tok == "exists()" || tok == "exists" {
		return node{kind: kindExists}, nil
	}

	if strings.HasPrefix(tok, "extension(") && strings.HasSuffix(tok, ")") {
		url := strings.Trim(tok[10:len(tok)-1], `'"`)
		return node{kind: kindExtension, extURL: url}, nil
	}

	// Plain field name (may include array index notation like [0] — ignore it)
	field := strings.SplitN(tok, "[", 2)[0]
	return node{kind: kindPath, field: field}, nil
}

func parseWhere(inner string) (node, error) {
	// Supports: key = 'value'  or  key != 'value'
	// "!=" must be checked before "=" to avoid matching the "=" inside "!="
	for _, sep := range []string{"!=", "="} {
		idx := strings.Index(inner, sep)
		if idx < 0 {
			continue
		}
		key := strings.TrimSpace(inner[:idx])
		val := strings.TrimSpace(inner[idx+len(sep):])
		val = strings.Trim(val, `'"`)
		return node{kind: kindWhere, whereKey: key, whereVal: val, field: sep}, nil
	}
	// Unsupported where clause — treat as pass-through
	return node{kind: kindWhere, whereKey: "", whereVal: ""}, nil
}

func isResourceType(s string) bool {
	return len(s) > 0 && s[0] >= 'A' && s[0] <= 'Z'
}

// ─── Evaluator ────────────────────────────────────────────────────────────────

func evalNode(n node, inputs []any) ([]any, error) {
	var results []any
	for _, input := range inputs {
		vals, err := applyNode(n, input)
		if err != nil {
			return nil, err
		}
		results = append(results, vals...)
	}
	return results, nil
}

// applyNode applies a single AST node to a single input value, returning the
// matched values (which may be multiple due to arrays).
func applyNode(n node, input any) ([]any, error) {
	switch n.kind {

	case kindPath:
		return traverseField(input, n.field), nil

	case kindOfType:
		return filterByType(input, n.typeName), nil

	case kindWhere:
		return filterWhere(input, n.whereKey, n.whereVal, n.field), nil

	case kindExists:
		// exists() returns a boolean — not useful for value extraction; return input as-is
		return []any{input}, nil

	case kindExtension:
		return traverseExtension(input, n.extURL), nil
	}

	return nil, fmt.Errorf("unknown node kind %d", n.kind)
}

// traverseField descends into the named field, flattening any arrays along
// the way. This implements FHIRPath's implicit iteration semantics.
func traverseField(input any, field string) []any {
	switch v := input.(type) {
	case map[string]any:
		val, ok := v[field]
		if !ok {
			return nil
		}
		return flatten(val)
	case []any:
		var results []any
		for _, item := range v {
			results = append(results, traverseField(item, field)...)
		}
		return results
	}
	return nil
}

// flatten unwraps a top-level array into individual elements.
func flatten(v any) []any {
	if arr, ok := v.([]any); ok {
		return arr
	}
	return []any{v}
}

// filterByType implements ofType(TypeName). For map inputs we only return
// objects whose "resourceType" matches typeName. FHIR polymorphic field
// resolution (e.g. value[x].ofType(Quantity)) is handled at path traversal,
// not here — so map inputs without a matching resourceType are not a match.
func filterByType(input any, typeName string) []any {
	switch v := input.(type) {
	case map[string]any:
		if rt, ok := v["resourceType"].(string); ok && rt == typeName {
			return []any{v}
		}
		return nil
	case []any:
		var results []any
		for _, item := range v {
			results = append(results, filterByType(item, typeName)...)
		}
		return results
	}
	return nil
}

// filterWhere implements where(key='val') filtering. parseWhere returns a
// where node with an empty key when the clause is unsupported; in that case
// we drop all matches rather than passing input through, so unsupported
// predicates do not silently broaden extraction.
func filterWhere(input any, key, val, op string) []any {
	if key == "" {
		return nil
	}
	switch v := input.(type) {
	case map[string]any:
		fieldVal, ok := v[key]
		if !ok {
			return nil
		}
		match := fmt.Sprintf("%v", fieldVal) == val
		if op == "!=" {
			match = !match
		}
		if match {
			return []any{v}
		}
		return nil
	case []any:
		var results []any
		for _, item := range v {
			results = append(results, filterWhere(item, key, val, op)...)
		}
		return results
	}
	return nil
}

// traverseExtension finds extension entries matching a URL.
func traverseExtension(input any, url string) []any {
	extensions := traverseField(input, "extension")
	var results []any
	for _, ext := range extensions {
		m, ok := ext.(map[string]any)
		if !ok {
			continue
		}
		if u, ok := m["url"].(string); ok && u == url {
			results = append(results, m)
		}
	}
	return results
}

// ─── Polymorphic field helper ─────────────────────────────────────────────────

// EvaluatePolymorphic handles expressions like "Observation.value.ofType(Quantity)"
// by looking for the concrete field "valueQuantity" in the resource.
func EvaluatePolymorphic(expr string, resource map[string]any) ([]any, error) {
	// Pre-process: convert "foo.ofType(Bar)" into a direct lookup of "fooBar"
	expr = expandPolymorphic(expr)
	return Evaluate(expr, resource)
}

func expandPolymorphic(expr string) string {
	const marker = ".ofType("
	for {
		idx := strings.Index(expr, marker)
		if idx < 0 {
			break
		}
		end := strings.Index(expr[idx:], ")")
		if end < 0 {
			break
		}
		typeName := expr[idx+len(marker) : idx+end]

		// Find the field before .ofType
		pre := expr[:idx]
		lastDot := strings.LastIndex(pre, ".")
		var field string
		if lastDot < 0 {
			field = pre
			pre = ""
		} else {
			field = pre[lastDot+1:]
			pre = pre[:lastDot]
		}

		// FHIR camelCase: valueQuantity, onsetDateTime — capitalize the type name's first letter.
		var concreteField string
		if len(typeName) > 0 {
			concreteField = field + strings.ToUpper(typeName[:1]) + typeName[1:]
		} else {
			concreteField = field
		}
		if pre == "" {
			expr = concreteField + expr[idx+end+1:]
		} else {
			expr = pre + "." + concreteField + expr[idx+end+1:]
		}
	}
	return expr
}
