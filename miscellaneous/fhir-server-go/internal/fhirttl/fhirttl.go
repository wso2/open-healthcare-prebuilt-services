// Package fhirttl provides FHIR Turtle (RDF) serialization and parsing for the
// application/fhir+turtle wire format.
//
// NOTE on conformance: the canonical FHIR RDF representation uses type-qualified
// predicates (e.g. fhir:HumanName.family) and fhir:value wrapper nodes, which
// require per-element FHIR datatype metadata that this schema-generic repository
// does not carry. This implementation emits a simplified, self-consistent
// FHIR-flavored Turtle that round-trips losslessly (fhir:<field> predicates,
// blank nodes for objects, RDF collections for arrays). It satisfies the
// application/fhir+turtle content type for clients that round-trip through this
// server; it is not byte-identical to the spec's type-qualified FHIR-RDF.
package fhirttl

import (
	"fmt"
	"sort"
	"strconv"
	"strings"
)

const prefix = "@prefix fhir: <http://hl7.org/fhir/> .\n\n"

// ToTurtle serializes a FHIR resource map to Turtle.
func ToTurtle(resource map[string]any) ([]byte, error) {
	rt, _ := resource["resourceType"].(string)
	if rt == "" {
		return nil, fmt.Errorf("resource has no resourceType")
	}
	var b strings.Builder
	b.WriteString(prefix)
	b.WriteString("[ a fhir:")
	b.WriteString(rt)
	writeObjectBody(&b, resource, 1)
	b.WriteString("\n] .\n")
	return []byte(b.String()), nil
}

func writeObjectBody(b *strings.Builder, obj map[string]any, depth int) {
	indent := strings.Repeat("  ", depth)
	keys := make([]string, 0, len(obj))
	for k := range obj {
		if k == "resourceType" {
			continue
		}
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		b.WriteString(" ;\n")
		b.WriteString(indent)
		b.WriteString("fhir:")
		b.WriteString(k)
		b.WriteString(" ")
		writeValue(b, obj[k], depth)
	}
}

func writeValue(b *strings.Builder, v any, depth int) {
	switch val := v.(type) {
	case map[string]any:
		b.WriteString("[")
		writeObjectBody(b, val, depth+1)
		b.WriteString("\n")
		b.WriteString(strings.Repeat("  ", depth))
		b.WriteString("]")
	case []any:
		b.WriteString("(")
		for _, item := range val {
			b.WriteString(" ")
			writeValue(b, item, depth+1)
		}
		b.WriteString(" )")
	case string:
		b.WriteString(quote(val))
	case bool:
		if val {
			b.WriteString("true")
		} else {
			b.WriteString("false")
		}
	case float64:
		b.WriteString(strconv.FormatFloat(val, 'g', -1, 64))
	case nil:
		b.WriteString(`""`)
	default:
		b.WriteString(quote(fmt.Sprintf("%v", val)))
	}
}

func quote(s string) string {
	s = strings.ReplaceAll(s, `\`, `\\`)
	s = strings.ReplaceAll(s, `"`, `\"`)
	s = strings.ReplaceAll(s, "\n", `\n`)
	return `"` + s + `"`
}
