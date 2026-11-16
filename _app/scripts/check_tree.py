"""Check the repo's two folder taxonomies on every folder git sees (tracked + new, not ignored).

1. `_` mark: exactly one entry (file or folder) per folder starts with `_`: its most critical entry.
2. HD: at most 5 entries per folder; past 5, group them into meaningful sub-folders.

Dot entries (.github, .gitignore) are exempt. Exit 1 with one line per violation.
Usage: python3 -I _app/scripts/check_tree.py
"""

from __future__ import annotations

import subprocess
import sys
from collections import defaultdict
from pathlib import PurePosixPath

MAX_ENTRIES = 5


def tree_entries(root: str) -> dict[str, set[str]]:
    out = subprocess.run(["git", "-C", root, "ls-files", "--cached", "--others", "--exclude-standard"],
                         capture_output=True, text=True, check=True).stdout
    folders: dict[str, set[str]] = defaultdict(set)
    for line in out.splitlines():
        parts = PurePosixPath(line).parts
        if any(p.startswith(".") for p in parts):
            continue
        for depth in range(len(parts)):
            folders["/".join(parts[:depth]) or "."].add(parts[depth])
    return folders


def violations(folders: dict[str, set[str]]) -> list[str]:
    found = []
    for folder, entries in sorted(folders.items()):
        marks = sorted(e for e in entries if e.startswith("_"))
        if len(marks) != 1:
            found.append(f"{folder}: {len(marks)} `_` entries {marks or ''} (need exactly 1)")
        if len(entries) > MAX_ENTRIES:
            found.append(f"{folder}: {len(entries)} entries (max {MAX_ENTRIES}): {sorted(entries)}")
    return found


def main() -> int:
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True,
                          check=True).stdout.strip()
    folders = tree_entries(root)
    bad = violations(folders)
    for line in bad:
        print(line)
    print(f"check_tree: {len(folders)} folders, {len(bad)} violations")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
