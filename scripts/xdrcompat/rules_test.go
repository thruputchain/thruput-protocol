package main

import (
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"
)

func model(t *testing.T, files map[string]string) *Model {
	t.Helper()
	m := newModel()
	for _, path := range sortedKeys(files) {
		if err := Parse(files[path], m, path); err != nil {
			t.Fatal(err)
		}
	}
	return m
}
func pair(t *testing.T, base, head string) (*Model, *Model) {
	t.Helper()
	return model(t, map[string]string{"wire.x": base}), model(t, map[string]string{"wire.x": head})
}
func fixture(t *testing.T, rule, outcome, rev string) *Model {
	t.Helper()
	p := filepath.Join("testdata", rule, outcome, rev+".x")
	b, e := os.ReadFile(p)
	if e != nil {
		t.Fatal(e)
	}
	return model(t, map[string]string{p: string(b)})
}
func core(fs []Finding) [][4]string {
	o := make([][4]string, len(fs))
	for i, f := range fs {
		o[i] = [4]string{f.Rule, f.Subject, f.Detail, f.Remedy}
	}
	return o
}
func exact(t *testing.T, got []Finding, want ...[4]string) {
	t.Helper()
	if len(got) == 0 && len(want) == 0 {
		return
	}
	if !reflect.DeepEqual(core(got), want) {
		t.Fatalf("findings mismatch\n got: %#v\nwant: %#v", core(got), want)
	}
}

func TestOriginalRuleFixturesAreExact(t *testing.T) {
	cases := []struct {
		rule string
		want [4]string
	}{
		{"r1", [4]string{"R1", "P.P1 proc 1 (call)", "signature changed\n         was: int call(int)\n         now: hyper call(int)", "same number with a new layout is a SILENT break. Add a new procedure number, or declare P version 2 (R6)."}},
		{"r2", [4]string{"R2", "P.P1 proc 1", "number reused: old_name -> reused", "allocate a new procedure number instead"}},
		{"r3", [4]string{"R3", "struct Payload", "added \"int second\"", "XDR is positional; a decoder cannot skip or reorder. Define a new struct and reach it from a new procedure."}},
		{"r4", [4]string{"R4", "enum State", "case DONE renumbered 1 -> 2", "never renumber an existing case; append a new one"}},
		{"r5", [4]string{"R3", "union Result", "wire layout changed\n         was: union(enum;0=>int,default=>void)\n         now: union(enum;0=>int)", "union discriminants, case values, arm payloads, and default payloads are wire layout; define a new union and procedure/version"}},
		{"r7", [4]string{"R7", "program P (0x1001)", "program was deleted outright", "deprecate across a release before removing; peers still call it"}},
		{"r8", [4]string{"R8", "program number 0x1001", "new owner(s) B make the owner set: A, B", "program numbers identify a service on the wire; allocate a distinct number (two versions of one program may share it)"}},
	}
	for _, tc := range cases {
		t.Run(tc.rule+" fail", func(t *testing.T) {
			got := Check(fixture(t, tc.rule, "fail", "base"), fixture(t, tc.rule, "fail", "head"))
			if tc.rule == "r5" { // R5 and the newly complete union-layout rule are both intentional.
				exact(t, got,
					[4]string{"R1", "P.P1 proc 1 (call)", "signature changed\n         was: union(enum;0=>int,default=>void) call()\n         now: union(enum;0=>int) call()", "same number with a new layout is a SILENT break. Add a new procedure number, or declare P version 2 (R6)."},
					tc.want,
					[4]string{"R5", "union Result", "crosses a service boundary but has no `default:` arm", "add `default: void;` so an old peer can decode and report rather than fail to parse"},
				)
				return
			}
			if tc.rule == "r8" {
				exact(t, got, tc.want, [4]string{"R8", "program B", "renumbered 0x1002 -> 0x1001", "program numbers are permanent; peers dial the old number"})
			} else {
				exact(t, got, tc.want)
			}
		})
		t.Run(tc.rule+" pass", func(t *testing.T) {
			exact(t, Check(fixture(t, tc.rule, "pass", "base"), fixture(t, tc.rule, "pass", "head")))
		})
	}
}

