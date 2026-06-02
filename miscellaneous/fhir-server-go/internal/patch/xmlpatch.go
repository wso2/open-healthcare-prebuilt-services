package patch

// XML Patch (RFC 5261) support for FHIR resources, content type
// application/xml-patch+xml.
//
// A diff document looks like:
//
//	<diff xmlns="http://hl7.org/fhir">
//	  <replace sel="/f:Patient/f:gender/@value">male</replace>
//	  <remove sel="/f:Patient/f:active"/>
//	  <add sel="/f:Patient" type="element"><birthDate value="1990-01-01"/></add>
//	</diff>
//
// Because the repository stores resources as JSON maps, the supported XPath
// selectors are the simple element/attribute paths FHIR tools generate:
//
//	/f:ResourceType/f:field            → field
//	/f:ResourceType/f:field[n]/f:sub   → field[n-1].sub (1-based index)
//	…/@value                           → the element's primitive value
//
// Supported operations: replace (value or element), remove, add (element).
// Full XPath expressions and namespace gymnastics beyond the f: prefix are
// not supported.

import (
	"encoding/xml"
	"fmt"
	"strconv"
	"strings"
)

// ApplyXMLPatch applies an RFC 5261 XML Patch document to a FHIR resource map.
func ApplyXMLPatch(doc map[string]any, xmlBytes []byte) (map[string]any, error) {
	ops, err := parseDiff(xmlBytes)
	if err != nil {
		return nil, err
	}
	result, err := deepCopyMap(doc)
	if err != nil {
		return nil, err
	}
	for i, op := range ops {
		ptr, err := xpathToPointer(op.sel)
		if err != nil {
			return nil, fmt.Errorf("op %d (%s %q): %w", i, op.kind, op.sel, err)
		}
		switch op.kind {
		case "replace":
			if err := jsonPatchRemove(result, ptr); err != nil {
				return nil, fmt.Errorf("op %d replace(remove) %s: %w", i, ptr, err)
			}
			if err := jsonPatchAdd(result, ptr, op.value); err != nil {
				return nil, fmt.Errorf("op %d replace(add) %s: %w", i, ptr, err)
			}
		case "remove":
			if err := jsonPatchRemove(result, ptr); err != nil {
				return nil, fmt.Errorf("op %d remove %s: %w", i, ptr, err)
			}
		case "add":
			// For add, sel points at the parent element; op.childName is the
			// new field; the JSON pointer for the child is ptr + "/" + childName.
			childPtr := ptr
			if op.childName != "" {
				childPtr = ptr + "/" + op.childName
			}
			// If the field already exists as an array, append; else set.
			if existing, err := jsonPatchGet(result, childPtr); err == nil {
				if _, isArr := existing.([]any); isArr {
					childPtr += "/-"
				}
			}
			if err := jsonPatchAdd(result, childPtr, op.value); err != nil {
				return nil, fmt.Errorf("op %d add %s: %w", i, childPtr, err)
			}
		default:
			return nil, fmt.Errorf("op %d: unsupported XML Patch operation %q", i, op.kind)
		}
	}
	return result, nil
}

type xmlPatchOp struct {
	kind      string // replace | remove | add
	sel       string // XPath selector
	value     any    // for replace/add: scalar string or decoded element value
	childName string // for add: the new element's field name
}

// parseDiff token-parses a <diff> document into operations.
func parseDiff(data []byte) ([]xmlPatchOp, error) {
	dec := xml.NewDecoder(strings.NewReader(string(data)))
	var ops []xmlPatchOp
	for {
		tok, err := dec.Token()
		if err != nil {
			break
		}
		se, ok := tok.(xml.StartElement)
		if !ok {
			continue
		}
		kind := se.Name.Local
		if kind != "replace" && kind != "remove" && kind != "add" {
			continue
		}
		op := xmlPatchOp{kind: kind}
		for _, a := range se.Attr {
			if a.Name.Local == "sel" {
				op.sel = a.Value
			}
		}
		switch kind {
		case "remove":
			// self-closing or empty — consume to end element
			dec.Skip()
		case "replace":
			// text content is the new value
			var inner struct {
				Text  string     `xml:",chardata"`
				Child []xmlRaw   `xml:",any"`
			}
			if err := dec.DecodeElement(&inner, &se); err != nil {
				return nil, err
			}
			if len(inner.Child) > 0 {
				op.childName = inner.Child[0].XMLName.Local
				op.value = decodeRawElement(inner.Child[0])
			} else {
				op.value = strings.TrimSpace(inner.Text)
			}
		case "add":
			var inner struct {
				Child []xmlRaw `xml:",any"`
			}
			if err := dec.DecodeElement(&inner, &se); err != nil {
				return nil, err
			}
			if len(inner.Child) > 0 {
				op.childName = inner.Child[0].XMLName.Local
				op.value = decodeRawElement(inner.Child[0])
			}
		}
		ops = append(ops, op)
	}
	if len(ops) == 0 {
		return nil, fmt.Errorf("no replace/remove/add operations found in XML Patch diff")
	}
	return ops, nil
}

// xmlRaw captures an arbitrary FHIR XML element: a value attribute and/or
// nested children.
type xmlRaw struct {
	XMLName xml.Name
	Attrs   []xml.Attr `xml:",any,attr"`
	Child   []xmlRaw   `xml:",any"`
}

// decodeRawElement converts an xmlRaw FHIR element into a JSON value:
// a scalar string if it has only a value attribute, else a nested map.
func decodeRawElement(e xmlRaw) any {
	var valueAttr string
	hasValue := false
	for _, a := range e.Attrs {
		if a.Name.Local == "value" {
			valueAttr = a.Value
			hasValue = true
		}
	}
	if len(e.Child) == 0 {
		if hasValue {
			return valueAttr
		}
		return ""
	}
	out := map[string]any{}
	for _, c := range e.Child {
		name := c.XMLName.Local
		v := decodeRawElement(c)
		if existing, ok := out[name]; ok {
			if arr, isArr := existing.([]any); isArr {
				out[name] = append(arr, v)
			} else {
				out[name] = []any{existing, v}
			}
		} else {
			out[name] = v
		}
	}
	return out
}

// xpathToPointer converts a simple FHIR XPath selector to a JSON Pointer.
// "/f:Patient/f:name[1]/f:family/@value" → "/name/0/family"
// The leading resource type segment and the trailing /@value are stripped.
func xpathToPointer(sel string) (string, error) {
	sel = strings.TrimSpace(sel)
	if sel == "" {
		return "", fmt.Errorf("empty selector")
	}
	sel = strings.TrimSuffix(sel, "/@value")
	parts := strings.Split(strings.TrimPrefix(sel, "/"), "/")
	if len(parts) == 0 {
		return "", fmt.Errorf("invalid selector %q", sel)
	}
	var ptr strings.Builder
	for i, p := range parts {
		if i == 0 {
			continue // skip the resource-type root segment
		}
		field := strings.TrimPrefix(p, "f:")
		// Handle [n] index → /field/(n-1)
		if idx := strings.IndexByte(field, '['); idx >= 0 {
			name := field[:idx]
			numStr := strings.TrimSuffix(field[idx+1:], "]")
			n, err := strconv.Atoi(numStr)
			if err != nil || n < 1 {
				return "", fmt.Errorf("invalid index in %q", p)
			}
			ptr.WriteString("/" + name + "/" + strconv.Itoa(n-1))
		} else {
			ptr.WriteString("/" + field)
		}
	}
	return ptr.String(), nil
}
