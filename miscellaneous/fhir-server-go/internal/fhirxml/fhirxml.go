// Package fhirxml provides FHIR XML ↔ JSON map conversion.
//
// FHIR XML format rules (https://hl7.org/fhir/R4/xml.html):
//   - Root element = resourceType with xmlns="http://hl7.org/fhir"
//   - Primitive properties → <elem value="..."/> (self-closing with value attr)
//   - Object properties → <elem>...children...</elem>
//   - Arrays → repeated sibling elements with the same name
//   - The "div" element (narrative) carries raw XHTML content, not a value attr
//   - "resourceType" and "id" in JSON have special XML positions (root tag / id element)
//   - Extension keys starting with "_" carry extension data alongside primitive values
//
// This is a best-effort converter that handles the core FHIR resource shape.
// Extension objects, contained resources, and full XHTML round-tripping are
// supported to the extent needed by common repository operations.
package fhirxml

import (
	"bytes"
	"encoding/json"
	"encoding/xml"
	"fmt"
	"io"
	"strings"
)

const fhirNS = "http://hl7.org/fhir"

// ToXML converts a FHIR JSON map to FHIR XML bytes.
func ToXML(resource map[string]any) ([]byte, error) {
	rt, _ := resource["resourceType"].(string)
	if rt == "" {
		return nil, fmt.Errorf("resource has no resourceType")
	}
	var buf bytes.Buffer
	buf.WriteString(xml.Header)
	enc := xml.NewEncoder(&buf)
	enc.Indent("", "  ")
	if err := encodeElement(enc, rt, resource, true); err != nil {
		return nil, err
	}
	if err := enc.Flush(); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

// FromXML parses FHIR XML into a JSON-compatible map. The root element name
// becomes "resourceType".
func FromXML(data []byte) (map[string]any, error) {
	dec := xml.NewDecoder(bytes.NewReader(data))
	dec.Strict = false
	// Skip the XML declaration.
	for {
		tok, err := dec.Token()
		if err != nil {
			return nil, fmt.Errorf("XML parse: %w", err)
		}
		if _, ok := tok.(xml.StartElement); ok {
			// Put back and let decodeElement consume it.
			dec = xml.NewDecoder(bytes.NewReader(data))
			break
		}
	}
	root, err := decodeElement(dec)
	if err != nil {
		return nil, err
	}
	m, ok := root.(map[string]any)
	if !ok {
		return nil, fmt.Errorf("unexpected root type %T", root)
	}
	return m, nil
}

// ─── Encoder ──────────────────────────────────────────────────────────────────

func encodeElement(enc *xml.Encoder, name string, value any, isRoot bool) error {
	switch v := value.(type) {
	case map[string]any:
		start := xml.StartElement{Name: xml.Name{Local: name}}
		if isRoot {
			start.Attr = []xml.Attr{{Name: xml.Name{Local: "xmlns"}, Value: fhirNS}}
		}
		enc.EncodeToken(start)
		// id first if present (FHIR convention).
		if id, ok := v["id"].(string); ok {
			enc.EncodeToken(xml.StartElement{Name: xml.Name{Local: "id"}, Attr: []xml.Attr{{Name: xml.Name{Local: "value"}, Value: id}}})
			enc.EncodeToken(xml.EndElement{Name: xml.Name{Local: "id"}})
		}
		for k, child := range v {
			if k == "resourceType" || k == "id" || strings.HasPrefix(k, "_") {
				continue
			}
			if err := encodeField(enc, k, child); err != nil {
				return err
			}
		}
		enc.EncodeToken(xml.EndElement{Name: xml.Name{Local: name}})
	case []any:
		for _, item := range v {
			if err := encodeElement(enc, name, item, false); err != nil {
				return err
			}
		}
	case string:
		if name == "div" {
			// XHTML narrative: emit as CharData inside a div element.
			enc.EncodeToken(xml.StartElement{Name: xml.Name{Local: "div"}, Attr: []xml.Attr{{Name: xml.Name{Space: "http://www.w3.org/1999/xhtml", Local: "xmlns"}, Value: "http://www.w3.org/1999/xhtml"}}})
			enc.EncodeToken(xml.CharData(v))
			enc.EncodeToken(xml.EndElement{Name: xml.Name{Local: "div"}})
			return nil
		}
		enc.EncodeToken(xml.StartElement{Name: xml.Name{Local: name}, Attr: []xml.Attr{{Name: xml.Name{Local: "value"}, Value: v}}})
		enc.EncodeToken(xml.EndElement{Name: xml.Name{Local: name}})
	case float64:
		enc.EncodeToken(xml.StartElement{Name: xml.Name{Local: name}, Attr: []xml.Attr{{Name: xml.Name{Local: "value"}, Value: formatNumber(v)}}})
		enc.EncodeToken(xml.EndElement{Name: xml.Name{Local: name}})
	case bool:
		val := "false"
		if v {
			val = "true"
		}
		enc.EncodeToken(xml.StartElement{Name: xml.Name{Local: name}, Attr: []xml.Attr{{Name: xml.Name{Local: "value"}, Value: val}}})
		enc.EncodeToken(xml.EndElement{Name: xml.Name{Local: name}})
	case nil:
		// omit nil values
	}
	return nil
}

func encodeField(enc *xml.Encoder, key string, value any) error {
	if arr, ok := value.([]any); ok {
		for _, item := range arr {
			if err := encodeElement(enc, key, item, false); err != nil {
				return err
			}
		}
		return nil
	}
	return encodeElement(enc, key, value, false)
}

func formatNumber(f float64) string {
	// Use JSON marshalling to avoid trailing zeros while preserving precision.
	b, _ := json.Marshal(f)
	return string(b)
}

// ─── Decoder ──────────────────────────────────────────────────────────────────

// decodeElement reads from dec starting at the next StartElement and returns
// the decoded value (string for primitives, map for objects, or an array-aware
// struct). It consumes the matching EndElement.
func decodeElement(dec *xml.Decoder) (any, error) {
	// Find the next start element.
	var start xml.StartElement
	for {
		tok, err := dec.Token()
		if err == io.EOF {
			return nil, io.EOF
		}
		if err != nil {
			return nil, err
		}
		if se, ok := tok.(xml.StartElement); ok {
			start = se
			break
		}
	}
	return decodeStarted(dec, start)
}

func decodeStarted(dec *xml.Decoder, start xml.StartElement) (any, error) {
	localName := start.Name.Local

	// Check for "value" attribute → primitive.
	var valueAttr string
	var hasValueAttr bool
	for _, a := range start.Attr {
		if a.Name.Local == "value" && a.Name.Space == "" {
			valueAttr = a.Value
			hasValueAttr = true
		}
	}

	// Collect all child tokens.
	result := map[string]any{"resourceType": localName}
	childCounts := map[string]int{}
	var charData strings.Builder
	hasChildren := false

	for {
		tok, err := dec.Token()
		if err != nil {
			return nil, err
		}
		switch t := tok.(type) {
		case xml.StartElement:
			hasChildren = true
			child, err := decodeStarted(dec, t)
			if err != nil {
				return nil, err
			}
			childName := t.Name.Local
			childCounts[childName]++
			existing, exists := result[childName]
			if !exists {
				result[childName] = child
			} else if arr, ok := existing.([]any); ok {
				result[childName] = append(arr, child)
			} else {
				result[childName] = []any{existing, child}
			}
		case xml.CharData:
			charData.Write(t)
		case xml.EndElement:
			goto done
		}
	}
done:
	// If this element had no children and had a value attribute → return the scalar.
	if !hasChildren && hasValueAttr {
		return valueAttr, nil
	}
	// If this element had only character data (e.g. div XHTML) → return the string.
	if !hasChildren && !hasValueAttr && charData.Len() > 0 {
		return charData.String(), nil
	}
	// Object: remove the resourceType field for non-root elements.
	delete(result, "resourceType")
	if hasValueAttr {
		// Primitive with extension children: set the value and keep children.
		result["value"] = valueAttr
	}
	// Return just the primitive value if no children were collected.
	if len(result) == 0 {
		return "", nil
	}
	// Root object: put resourceType back.
	result["resourceType"] = localName
	return result, nil
}
