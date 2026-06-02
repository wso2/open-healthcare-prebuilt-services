// Package patch implements JSON Patch (RFC 6902) and FHIR Patch applied to
// FHIR resource maps.
//
// # JSON Patch (RFC 6902)
//
// Content-Type: application/json-patch+json
// Body is an array of operation objects with op, path (JSON Pointer per
// RFC 6901), and optionally value/from.
// Supported operations: add, remove, replace, copy, move, test.
//
// # FHIR Patch
//
// Content-Type: application/fhir+json (resourceType = "Parameters")
// Each parameter named "operation" has parts: type (add|delete|replace|move|
// insert|reorder), path (FHIRPath), and optionally name/value/index.
// This implementation supports: replace (simple path, scalar value),
// add (append to array or set scalar), delete.
package patch

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
)

// ApplyJSONPatch applies RFC 6902 JSON Patch operations to doc (in-place copy).
// doc is not mutated; a modified copy is returned.
func ApplyJSONPatch(doc map[string]any, ops []map[string]any) (map[string]any, error) {
	// Work on a deep copy so the original is unchanged on error.
	result, err := deepCopyMap(doc)
	if err != nil {
		return nil, err
	}
	for i, op := range ops {
		opName, _ := op["op"].(string)
		path, _ := op["path"].(string)
		from, _ := op["from"].(string)

		switch opName {
		case "add":
			if err := jsonPatchAdd(result, path, op["value"]); err != nil {
				return nil, fmt.Errorf("op %d (add %s): %w", i, path, err)
			}
		case "remove":
			if err := jsonPatchRemove(result, path); err != nil {
				return nil, fmt.Errorf("op %d (remove %s): %w", i, path, err)
			}
		case "replace":
			if err := jsonPatchRemove(result, path); err != nil {
				return nil, fmt.Errorf("op %d (replace %s): %w", i, path, err)
			}
			if err := jsonPatchAdd(result, path, op["value"]); err != nil {
				return nil, fmt.Errorf("op %d (replace %s add): %w", i, path, err)
			}
		case "move":
			val, err := jsonPatchGet(result, from)
			if err != nil {
				return nil, fmt.Errorf("op %d (move from %s): %w", i, from, err)
			}
			if err := jsonPatchRemove(result, from); err != nil {
				return nil, fmt.Errorf("op %d (move remove %s): %w", i, from, err)
			}
			if err := jsonPatchAdd(result, path, val); err != nil {
				return nil, fmt.Errorf("op %d (move add %s): %w", i, path, err)
			}
		case "copy":
			val, err := jsonPatchGet(result, from)
			if err != nil {
				return nil, fmt.Errorf("op %d (copy from %s): %w", i, from, err)
			}
			if err := jsonPatchAdd(result, path, val); err != nil {
				return nil, fmt.Errorf("op %d (copy add %s): %w", i, path, err)
			}
		case "test":
			val, err := jsonPatchGet(result, path)
			if err != nil {
				return nil, fmt.Errorf("op %d (test %s): %w", i, path, err)
			}
			if !deepEq(val, op["value"]) {
				return nil, fmt.Errorf("op %d: test failed: %s value %v != %v", i, path, val, op["value"])
			}
		default:
			return nil, fmt.Errorf("op %d: unknown op %q", i, opName)
		}
	}
	return result, nil
}

