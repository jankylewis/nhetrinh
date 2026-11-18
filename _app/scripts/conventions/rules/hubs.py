"""Hub rules (HUB-FOUNDBY-1, headmate rule 2026-11-18): every bug, failure, tool gap and lesson says who
found it. An entry of these hubs needs a head line `found_by: <value> (<source>)`, the source not empty, among
the head lines (before the first `## ` heading); both TRIAGE tables a `Found by` column,
second after Id (later cells may hold a `|` inside backticks), with a valid value on every row."""

from __future__ import annotations

import re
from pathlib import PurePosixPath

FOUND_BY = ("headmate", "readback", "self-test", "development")
ENTRY_HUBS = ("hubs/bugs/bugfacing/", "hubs/failures/failurereason/", "hubs/lessons/toolgap/",
              "hubs/lessons/lessonlearn/")
TRIAGES = ("hubs/bugs/TRIAGE.md", "hubs/failures/TRIAGE.md")
LINE = re.compile(r"^found_by: (" + "|".join(FOUND_BY) + r") \(.*\S.*\)$")


def violations(path: str, text: str) -> list[str]:
    if path in TRIAGES:
        return triage(path, text)
    name = PurePosixPath(path).name
    if path.startswith(ENTRY_HUBS) and name.endswith(".md") and not name.startswith("_") and not found_by(text):
        return [f"{path}: no head line `found_by: <{'|'.join(FOUND_BY)}> (<source>)`"]
    return []


def found_by(text: str) -> bool:
    """Whether a valid `found_by` line is among the head lines: those before the first `## ` heading."""
    for line in text.splitlines():
        if line.startswith("## "):
            return False
        if LINE.match(line):
            return True
    return False


def triage(path: str, text: str) -> list[str]:
    rows = [line for line in text.splitlines() if line.startswith("|")]
    header = [cell.strip() for cell in rows[0].split("|")] if rows else []
    if header[1:3] != ["Id", "Found by"]:
        return [f"{path}: the table needs a `Found by` column right after Id"]
    found = []
    for row in rows:
        cells = [cell.strip() for cell in row.split("|")]
        if not cells[1].startswith("NT-"):
            continue
        if cells[2] not in FOUND_BY:
            found.append(f"{path}: {cells[1]} has no valid Found by ({' | '.join(FOUND_BY)})")
    return found
