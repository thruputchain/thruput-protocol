#!/usr/bin/env python3
"""Check syscalls.yaml against the versioning rules it states.

    syscallcompat.py HEAD.yaml             check one file on its own
    syscallcompat.py BASE.yaml HEAD.yaml   also check the change from BASE

Exits 1 and prints one line per violation. A BASE that predates
syscall_api_version is not compared.
"""

import sys
from typing import Any, Dict, List, Optional, Tuple

import yaml

# What a guest can observe of a syscall. A difference in any of these between
# two versions with the same major is a break.
SIGNATURE_FIELDS = ("number", "inputs", "outputs", "returns", "read_only")


def _is_count(value: Any) -> bool:
    # bool is an int in Python, and YAML reads `yes` as one.
    return isinstance(value, int) and not isinstance(value, bool) and value >= 0


def api_version(spec: Dict[str, Any]) -> Optional[Tuple[int, int]]:
    """(major, minor), or None if absent or malformed."""
    version = spec.get("syscall_api_version")
    if not isinstance(version, dict) or set(version) != {"major", "minor"}:
        return None
    if not _is_count(version["major"]) or not _is_count(version["minor"]):
        return None
    return version["major"], version["minor"]


def validate(spec: Dict[str, Any]) -> List[str]:
    """Violations a file shows on its own."""
    version = api_version(spec)
    if version is None:
        return ["syscall_api_version must be exactly {major, minor}, both "
                "non-negative integers"]
    _, minor = version

    issues = []
    previous = 0
    for syscall in sorted(spec.get("syscalls") or [],
                          key=lambda s: s.get("number", -1)):
        name = syscall.get("name", "<unnamed>")
        since = syscall.get("since_minor")
        if not _is_count(since):
            issues.append(f"{name}: since_minor must be a non-negative integer")
            continue
        if since > minor:
            issues.append(f"{name}: since_minor {since} is later than the "
                          f"current minor {minor}")
        # Numbers are handed out in order, so a later number cannot have
        # arrived in an earlier version.
        if since < previous:
            issues.append(f"{name}: since_minor {since} is earlier than that "
                          f"of a lower-numbered syscall ({previous})")
        previous = max(previous, since)
        if not isinstance(syscall.get("experimental", False), bool):
            issues.append(f"{name}: experimental must be a boolean")
    return issues


def _signature(syscall: Dict[str, Any]) -> Dict[str, Any]:
    signature = {field: syscall.get(field) for field in SIGNATURE_FIELDS}
    # Spell out the defaults so writing one down is not a change.
    signature["inputs"] = signature["inputs"] or []
    signature["outputs"] = signature["outputs"] or []
    signature["returns"] = syscall.get("returns", True) is not False
    signature["read_only"] = bool(syscall.get("read_only", False))
    return signature


def compare(base: Dict[str, Any], head: Dict[str, Any]) -> List[str]:
    """Violations in the change from base to head. Both must validate."""
    base_major, base_minor = api_version(base)
    head_major, head_minor = api_version(head)
    if head_major < base_major:
        return [f"major went backwards: {base_major} -> {head_major}"]
    if head_major > base_major:
        if head_minor != 0:
            return [f"major {head_major} must start at minor 0"]
        return [f"{s['name']}: since_minor must be 0 at the start of a major"
                for s in head.get("syscalls") or [] if s.get("since_minor")]

    issues = []
    if head_minor < base_minor:
        issues.append(f"minor went backwards: {base_minor} -> {head_minor}")
    for key in ("syscall_input_count", "type_mappings"):
        # A mapping only added for a new syscall changes nothing existing.
        if key == "type_mappings":
            names = {m.get("base_name") for m in base.get(key) or []}
            kept = [m for m in head.get(key) or []
                    if m.get("base_name") in names]
            changed = kept != (base.get(key) or [])
        else:
            changed = base.get(key) != head.get(key)
        if changed:
            issues.append(f"{key} changed: bump major")

    head_by_name = {s["name"]: s for s in head.get("syscalls") or []}
    base_names = set()
    for old in base.get("syscalls") or []:
        name = old["name"]
        base_names.add(name)
        if old.get("experimental", False):
            continue
        new = head_by_name.get(name)
        if new is None:
            issues.append(f"{name}: removed or renamed: bump major")
            continue
        if new.get("experimental", False):
            issues.append(f"{name}: a stable syscall cannot become "
                          "experimental: bump major")
        if new.get("since_minor") != old.get("since_minor"):
            issues.append(f"{name}: since_minor changed")
        old_sig, new_sig = _signature(old), _signature(new)
        for field in SIGNATURE_FIELDS:
            if old_sig[field] != new_sig[field]:
                issues.append(f"{name}: {field} changed: bump major")

    for name, new in head_by_name.items():
        if name in base_names:
            continue
        if head_minor == base_minor:
            issues.append(f"{name}: new syscall: bump minor")
        elif new.get("since_minor") != head_minor:
            issues.append(f"{name}: new syscall must have since_minor "
                          f"{head_minor}")
    return issues


def _load(path: str) -> Dict[str, Any]:
    with open(path, "r") as f:
        return yaml.safe_load(f) or {}


def main(argv: List[str]) -> int:
    if len(argv) not in (2, 3):
        print(__doc__, file=sys.stderr)
        return 2
    head = _load(argv[-1])
    issues = validate(head)
    if not issues and len(argv) == 3:
        base = _load(argv[1])
        if api_version(base) is None:
            print("base has no syscall_api_version; not compared")
        elif validate(base):
            print("base does not validate; not compared")
        else:
            issues = compare(base, head)
    for issue in issues:
        print(f"syscalls.yaml: {issue}", file=sys.stderr)
    return 1 if issues else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
