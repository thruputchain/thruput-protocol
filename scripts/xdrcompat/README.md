# xdrcompat

`xdrcompat` compares two protocol repository revisions and reports XDR changes
that can silently break peers. XDR has no field tags and is not self-describing,
so the checker resolves named declarations to their encoded wire layouts rather
than treating unchanged declaration text as proof of compatibility.

It detects:

- changed procedure argument and return layouts under an existing procedure
  number, including pointers, fixed/variable arrays, bounds, typedef chains,
  constants, structs, enums, and unions;
- removed or reused procedure numbers, removed versions/programs, and program
  renumbering;
- changed struct field layouts, typedef layouts, enum values (including values
  supplied by constants), and union discriminants/case values/arm/default
  payloads;
- reachable unions that newly lack a `default:` arm; and
- new owners joining an already-used program number. Existing collisions are
  grandfathered only for their exact owner set.

Arm declaration order is ignored when union case values and payloads are
unchanged. Namespace identity and source paths are retained to prevent
same-short-name declarations from hiding each other, while a namespace rename
alone is not reported as a wire change. Ambiguous duplicate declarations,
program identities, version numbers, and procedure numbers are parse errors;
the sanctioned same-program/same-number declarations in separate files may
contribute distinct versions.

## Coverage boundary

The loader examines only `.x` files at the protocol repository root. Nested
tool fixtures and other non-production files are excluded. The parser covers
the XDR syntax used by this repository, including its anonymous inline
aggregates; it is not a general-purpose implementation of every rpcgen dialect
or preprocessor. The checker evaluates schema-level wire compatibility. It
does not prove application semantics, runtime dispatch behaviour, generated
binding compatibility, or whether a removed type is still used outside the
program declarations present here. Source paths are reported; line numbers are
not currently tracked.

The tool exits 0 when clean, 1 for compatibility findings, and 2 when it cannot
load or parse either revision. CI keeps exit 1 advisory but fails on exit 2.
Pull requests compare their merge base with the exact PR head. Pushes compare
the event's before/after commits; an initial push uses Git's empty tree so the
whole pushed history is represented. Findings remain in the step log and
`$GITHUB_STEP_SUMMARY`.

The module lives here rather than at the repository root because the existing
workflow creates a temporary root module to vet generated Go code.

Run locally from this directory:

```console
go test ./...
go vet ./...
go run . --repo ../.. --base BASE --head HEAD
```