func TestTypedefWireLayouts(t *testing.T) {
	cases := [][2]string{
		{"typedef opaque Payload<16>;", "typedef string Payload<32>;"},
		{"typedef opaque Hash[32];", "typedef opaque Hash<32>;"},
		{"struct Item { int n; }; typedef Item MaybeItem;", "struct Item { int n; }; typedef Item *MaybeItem;"},
		{"typedef int Handle;", "typedef hyper Handle;"},
		// Declared text is byte-identical on both sides; only the resolved
		// bound moves. Guards against reporting the unresolved declaration,
		// which rendered as "int[MAXN] -> int[MAXN]" and read as a false
		// positive.
		{"const MAXN = 4; typedef int Arr[MAXN];", "const MAXN = 8; typedef int Arr[MAXN];"},
		// The bound is reached through a constant alias chain. Resolving only
		// one level leaves both sides as the alias name "BASE", identical, and
		// reports nothing despite the encoded width moving.
		{"const BASE = 4; const LIMIT = BASE; typedef int Arr[LIMIT];", "const BASE = 8; const LIMIT = BASE; typedef int Arr[LIMIT];"},
	}
	for _, c := range cases {
		b, h := pair(t, c[0], c[1])
		got := Check(b, h)
		if len(got) != 1 || got[0].Rule != "R3" || got[0].Subject != "typedef "+firstTypedef(b) || got[0].Remedy != "typedef layouts are part of every declaration that uses them; introduce a new type and procedure/version" {
			t.Fatalf("unexpected exact finding: %#v", core(got))
		}
		was := b.wireDecl(sortedKeys(b.Typedefs)[0], map[string]bool{})
		now := h.wireDecl(sortedKeys(h.Typedefs)[0], map[string]bool{})
		if got[0].Detail != "wire layout changed\n         was: "+was+"\n         now: "+now {
			t.Fatalf("detail: %q", got[0].Detail)
		}
		// A finding whose two rendered layouts are identical is unreadable:
		// it presents as a false positive even when the detection is correct.
		if was == now {
			t.Fatalf("rendered layouts are identical (%q); the message cannot show what changed", was)
		}
	}
}
func firstTypedef(m *Model) string { return m.Typedefs[sortedKeys(m.Typedefs)[0]].Name }

func TestConstantsResolveInBoundsAndEnums(t *testing.T) {
	b, h := pair(t, "const LIMIT = 16; struct Packet { opaque bytes[LIMIT]; };", "const LIMIT = 32; struct Packet { opaque bytes[LIMIT]; };")
	exact(t, Check(b, h), [4]string{"R3", "struct Packet", "resolved field layout changed through a referenced typedef or constant", "XDR is positional; a decoder cannot skip or reorder. Define a new struct and reach it from a new procedure."})
	b, h = pair(t, "const DONE_VALUE = 1; enum State { READY = 0, DONE = DONE_VALUE };", "const DONE_VALUE = 2; enum State { READY = 0, DONE = DONE_VALUE };")
	exact(t, Check(b, h), [4]string{"R4", "enum State", "case DONE renumbered 1 -> 2", "never renumber an existing case; append a new one"})
}

func TestUnionLayoutAndArmOrder(t *testing.T) {
	b, h := pair(t, "union Choice switch (int kind) { case 0: int n; default: void; };", "union Choice switch (bool kind) { case 1: hyper n; default: int fallback; };")
	exact(t, Check(b, h), [4]string{"R3", "union Choice", "wire layout changed\n         was: union(int;0=>int,default=>void)\n         now: union(bool;1=>hyper,default=>int)", "union discriminants, case values, arm payloads, and default payloads are wire layout; define a new union and procedure/version"})
	b, h = pair(t, "union Choice switch (int kind) { case 0: int n; case 1: hyper h; default: void; };", "union Choice switch (int kind) { case 1: hyper h; case 0: int n; default: void; };")
	exact(t, Check(b, h))
}

