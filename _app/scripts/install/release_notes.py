"""The release notes of nhetrinh (P8), made from the hubs/product/features rows.

    python3 _app/scripts/install/release_notes.py 1.0.0 [--root <repository>]   # markdown on stdout
    python3 _app/scripts/install/release_notes.py 0.8.0 --kind                  # prerelease | release

Rows are grouped by phase, in phase order, with the phase's name from hubs/product/plan/_PLAN.md; the
rows of the R&D app (no phase) come first as "The basics". A shelf whose header has a "Release note" column
(| Id | Feature | Release note | Commit | Date | Closed bug |) gives the notes that column, written for users
of the release; "-" leaves the row out (a tool row, or a row a later change superseded: its new row says
how it works now). A shelf without that column falls back to the feature text, less its phase note, task
ids, hub ids and a remark about the readback. A feature row of the wrong shape, an empty note, or a note
with a hub id, a task id or the readback in it is an error: the build fails, never silent notes.
"""
import argparse
import glob
import os
import re
import sys

ROW = re.compile(r"^\| (NT-FEAT-\d+) \| (.*) \| ([^|]*) \| ([^|]*) \| ([^|]*) \|\s*$")
NOTED_ROW = re.compile(r"^\| (NT-FEAT-\d+) \| (.*) \| ([^|]*) \| ([^|]*) \| ([^|]*) \| ([^|]*) \|\s*$")
NOTED_HEAD = re.compile(r"^\| Id \| Feature \| Release note \|")
TASK = re.compile(r"\s*\(P\d+-[A-Z]+-\d+\)")
TOOL_REMARK = re.compile(r"\s*\([^()]*readback[^()]*\)", re.IGNORECASE)
INTERNAL = re.compile(r"(?i:readback)|NT-[A-Z]+-\d+|\bP\d+-[A-Z]+-\d+")
PHASE = re.compile(r"\((P\d+)[-;)]")
NOTE = re.compile(r"\s*\(P\d+[^()]*(\([^()]*\)[^()]*)*\)\s*$")
REFS = re.compile(r",\s*(NT-[A-Z]+-\d+|D\d+|Q\d+)(?=[,)])")
VERSION = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")
PLAN_ROW = re.compile(r"^\| (P\d+) ([^|]+?) \| \d+\.\d+\.\d+ \|")


def parse_rows(text):
    """Every feature row of a features shelf: id, note for users (None: not in the notes) and phase (None: R&D)."""
    rows, shape = [], ROW
    for number, line in enumerate(text.splitlines(), 1):
        if NOTED_HEAD.match(line):
            shape = NOTED_ROW
        if not line.startswith("| NT-FEAT-"):
            continue
        match = shape.match(line)
        if not match:
            raise ValueError(f"line {number}: a feature row of the wrong shape: {line}")
        rows.append(noted(match) if shape is NOTED_ROW else fallback(match))
    return rows


def noted(match):
    ident, note, commit = match.group(1), match.group(3).strip(), match.group(4)
    if not note:
        raise ValueError(f"{ident}: an empty release note (write - to leave the row out)")
    found = PHASE.search(commit) or PHASE.search(match.group(2))
    return {"id": ident, "text": None if note == "-" else note, "phase": found.group(1) if found else None}


def fallback(match):
    ident, feature, commit = match.group(1), match.group(2).strip(), match.group(3)
    found = PHASE.search(commit) or PHASE.search(feature)
    text = TOOL_REMARK.sub("", TASK.sub("", REFS.sub("", NOTE.sub("", feature))))
    if text.lower().startswith("readback"):
        text = None  # a row about the readback tool
    return {"id": ident, "text": text, "phase": found.group(1) if found else None}


def phase_names(plan_text):
    """P1 -> "Tab lifecycle", from the phases table of _PLAN.md."""
    names = {}
    for line in plan_text.splitlines():
        match = PLAN_ROW.match(line)
        if match:
            names[match.group(1)] = match.group(2).strip()
    return names


def prerelease(version):
    """0.x is a GitHub prerelease (not "latest"); 1.0.0 and later a full release (headmate ruling, D26)."""
    match = VERSION.match(version)
    if not match:
        raise ValueError(f"version {version!r} is not <major>.<minor>.<patch>")
    return int(match.group(1)) == 0


def notes(version, rows, names):
    """The notes in markdown. No row: an error, never empty notes."""
    shown = [row for row in rows if row["text"]]
    for row in shown:
        if INTERNAL.search(row["text"]):
            raise ValueError(f"{row['id']}: the note says {INTERNAL.search(row['text']).group(0)!r}, not for users")
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
    parser.add_argument("--kind", action="store_true", help="print prerelease (0.x) or release, nothing else")
    parser.add_argument("--root", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
    args = parser.parse_args(argv)
    if args.kind:
        sys.stdout.write(("prerelease" if prerelease(args.version) else "release") + "\n")
        return
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
