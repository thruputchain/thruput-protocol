# Protocol

XDR protocol files and other common definitions that must be shared between languages.

## Contents

- `*.x`: XDR types and RPC programs (RFC 4506 and RFC 5531).
- `syscalls.yaml`: the contract syscall interface. `generate_syscalls_doc.py`
  validates it and renders `syscalls_docs.json` and the per-syscall reference,
  `syscalls_generated.md`, from it. The reference is committed; CI checks it is
  current.
- `syscalls.md`: conventions that hold across all syscalls. The generator puts
  them at the head of `syscalls_generated.md`.

## Usage

Include as a submodule in other repositories. hogd does, as do
thruput-protocol-rs, thruput-protocol-go and thruput-protocol-ts, which generate
bindings from it. Every push to `main` dispatches their auto-update workflows
(`.github/workflows/notify-protocol-rs.yml`).

## Formatting

`./scripts/xdrformat` reindents every tracked `.x` file with Emacs
(`scripts/reindent.el`, `scripts/xdr-mode.el`). `./scripts/xdrformat --check`
fails if that changes anything; CI runs it.

## Checks

CI also compiles the `.x` files with goxdr, lints `syscalls.yaml`, and runs
`scripts/xdrcompat`, which compares a change with its base and comments on the
pull request with any wire-compatibility violation. That check is advisory; see
`scripts/xdrcompat/README.md` for its rules.