// ApplyFHIRPatch applies FHIR Patch operations (from a Parameters resource body)
// to doc. Supported operation types: replace, add, delete.
func ApplyFHIRPatch(doc map[string]any, params map[string]any) (map[string]any, error) {
	if rt, _ := params["resourceType"].(string); rt != "Parameters" {
		return nil, fmt.Errorf("FHIR Patch body must be a Parameters resource, got %q", rt)
	}
	result, err := deepCopyMap(doc)
	if err != nil {
		return nil, err
	}
	parameters, _ := params["parameter"].([]any)
	for i, raw := range parameters {
		p, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		if name, _ := p["name"].(string); name != "operation" {
			continue
		}
		parts := paramParts(p)
		opType, _ := parts["type"].(string)
		path, _ := parts["path"].(string)
		if path == "" {
			return nil, fmt.Errorf("parameter %d: missing path", i)
		}
		// Convert FHIRPath to JSON Pointer (simple: replace '.' with '/')
		ptr := fhirPathToPointer(path)

		switch opType {
		case "replace":
			val := fhirParamValue(parts)
			if err := jsonPatchRemove(result, ptr); err != nil {
				return nil, fmt.Errorf("FHIR Patch replace (remove) %s: %w", path, err)
			}
			if err := jsonPatchAdd(result, ptr, val); err != nil {
				return nil, fmt.Errorf("FHIR Patch replace (add) %s: %w", path, err)
			}
		case "add":
			val := fhirParamValue(parts)
			if err := jsonPatchAdd(result, ptr, val); err != nil {
				return nil, fmt.Errorf("FHIR Patch add %s: %w", path, err)
			}
		case "delete":
			if err := jsonPatchRemove(result, ptr); err != nil {
				return nil, fmt.Errorf("FHIR Patch delete %s: %w", path, err)
			}
		case "move":
			// move: remove value at source path (parts["source"]) and insert at ptr.
			// source may be a FHIRPath string or an integer array index.
			var srcPtr string
			switch sv := parts["source"].(type) {
			case string:
				if sv == "" {
					return nil, fmt.Errorf("FHIR Patch move: missing source part")
				}
				srcPtr = fhirPathToPointer(sv)
			case float64:
				srcPtr = fmt.Sprintf("%s/%d", ptr, int(sv))
			default:
				return nil, fmt.Errorf("FHIR Patch move: source must be a path string or integer index")
			}
			val, err := jsonPatchGet(result, srcPtr)
			if err != nil {
				return nil, fmt.Errorf("FHIR Patch move source %s: %w", srcPtr, err)
			}
			if err := jsonPatchRemove(result, srcPtr); err != nil {
				return nil, fmt.Errorf("FHIR Patch move remove %s: %w", srcPtr, err)
			}
			// Destination: if parts["index"] is an integer, use ptr/index;
			// otherwise treat ptr as the full destination path.
			dstPtr := ptr
			if dstIdxRaw, ok := parts["index"]; ok {
				switch v := dstIdxRaw.(type) {
				case float64:
					dstPtr = fmt.Sprintf("%s/%d", ptr, int(v))
				}
			}
			if err := jsonPatchAdd(result, dstPtr, val); err != nil {
				return nil, fmt.Errorf("FHIR Patch move insert %s: %w", dstPtr, err)
			}
		case "insert":
			// insert: add value at a specific array index. parts["index"] is the
			// position (integer), parts["value"] is the value to insert.
			val := fhirParamValue(parts)
			idxRaw, _ := parts["index"]
			var idx int
			switch v := idxRaw.(type) {
			case float64:
				idx = int(v)
			case string:
				fmt.Sscanf(v, "%d", &idx)
			}
			// Build a JSON-Pointer path with the index appended.
			indexedPtr := fmt.Sprintf("%s/%d", ptr, idx)
			if err := jsonPatchAdd(result, indexedPtr, val); err != nil {
				return nil, fmt.Errorf("FHIR Patch insert %s[%d]: %w", ptr, idx, err)
			}
		case "reorder":
			// reorder: parts["index"] is the new position for the element currently
			// at parts["source"] index. Move from source to destination index.
			srcIdxRaw, _ := parts["source"]
			dstIdxRaw, _ := parts["index"]
			var srcIdx, dstIdx int
			switch v := srcIdxRaw.(type) {
			case float64:
				srcIdx = int(v)
			case string:
				fmt.Sscanf(v, "%d", &srcIdx)
			}
			switch v := dstIdxRaw.(type) {
			case float64:
				dstIdx = int(v)
			case string:
				fmt.Sscanf(v, "%d", &dstIdx)
			}
			srcPtr := fmt.Sprintf("%s/%d", ptr, srcIdx)
			val, err := jsonPatchGet(result, srcPtr)
			if err != nil {
				return nil, fmt.Errorf("FHIR Patch reorder source %s[%d]: %w", path, srcIdx, err)
			}
			if err := jsonPatchRemove(result, srcPtr); err != nil {
				return nil, fmt.Errorf("FHIR Patch reorder remove: %w", err)
			}
			dstPtr := fmt.Sprintf("%s/%d", ptr, dstIdx)
			if err := jsonPatchAdd(result, dstPtr, val); err != nil {
				return nil, fmt.Errorf("FHIR Patch reorder insert: %w", err)
			}
		default:
			return nil, fmt.Errorf("unknown FHIR Patch operation type %q", opType)
		}
	}
	return result, nil
}

