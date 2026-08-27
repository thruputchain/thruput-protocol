package main

import (
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

type Origin struct {
	Path string `json:"path"`
}

func (o Origin) String() string { return o.Path }

type TypeSpec struct {
	Base    string
	Pointer bool
	Suffix  string
}

func (t TypeSpec) String() string {
	star := ""
	if t.Pointer {
		star = "*"
	}
	return t.Base + star + t.Suffix
}

type Field struct {
	Name string
	Type TypeSpec
}

func (f Field) String() string { return strings.TrimSpace(f.Type.String() + " " + f.Name) }

type Proc struct {
	Name   string
	Ret    TypeSpec
	Args   []TypeSpec
	Origin Origin
}

func (p Proc) Signature() string {
	a := make([]string, len(p.Args))
	for i := range p.Args {
		a[i] = p.Args[i].String()
	}
	return fmt.Sprintf("%s %s(%s)", p.Ret.String(), p.Name, strings.Join(a, ", "))
}

type Version struct {
	Name, Namespace string
	Number          int
	Procs           map[int]Proc
	Origin          Origin
}
type Program struct {
	Name, Namespace string
	Number          int
	Versions        map[int]*Version
	Origins         []Origin
}

func (p *Program) QualifiedName() string { return qualify(p.Namespace, p.Name) }

type Struct struct {
	Name, Namespace string
	Fields          []Field
	Origin          Origin
}
type Enum struct {
	Name, Namespace string
	Cases           map[string]string
	Origin          Origin
}
type Arm struct {
	Labels []string
	Field  Field
}
type Union struct {
	Name, Namespace string
	Discriminant    Field
	Arms            []Arm
	Default         *Field
	Origin          Origin
}
type Typedef struct {
	Name, Namespace string
	Type            TypeSpec
	Origin          Origin
}
type Constant struct {
	Name, Namespace, Value string
	Origin                 Origin
}

type Model struct {
	Structs   map[string]*Struct
	Enums     map[string]*Enum
	Unions    map[string]*Union
	Typedefs  map[string]*Typedef
	Constants map[string]*Constant
	Programs  map[string]*Program
}

func newModel() *Model {
	return &Model{Structs: map[string]*Struct{}, Enums: map[string]*Enum{}, Unions: map[string]*Union{}, Typedefs: map[string]*Typedef{}, Constants: map[string]*Constant{}, Programs: map[string]*Program{}}
}
func qualify(ns, name string) string {
	if ns == "" {
		return name
	}
	return ns + "." + name
}

var (
	blockComment = regexp.MustCompile(`(?s)/\*.*?\*/`)
	lineComment  = regexp.MustCompile(`//[^\n]*`)
	passthrough  = regexp.MustCompile(`(?m)^%[^\n]*$`)
	tokenPattern = regexp.MustCompile(`[A-Za-z_][A-Za-z_0-9]*|0[xX][0-9a-fA-F]+|-?[0-9][0-9']*|[{}();=,<>&|+\-/\[\]*:]`)
	identStart   = regexp.MustCompile(`^[A-Za-z_]`)
)

func tokenize(src string) []string {
	src = blockComment.ReplaceAllString(src, " ")
	src = lineComment.ReplaceAllString(src, " ")
	src = passthrough.ReplaceAllString(src, " ")
	return tokenPattern.FindAllString(src, -1)
}

type parseError struct{ msg string }

func (e parseError) Error() string { return e.msg }
func failf(f string, a ...any)     { panic(parseError{fmt.Sprintf(f, a...)}) }

type cursor struct {
	toks []string
	i    int
}

func (c *cursor) peek(n int) string {
	if c.i+n < len(c.toks) {
		return c.toks[c.i+n]
	}
	return ""
}
func (c *cursor) next() string {
	t := c.peek(0)
	if t != "" {
		c.i++
	}
	return t
}
func (c *cursor) expect(w string) {
	if g := c.next(); g != w {
		failf("expected %q, got %q", w, g)
	}
}
func (c *cursor) accept(t string) bool {
	if c.peek(0) == t {
		c.i++
		return true
	}
	return false
}
func (c *cursor) done() bool { return c.i >= len(c.toks) }

var typeWords = map[string]bool{"unsigned": true, "int": true, "hyper": true, "float": true, "double": true, "quadruple": true, "bool": true, "void": true, "string": true, "opaque": true, "char": true, "short": true, "long": true}

func parseBase(c *cursor) string {
	var w []string
	for {
		t := c.peek(0)
		if t == "" || !identStart.MatchString(t) {
			break
		}
		if len(w) > 0 && !typeWords[t] {
			break
		}
		w = append(w, c.next())
		if !typeWords[w[len(w)-1]] {
			break
		}
	}
	if len(w) == 0 {
		failf("expected a type, got %q", c.peek(0))
	}
	return strings.Join(w, " ")
}
func parseSuffix(c *cursor) string {
	o, cl := "", ""
	if c.accept("<") {
		o, cl = "<", ">"
	} else if c.accept("[") {
		o, cl = "[", "]"
	} else {
		return ""
	}
	var b strings.Builder
	for c.peek(0) != "" && c.peek(0) != cl {
		b.WriteString(c.next())
	}
	c.expect(cl)
	return o + b.String() + cl
}
func parseTypeSpec(c *cursor) TypeSpec {
	t := TypeSpec{Base: parseTypeOrInline(c)}
	t.Pointer = c.accept("*")
	t.Suffix = parseSuffix(c)
	return t
}
func parseDeclaration(c *cursor) Field {
	t := parseTypeSpec(c)
	if t.Base == "void" {
		return Field{Type: t}
	}
	n := c.next()
	if n == "" {
		failf("expected declaration name")
	}
	if t.Suffix == "" {
		t.Suffix = parseSuffix(c)
	}
	return Field{Name: n, Type: t}
}
func parseValue(c *cursor, stops ...string) string {
	s := map[string]bool{}
	for _, x := range stops {
		s[x] = true
	}
	var b strings.Builder
	for c.peek(0) != "" && !s[c.peek(0)] {
		b.WriteString(c.next())
	}
	if b.Len() == 0 {
		failf("expected value")
	}
	return b.String()
}
func parseTypeOrInline(c *cursor) string {
	if c.peek(0) == "struct" && c.peek(1) == "{" {
		c.next()
		c.expect("{")
		var f []string
		for c.peek(0) != "" && c.peek(0) != "}" {
			d := parseDeclaration(c)
			f = append(f, d.Type.String())
			c.accept(";")
		}
		c.expect("}")
		return "struct{" + strings.Join(f, ";") + "}"
	}
	if c.peek(0) == "union" && c.peek(1) == "switch" {
		c.next()
		c.expect("switch")
		c.expect("(")
		d := parseDeclaration(c)
		c.expect(")")
		c.expect("{")
		a, def := parseArms(c)
		c.expect("}")
		return "union<" + d.Type.String() + ">{" + strings.Join(canonicalArms(a, def), ",") + "}"
	}
	if c.peek(0) == "enum" && c.peek(1) == "{" {
		c.next()
		c.expect("{")
		var cs []string
		for c.peek(0) != "" && c.peek(0) != "}" {
			n := c.next()
			v := ""
			if c.accept("=") {
				v = parseValue(c, ",", "}")
			}
			cs = append(cs, n+"="+v)
			c.accept(",")
		}
		c.expect("}")
		return "enum{" + strings.Join(cs, ",") + "}"
	}
	return parseBase(c)
}
func parseArms(c *cursor) ([]Arm, *Field) {
	var a []Arm
	var labels []string
	var def *Field
	for c.peek(0) != "" && c.peek(0) != "}" {
		if c.accept("case") {
			labels = append(labels, parseValue(c, ":"))
			c.expect(":")
			continue
		}
		if c.accept("default") {
			c.expect(":")
			f := parseDeclaration(c)
			def = &f
			c.accept(";")
			continue
		}
		f := parseDeclaration(c)
		a = append(a, Arm{Labels: append([]string{}, labels...), Field: f})
		labels = nil
		c.accept(";")
	}
	return a, def
}
func canonicalArms(a []Arm, def *Field) []string {
	p := make([]string, 0, len(a)+1)
	for _, x := range a {
		l := append([]string{}, x.Labels...)
		sort.Strings(l)
		p = append(p, strings.Join(l, "|")+"=>"+x.Field.Type.String())
	}
	if def != nil {
		p = append(p, "default=>"+def.Type.String())
	}
	sort.Strings(p)
	return p
}
func originPath(o string) string {
	if i := strings.Index(o, ":"); i >= 0 {
		return o[i+1:]
	}
	return o
}
func Parse(src string, m *Model, origin string) (err error) {
	defer func() {
		if r := recover(); r != nil {
			if pe, ok := r.(parseError); ok {
				err = fmt.Errorf("%s: %s", origin, pe.msg)
				return
			}
			panic(r)
		}
	}()
	p := parser{c: &cursor{toks: tokenize(src)}, m: m, origin: Origin{originPath(origin)}}
	p.body("")
	return nil
}

type parser struct {
	c      *cursor
	m      *Model
	origin Origin
}

func (p *parser) body(ns string) {
	for !p.c.done() && p.c.peek(0) != "}" {
		switch p.c.peek(0) {
		case ";":
			p.c.next()
		case "namespace":
			p.c.next()
			n := p.c.next()
			p.c.expect("{")
			p.body(qualify(ns, n))
			p.c.expect("}")
			p.c.accept(";")
		case "struct":
			p.parseStruct(ns)
		case "enum":
			p.parseEnum(ns)
		case "union":
			p.parseUnion(ns)
		case "typedef":
			p.parseTypedef(ns)
		case "const":
			p.parseConst(ns)
		case "program":
			p.parseProgram(ns)
		default:
			p.c.next()
		}
	}
}
func putUnique[T any](b map[string]T, k, kind string, v T) {
	if _, ok := b[k]; ok {
		failf("duplicate %s %s", kind, k)
	}
	b[k] = v
}
func (p *parser) parseStruct(ns string) {
	p.c.expect("struct")
	n := p.c.next()
	p.c.expect("{")
	var f []Field
	for p.c.peek(0) != "" && p.c.peek(0) != "}" {
		f = append(f, parseDeclaration(p.c))
		p.c.accept(";")
	}
	p.c.expect("}")
	p.c.accept(";")
	k := qualify(ns, n)
	putUnique(p.m.Structs, k, "struct", &Struct{n, ns, f, p.origin})
}
func (p *parser) parseEnum(ns string) {
	p.c.expect("enum")
	n := p.c.next()
	p.c.expect("{")
	cs := map[string]string{}
	for p.c.peek(0) != "" && p.c.peek(0) != "}" {
		cn := p.c.next()
		v := ""
		if p.c.accept("=") {
			v = parseValue(p.c, ",", "}")
		}
		if _, ok := cs[cn]; ok {
			failf("duplicate enum case %s.%s", n, cn)
		}
		cs[cn] = v
		p.c.accept(",")
	}
	p.c.expect("}")
	p.c.accept(";")
	k := qualify(ns, n)
	putUnique(p.m.Enums, k, "enum", &Enum{n, ns, cs, p.origin})
}
func (p *parser) parseUnion(ns string) {
	p.c.expect("union")
	n := p.c.next()
	p.c.expect("switch")
	p.c.expect("(")
	d := parseDeclaration(p.c)
	p.c.expect(")")
	p.c.expect("{")
	a, def := parseArms(p.c)
	p.c.expect("}")
	p.c.accept(";")
	k := qualify(ns, n)
	putUnique(p.m.Unions, k, "union", &Union{n, ns, d, a, def, p.origin})
}
func (p *parser) parseTypedef(ns string) {
	p.c.expect("typedef")
	f := parseDeclaration(p.c)
	p.c.accept(";")
	k := qualify(ns, f.Name)
	putUnique(p.m.Typedefs, k, "typedef", &Typedef{f.Name, ns, f.Type, p.origin})
}
func (p *parser) parseConst(ns string) {
	p.c.expect("const")
	n := p.c.next()
	p.c.expect("=")
	v := parseValue(p.c, ";")
	p.c.expect(";")
	k := qualify(ns, n)
	putUnique(p.m.Constants, k, "constant", &Constant{n, ns, v, p.origin})
}
func (p *parser) parseProgram(ns string) {
	p.c.expect("program")
	n := p.c.next()
	p.c.expect("{")
	vs := map[int]*Version{}
	for p.c.peek(0) != "" && p.c.peek(0) != "}" {
		if !p.c.accept("version") {
			failf("expected version in program %s, got %q", n, p.c.peek(0))
		}
		vn := p.c.next()
		p.c.expect("{")
		ps := map[int]Proc{}
		for p.c.peek(0) != "" && p.c.peek(0) != "}" {
			ret := parseTypeSpec(p.c)
			pn := p.c.next()
			p.c.expect("(")
			var args []TypeSpec
			for p.c.peek(0) != "" && p.c.peek(0) != ")" {
				a := parseTypeSpec(p.c)
				if a.Base != "void" {
					args = append(args, a)
				}
				if !p.c.accept(",") && p.c.peek(0) != ")" {
					failf("expected comma in %s", pn)
				}
			}
			p.c.expect(")")
			p.c.expect("=")
			num := parseInt(parseValue(p.c, ";"))
			p.c.accept(";")
			if _, ok := ps[num]; ok {
				failf("duplicate procedure number %d in %s.%s", num, n, vn)
			}
			ps[num] = Proc{pn, ret, args, p.origin}
		}
		p.c.expect("}")
		p.c.expect("=")
		vnum := parseInt(parseValue(p.c, ";"))
		p.c.accept(";")
		if _, ok := vs[vnum]; ok {
			failf("duplicate version number %d in program %s", vnum, n)
		}
		vs[vnum] = &Version{vn, ns, vnum, ps, p.origin}
	}
	p.c.expect("}")
	p.c.expect("=")
	pnum := parseInt(parseValue(p.c, ";"))
	p.c.accept(";")
	k := qualify(ns, n)
	if old, ok := p.m.Programs[k]; ok {
		if old.Number != pnum {
			failf("duplicate program %s has numbers 0x%x and 0x%x", k, old.Number, pnum)
		}
		for x, v := range vs {
			if _, dup := old.Versions[x]; dup {
				failf("duplicate version number %d in program %s", x, k)
			}
			old.Versions[x] = v
		}
		old.Origins = append(old.Origins, p.origin)
		return
	}
	p.m.Programs[k] = &Program{n, ns, pnum, vs, []Origin{p.origin}}
}
func parseInt(t string) int {
	t = strings.ReplaceAll(t, "'", "")
	if strings.HasPrefix(strings.ToLower(t), "0x") {
		n, e := strconv.ParseInt(t[2:], 16, 64)
		if e != nil {
			failf("bad hex number %q", t)
		}
		return int(n)
	}
	n, e := strconv.Atoi(t)
	if e != nil {
		failf("bad number %q", t)
	}
	return n
}

func (m *Model) hasType(k string) bool {
	return m.Structs[k] != nil || m.Enums[k] != nil || m.Unions[k] != nil || m.Typedefs[k] != nil
}
func (m *Model) typeKeys() map[string]bool {
	o := map[string]bool{}
	for k := range m.Structs {
		o[k] = true
	}
	for k := range m.Enums {
		o[k] = true
	}
	for k := range m.Unions {
		o[k] = true
	}
	for k := range m.Typedefs {
		o[k] = true
	}
	return o
}
func (m *Model) lookup(ns, n string) (string, bool) {
	if typeWords[n] || strings.Contains(n, "{") {
		return n, true
	}
	if k := qualify(ns, n); m.hasType(k) {
		return k, true
	}
	var got string
	count := 0
	for k := range m.typeKeys() {
		if k == n || strings.HasSuffix(k, "."+n) {
			got = k
			count++
		}
	}
	return got, count == 1
}
// constLookup resolves v by one level, returning the value as declared and
// whether v named a constant at all. An unresolvable name returns itself.
func (m *Model) constLookup(ns, v string) (string, bool) {
	if c := m.Constants[qualify(ns, v)]; c != nil {
		return c.Value, true
	}
	got := ""
	count := 0
	for k, c := range m.Constants {
		if k == v || strings.HasSuffix(k, "."+v) {
			got = c.Value
			count++
		}
	}
	if count == 1 {
		return got, true
	}
	return v, false
}

// constValue resolves v to a terminal value, following constant aliases.
//
// A constant may name another constant (`const LIMIT = BASE;`). Resolving only
// one level leaves the canonical layout as the alias name, identical on both
// revisions, so a change to the terminal value reports nothing even though the
// encoded width moved — a silent wire break. Follow the chain to its end.
//
// A cycle terminates deterministically at the name that closed it; such input
// is malformed, and looping would be worse than an arbitrary answer.
func (m *Model) constValue(ns, v string) string {
	seen := map[string]bool{}
	cur := v
	for !seen[cur] {
		seen[cur] = true
		next, ok := m.constLookup(ns, cur)
		if !ok || next == cur {
			return next
		}
		cur = next
	}
	return cur
}
func suffixParts(s string) (string, string) {
	if len(s) < 2 {
		return "", s
	}
	return s[:1], s[1 : len(s)-1]
}
func (m *Model) wireType(t TypeSpec, ns string, seen map[string]bool) string {
	b := t.Base
	if k, ok := m.lookup(ns, b); ok && m.hasType(k) {
		b = m.wireDecl(k, seen)
	}
	if t.Pointer {
		b = "optional(" + b + ")"
	}
	if t.Suffix != "" {
		kind, bound := suffixParts(t.Suffix)
		if bound != "" {
			bound = m.constValue(ns, bound)
		}
		if kind == "[" {
			b = "fixed[" + bound + "](" + b + ")"
		} else {
			b = "var<" + bound + ">(" + b + ")"
		}
	}
	return b
}
func (m *Model) wireDecl(k string, seen map[string]bool) string {
	if seen[k] {
		return "recursive(" + k + ")"
	}
	n := map[string]bool{}
	for x, v := range seen {
		n[x] = v
	}
	n[k] = true
	if d := m.Typedefs[k]; d != nil {
		return m.wireType(d.Type, d.Namespace, n)
	}
	if d := m.Structs[k]; d != nil {
		p := make([]string, len(d.Fields))
		for i, f := range d.Fields {
			p[i] = m.wireType(f.Type, d.Namespace, n)
		}
		return "struct(" + strings.Join(p, ",") + ")"
	}
	if d := m.Enums[k]; d != nil {
		// Every XDR enum is one 32-bit integer. Its cases constrain valid
		// values (checked separately by R4) but do not add bytes to a use site.
		return "enum"
	}
	if d := m.Unions[k]; d != nil {
		return m.wireUnion(d, n)
	}
	return k
}
func (m *Model) wireUnion(u *Union, seen map[string]bool) string {
	var p []string
	for _, a := range u.Arms {
		l := make([]string, len(a.Labels))
		for i, x := range a.Labels {
			l[i] = m.unionLabelValue(u, x)
		}
		sort.Strings(l)
		p = append(p, strings.Join(l, "|")+"=>"+m.wireType(a.Field.Type, u.Namespace, seen))
	}
	if u.Default != nil {
		p = append(p, "default=>"+m.wireType(u.Default.Type, u.Namespace, seen))
	}
	sort.Strings(p)
	return "union(" + m.wireType(u.Discriminant.Type, u.Namespace, seen) + ";" + strings.Join(p, ",") + ")"
}
func (m *Model) unionLabelValue(u *Union, value string) string {
	value = m.constValue(u.Namespace, value)
	if key, ok := m.lookup(u.Namespace, u.Discriminant.Type.Base); ok {
		if enum := m.Enums[key]; enum != nil {
			if enumValue, present := enum.Cases[value]; present {
				return m.constValue(enum.Namespace, enumValue)
			}
		}
	}
	return value
}
func (m *Model) procWireSignature(p Proc, ns string) string {
	a := make([]string, len(p.Args))
	for i, x := range p.Args {
		a[i] = m.wireType(x, ns, map[string]bool{})
	}
	return m.wireType(p.Ret, ns, map[string]bool{}) + "(" + strings.Join(a, ",") + ")"
}
func (m *Model) resolvedProcSignature(p Proc, ns string) string {
	a := make([]string, len(p.Args))
	for i, x := range p.Args {
		a[i] = m.wireType(x, ns, map[string]bool{})
	}
	return fmt.Sprintf("%s %s(%s)", m.wireType(p.Ret, ns, map[string]bool{}), p.Name, strings.Join(a, ", "))
}
