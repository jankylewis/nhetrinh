"""The release notes of nhetrinh (P8), made from the hubs/product/features rows.

    python3 _app/scripts/install/release_notes.py 1.0.0 [--root <repository>]   # markdown on stdout

Rows are grouped by phase, in phase order, with the phase's name from hubs/product/plan/_PLAN.md; the
rows of the R&D app (no phase) come first as "The basics". A phase note at the end of a row ("(P3; not
read back, …)") and a hub id (NT-PRF-001, D19) are for the hubs, not for users: they are left out, and so
are rows about the readback tool.
"""
import argparse
import glob
import os
import re
import sys

ROW = re.compile(r"^\| (NT-FEAT-\d+) \| (.*) \| ([^|]*) \| ([^|]*) \| ([^|]*) \|\s*$")
PHASE = re.compile(r"\((P\d+)[-;)]")
NOTE = re.compile(r"\s*\(P\d+[^()]*(\([^()]*\)[^()]*)*\)\s*$")
REFS = re.compile(r",\s*(NT-[A-Z]+-\d+|D\d+|Q\d+)(?=[,)])")
PLAN_ROW = re.compile(r"^\| (P\d+) ([^|]+?) \| \d+\.\d+\.\d+ \|")


def parse_rows(text):
    """Every feature row of a features shelf: id, text (without its phase note) and phase (None: R&D)."""
    rows = []
    for line in text.splitlines():
        match = ROW.match(line)
        if not match:
            continue
        ident, feature, commit = match.group(1), match.group(2).strip(), match.group(3)
        found = PHASE.search(commit) or PHASE.search(feature)
        text = REFS.sub("", NOTE.sub("", feature))  # hub ids (NT-PRF-001, D19, Q5) are for the hubs
        rows.append({"id": ident, "text": text, "phase": found.group(1) if found else None})
    return rows


def phase_names(plan_text):
    """P1 -> "Tab lifecycle", from the phases table of _PLAN.md."""
    names = {}
    for line in plan_text.splitlines():
        match = PLAN_ROW.match(line)
        if match:
            names[match.group(1)] = match.group(2).strip()
    return names


def internal(row):
    return row["text"].lower().startswith("readback")


def notes(version, rows, names):
    """The notes in markdown. No row: an error, never empty notes."""
    shown = [row for row in rows if not internal(row)]
    if not shown:
        raise ValueError("no feature row: the notes would be empty")
    order = sorted({row["phase"] for row in shown}, key=lambda phase: -1 if phase is None else int(phase[1:]))
    lines = [f"# nhetrinh {version}", "",
             "A very small macOS browser: WebKit, a vertical tab sidebar, the basics. Lightness first.", ""]
    for phase in order:
        lines += [f"## {'The basics' if phase is None else names.get(phase, phase)}", ""]
        lines += [f"- {row['text']}" for row in shown if row["phase"] == phase] + [""]
    return "\n".join(lines + install(version)) + "\n"


def install(version):
    zip_name = f"nhetrinh-{version}-arm64.zip"
    return ["## Install", "",
            f"Apple silicon, macOS 13 or later. Download `{zip_name}` and `{zip_name}.sha256`, check it with",
            f"`shasum -a 256 -c {zip_name}.sha256`, unzip, and move nhetrinh.app to Applications.",
            "nhetrinh is not notarized (there is no Apple Developer ID): the first open shows a macOS warning.",
            "Open it once from System Settings > Privacy & Security > Open Anyway. The README says more."]


def main(argv):
    parser = argparse.ArgumentParser(description="nhetrinh release notes from the feature rows")
    parser.add_argument("version")
    parser.add_argument("--root", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
    args = parser.parse_args(argv)
    product = os.path.join(args.root, "hubs", "product")
    rows = []
    for shelf in sorted(glob.glob(os.path.join(product, "features", "S*.md"))):
        with open(shelf, encoding="utf-8") as file:
            rows += parse_rows(file.read())
    with open(os.path.join(product, "plan", "_PLAN.md"), encoding="utf-8") as file:
        names = phase_names(file.read())
    sys.stdout.write(notes(args.version, rows, names))


if __name__ == "__main__":
    main(sys.argv[1:])
