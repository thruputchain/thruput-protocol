#!/usr/bin/env python3
"""Tests for syscallcompat.py. Run: python3 scripts/syscallcompat_test.py"""

import copy
import unittest
from pathlib import Path

import yaml

import syscallcompat

ROOT = Path(__file__).resolve().parent.parent


def spec(minor=1, major=1):
    return {
        "syscall_api_version": {"major": major, "minor": minor},
        "syscall_input_count": 7,
        "type_mappings": [{"base_name": "uint32_t", "rust_name": "u32"}],
        "syscalls": [
            {"name": "A", "number": 0, "since_minor": 0,
             "inputs": [{"name": "x", "typename": "uint32_t"}]},
            {"name": "B", "number": 1, "since_minor": 1, "outputs": None},
        ],
    }


def added(base, **extra):
    head = copy.deepcopy(base)
    head["syscall_api_version"]["minor"] += 1
    head["syscalls"].append({
        "name": "C", "number": len(head["syscalls"]),
        "since_minor": head["syscall_api_version"]["minor"], **extra})
    return head


class Validate(unittest.TestCase):
    def test_committed_file(self):
        committed = yaml.safe_load((ROOT / "syscalls.yaml").read_text())
        self.assertEqual(syscallcompat.validate(committed), [])

    def test_ok(self):
        self.assertEqual(syscallcompat.validate(spec()), [])

    def test_version_shape(self):
        for bad in (None, {"major": 1}, {"major": 1, "minor": True},
                    {"major": 1, "minor": -1}, {"major": 1, "minor": 1.0},
                    {"major": 1, "minor": 1, "patch": 0}):
            s = spec()
            s["syscall_api_version"] = bad
            self.assertEqual(len(syscallcompat.validate(s)), 1, bad)

    def test_since_minor(self):
        s = spec()
        del s["syscalls"][0]["since_minor"]
        self.assertIn("non-negative", syscallcompat.validate(s)[0])
        self.assertIn("later than", syscallcompat.validate(spec(minor=0))[0])
        s = spec()
        s["syscalls"][0]["since_minor"] = 1
        s["syscalls"][1]["since_minor"] = 0
        self.assertIn("earlier than", syscallcompat.validate(s)[0])

    def test_experimental_type(self):
        s = spec()
        s["syscalls"][0]["experimental"] = "yes"
        self.assertIn("boolean", syscallcompat.validate(s)[0])


class Compare(unittest.TestCase):
    def check(self, head, *fragments, base=None):
        base = base or spec()
        self.assertEqual(syscallcompat.validate(head), [])
        issues = syscallcompat.compare(base, head)
        self.assertEqual(len(issues), len(fragments), issues)
        for issue, fragment in zip(issues, fragments):
            self.assertIn(fragment, issue)

    def test_unchanged_and_docs(self):
        head = spec()
        head["syscalls"][0]["description"] = "new words"
        head["syscalls"][1]["outputs"] = []
        head["syscalls"][1]["returns"] = True
        self.check(head)

    def test_add(self):
        self.check(added(spec()))
        head = added(spec())
        head["type_mappings"].append({"base_name": "T", "rust_name": "T"})
        self.check(head)

    def test_add_without_bump(self):
        head = added(spec())
        head["syscall_api_version"]["minor"] = 1
        head["syscalls"][-1]["since_minor"] = 1
        self.check(head, "bump minor")

    def test_add_with_stale_since(self):
        head = added(spec())
        head["syscalls"][-1]["since_minor"] = 1
        self.check(head, "must have since_minor 2")

    def test_breaks(self):
        head = spec()
        head["syscalls"][0]["inputs"][0]["typename"] = "uint64_t"
        self.check(head, "inputs changed")
        head = spec()
        head["syscalls"][0]["read_only"] = True
        self.check(head, "read_only changed")
        head = spec()
        del head["syscalls"][1]
        self.check(head, "removed or renamed")
        head = spec()
        head["syscalls"][1]["experimental"] = True
        self.check(head, "cannot become experimental")
        head = spec()
        head["syscall_input_count"] = 8
        self.check(head, "syscall_input_count changed")
        head = spec()
        head["type_mappings"][0]["rust_name"] = "u64"
        self.check(head, "type_mappings changed")
        self.check(spec(minor=1), "minor went backwards", base=spec(minor=2))

    def test_experimental_is_free(self):
        base = added(spec(), experimental=True)
        head = copy.deepcopy(base)
        head["syscalls"][-1]["inputs"] = [{"name": "y", "span_argument": True}]
        self.check(head, base=base)
        del head["syscalls"][-1]
        self.check(head, base=base)
        # Stabilising is allowed.
        head = copy.deepcopy(base)
        del head["syscalls"][-1]["experimental"]
        self.check(head, base=base)

    def test_major(self):
        head = spec(major=2, minor=0)
        head["syscalls"] = [{"name": "Z", "number": 0, "since_minor": 0}]
        self.check(head)
        self.check(spec(major=2, minor=1), "must start at minor 0")
        self.check(spec(major=0), "major went backwards")


if __name__ == "__main__":
    unittest.main()
