"""Check nhetrinh's conventions on every file git sees (tracked and new, not ignored).

Folders (dot folders exempt): exactly one `_` entry per folder, at most 5 entries.
Files: .md at most 100 lines; code at most 150 lines and 120 characters a line.
Swift and Python: function at most 30 lines and 5 parameters.
Swift: no force unwrap, try! or as!; Package.swift has no dependency.
Hubs: every bug, failure, tool gap and lesson entry has `found_by:`; both TRIAGE tables a Found by column.

Prints one line per violation and exits 1.   Usage: python3 _app/scripts/conventions/_check.py
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from rules import _folders as folders
from rules import hubs, sizes, swift

TEXT_SUFFIXES = {".md"} | sizes.CODE_SUFFIXES


def git(root: str, *args: str) -> str:
    return subprocess.run(["git", "-C", root, *args], capture_output=True, text=True, check=True).stdout


def all_violations(root: str) -> tuple[int, list[str]]:
    paths = git(root, "ls-files", "--cached", "--others", "--exclude-standard").splitlines()
    paths = [path for path in paths if (Path(root) / path).is_file()]
    found = folders.violations(paths)
    for path in paths:
        if Path(path).suffix not in TEXT_SUFFIXES:
            continue
        text = (Path(root) / path).read_text(encoding="utf-8")
        found += sizes.violations(path, text)
        found += hubs.violations(path, text)
        if path.endswith(".swift"):
            found += swift.violations(path, text)
    return len(paths), found


def main() -> int:
    root = git(".", "rev-parse", "--show-toplevel").strip()
    count, found = all_violations(root)
    for line in found:
        print(line)
    print(f"conventions: {count} files, {len(found)} violations")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
