package store

// applyFilter parses a FHIR _filter expression and applies the resulting
// predicates to the query builder. The supported grammar subset is:
//
//	expr     = term (('and'|'or') term)*
//	term     = param op value | param 'pr' | '(' expr ')'
//	op       = 'eq'|'ne'|'co'|'sw'|'ew'|'gt'|'lt'|'ge'|'le'
//
// 'eq' maps to the default search; 'co' maps to the :contains modifier;
// 'sw' maps to the default string prefix; 'ne' maps to :not; 'gt'/'lt'/
// 'ge'/'le' are passed as FHIR date/number comparator prefixes.
// 'pr' checks for :missing=false. 'or' is implemented as an OR join.
//
// Unsupported constructs set b.err with an UnsupportedParamError.
func (b *queryBuilder) applyFilter(expr string) {
	p := &filterParser{input: expr, b: b}
	p.parseExpr()
}

type filterParser struct {
	input string
	pos   int
	b     *queryBuilder
}

func (p *filterParser) peek() string {
	p.skipWS()
	if p.pos >= len(p.input) {
		return ""
	}
	return p.input[p.pos:]
}

func (p *filterParser) skipWS() {
	for p.pos < len(p.input) && (p.input[p.pos] == ' ' || p.input[p.pos] == '\t') {
		p.pos++
	}
}

func (p *filterParser) consume(n int) {
	p.pos += n
}

// parseExpr handles the top-level and/or joining.
func (p *filterParser) parseExpr() {
	var ors []string

	first := p.parseTerm()
	if first != "" {
		ors = append(ors, first)
	}

	for {
		p.skipWS()
		rest := p.peek()
		if len(rest) >= 3 && rest[:3] == "and" && (len(rest) == 3 || rest[3] == ' ') {
			p.consume(3)
			term := p.parseTerm()
			if term != "" {
				// AND: add directly to the query builder
				if len(ors) > 0 {
					// commit accumulated OR first
					p.commitOr(ors)
					ors = ors[:0]
				}
				p.b.and(term)
			}
		} else if len(rest) >= 2 && rest[:2] == "or" && (len(rest) == 2 || rest[2] == ' ') {
			p.consume(2)
			term := p.parseTerm()
			if term != "" {
				ors = append(ors, term)
			}
		} else {
			break
		}
	}
	if len(ors) > 0 {
		p.commitOr(ors)
	}
}

func (p *filterParser) commitOr(conds []string) {
	if len(conds) == 0 {
		return
	}
	if len(conds) == 1 {
		p.b.and(conds[0])
		return
	}
	joined := "("
	for i, c := range conds {
		if i > 0 {
			joined += " OR "
		}
		joined += c
	}
	joined += ")"
	p.b.and(joined)
}

// parseTerm handles a single predicate: param op value, param pr, or (expr).
// Returns the SQL condition string (already in a form suitable for b.and()).
func (p *filterParser) parseTerm() string {
	p.skipWS()
	if p.pos >= len(p.input) {
		return ""
	}

	// Parenthesised sub-expression — evaluate in-place.
	if p.input[p.pos] == '(' {
		p.consume(1)
		p.parseExpr()
		p.skipWS()
		if p.pos < len(p.input) && p.input[p.pos] == ')' {
			p.consume(1)
		}
		return "" // already applied via parseExpr
	}

	// Read the param name (letters, digits, dashes, dots, colons).
	param := p.readToken()
	if param == "" {
		return ""
	}

	p.skipWS()
	op := p.readToken()
	if op == "" {
		return ""
	}

	// pr (present): maps to :missing=false.
	if op == "pr" {
		cond, ok := p.b.buildExistsForValue(param, "missing", "false")
		if !ok {
			return ""
		}
		return "EXISTS (" + cond + ")"
	}

	p.skipWS()
	value := p.readValue()

	// Map _filter operators to search param and modifier.
	switch op {
	case "eq":
		cond, ok := p.b.buildExistsForValue(param, "", value)
		if ok {
			return "EXISTS (" + cond + ")"
		}
	case "ne":
		cond, ok := p.b.buildExistsForValue(param, "", value)
		if ok {
			return "NOT EXISTS (" + cond + ")"
		}
	case "co":
		cond, ok := p.b.buildExistsForValue(param, "contains", value)
		if ok {
			return "EXISTS (" + cond + ")"
		}
	case "sw":
		// starts-with — default string prefix match
		cond, ok := p.b.buildExistsForValue(param, "", value)
		if ok {
			return "EXISTS (" + cond + ")"
		}
	case "gt", "lt", "ge", "le":
		// Prefix the value with the comparator so buildDateExists/buildNumberExists
		// handle it correctly (they parse comparator prefixes).
		cond, ok := p.b.buildExistsForValue(param, "", op+value)
		if ok {
			return "EXISTS (" + cond + ")"
		}
	default:
		p.b.err = &UnsupportedParamError{Msg: "_filter operator " + op + " is not supported"}
	}
	return ""
}

// readToken reads a run of non-whitespace, non-operator chars.
func (p *filterParser) readToken() string {
	p.skipWS()
	start := p.pos
	for p.pos < len(p.input) && p.input[p.pos] != ' ' && p.input[p.pos] != '\t' {
		p.pos++
	}
	return p.input[start:p.pos]
}

// readValue reads a quoted or unquoted value.
func (p *filterParser) readValue() string {
	p.skipWS()
	if p.pos >= len(p.input) {
		return ""
	}
	if p.input[p.pos] == '"' {
		p.consume(1)
		start := p.pos
		for p.pos < len(p.input) && p.input[p.pos] != '"' {
			p.pos++
		}
		val := p.input[start:p.pos]
		if p.pos < len(p.input) {
			p.consume(1) // consume closing "
		}
		return val
	}
	return p.readToken()
}
