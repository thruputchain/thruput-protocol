// Command xdrcompat checks XDR wire-compatibility between two revisions of
// the protocol repository.
//
// XDR is non-self-describing: there are no field tags and no lengths on
// scalars, so a decoder must know the exact layout in advance. That makes an
// in-place change to a live declaration a *silent* break — the peer does not
// fail to parse, it reads the wrong bytes. These rules follow from that:
//
//	R1  procedure signatures are immutable
//	R2  procedure numbers are permanent (no renumber, no reuse)
//	R3  struct fields are immutable (no add, remove, or reorder)
//	R4  enum cases are immutable (append-only, never renumbered)
//	R5  boundary-crossing unions carry a `default:` arm
//	R7  program deletion requires a deprecation cycle
//	R8  program numbers are permanent and uniquely owned
//
// R6 ("breaking change -> new version N+1") needs no separate check: it is
// what an R1/R2/R3 failure inside an existing version means, and the remedy
// is printed with the violation. R9 ("additive procedures are safe") is the
// escape hatch, not a rule to enforce.
//
// Usage:
//
//	xdrcompat --base origin/main [--head HEAD] [--repo DIR] [--format json]
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"sort"
	"strconv"
	"strings"
)

func gitOutput(repo string, args ...string) (string, error) {
	cmd := exec.Command("git", append([]string{"-C", repo}, args...)...)
	var stderr strings.Builder
	cmd.Stderr = &stderr
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("git %s: %s", strings.Join(args, " "),
			strings.TrimSpace(stderr.String()))
	}
	return string(out), nil
}

// readBlobs fetches every requested object in a single `git cat-file --batch`
// pass. Spawning one `git show` per file dominates runtime otherwise — 80 .x
// files means 80 process spawns per revision.
func readBlobs(repo string, specs []string) ([]string, error) {
	cmd := exec.Command("git", "-C", repo, "cat-file", "--batch")
	cmd.Stdin = strings.NewReader(strings.Join(specs, "\n") + "\n")
	var stderr strings.Builder
	cmd.Stderr = &stderr
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("git cat-file --batch: %s", strings.TrimSpace(stderr.String()))
	}

	// Each record is "<oid> <type> <size>\n<contents>\n", in request order.
	contents := make([]string, 0, len(specs))
	buf := out
	for range specs {
		nl := bytes.IndexByte(buf, '\n')
		if nl < 0 {
			return nil, fmt.Errorf("git cat-file: truncated output")
		}
		header := string(buf[:nl])
		fields := strings.Fields(header)
		if len(fields) < 3 {
			return nil, fmt.Errorf("git cat-file: %s", header)
		}
		size, err := strconv.Atoi(fields[2])
		if err != nil {
			return nil, fmt.Errorf("git cat-file: bad size in %q", header)
		}
		start := nl + 1
		if start+size > len(buf) {
			return nil, fmt.Errorf("git cat-file: truncated blob")
		}
		contents = append(contents, string(buf[start:start+size]))
		buf = buf[start+size:]
		if len(buf) > 0 && buf[0] == '\n' {
			buf = buf[1:]
		}
	}
	return contents, nil
}

// LoadRevision parses the production interface set: .x files at the protocol
// repository root. Tool fixtures and other nested test data are never protocol.
func LoadRevision(repo, ref string) (*Model, error) {
	listing, err := gitOutput(repo, "ls-tree", "-r", "--name-only", ref)
	if err != nil {
		return nil, err
	}

	var paths []string
	for _, p := range strings.Split(listing, "\n") {
		if strings.HasSuffix(p, ".x") && !strings.Contains(p, "/") {
			paths = append(paths, p)
		}
	}
	sort.Strings(paths)

	specs := make([]string, len(paths))
	for i, p := range paths {
		specs[i] = ref + ":" + p
	}
	blobs, err := readBlobs(repo, specs)
	if err != nil {
		return nil, err
	}

	m := newModel()
	for i, blob := range blobs {
		if err := Parse(blob, m, specs[i]); err != nil {
			return nil, err
		}
	}
	return m, nil
}