func TestProcedureQualifiersAreWireSignificant(t *testing.T) {
	b, h := pair(t, "program P { version P1 { void send(opaque[16]) = 1; opaque[8] receive(void) = 2; } = 1; } = 0x1001;", "program P { version P1 { void send(opaque<32>) = 1; opaque<8> receive(void) = 2; } = 1; } = 0x1001;")
	got := Check(b, h)
	if len(got) != 2 {
		t.Fatalf("got %#v", core(got))
	}
	if got[0].Rule != "R1" || got[0].Subject != "P.P1 proc 1 (send)" || got[0].Detail != "signature changed\n         was: void send(opaque[16])\n         now: void send(opaque<32>)" {
		t.Fatalf("send: %#v", core(got))
	}
	if got[1].Subject != "P.P1 proc 2 (receive)" || got[1].Detail != "signature changed\n         was: opaque[8] receive()\n         now: opaque<8> receive()" {
		t.Fatalf("receive: %#v", core(got))
	}
	for _, f := range got {
		if f.Remedy != "same number with a new layout is a SILENT break. Add a new procedure number, or declare P version 2 (R6)." {
			t.Fatalf("remedy %q", f.Remedy)
		}
	}
}

func TestNamespacesDoNotOverwriteAndRenameAloneIsQuiet(t *testing.T) {
	base := model(t, map[string]string{"a.x": "namespace A { struct Item { int value; }; }", "b.x": "namespace B { struct Item { int value; }; }"})
	head := model(t, map[string]string{"a.x": "namespace A { struct Item { hyper value; }; }", "b.x": "namespace B { struct Item { int value; }; }"})
	exact(t, Check(base, head), [4]string{"R3", "struct Item", "removed \"int value\"; added \"hyper value\"", "XDR is positional; a decoder cannot skip or reorder. Define a new struct and reach it from a new procedure."})
	base = model(t, map[string]string{"a.x": "namespace Old { struct Item { int value; }; }"})
	head = model(t, map[string]string{"a.x": "namespace New { struct Item { int value; }; }"})
	exact(t, Check(base, head))
	base = model(t, map[string]string{"old.x": "namespace Old { struct Unique { int value; }; }"})
	head = model(t, map[string]string{"new.x": "namespace New { struct Unique { hyper value; }; }"})
	exact(t, Check(base, head), [4]string{"R3", "struct Unique", "removed \"int value\"; added \"hyper value\"", "XDR is positional; a decoder cannot skip or reorder. Define a new struct and reach it from a new procedure."})
}

func TestAmbiguousDuplicatesAreErrors(t *testing.T) {
	cases := map[string]string{"declaration": "struct Item { int n; }; struct Item { hyper n; };", "program": "program P { version P1 { void a(void)=1; }=1; }=1; program P { version P2 { void b(void)=2; }=2; }=2;", "version": "program P { version P1 { void a(void)=1; }=1; version PAgain { void b(void)=2; }=1; }=1;", "procedure": "program P { version P1 { void a(void)=1; void b(void)=1; }=1; }=1;"}
	for name, src := range cases {
		t.Run(name, func(t *testing.T) {
			if err := Parse(src, newModel(), "dup.x"); err == nil || !strings.Contains(err.Error(), "duplicate") {
				t.Fatalf("expected duplicate error, got %v", err)
			}
		})
	}
	// The sanctioned arrangement is the same program number and identity split into distinct versions.
	m := newModel()
	if err := Parse("program Repair { version Repair1 { void a(void)=1; }=1; }=0x2233cccc;", m, "repair.x"); err != nil {
		t.Fatal(err)
	}
	if err := Parse("program Repair { version Repair2 { void b(void)=2; }=2; }=0x2233cccc;", m, "repair2.x"); err != nil {
		t.Fatal(err)
	}
	if len(m.Programs) != 1 || len(m.Programs["Repair"].Versions) != 2 {
		t.Fatalf("bad merge: %#v", m.Programs)
	}
}