// ─── JSON Pointer helpers ─────────────────────────────────────────────────────

// parsePointer splits an RFC 6901 JSON Pointer into segments, unescaping ~1 → /
// and ~0 → ~. Leading "/" is stripped; "" → nil (root).
func parsePointer(ptr string) ([]string, error) {
	if ptr == "" {
		return nil, nil
	}
	if !strings.HasPrefix(ptr, "/") {
		return nil, fmt.Errorf("JSON Pointer must start with /: %q", ptr)
	}
	parts := strings.Split(ptr[1:], "/")
	for i, p := range parts {
		parts[i] = strings.ReplaceAll(strings.ReplaceAll(p, "~1", "/"), "~0", "~")
	}
	return parts, nil
}

func jsonPatchGet(doc map[string]any, ptr string) (any, error) {
	parts, err := parsePointer(ptr)
	if err != nil {
		return nil, err
	}
	var cur any = doc
	for _, key := range parts {
		switch v := cur.(type) {
		case map[string]any:
			cur = v[key]
		case []any:
			idx, e := parseIndex(key, len(v))
			if e != nil {
				return nil, e
			}
			cur = v[idx]
		default:
			return nil, fmt.Errorf("cannot navigate into %T at %q", cur, key)
		}
	}
	return cur, nil
}

func jsonPatchAdd(doc map[string]any, ptr string, val any) error {
	parts, err := parsePointer(ptr)
	if err != nil {
		return err
	}
	if len(parts) == 0 {
		return fmt.Errorf("cannot add to root document")
	}
	parent, last := navigate(doc, parts)
	if parent == nil {
		return fmt.Errorf("parent path not found for %q", ptr)
	}
	switch p := parent.(type) {
	case map[string]any:
		p[last] = val
	case []any:
		if last == "-" {
			// append
			p = append(p, val)
			setAt(doc, parts[:len(parts)-1], p)
		} else {
			idx, e := parseInsertIndex(last, len(p))
			if e != nil {
				return e
			}
			p = append(p[:idx], append([]any{val}, p[idx:]...)...)
			setAt(doc, parts[:len(parts)-1], p)
		}
	default:
		return fmt.Errorf("cannot add to %T at %q", parent, last)
	}
	return nil
}

func jsonPatchRemove(doc map[string]any, ptr string) error {
	parts, err := parsePointer(ptr)
	if err != nil {
		return err
	}
	if len(parts) == 0 {
		return fmt.Errorf("cannot remove root")
	}
	parent, last := navigate(doc, parts)
	if parent == nil {
		return fmt.Errorf("parent path not found for %q", ptr)
	}
	switch p := parent.(type) {
	case map[string]any:
		if _, ok := p[last]; !ok {
			return fmt.Errorf("key %q not found", last)
		}
		delete(p, last)
	case []any:
		idx, e := parseIndex(last, len(p))
		if e != nil {
			return e
		}
		newP := append(p[:idx], p[idx+1:]...)
		setAt(doc, parts[:len(parts)-1], newP)
	default:
		return fmt.Errorf("cannot remove from %T at %q", parent, last)
	}
	return nil
}

