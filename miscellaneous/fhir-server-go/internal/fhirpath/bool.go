package fhirpath

// EvaluateBool evaluates a FHIRPath boolean-result expression against a
// resource and returns (result, error). It handles the constraint sublanguage
// commonly used in StructureDefinition.constraint[].expression:
//
//   - Binary operators: implies, and, or, xor
//   - Comparisons: =, !=, <, >, <=, >= (using string representation)
//   - Path navigation with .exists(), .empty(), .count() comparisons
//   - Unary: not() as a function on a path-result
//   - .matches(regex) — substring match (full regex requires regexp package)
//   - .startsWith(str)
//
// The strategy: recursively split on the lowest-precedence binary operator,
// evaluate each side, combine. Leaf expressions are evaluated via Evaluate()
// and their truthiness is: non-empty result = true, empty = false.
//
// Precedence (lowest to highest): implies < xor < or < and < comparison < path
import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

// EvaluateBool evaluates expr as a boolean FHIRPath expression against resource.
func EvaluateBool(expr string, resource map[string]any) (bool, error) {
	expr = strings.TrimSpace(expr)
	if expr == "" {
		return true, nil
	}
	return evalBool(expr, resource)
}

func evalBool(expr string, res map[string]any) (bool, error) {
	expr = strings.TrimSpace(expr)

	// implies (lowest precedence)
	if left, right, ok := splitBinaryOp(expr, "implies"); ok {
		l, err := evalBool(left, res)
		if err != nil {
			return false, err
		}
		if !l {
			return true, nil // vacuously true
		}
		return evalBool(right, res)
	}
	// xor
	if left, right, ok := splitBinaryOp(expr, "xor"); ok {
		l, err := evalBool(left, res)
		if err != nil {
			return false, err
		}
		r, err := evalBool(right, res)
		if err != nil {
			return false, err
		}
		return l != r, nil
	}
	// or
	if left, right, ok := splitBinaryOp(expr, " or "); ok {
		l, err := evalBool(left, res)
		if err != nil {
			return false, err
		}
		if l {
			return true, nil
		}
		return evalBool(right, res)
	}
	// and
	if left, right, ok := splitBinaryOp(expr, " and "); ok {
		l, err := evalBool(left, res)
		if err != nil {
			return false, err
		}
		if !l {
			return false, nil
		}
		return evalBool(right, res)
	}

	// Comparison operators
	for _, op := range []string{"!=", "<=", ">=", "=", "<", ">"} {
		if left, right, ok := splitComparison(expr, op); ok {
			return evalComparison(left, right, op, res)
		}
	}

	// Path expression with terminal function.
	return evalPathExpr(expr, res)
}

// splitBinaryOp splits expr on the LAST occurrence of op that is not inside
// parentheses or quotes. Returns (left, right, true) or ("", "", false).
func splitBinaryOp(expr, op string) (string, string, bool) {
	depth := 0
	i := len(expr) - len(op)
	for i >= 0 {
		ch := expr[i]
		switch ch {
		case ')':
			depth++
		case '(':
			depth--
		case '"', '\'':
			// skip quoted string backwards
			j := i - 1
			for j >= 0 && expr[j] != ch {
				j--
			}
			i = j
			continue
		}
		if depth == 0 && strings.EqualFold(expr[i:i+len(op)], op) {
			left := strings.TrimSpace(expr[:i])
			right := strings.TrimSpace(expr[i+len(op):])
			if left != "" && right != "" {
				return left, right, true
			}
		}
		i--
	}
	return "", "", false
}

// splitComparison splits on the LAST comparison operator not inside parens.
func splitComparison(expr, op string) (string, string, bool) {
	return splitBinaryOp(expr, op)
}

func evalComparison(leftExpr, rightExpr, op string, res map[string]any) (bool, error) {
	lv := evalLeafStr(leftExpr, res)
	rv := evalLeafStr(rightExpr, res)
	// Try numeric comparison first.
	lf, lerr := strconv.ParseFloat(lv, 64)
	rf, rerr := strconv.ParseFloat(rv, 64)
	if lerr == nil && rerr == nil {
		switch op {
		case "=":
			return lf == rf, nil
		case "!=":
			return lf != rf, nil
		case "<":
			return lf < rf, nil
		case ">":
			return lf > rf, nil
		case "<=":
			return lf <= rf, nil
		case ">=":
			return lf >= rf, nil
		}
	}
	// String comparison.
	switch op {
	case "=":
		return lv == rv, nil
	case "!=":
		return lv != rv, nil
	case "<":
		return lv < rv, nil
	case ">":
		return lv > rv, nil
	case "<=":
		return lv <= rv, nil
	case ">=":
		return lv >= rv, nil
	}
	return false, fmt.Errorf("unknown comparison operator %q", op)
}

