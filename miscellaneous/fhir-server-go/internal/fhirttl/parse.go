package fhirttl

import (
	"fmt"
	"strconv"
	"strings"
)

// FromTurtle parses the FHIR-flavored Turtle produced by ToTurtle back into a
// resource map. It handles the subset this package emits: a top-level blank
// node "[ a fhir:Type ; fhir:field value ; ... ]", blank nodes for objects,
// RDF collections "( … )" for arrays, and string/bool/number literals.
func FromTurtle(data []byte) (map[string]any, error) {
	tz := &ttlTokenizer{src: string(data)}
	tokens, err := tz.tokenize()
	if err != nil {
		return nil, err
	}
	p := &ttlParser{toks: tokens}
	// Skip to the first "[".
	for p.pos < len(p.toks) && p.toks[p.pos] != "[" {
		p.pos++
	}
	if p.pos >= len(p.toks) {
		return nil, fmt.Errorf("turtle: no resource node found")
	}
	node, err := p.parseNode()
	if err != nil {
		return nil, err
	}
	m, ok := node.(map[string]any)
	if !ok {
		return nil, fmt.Errorf("turtle: top-level node is not an object")
	}
	return m, nil
}

// ─── Tokenizer ──────────────────────────────────────────────────────────────

type ttlTokenizer struct {
	src string
	pos int
}

func (t *ttlTokenizer) tokenize() ([]string, error) {
	var toks []string
	for t.pos < len(t.src) {
		ch := t.src[t.pos]
		switch {
		case ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r':
			t.pos++
		case ch == '#':
			// comment to end of line
			for t.pos < len(t.src) && t.src[t.pos] != '\n' {
				t.pos++
			}
		case ch == '@':
			// @prefix … . — skip the whole directive up to the terminating " ."
			for t.pos < len(t.src) && t.src[t.pos] != '\n' {
				t.pos++
			}
		case ch == '[' || ch == ']' || ch == '(' || ch == ')' || ch == ';' || ch == ',':
			toks = append(toks, string(ch))
			t.pos++
		case ch == '"':
			s, err := t.readString()
			if err != nil {
				return nil, err
			}
			toks = append(toks, s)
		case ch == '.':
			// statement terminator (only when followed by whitespace/EOF)
			toks = append(toks, ".")
			t.pos++
		default:
			toks = append(toks, t.readBareword())
		}
	}
	return toks, nil
}

func (t *ttlTokenizer) readString() (string, error) {
	// Includes the surrounding quotes in the token so the parser knows it's a literal.
	var b strings.Builder
	b.WriteByte('"')
	t.pos++ // opening quote
	for t.pos < len(t.src) {
		ch := t.src[t.pos]
		if ch == '\\' && t.pos+1 < len(t.src) {
			next := t.src[t.pos+1]
			switch next {
			case 'n':
				b.WriteByte('\n')
			case 't':
				b.WriteByte('\t')
			default:
				b.WriteByte(next)
			}
			t.pos += 2
			continue
		}
		if ch == '"' {
			t.pos++
			b.WriteByte('"')
			return b.String(), nil
		}
		b.WriteByte(ch)
		t.pos++
	}
	return "", fmt.Errorf("turtle: unterminated string")
}

func (t *ttlTokenizer) readBareword() string {
	start := t.pos
	for t.pos < len(t.src) {
		ch := t.src[t.pos]
		if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' ||
			ch == '[' || ch == ']' || ch == '(' || ch == ')' || ch == ';' || ch == ',' {
			break
		}
		// A '.' that ends a token (followed by ws) is a terminator; a '.' inside
		// a number/word is kept. Break on trailing '.'.
		if ch == '.' && t.pos+1 < len(t.src) {
			nx := t.src[t.pos+1]
			if nx == ' ' || nx == '\t' || nx == '\n' || nx == '\r' {
				break
			}
		}
		t.pos++
	}
	return t.src[start:t.pos]
}

// ─── Parser ──────────────────────────────────────────────────────────────────

type ttlParser struct {
	toks []string
	pos  int
}

func (p *ttlParser) peek() string {
	if p.pos < len(p.toks) {
		return p.toks[p.pos]
	}
	return ""
}

func (p *ttlParser) next() string {
	t := p.peek()
	p.pos++
	return t
}

// parseNode parses an object "[ … ]", a collection "( … )", or a literal.
func (p *ttlParser) parseNode() (any, error) {
	switch p.peek() {
	case "[":
		return p.parseObject()
	case "(":
		return p.parseCollection()
	default:
		return p.parseLiteral(p.next()), nil
	}
}

func (p *ttlParser) parseObject() (map[string]any, error) {
	p.next() // consume "["
	obj := map[string]any{}
	for {
		tok := p.peek()
		if tok == "]" || tok == "" {
			p.next()
			break
		}
		if tok == ";" || tok == "," {
			p.next()
			continue
		}
		if tok == "a" {
			// "a fhir:Type" → resourceType
			p.next()
			typeTok := p.next()
			obj["resourceType"] = strings.TrimPrefix(typeTok, "fhir:")
			continue
		}
		// predicate fhir:field
		if strings.HasPrefix(tok, "fhir:") {
			field := strings.TrimPrefix(p.next(), "fhir:")
			val, err := p.parseNode()
			if err != nil {
				return nil, err
			}
			obj[field] = val
			continue
		}
		// Unknown token — skip defensively.
		p.next()
	}
	return obj, nil
}

func (p *ttlParser) parseCollection() ([]any, error) {
	p.next() // consume "("
	var arr []any
	for {
		tok := p.peek()
		if tok == ")" || tok == "" {
			p.next()
			break
		}
		item, err := p.parseNode()
		if err != nil {
			return nil, err
		}
		arr = append(arr, item)
	}
	return arr, nil
}

func (p *ttlParser) parseLiteral(tok string) any {
	if strings.HasPrefix(tok, `"`) && strings.HasSuffix(tok, `"`) && len(tok) >= 2 {
		return tok[1 : len(tok)-1]
	}
	switch tok {
	case "true":
		return true
	case "false":
		return false
	}
	if f, err := strconv.ParseFloat(tok, 64); err == nil {
		return f
	}
	return tok
}
