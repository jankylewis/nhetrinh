"""Tests of release_notes.py (P8): the release notes are made from the product/features rows."""
import os
import pathlib
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
HEAD = "| Id | Feature | Release note | Commit | Date | Closed bug |\n"


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
        self.assertIn("## Install", text)  # how to install and open
        self.assertIn("not notarized", text)
        self.assertIn("nhetrinh-1.0.0-arm64.zip", text)

    def test_the_command_line_reads_the_repository_and_says_the_kind(self):
        root = tempfile.mkdtemp()
        features = os.path.join(root, "hubs", "product", "features")
        os.makedirs(features)
        os.makedirs(os.path.join(root, "hubs", "product", "plan"))
        pathlib.Path(features, "S01.md").write_text(FEATURES, encoding="utf-8")
        pathlib.Path(root, "hubs", "product", "plan", "_PLAN.md").write_text(PLAN, encoding="utf-8")
        out = subprocess.run([sys.executable, release_notes.__file__, "1.0.0", "--root", root],
                             capture_output=True, text=True, check=True).stdout
        self.assertIn("## Tab folders", out)
        self.assertIn("- A row with a | in its text\n", out)
        for version, kind in [("0.8.0", "prerelease"), ("1.0.0", "release")]:
            out = subprocess.run([sys.executable, release_notes.__file__, version, "--kind"],
                                 capture_output=True, text=True, check=True).stdout
            self.assertEqual(out, kind + "\n")

    def test_0x_is_a_prerelease_1_0_and_later_a_release_and_not_x_y_z_an_error(self):
        cases = {"0.1.0": True, "0.8.0": True, "0.10.3": True, "1.0.0": False, "1.2.3": False, "2.0.0": False}
        for version, expected in cases.items():
            self.assertEqual(release_notes.prerelease(version), expected, version)
        for version in ["", "v1.0.0", "1.0", "1.0.0-beta", "one.0.0"]:
            with self.assertRaises(ValueError, msg=version):
                release_notes.prerelease(version)

    def test_a_release_note_column_gives_the_notes_and_a_dash_leaves_a_row_out(self):
        rows = release_notes.parse_rows(HEAD + "| NT-FEAT-034 | Footer: up to 3 rows (P5) | - | x | d | - |\n"
                                        "| NT-FEAT-036 | `WKDownload` rows (P5-FIX-1) | Every download has a row "
                                        "| not committed (P5-FIX-1) | d | - |\n")
        self.assertEqual([(r["text"], r["phase"]) for r in rows], [(None, "P5"), ("Every download has a row", "P5")])
        for bad in ["| NT-FEAT-036 | A | x | d | - |", "| NT-FEAT-036 | A |  | x | d | - |"]:  # 5 cells, empty
            with self.assertRaises(ValueError, msg=bad):
                release_notes.parse_rows(HEAD + bad)

    def test_a_pipe_in_a_note_is_written_escaped_and_a_bare_one_is_an_error(self):
        rows = release_notes.parse_rows(HEAD + "| NT-FEAT-050 | A | Tabs \\| folders | x (P7) | d | - |")
        self.assertEqual(rows[0]["text"], "Tabs | folders")
        with self.assertRaises(ValueError):  # P8-FIX-2: the Feature cell took "A | Tabs", the note was cut
            release_notes.parse_rows(HEAD + "| NT-FEAT-050 | A | Tabs | folders | x (P7) | d | - |")

    def test_a_note_with_a_decision_id_or_a_code_name_is_an_error(self):
        for note in ["Settings Hub (D19)", "Rows use `WKDownload`", "See D2"]:
            with self.assertRaises(ValueError, msg=note):
                release_notes.parse_rows(HEAD + f"| NT-FEAT-050 | A | {note} | x | d | - |")
        self.assertEqual(release_notes.parse_rows(HEAD + "| NT-FEAT-050 | A | Dock icon, 3D | x | d | - |")[0]["text"],
                         "Dock icon, 3D")

    def test_no_row_or_a_note_with_a_hub_id_a_task_id_or_the_readback_is_an_error(self):
        with self.assertRaises(ValueError):
            release_notes.notes("1.0.0", [], {})
        for text in ["Closes NT-BUG-017", "Guarded (P5-FIX-1)", "Read back by the Readback tool"]:
            with self.assertRaises(ValueError, msg=text):
                release_notes.notes("1.0.0", [{"id": "NT-FEAT-1", "text": text, "phase": None}], {})


class ReviewP8Tests(unittest.TestCase):
    """P8-REVIEW (REVIEW_P8.md), red on p8/release 41fc9df merged with p7/prep (e2bbc3f)."""

    def test_task_ids_and_the_readback_are_not_in_the_notes(self):
        rows = release_notes.parse_rows("\n".join([
            "| NT-FEAT-036 | Downloads guarded (P5-FIX-1): written as `<name>.download` until complete "
            "| x (P5-FIX-1) | 2026-11-17 | - |",
            "| NT-FEAT-035 | Links from other apps open as tabs (a possible default browser; never made the "
            "default by the app or the readback) (P5) | x | 2026-11-16 | - |"]))
        text = release_notes.notes("1.0.0", rows, {"P5": "Downloads, app links"})
        self.assertNotIn("P5-FIX-1", text)
        self.assertNotIn("readback", text)

    def test_a_feature_row_of_the_wrong_shape_is_an_error(self):
        with self.assertRaises(ValueError):  # 4 cells: today the row is dropped without a word
            release_notes.parse_rows("| NT-FEAT-099 | A feature with no date column | abc1234 | - |")

    def test_the_real_notes_do_not_contradict_themselves(self):
        root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..")
        out = subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                              "release_notes.py"), "1.0.0", "--root", root], capture_output=True, text=True)
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertNotIn("up to 3 download rows", out.stdout)  # since P5-FIX-1 every running one has a row


if __name__ == "__main__":
    unittest.main()