// evalLeafStr evaluates a leaf expression to its string representation.
// For path expressions it returns the string value of the first result.
// For quoted literals it strips the quotes.
func evalLeafStr(expr string, res map[string]any) string {
	expr = strings.TrimSpace(expr)
	if len(expr) >= 2 && (expr[0] == '\'' || expr[0] == '"') && expr[len(expr)-1] == expr[0] {
		return expr[1 : len(expr)-1]
	}
	vals, err := Evaluate(expr, res)
	if err != nil || len(vals) == 0 {
		return ""
	}
	return fmt.Sprintf("%v", vals[0])
}

// evalPathExpr handles path expressions with terminal boolean functions
// like .exists(), .empty(), .count(), .not(), .matches(), .startsWith().
func evalPathExpr(expr string, res map[string]any) (bool, error) {
	expr = strings.TrimSpace(expr)

	// Strip outer parentheses (grouping).
	if strings.HasPrefix(expr, "(") && strings.HasSuffix(expr, ")") {
		inner := strings.TrimSpace(expr[1 : len(expr)-1])
		return evalBool(inner, res)
	}

	// not(inner)
	if strings.HasPrefix(expr, "not(") && strings.HasSuffix(expr, ")") {
		inner := strings.TrimSpace(expr[4 : len(expr)-1])
		v, err := evalBool(inner, res)
		return !v, err
	}

	// Terminal functions on a path: path.func(arg)
	for _, suffix := range []string{
		".exists()", ".empty()", ".not()",
	} {
		if strings.HasSuffix(expr, suffix) {
			path := expr[:len(expr)-len(suffix)]
			vals, err := Evaluate(path, res)
			if err != nil {
				return false, nil // treat as empty
			}
			switch suffix {
			case ".exists()":
				return len(vals) > 0 && !isNilOrEmpty(vals[0]), nil
			case ".empty()":
				return len(vals) == 0 || isNilOrEmpty(vals[0]), nil
			case ".not()":
				v, _ := evalBool(path, res)
				return !v, nil
			}
		}
	}

	// .count() comparisons: path.count() op N
	if idx := strings.LastIndex(expr, ".count()"); idx >= 0 {
		path := expr[:idx]
		rest := strings.TrimSpace(expr[idx+8:])
		vals, err := Evaluate(path, res)
		cnt := 0
		if err == nil {
			cnt = len(vals)
		}
		if rest == "" {
			return cnt > 0, nil
		}
		return evalBool(fmt.Sprintf("%d%s", cnt, rest), res)
	}

	// .matches(pattern)
	if idx := strings.LastIndex(expr, ".matches("); idx >= 0 {
		path := expr[:idx]
		patStr := strings.TrimSuffix(strings.TrimPrefix(strings.TrimSpace(expr[idx+9:]), "'"), "')")
		patStr = strings.TrimSuffix(strings.TrimSuffix(patStr, "'"), ")")
		vals, err := Evaluate(path, res)
		if err != nil || len(vals) == 0 {
			return false, nil
		}
		sv := fmt.Sprintf("%v", vals[0])
		re, rerr := regexp.Compile(patStr)
		if rerr != nil {
			return strings.Contains(sv, patStr), nil // fallback to substring
		}
		return re.MatchString(sv), nil
	}

	// .startsWith(str)
	if idx := strings.LastIndex(expr, ".startsWith("); idx >= 0 {
		path := expr[:idx]
		arg := strings.TrimSuffix(strings.TrimPrefix(strings.TrimSpace(expr[idx+12:]), "'"), "')")
		arg = strings.TrimSuffix(strings.TrimSuffix(arg, "'"), ")")
		vals, err := Evaluate(path, res)
		if err != nil || len(vals) == 0 {
			return false, nil
		}
		return strings.HasPrefix(fmt.Sprintf("%v", vals[0]), arg), nil
	}

	// Bare path — truthy if non-empty.
	vals, err := Evaluate(expr, res)
	if err != nil {
		return false, nil
	}
	return len(vals) > 0 && !isNilOrEmpty(vals[0]), nil
}

func isNilOrEmpty(v any) bool {
	if v == nil {
		return true
	}
	if s, ok := v.(string); ok {
		return s == ""
	}
	return false
}
