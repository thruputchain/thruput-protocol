package main

import (
	"fmt"
	"sort"
	"strings"
)

type Finding struct {
	Rule       string `json:"rule"`
	Subject    string `json:"subject"`
	Detail     string `json:"detail"`
	Remedy     string `json:"remedy"`
	BaseOrigin string `json:"base_origin,omitempty"`
	HeadOrigin string `json:"head_origin,omitempty"`
}

func (f Finding) Render() string {
	where := ""
	if f.BaseOrigin != "" || f.HeadOrigin != "" {
		where = fmt.Sprintf("\n      source: %s -> %s", dash(f.BaseOrigin), dash(f.HeadOrigin))
	}
	return fmt.Sprintf("  %s  %s\n      %s%s\n      -> %s", f.Rule, f.Subject, f.Detail, where, f.Remedy)
}
func dash(s string) string {
	if s == "" {
		return "(absent)"
	}
	return s
}
func sortedKeys[V any](m map[string]V) []string {
	o := make([]string, 0, len(m))
	for k := range m {
		o = append(o, k)
	}
	sort.Strings(o)
	return o
}
func sortedIntKeys[V any](m map[int]V) []int {
	o := make([]int, 0, len(m))
	for k := range m {
		o = append(o, k)
	}
	sort.Ints(o)
	return o
}
func programsByNumber(m *Model) map[int]map[string]bool {
	o := map[int]map[string]bool{}
	for _, p := range m.Programs {
		if o[p.Number] == nil {
			o[p.Number] = map[string]bool{}
		}
		o[p.Number][p.QualifiedName()] = true
	}
	return o
}
func difference(a, b map[string]bool) []string {
	var o []string
	for k := range a {
		if !b[k] {
			o = append(o, k)
		}
	}
	sort.Strings(o)
	return o
}
func firstOrigin(p *Program) string {
	if len(p.Origins) == 0 {
		return ""
	}
	return p.Origins[0].Path
}
func programOrigins(m *Model, names []string) string {
	var paths []string
	for _, name := range names {
		if p := m.Programs[name]; p != nil {
			paths = append(paths, firstOrigin(p))
		}
	}
	sort.Strings(paths)
	return strings.Join(paths, ", ")
}

// stableMatches uses qualified identity first, then source-file plus short name.
// The fallback prevents a namespace-only rename from becoming a wire finding,
// while declarations with the same short name in different files remain distinct.
func stableMatches[T any](base, head map[string]T, meta func(T) (string, string)) map[string]string {
	out := map[string]string{}
	used := map[string]bool{}
	for k := range base {
		if _, ok := head[k]; ok {
			out[k] = k
			used[k] = true
		}
	}
	for bk, bv := range base {
		if _, ok := out[bk]; ok {
			continue
		}
		bn, bo := meta(bv)
		for hk, hv := range head {
			if used[hk] {
				continue
			}
			hn, ho := meta(hv)
			if bn == hn && bo == ho {
				out[bk] = hk
				used[hk] = true
				break
			}
		}
	}
	// A declaration can move files at the same time as its namespace changes.
	// Match by short name only when that name is unique among the remaining
	// declarations on both sides; otherwise treating it as identity would
	// recreate the last-wins ambiguity this checker is meant to reject.
	baseNames, headNames := map[string][]string{}, map[string][]string{}
	for bk, bv := range base {
		if _, ok := out[bk]; !ok {
			name, _ := meta(bv)
			baseNames[name] = append(baseNames[name], bk)
		}
	}
	for hk, hv := range head {
		if !used[hk] {
			name, _ := meta(hv)
			headNames[name] = append(headNames[name], hk)
		}
	}
	for name, baseKeys := range baseNames {
		if len(baseKeys) == 1 && len(headNames[name]) == 1 {
			out[baseKeys[0]] = headNames[name][0]
		}
	}
	return out
}