// navigate walks parts and returns (the value at that path, lastKey).
// Used by add/remove to reach the parent container.
// parts here is the full path including the final key.
// Returns (parentContainer, lastKey). parent is the container holding lastKey.
func navigate(doc map[string]any, parts []string) (any, string) {
	if len(parts) == 0 {
		return nil, ""
	}
	last := parts[len(parts)-1]
	if len(parts) == 1 {
		return doc, last
	}
	var cur any = doc
	for _, key := range parts[:len(parts)-1] {
		switch v := cur.(type) {
		case map[string]any:
			cur = v[key]
		case []any:
			idx, e := parseIndex(key, len(v))
			if e != nil {
				return nil, ""
			}
			cur = v[idx]
		default:
			return nil, ""
		}
	}
	return cur, last
}

// setAt writes val at the path given by parts in doc. Used to write back a
// newly constructed slice when an add/remove changes it.
func setAt(doc map[string]any, parts []string, val any) {
	if len(parts) == 0 {
		return
	}
	var cur any = doc
	for i, key := range parts[:len(parts)-1] {
		_ = i
		switch v := cur.(type) {
		case map[string]any:
			cur = v[key]
		}
	}
	if m, ok := cur.(map[string]any); ok {
		m[parts[len(parts)-1]] = val
	}
}

// parseIndex parses an array index that must reference an EXISTING element
// (0 <= idx < length). Used by get/remove/navigate, where idx==length is
// out of range.
func parseIndex(key string, length int) (int, error) {
	idx, err := strconv.Atoi(key)
	if err != nil || idx < 0 || idx >= length {
		return 0, fmt.Errorf("array index %q out of range (len=%d)", key, length)
	}
	return idx, nil
}

// parseInsertIndex parses an array index for insertion, where "-" or
// idx==length means "append at the end" (0 <= idx <= length). Used by add.
func parseInsertIndex(key string, length int) (int, error) {
	if key == "-" {
		return length, nil
	}
	idx, err := strconv.Atoi(key)
	if err != nil || idx < 0 || idx > length {
		return 0, fmt.Errorf("array index %q out of range (len=%d)", key, length)
	}
	return idx, nil
}

func deepEq(a, b any) bool {
	aj, _ := json.Marshal(a)
	bj, _ := json.Marshal(b)
	return string(aj) == string(bj)
}

func deepCopyMap(m map[string]any) (map[string]any, error) {
	b, err := json.Marshal(m)
	if err != nil {
		return nil, err
	}
	var out map[string]any
	if err := json.Unmarshal(b, &out); err != nil {
		return nil, err
	}
	return out, nil
}

// ─── FHIR Patch helpers ───────────────────────────────────────────────────────

// paramParts extracts the "part" array of a Parameters.parameter into a flat
// name→value map, treating valueX as the value field.
func paramParts(p map[string]any) map[string]any {
	out := make(map[string]any)
	parts, _ := p["part"].([]any)
	for _, raw := range parts {
		part, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		name, _ := part["name"].(string)
		if name == "" {
			continue
		}
		for k, v := range part {
			if strings.HasPrefix(k, "value") {
				out[name] = v
				break
			}
		}
	}
	return out
}

// fhirParamValue finds the "value" part entry, handling valueString,
// valueCode, valueBoolean, valueInteger, etc.
func fhirParamValue(parts map[string]any) any {
	return parts["value"]
}

// fhirPathToPointer converts a simple FHIRPath to a JSON Pointer by:
//   - stripping the resource type prefix (Patient.active → /active)
//   - converting dots to slashes
//   - converting [n] array indexers to /n
//
// This is an approximation; full FHIRPath semantics are not supported.
func fhirPathToPointer(path string) string {
	// Strip resource-type prefix if present.
	if i := strings.IndexByte(path, '.'); i >= 0 {
		path = path[i+1:]
	}
	// Convert [n] → /n, then . → /
	path = strings.ReplaceAll(path, "[", "/")
	path = strings.ReplaceAll(path, "]", "")
	path = strings.ReplaceAll(path, ".", "/")
	return "/" + path
}