func TestR8OwnerSetGrandfathering(t *testing.T) {
	baseSrc := "program SchedDb { version A1 { void a(void)=1; }=1; }=0x7ee79998; program SchedEvent { version B1 { void b(void)=1; }=1; }=0x7ee79998;" +
		" program AuthMempool { version C1 { void c(void)=1; }=1; }=0x8aa87aa7; program Wallet { version D1 { void d(void)=1; }=1; }=0x8aa87aa7;"
	b, h := pair(t, baseSrc, baseSrc+" program Attacker { version X1 { void x(void)=1; }=1; }=0x7ee79998;")
	exact(t, Check(b, h), [4]string{"R8", "program number 0x7ee79998", "new owner(s) Attacker make the owner set: Attacker, SchedDb, SchedEvent", "program numbers identify a service on the wire; allocate a distinct number (two versions of one program may share it)"})
	// Existing exact owner sets remain grandfathered.
	b, h = pair(t, baseSrc, baseSrc)
	exact(t, Check(b, h))
}

func TestParserHandlesAnonymousInlineAggregates(t *testing.T) {
	m := model(t, map[string]string{"inline.x": "struct Envelope { union switch (int version) { case 0: struct { int count; opaque digest[32]; } v0; default: void; } body; };"})
	d := m.Structs["Envelope"]
	if d == nil || len(d.Fields) != 1 || !strings.Contains(d.Fields[0].Type.String(), "struct{int;opaque[32]}") {
		t.Fatalf("not preserved: %#v", d)
	}
}

func git(t *testing.T, dir string, args ...string) string {
	t.Helper()
	c := exec.Command("git", append([]string{"-C", dir}, args...)...)
	b, e := c.CombinedOutput()
	if e != nil {
		t.Fatalf("git %v: %v: %s", args, e, b)
	}
	return strings.TrimSpace(string(b))
}
func TestLoadRevisionExcludesNestedTestdata(t *testing.T) {
	d := t.TempDir()
	git(t, d, "init")
	git(t, d, "config", "user.email", "test@example.com")
	git(t, d, "config", "user.name", "Test")
	if err := os.WriteFile(filepath.Join(d, "real.x"), []byte("struct Real { int n; };"), 0600); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(d, "scripts/xdrcompat/testdata"), 0700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(d, "scripts/xdrcompat/testdata/fake.x"), []byte("struct Fake { int n; };"), 0600); err != nil {
		t.Fatal(err)
	}
	git(t, d, "add", ".")
	git(t, d, "commit", "-m", "fixture")
	m, err := LoadRevision(d, "HEAD")
	if err != nil {
		t.Fatal(err)
	}
	if len(m.Structs) != 1 || m.Structs["Real"] == nil {
		t.Fatalf("loaded fixtures: %#v", m.Structs)
	}
}

func TestParseFailureExitsTwoAndFailsCIWrapper(t *testing.T) {
	d := t.TempDir()
	git(t, d, "init")
	git(t, d, "config", "user.email", "test@example.com")
	git(t, d, "config", "user.name", "Test")
	if err := os.WriteFile(filepath.Join(d, "bad.x"), []byte("struct Broken { int value;"), 0600); err != nil {
		t.Fatal(err)
	}
	git(t, d, "add", ".")
	git(t, d, "commit", "-m", "broken")

	binary := filepath.Join(t.TempDir(), "xdrcompat")
	build := exec.Command("go", "build", "-o", binary, ".")
	if output, err := build.CombinedOutput(); err != nil {
		t.Fatalf("build: %v: %s", err, output)
	}
	cmd := exec.Command(binary, "--repo", d, "--base", "HEAD", "--head", "HEAD")
	output, err := cmd.CombinedOutput()
	var exitErr *exec.ExitError
	if !errors.As(err, &exitErr) || exitErr.ExitCode() != 2 || !strings.Contains(string(output), "error:") {
		t.Fatalf("CLI should exit 2: err=%v output=%s", err, output)
	}

	wrapper := exec.Command("bash", "ci-wrapper.sh", d, "HEAD", "HEAD")
	output, err = wrapper.CombinedOutput()
	if !errors.As(err, &exitErr) || exitErr.ExitCode() != 2 || !strings.Contains(string(output), "error:") {
		t.Fatalf("wrapper should preserve operational failure: err=%v output=%s", err, output)
	}
}

