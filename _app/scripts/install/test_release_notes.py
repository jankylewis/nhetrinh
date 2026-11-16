"""Tests of release_notes.py (P8): the release notes are made from the product/features rows."""
import os
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import release_notes  # noqa: E402

FEATURES = "\n".join([
    "# Features — S01 (NT-FEAT-001 to 040)", "",
    "| Id | Feature | Commit | Date | Closed bug |", "|---|---|---|---|---|",
    "| NT-FEAT-001 | Window with a vertical tab sidebar (collapsible, ⌘S) | 0f99aee | 2026-11-16 | - |",
    "| NT-FEAT-011 | Idle unload keeps a tab that plays media: WebKit is asked first (P1) "
    "| not committed (P1-BUILD-1) | 2026-11-16 | - |",
    "| NT-FEAT-021 | `<input type=\"file\">` opens the open panel (P3; picking a file not read back, NT-TG-005) "
    "| x (P3-BUILD-1) | 2026-11-16 | - |",
    "| NT-FEAT-039 | Readback probe request `pressure` (warning, critical) (P6) | not committed (P6-BUILD-1) "
    "| 2026-11-16 | - |",
    "| NT-FEAT-050 | A row with a | in its text (P7) | abc1234 (P7-FIX-1) | 2026-11-17 | NT-BUG-014 |", ""])
PLAN = """| Phase | Version | Size | What | Status | Detail |
|---|---|---|---|---|---|
| P1 Tab lifecycle | 0.2.0 | M | tabs come back | DONE | `M1.md` |
| P3 Page basics | 0.4.0 | L | dialogs | DONE | `M2.md` |
| P7 Tab folders | 0.8.0 | L | groups | DONE | `M3.md` |
"""


class ReleaseNotesTests(unittest.TestCase):
    def test_rows_are_read_with_their_phase(self):
        rows = release_notes.parse_rows(FEATURES)
        self.assertEqual([r["id"] for r in rows], ["NT-FEAT-001", "NT-FEAT-011", "NT-FEAT-021", "NT-FEAT-039",
                                                  "NT-FEAT-050"])
        self.assertEqual([r["phase"] for r in rows], [None, "P1", "P3", "P6", "P7"])
        self.assertEqual(rows[4]["text"], "A row with a | in its text")

    def test_the_phase_note_at_the_end_goes(self):
        rows = release_notes.parse_rows(FEATURES)
        self.assertEqual(rows[1]["text"], "Idle unload keeps a tab that plays media: WebKit is asked first")
        self.assertEqual(rows[2]["text"], "`<input type=\"file\">` opens the open panel")

    def test_hub_references_are_left_out(self):
        rows = release_notes.parse_rows(
            "| NT-FEAT-009 | 256 px Dock icon (the 1024 px one cost ~33 MB, NT-PRF-001) | 0f99aee | d | - |\n"
            "| NT-FEAT-032 | Settings Hub ⌘, (nhetrinh > Settings Hub…, D19): look (P4) | x (P4-BUILD-1) | d | - |\n"
            "| NT-FEAT-022 | Error page: certificate (no proceed, Q5), other (P3) | x (P3-BUILD-1) | d | - |\n")
        self.assertEqual([row["text"] for row in rows], ["256 px Dock icon (the 1024 px one cost ~33 MB)",
                                                         "Settings Hub ⌘, (nhetrinh > Settings Hub…): look",
                                                         "Error page: certificate (no proceed), other"])

    def test_phase_names_come_from_the_plan(self):
        self.assertEqual(release_notes.phase_names(PLAN),
                         {"P1": "Tab lifecycle", "P3": "Page basics", "P7": "Tab folders"})

    def test_notes_group_by_phase_in_order_and_leave_out_the_readback_tools(self):
        text = release_notes.notes("1.0.0", release_notes.parse_rows(FEATURES), release_notes.phase_names(PLAN))
        self.assertTrue(text.startswith("# nhetrinh 1.0.0\n"))
        heads = [line for line in text.splitlines() if line.startswith("## ")]
        self.assertEqual(heads[:4], ["## The basics", "## Tab lifecycle", "## Page basics", "## Tab folders"])
        self.assertIn("- Window with a vertical tab sidebar (collapsible, ⌘S)\n", text)
        self.assertNotIn("Readback probe", text)
        self.assertNotIn("NT-", text.split("## Install")[0])

    def test_notes_say_how_to_install_and_open(self):
        text = release_notes.notes("1.0.0", release_notes.parse_rows(FEATURES), {})
        self.assertIn("## Install", text)
        self.assertIn("not notarized", text)
        self.assertIn("nhetrinh-1.0.0-arm64.zip", text)

    def test_the_command_line_reads_the_repository(self):
        root = tempfile.mkdtemp()
        features = os.path.join(root, "hubs", "product", "features")
        os.makedirs(features)
        os.makedirs(os.path.join(root, "hubs", "product", "plan"))
        with open(os.path.join(features, "S01.md"), "w") as file:
            file.write(FEATURES)
        with open(os.path.join(root, "hubs", "product", "plan", "_PLAN.md"), "w") as file:
            file.write(PLAN)
        out = subprocess.run([sys.executable, release_notes.__file__, "1.0.0", "--root", root],
                             capture_output=True, text=True, check=True).stdout
        self.assertIn("## Tab folders", out)
        self.assertIn("- A row with a | in its text\n", out)

    def test_0x_is_a_prerelease_and_1_0_and_later_a_release(self):
        cases = {"0.1.0": True, "0.8.0": True, "0.10.3": True, "1.0.0": False, "1.2.3": False, "2.0.0": False}
        for version, expected in cases.items():
            self.assertEqual(release_notes.prerelease(version), expected, version)

    def test_a_version_that_is_not_x_y_z_is_an_error(self):
        for version in ["", "v1.0.0", "1.0", "1.0.0-beta", "one.0.0"]:
            with self.assertRaises(ValueError, msg=version):
                release_notes.prerelease(version)

    def test_the_command_line_says_the_kind(self):
        for version, kind in [("0.8.0", "prerelease"), ("1.0.0", "release")]:
            out = subprocess.run([sys.executable, release_notes.__file__, version, "--kind"],
                                 capture_output=True, text=True, check=True).stdout
            self.assertEqual(out, kind + "\n")

    def test_no_feature_row_is_an_error(self):
        with self.assertRaises(ValueError):
            release_notes.notes("1.0.0", [], {})


if __name__ == "__main__":
    unittest.main()
