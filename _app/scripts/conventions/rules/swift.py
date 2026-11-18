"""Swift rules: function length, parameter count, no force unwrap / try! / as!, no dependencies.

A heuristic reader, not a compiler: strings and comments are blanked, then braces are counted.
A line may carry the marker `// force: <reason>` to allow one force unwrap.
"""

from __future__ import annotations

import re

from rules.sizes import FUNC_MAX_LINES, MAX_PARAMS

MODIFIERS = "private|fileprivate|internal|public|open|static|class|final|override|mutating|convenience|required"
DECL = re.compile(rf"^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:{MODIFIERS})\s+)*(func\s+[\w`]+|init[?!]?)\s*[<(]")
STRING = re.compile(r'"(?:\\.|[^"\\])*"')
FORCE = re.compile(r"\btry!|\bas!|[\w\)\]]!(?![=\w])")


def clean_lines(text: str) -> list[str]:
    """The lines with string contents and comments removed; multi-line strings are blanked."""
    cleaned, in_block = [], False
    for line in text.splitlines():
        toggles = line.count('"""')
        if in_block or toggles:
            in_block = in_block != (toggles % 2 == 1)
            cleaned.append("")
            continue
        cleaned.append(STRING.sub('""', line).split("//", 1)[0])
    return cleaned


def signature_end(lines: list[str], start: int) -> tuple[int, int, str]:
    """(line, column) just after the parameter list that opens on `start`, and its text."""
    depth, params = 0, []
    for number in range(start, min(start + 20, len(lines))):
        line = lines[number]
        begin = line.index("(", DECL.match(line).end() - 1) if number == start else 0
        for column in range(begin, len(line)):
            char = line[column]
            depth += char == "("
            depth -= char == ")"
            if depth == 0:
                return number, column + 1, "".join(params)[1:]
            params.append(char)
        params.append(" ")
    return start, len(lines[start]), ""


def body_end(lines: list[str], line: int, column: int) -> int | None:
    """Last line of the body that opens after (line, column); None for a declaration with no body."""
    depth, opened = 0, False
    for number in range(line, len(lines)):
        text = lines[number][column:] if number == line else lines[number]
        if not opened and number > line and (DECL.match(text) or text.strip() == "}"):
            return None
        for char in text:
            depth += char == "{"
            depth -= char == "}"
            opened = opened or char == "{"
            if opened and depth == 0:
                return number
    return None


def param_count(params: str) -> int:
    depth, count = 0, 1 if params.strip() else 0
    for char in params.replace("->", "  "):
        depth += char in "([<{"
        depth -= char in ")]>}"
        count += char == "," and depth == 0
    return count


def functions(path: str, lines: list[str]) -> list[str]:
    found = []
    for start, line in enumerate(lines):
        match = DECL.match(line)
        if not match:
            continue
        name = match.group(1).replace("func ", "")
        end_line, end_column, params = signature_end(lines, start)
        if param_count(params) > MAX_PARAMS:
            found.append(f"{path}:{start + 1}: `{name}` has {param_count(params)} parameters (max {MAX_PARAMS})")
        last = body_end(lines, end_line, end_column)
        if last is not None and last - start + 1 > FUNC_MAX_LINES:
            found.append(f"{path}:{start + 1}: `{name}` is {last - start + 1} lines (max {FUNC_MAX_LINES})")
    return found


def violations(path: str, text: str) -> list[str]:
    lines = clean_lines(text)
    found = functions(path, lines)
    for number, (raw, line) in enumerate(zip(text.splitlines(), lines), 1):
        if FORCE.search(line) and "// force:" not in raw:
            found.append(f"{path}:{number}: force unwrap, try! or as! (handle the nil, or mark `// force: <reason>`)")
    if path.endswith("Package.swift") and any(".package(" in line for line in lines):
        found.append(f"{path}: a package dependency (nhetrinh uses only Apple frameworks)")
    return found