func TestCIWrapperKeepsFindingsAdvisoryAndInitialPushUsesEmptyTree(t *testing.T) {
	d := t.TempDir()
	git(t, d, "init")
	git(t, d, "config", "user.email", "test@example.com")
	git(t, d, "config", "user.name", "Test")
	write := func(src string) {
		t.Helper()
		if err := os.WriteFile(filepath.Join(d, "wire.x"), []byte(src), 0600); err != nil {
			t.Fatal(err)
		}
		git(t, d, "add", ".")
		git(t, d, "commit", "-m", "revision")
	}
	write("program P { version P1 { int call(int)=1; }=1; }=1;")
	base := git(t, d, "rev-parse", "HEAD")
	write("program P { version P1 { hyper call(int)=1; }=1; }=1;")
	cmd := exec.Command("bash", "ci-wrapper.sh", d, base, "HEAD")
	output, err := cmd.CombinedOutput()
	if err != nil || !strings.Contains(string(output), "1 wire-compatibility violation(s)") {
		t.Fatalf("findings should be logged but advisory: err=%v output=%s", err, output)
	}
	workflow, err := os.ReadFile(filepath.Join("..", "..", ".github", "workflows", "cpp.yml"))
	if err != nil {
		t.Fatal(err)
	}
	text := string(workflow)
	if !strings.Contains(text, "git hash-object -t tree /dev/null") || strings.Contains(text, `base="${head}^"`) || strings.Contains(text, "continue-on-error: true") {
		t.Fatalf("initial-push/error policy regressed:\n%s", text)
	}
}

func TestFindingsCarrySourceOrigins(t *testing.T) {
	base := model(t, map[string]string{
		"types.x": "struct Packet { int n; }; enum State { READY=0, DONE=1 }; union Choice switch (int k) { case 0: int n; default: void; };",
		"rpc.x":   "program P { version P1 { int call(int)=1; }=1; }=1;",
		"gone.x":  "program Gone { version G1 { void ping(void)=1; }=1; }=2;",
	})
	head := model(t, map[string]string{
		"types.x": "struct Packet { hyper n; }; enum State { READY=0, DONE=2 }; union Choice switch (bool k) { case 0: int n; default: void; };",
		"rpc.x":   "program P { version P1 { hyper call(int)=1; }=1; }=1;",
	})
	findings := Check(base, head)
	want := map[string][2]string{
		"P.P1 proc 1 (call)": {"rpc.x", "rpc.x"}, "program Gone (0x2)": {"gone.x", ""},
		"struct Packet": {"types.x", "types.x"}, "enum State": {"types.x", "types.x"}, "union Choice": {"types.x", "types.x"},
	}
	for _, f := range findings {
		origins, ok := want[f.Subject]
		if !ok {
			t.Fatalf("unrelated finding: %#v", f)
		}
		if f.BaseOrigin != origins[0] || f.HeadOrigin != origins[1] {
			t.Fatalf("origins for %s: %#v", f.Subject, f)
		}
		delete(want, f.Subject)
	}
	if len(want) != 0 {
		t.Fatalf("missing findings: %#v", want)
	}
}

// A constant cycle is malformed input, but resolution must terminate rather
// than loop, and must do so deterministically.
func TestConstantCycleTerminates(t *testing.T) {
	m, _ := pair(t, "const A = B; const B = A; typedef int Arr[A];", "const A = B; const B = A; typedef int Arr[A];")
	done := make(chan string, 1)
	go func() { done <- m.constValue("", "A") }()
	select {
	case got := <-done:
		if got != "A" && got != "B" {
			t.Fatalf("cycle resolved to unexpected value %q", got)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("constValue did not terminate on a constant cycle")
	}
}