// GitHub renders at most ten warning annotations per step and silently drops
// the rest, so an over-long run must say what it withheld rather than appear
// to have found only ten things.
const maxAnnotations = 10

// escapeCommandData escapes a GitHub Actions workflow-command message.
var escapeCommandData = strings.NewReplacer("%", "%25", "\r", "%0D", "\n", "%0A")

// escapeCommandProperty additionally escapes the separators that terminate a
// property value inside the command header.
var escapeCommandProperty = strings.NewReplacer(
	"%", "%25", "\r", "%0D", "\n", "%0A", ":", "%3A", ",", "%2C")

// emitAnnotations writes findings as GitHub Actions warning annotations, which
// surface on the pull request's Files changed tab. Findings are advisory, so
// these are warnings and never errors. The tool tracks source paths but not
// line numbers, so each annotation anchors to its file.
func emitAnnotations(w io.Writer, findings []Finding) {
	for i, f := range findings {
		if len(findings) > maxAnnotations && i == maxAnnotations-1 {
			fmt.Fprintf(w, "::warning title=xdrcompat::%s\n", escapeCommandData.Replace(
				fmt.Sprintf("%d more wire-compatibility violation(s) not annotated; "+
					"see the step log and job summary for the full report.",
					len(findings)-(maxAnnotations-1))))
			return
		}
		file := f.HeadOrigin
		if file == "" {
			file = f.BaseOrigin
		}
		props := fmt.Sprintf("title=%s",
			escapeCommandProperty.Replace(f.Rule+" "+f.Subject))
		if file != "" {
			props = fmt.Sprintf("file=%s,%s", escapeCommandProperty.Replace(file), props)
		}
		fmt.Fprintf(w, "::warning %s::%s\n", props,
			escapeCommandData.Replace(f.Detail+"\n-> "+f.Remedy))
	}
}

func main() {
	var (
		base     = flag.String("base", "", "git ref to compare against (required)")
		head     = flag.String("head", "HEAD", "git ref under review")
		repo     = flag.String("repo", ".", "protocol repo path")
		format   = flag.String("format", "text", "output format: text or json")
		annotate = flag.Bool("annotate", false, "also write GitHub Actions warning annotations to stderr")
	)
	flag.Usage = func() {
		fmt.Fprintln(os.Stderr, "usage: xdrcompat --base REF [--head REF] [--repo DIR] [--format text|json] [--annotate]")
		flag.PrintDefaults()
	}
	flag.Parse()

	if *base == "" {
		flag.Usage()
		os.Exit(2)
	}
	if *format != "text" && *format != "json" {
		fmt.Fprintf(os.Stderr, "error: unknown format %q\n", *format)
		os.Exit(2)
	}

	baseModel, err := LoadRevision(*repo, *base)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(2)
	}
	headModel, err := LoadRevision(*repo, *head)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(2)
	}

	findings := Check(baseModel, headModel)

	if *annotate {
		emitAnnotations(os.Stderr, findings)
	}

	if *format == "json" {
		if findings == nil {
			findings = []Finding{}
		}
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		if err := enc.Encode(findings); err != nil {
			fmt.Fprintf(os.Stderr, "error: %v\n", err)
			os.Exit(2)
		}
		if len(findings) > 0 {
			os.Exit(1)
		}
		return
	}

	fmt.Printf("xdrcompat: %s...%s  (%d programs, %d structs, %d enums, %d unions)\n",
		*base, *head, len(headModel.Programs), len(headModel.Structs),
		len(headModel.Enums), len(headModel.Unions))

	if len(findings) == 0 {
		fmt.Println("\nOK: no wire-compatibility violations")
		return
	}

	// Group by rule so a reviewer reads all R1s together.
	byRule := map[string][]Finding{}
	for _, f := range findings {
		byRule[f.Rule] = append(byRule[f.Rule], f)
	}

	fmt.Printf("\n%d wire-compatibility violation(s):\n\n", len(findings))
	for _, rule := range sortedKeys(byRule) {
		for _, f := range byRule[rule] {
			fmt.Println(f.Render())
			fmt.Println()
		}
	}
	os.Exit(1)
}
