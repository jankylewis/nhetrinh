"""Size rules for every file, and function rules for Python (Swift is in swift.py)."""

from __future__ import annotations

import ast
from pathlib import PurePosixPath

MD_MAX_LINES = 100
CODE_MAX_LINES = 150
LINE_MAX_CHARS = 120
FUNC_MAX_LINES = 30
MAX_PARAMS = 5
CODE_SUFFIXES = {".swift", ".py", ".c", ".sh", ".yml"}


def violations(path: str, text: str) -> list[str]:
    suffix = PurePosixPath(path).suffix
    lines = text.splitlines()
    found = []
    if suffix == ".md" and len(lines) > MD_MAX_LINES:
        found.append(f"{path}: {len(lines)} lines (.md max {MD_MAX_LINES})")
    if suffix in CODE_SUFFIXES:
        if len(lines) > CODE_MAX_LINES:
            found.append(f"{path}: {len(lines)} lines (code max {CODE_MAX_LINES})")
        for number, line in enumerate(lines, 1):
            if len(line) > LINE_MAX_CHARS:
                found.append(f"{path}:{number}: {len(line)} characters (max {LINE_MAX_CHARS})")
    if suffix == ".py":
        found += python_functions(path, text)
    return found


def python_functions(path: str, text: str) -> list[str]:
    found = []
    for node in ast.walk(ast.parse(text)):
        if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        length = (node.end_lineno or node.lineno) - node.lineno + 1
        if length > FUNC_MAX_LINES:
            found.append(f"{path}:{node.lineno}: `{node.name}` is {length} lines (max {FUNC_MAX_LINES})")
        args = node.args
        names = [a.arg for a in args.posonlyargs + args.args + args.kwonlyargs]
        count = len([name for name in names if name not in ("self", "cls")])
        if count > MAX_PARAMS:
            found.append(f"{path}:{node.lineno}: `{node.name}` has {count} parameters (max {MAX_PARAMS})")
    return found
