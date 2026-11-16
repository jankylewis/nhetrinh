"""Folder rules: one `_` entry per folder (its most critical entry), at most 5 entries."""

from __future__ import annotations

from collections import defaultdict
from pathlib import PurePosixPath

MAX_ENTRIES = 5


def tree(paths: list[str]) -> dict[str, set[str]]:
    """Folder -> direct entries, from repo-relative file paths. Dot entries are exempt."""
    folders: dict[str, set[str]] = defaultdict(set)
    for path in paths:
        parts = PurePosixPath(path).parts
        if any(part.startswith(".") for part in parts):
            continue
        for depth in range(len(parts)):
            folders["/".join(parts[:depth]) or "."].add(parts[depth])
    return folders


def violations(paths: list[str]) -> list[str]:
    found = []
    for folder, entries in sorted(tree(paths).items()):
        marks = sorted(entry for entry in entries if entry.startswith("_"))
        if len(marks) != 1:
            found.append(f"{folder}: {len(marks)} `_` entries {marks} (need exactly 1)")
        if len(entries) > MAX_ENTRIES:
            found.append(f"{folder}: {len(entries)} entries (max {MAX_ENTRIES}); group them by meaning")
    return found