func Check(base, head *Model) []Finding {
	var out []Finding
	bbn, hbn := programsByNumber(base), programsByNumber(head)
	for _, num := range sortedIntKeys(hbn) {
		added := difference(hbn[num], bbn[num])
		if len(hbn[num]) > 1 && len(added) > 0 {
			out = append(out, Finding{Rule: "R8", Subject: fmt.Sprintf("program number 0x%x", num), Detail: "new owner(s) " + strings.Join(added, ", ") + " make the owner set: " + strings.Join(sortedKeys(hbn[num]), ", "), Remedy: "program numbers identify a service on the wire; allocate a distinct number (two versions of one program may share it)", HeadOrigin: programOrigins(head, sortedKeys(hbn[num]))})
		}
	}

	pm := stableMatches(base.Programs, head.Programs, func(p *Program) (string, string) { return p.Name, firstOrigin(p) })
	for _, bk := range sortedKeys(base.Programs) {
		p := base.Programs[bk]
		hk, ok := pm[bk]
		if !ok {
			out = append(out, Finding{Rule: "R7", Subject: fmt.Sprintf("program %s (0x%x)", p.Name, p.Number), Detail: "program was deleted outright", Remedy: "deprecate across a release before removing; peers still call it", BaseOrigin: firstOrigin(p)})
			continue
		}
		np := head.Programs[hk]
		if np.Number != p.Number {
			out = append(out, Finding{Rule: "R8", Subject: "program " + p.Name, Detail: fmt.Sprintf("renumbered 0x%x -> 0x%x", p.Number, np.Number), Remedy: "program numbers are permanent; peers dial the old number", BaseOrigin: firstOrigin(p), HeadOrigin: firstOrigin(np)})
		}
		for _, vn := range sortedIntKeys(p.Versions) {
			v := p.Versions[vn]
			nv, ok := np.Versions[vn]
			if !ok {
				out = append(out, Finding{Rule: "R7", Subject: fmt.Sprintf("%s version %s (=%d)", p.Name, v.Name, vn), Detail: "interface version was removed", Remedy: "serve version N alongside N+1 until peers have migrated", BaseOrigin: v.Origin.Path})
				continue
			}
			for _, pn := range sortedIntKeys(v.Procs) {
				pr := v.Procs[pn]
				npr, ok := nv.Procs[pn]
				if !ok {
					out = append(out, Finding{Rule: "R2", Subject: fmt.Sprintf("%s.%s proc %d (%s)", p.Name, v.Name, pn, pr.Name), Detail: "procedure number was removed", Remedy: "leave retired numbers reserved; never reuse them", BaseOrigin: pr.Origin.Path})
					continue
				}
				switch {
				case npr.Name != pr.Name:
					out = append(out, Finding{Rule: "R2", Subject: fmt.Sprintf("%s.%s proc %d", p.Name, v.Name, pn), Detail: fmt.Sprintf("number reused: %s -> %s", pr.Name, npr.Name), Remedy: "allocate a new procedure number instead", BaseOrigin: pr.Origin.Path, HeadOrigin: npr.Origin.Path})
				case base.procWireSignature(pr, p.Namespace) != head.procWireSignature(npr, np.Namespace):
					oldSignature, newSignature := pr.Signature(), npr.Signature()
					if oldSignature == newSignature {
						oldSignature = base.resolvedProcSignature(pr, p.Namespace)
						newSignature = head.resolvedProcSignature(npr, np.Namespace)
					}
					out = append(out, Finding{Rule: "R1", Subject: fmt.Sprintf("%s.%s proc %d (%s)", p.Name, v.Name, pn, pr.Name), Detail: fmt.Sprintf("signature changed\n         was: %s\n         now: %s", oldSignature, newSignature), Remedy: fmt.Sprintf("same number with a new layout is a SILENT break. Add a new procedure number, or declare %s version %d (R6).", p.Name, vn+1), BaseOrigin: pr.Origin.Path, HeadOrigin: npr.Origin.Path})
				}
			}
		}
	}

	sm := stableMatches(base.Structs, head.Structs, func(d *Struct) (string, string) { return d.Name, d.Origin.Path })
	for _, bk := range sortedKeys(sm) {
		a, b := base.Structs[bk], head.Structs[sm[bk]]
		if base.wireDecl(bk, map[string]bool{}) != head.wireDecl(sm[bk], map[string]bool{}) {
			old, new := fieldStrings(a.Fields), fieldStrings(b.Fields)
			out = append(out, Finding{Rule: "R3", Subject: "struct " + a.Name, Detail: fieldDelta(old, new), Remedy: "XDR is positional; a decoder cannot skip or reorder. Define a new struct and reach it from a new procedure.", BaseOrigin: a.Origin.Path, HeadOrigin: b.Origin.Path})
		}
	}

	tm := stableMatches(base.Typedefs, head.Typedefs, func(d *Typedef) (string, string) { return d.Name, d.Origin.Path })
	for _, bk := range sortedKeys(tm) {
		a, b := base.Typedefs[bk], head.Typedefs[tm[bk]]
		if base.wireDecl(bk, map[string]bool{}) != head.wireDecl(tm[bk], map[string]bool{}) {
			out = append(out, Finding{Rule: "R3", Subject: "typedef " + a.Name, Detail: fmt.Sprintf("wire layout changed\n         was: %s\n         now: %s", base.wireDecl(bk, map[string]bool{}), head.wireDecl(tm[bk], map[string]bool{})), Remedy: "typedef layouts are part of every declaration that uses them; introduce a new type and procedure/version", BaseOrigin: a.Origin.Path, HeadOrigin: b.Origin.Path})
		}
	}

	em := stableMatches(base.Enums, head.Enums, func(d *Enum) (string, string) { return d.Name, d.Origin.Path })
	for _, bk := range sortedKeys(em) {
		a, b := base.Enums[bk], head.Enums[em[bk]]
		for _, c := range sortedKeys(a.Cases) {
			ov := base.constValue(a.Namespace, a.Cases[c])
			raw, present := b.Cases[c]
			nv := head.constValue(b.Namespace, raw)
			if !present {
				out = append(out, Finding{Rule: "R4", Subject: "enum " + a.Name, Detail: fmt.Sprintf("case %s = %s was removed", c, ov), Remedy: "enum cases are append-only; retired names stay declared", BaseOrigin: a.Origin.Path, HeadOrigin: b.Origin.Path})
			} else if nv != ov {
				out = append(out, Finding{Rule: "R4", Subject: "enum " + a.Name, Detail: fmt.Sprintf("case %s renumbered %s -> %s", c, ov, nv), Remedy: "never renumber an existing case; append a new one", BaseOrigin: a.Origin.Path, HeadOrigin: b.Origin.Path})
			}
		}
	}

	um := stableMatches(base.Unions, head.Unions, func(d *Union) (string, string) { return d.Name, d.Origin.Path })
	for _, bk := range sortedKeys(um) {
		a, b := base.Unions[bk], head.Unions[um[bk]]
		if base.wireDecl(bk, map[string]bool{}) != head.wireDecl(um[bk], map[string]bool{}) {
			out = append(out, Finding{Rule: "R3", Subject: "union " + a.Name, Detail: fmt.Sprintf("wire layout changed\n         was: %s\n         now: %s", base.wireDecl(bk, map[string]bool{}), head.wireDecl(um[bk], map[string]bool{})), Remedy: "union discriminants, case values, arm payloads, and default payloads are wire layout; define a new union and procedure/version", BaseOrigin: a.Origin.Path, HeadOrigin: b.Origin.Path})
		}
	}

	wire := head.ReachableFromPrograms()
	for _, k := range sortedKeys(head.Unions) {
		u := head.Unions[k]
		if !wire[k] || u.HasDefault {
			continue
		}
		preexisting := false
		for bk, hk := range um {
			if hk == k && base.Unions[bk].HasDefault == false {
				preexisting = true
			}
		}
		if preexisting {
			continue
		}
		out = append(out, Finding{Rule: "R5", Subject: "union " + u.Name, Detail: "crosses a service boundary but has no `default:` arm", Remedy: "add `default: void;` so an old peer can decode and report rather than fail to parse", HeadOrigin: u.Origin.Path})
	}
	return out
}
func fieldStrings(fs []Field) []string {
	o := make([]string, len(fs))
	for i, f := range fs {
		o[i] = f.String()
	}
	return o
}
func fieldDelta(old, new []string) string {
	if equalStrings(old, new) {
		return "resolved field layout changed through a referenced typedef or constant"
	}
	inN := map[string]bool{}
	for _, f := range new {
		inN[f] = true
	}
	inO := map[string]bool{}
	for _, f := range old {
		inO[f] = true
	}
	var rm, add []string
	for _, f := range old {
		if !inN[f] {
			rm = append(rm, f)
		}
	}
	for _, f := range new {
		if !inO[f] {
			add = append(add, f)
		}
	}
	if len(rm) == 0 && len(add) == 0 {
		return fmt.Sprintf("fields reordered\n         was: %s\n         now: %s", strings.Join(old, ", "), strings.Join(new, ", "))
	}
	var p []string
	if len(rm) > 0 {
		p = append(p, "removed "+quoteAll(rm))
	}
	if len(add) > 0 {
		p = append(p, "added "+quoteAll(add))
	}
	return strings.Join(p, "; ")
}
func equalStrings(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}
func quoteAll(x []string) string {
	o := make([]string, len(x))
	for i, s := range x {
		o[i] = fmt.Sprintf("%q", s)
	}
	return strings.Join(o, ", ")
}
