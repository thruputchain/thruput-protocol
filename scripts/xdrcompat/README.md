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
- new owners joining an already-used program number. Existing collisions are
  grandfathered only for their exact owner set.

## Why there is no R5

R5 required every union crossing a service boundary to carry a `default:` arm,
so that an old peer could decode and report rather than fail to parse. It was
withdrawn: the remedy causes the failure it claims to prevent.

A `default: void` arm decodes **zero bytes**. When a peer meets a discriminant
added after it was built, it consumes the discriminant, matches the default,
consumes nothing more, and then reads every following field out of the sender's
arm payload. For a union embedded in a larger message that silently corrupts
everything after it — including, in this schema, the multi-signature weight in
`address_auth.x:PublicKeyConfig`. Without the default the same message is a
clean decode error, which is the correct outcome. XDR cannot skip an unknown
arm; that is the premise the whole tool rests on, and R5 contradicted it.

Unknown discriminants are what the ONC version mechanism is for. Adding a
`default:` arm remains a reportable layout change like any other, and removing
one still breaks peers that relied on it.

The hazard R5 was groping at is real but differential, and belongs in a rule
that fires when an enum **gains** a case that some reachable union switching on
it has no arm for. That check is sound and its remedy is correct. It is not
implemented.

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
whole pushed history is represented.

## Reporting

Advisory findings leave the job green, so the report has to travel to the
reviewer rather than wait to be found. Every pull request run publishes the
same report three ways:

- a **pull request comment**, upserted through the `<!-- xdrcompat-report -->`
  marker so repeated pushes edit one comment in place instead of stacking;
- **warning annotations** on the Files changed tab, anchored to each finding's
  source file, capped at the ten GitHub renders per step with a notice naming
  how many were withheld; and
- the **job summary**, which carries the full untruncated report.

The comment needs `pull-requests: write` and a writable `GH_TOKEN`. The
workflow deliberately leaves `GH_TOKEN` unset for fork pull requests, whose
token is read-only, and the wrapper then skips the comment. Where the comment
is attempted and fails, that is an operational failure and the step fails: a
report nobody receives is the same as no checker at all, which is also why
`continue-on-error` is never used here.

The module lives here rather than at the repository root because the existing
workflow creates a temporary root module to vet generated Go code.

Run locally from this directory:

```console
go test ./...
go vet ./...
go run . --repo ../.. --base BASE --head HEAD
```

`--annotate` adds the GitHub workflow-command annotations on stderr, keeping
stdout as the plain report; `ci-wrapper.sh` passes it and CI consumes both.
