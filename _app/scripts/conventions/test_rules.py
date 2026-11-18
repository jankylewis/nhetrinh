"""Tests of the conventions checker: every rule must pass a good case and catch a broken one.

Run: python3 -m unittest discover -s _app/scripts/conventions -p 'test_*.py'
"""

from __future__ import annotations

import unittest

from rules import _folders as folders
from rules import sizes, swift

GOOD_TREE = ["a/_core.swift", "a/b.swift", "_a.md", "top.md", ".github/x.yml", ".github/y.yml"]


def swift_func(lines: int, params: str = "") -> str:
    body = "\n".join("        work()" for _ in range(lines - 2))
    return f"final class A {{\n    func run({params}) {{\n{body}\n    }}\n}}\n"


def python_func(lines: int, params: str = "") -> str:
    return f"def run({params}):\n" + "\n".join("    pass" for _ in range(lines - 1)) + "\n"


class FolderRules(unittest.TestCase):
    def test_good_tree_has_no_violation(self) -> None:
        self.assertEqual(folders.violations(GOOD_TREE), [])

    def test_broken_trees_are_caught(self) -> None:
        cases = {
            "no mark": (["a/b.swift", "_a.md"], "a: 0 `_` entries"),
            "two marks": (["_a.md", "_b.md"], ".: 2 `_` entries"),
            "six entries": (["_a", "b", "c", "d", "e", "f"], ".: 6 entries"),
            "deep folder": (["_a/_b/c/x.md"], "_a/_b/c: 0 `_` entries"),
        }
        for name, (paths, expected) in cases.items():
            with self.subTest(name):
                self.assertTrue(any(expected in line for line in folders.violations(paths)))

    def test_dot_folders_are_exempt(self) -> None:
        paths = ["_a.md"] + [f".claude/skills/s{i}/SKILL.md" for i in range(8)]
        self.assertEqual(folders.violations(paths), [])


class SizeRules(unittest.TestCase):
    def test_caps(self) -> None:
        cases = {
            "md at cap": ("a.md", "x\n" * 100, 0),
            "md over cap": ("a.md", "x\n" * 101, 1),
            "skill file over cap": (".claude/skills/s/SKILL.md", "x\n" * 101, 1),
            "swift at cap": ("a.swift", "x\n" * 150, 0),
            "swift over cap": ("a.swift", "x\n" * 151, 1),
            "shell over cap": ("a.sh", "x\n" * 151, 1),
            "line at cap": ("a.py", "#" * 120 + "\n", 0),
            "line over cap": ("a.py", "#" * 121 + "\n", 1),
            "md long line is allowed": ("a.md", "|" * 300 + "\n", 0),
            "data file is not checked": ("a.jsonl", "x\n" * 999, 0),
        }
        for name, (path, text, count) in cases.items():
            with self.subTest(name):
                self.assertEqual(len(sizes.violations(path, text)), count)

    def test_python_functions(self) -> None:
        cases = {
            "30 lines": (python_func(30), 0),
            "31 lines": (python_func(31), 1),
            "5 parameters": (python_func(2, "a, b, c, d, e"), 0),
            "6 parameters": (python_func(2, "a, b, c, d, e, f"), 1),
            "self does not count": (python_func(2, "self, a, b, c, d, e"), 0),
        }
        for name, (text, count) in cases.items():
            with self.subTest(name):
                self.assertEqual(len(sizes.violations("a.py", text)), count)


class SwiftRules(unittest.TestCase):
    def test_function_length_and_parameters(self) -> None:
        closure = "_ a: Int, done: @escaping (Int, Int) -> Void, map: [String: Int], d: Int, e: Int"
        cases = {
            "30 lines": (swift_func(30), 0),
            "31 lines": (swift_func(31), 1),
            "5 parameters": (swift_func(3, "a: Int, b: Int, c: Int, d: Int, e: Int"), 0),
            "6 parameters": (swift_func(3, "a: Int, b: Int, c: Int, d: Int, e: Int, f: Int"), 1),
            "commas inside types do not count": (swift_func(3, closure), 0),
            "braces in strings do not count": ('func a() {\n    print("}{{{")\n}\n', 0),
            "protocol requirement has no body": ("protocol P {\n    func a()\n    func b()\n}\n", 0),
            "long init": ("init() {\n" + "    work()\n" * 30 + "}\n", 1),
            "signature on two lines": ("func a(_ x: Int,\n       y: Int) -> Int {\n    return 1\n}\n", 0),
        }
        for name, (text, count) in cases.items():
            with self.subTest(name):
                self.assertEqual(len(swift.violations("a.swift", text)), count, swift.violations("a.swift", text))

    def test_force_unwraps(self) -> None:
        cases = {
            "force unwrap": ("let a = b!\n", 1),
            "unwrap of a call": ("let a = f()!\n", 1),
            "unwrap then member": ("let a = b!.c\n", 1),
            "try!": ("let a = try! f()\n", 1),
            "as!": ("let a = b as! C\n", 1),
            "implicitly unwrapped type": ("var a: Foo!\n", 1),
            "marked with a reason": ("let a = b!  // force: constant, cannot fail\n", 0),
            "not equal": ("if a != b { }\n", 0),
            "logical not": ("if !a { }\n", 0),
            "bang in a string": ('let a = "go!"\n', 0),
            "bang in a comment": ("let a = 1  // done!\n", 0),
            "optional chaining": ("let a = b?.c ?? d\n", 0),
        }
        for name, (text, count) in cases.items():
            with self.subTest(name):
                self.assertEqual(len(swift.violations("a.swift", text)), count)

    def test_package_dependencies(self) -> None:
        dependency = 'let p = Package(dependencies: [.package(url: "x", from: "1.0.0")])\n'
        self.assertEqual(len(swift.violations("_app/Package.swift", dependency)), 1)
        self.assertEqual(len(swift.violations("_app/Package.swift", "let p = Package(name: \"n\")\n")), 0)


if __name__ == "__main__":
    unittest.main()
