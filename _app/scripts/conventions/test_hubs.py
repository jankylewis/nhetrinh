"""Tests of the hub rule (HUB-FOUNDBY-1): every bug, failure, tool gap and lesson says who found it.

Run: python3 -m unittest discover -s _app/scripts/conventions -p 'test_*.py'
"""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

import _check
from rules import hubs

ENTRY = "hubs/failures/failurereason/APP/NAV/NT_NAV_099_X.md"


def entry(found_by: str | None, body: str = "") -> str:
    head = ["# NT-NAV-099 — x", "", "id: NT-NAV-099", "family: NAV", "status: OPEN", "date: 2026-11-18"]
    if found_by is not None:
        head.append(f"found_by: {found_by}")
    return "\n".join(head + ["links: fix=no lesson=no evidence=no toolgap=none", "", "## Mechanism", body, ""])


def triage(header: str, rows: list[str]) -> str:
    return "\n".join(["# Triage", "", header, "|---|---|---|---|---|", *rows, ""])


GOOD_HEADER = "| Id | Found by | Signature | Status | First check |"


class EntryRules(unittest.TestCase):
    def test_each_value_passes(self):
        for value in ("headmate (2026-11-16 report, the brief)", "readback (R2 13:19)", "self-test (test.sh red)",
                      "development (P2 review)", "development (found_by not proven)"):
            with self.subTest(value=value):
                self.assertEqual(hubs.violations(ENTRY, entry(value)), [])

    def test_a_missing_or_wrong_line_is_a_violation(self):
        for value in (None, "user (x)", "Headmate (x)", "", "readback-ish (x)", "headmate", "readback ()",
                      "self-test ( )", "development (x", "development x)"):
            with self.subTest(value=value):
                self.assertEqual(len(hubs.violations(ENTRY, entry(value))), 1)

    def test_a_found_by_line_in_the_body_does_not_count(self):
        text = entry(None, body="found_by: development (P2 review)")
        self.assertEqual(len(hubs.violations(ENTRY, text)), 1)

    def test_every_hub_that_needs_it(self):
        for path in ("hubs/bugs/bugfacing/C1/D1/S01/NT_BUG_099_X.md", "hubs/lessons/toolgap/NT_TG_099_X.md",
                     "hubs/lessons/lessonlearn/SHIP/GAT/NT_GAT_099_X.md", ENTRY):
            with self.subTest(path=path):
                self.assertEqual(len(hubs.violations(path, entry(None))), 1)

    def test_indexes_and_other_hubs_are_exempt(self):
        for path in ("hubs/failures/failurereason/APP/NAV/_INDEX.md", "hubs/bugs/bugfix/C1/D1/S01/NT_BUG_099_X.md",
                     "hubs/failures/failfix/APP/NAV/NT_NAV_099_X.md", "README.md"):
            with self.subTest(path=path):
                self.assertEqual(hubs.violations(path, entry(None)), [])


class TriageRules(unittest.TestCase):
    PATHS = ("hubs/bugs/TRIAGE.md", "hubs/failures/TRIAGE.md")

    def test_a_good_table_passes(self):
        rows = ["| NT-BUG-001 | headmate | `x` | FIXED | y |", "| NT-TG-001 | self-test | `a | b` | OPEN | y |"]
        for path in self.PATHS:
            self.assertEqual(hubs.violations(path, triage(GOOD_HEADER, rows)), [])

    def test_no_found_by_column_is_a_violation(self):
        text = triage("| Id | Signature | Status | First check |", ["| NT-BUG-001 | `x` | FIXED | y |"])
        for path in self.PATHS:
            self.assertEqual(len(hubs.violations(path, text)), 1)

    def test_a_row_without_a_valid_value_names_its_id(self):
        rows = ["| NT-BUG-001 | | `x` | FIXED | y |", "| NT-BUG-002 | user | `x` | FIXED | y |",
                "| NT-BUG-003 | readback | `x` | FIXED | y |"]
        found = hubs.violations(self.PATHS[0], triage(GOOD_HEADER, rows))
        self.assertEqual(len(found), 2)
        self.assertTrue("NT-BUG-001" in found[0] and "NT-BUG-002" in found[1])


class TheCheckerRunsTheRule(unittest.TestCase):
    """REVIEW_HUB_FOUNDBY defect 1: `_check.all_violations` runs the hub rule on a git tree."""

    def violations(self, found_by: str | None) -> list[str]:
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / ENTRY
            path.parent.mkdir(parents=True)
            path.write_text(entry(found_by), encoding="utf-8")
            subprocess.run(["git", "-C", root, "init", "-q"], check=True)
            _, found = _check.all_violations(root)
        return [line for line in found if "found_by" in line]

    def test_an_entry_without_found_by_is_reported(self):
        found = self.violations(None)
        self.assertEqual(len(found), 1)
        self.assertIn(ENTRY, found[0])

    def test_an_entry_with_found_by_is_not(self):
        self.assertEqual(self.violations("development (P2 review)"), [])


if __name__ == "__main__":
    unittest.main()
