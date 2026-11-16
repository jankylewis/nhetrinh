"""../results/raw.jsonl -> ../results/_RESULTS.md: the median per app and scenario (R&D run, A vs B)."""

from __future__ import annotations

import json
import statistics
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
RAW = HERE.parent / "results" / "raw.jsonl"
OUT = HERE.parent / "results" / "_RESULTS.md"

ROWS = [  # (label, scenario, field, unit, better)
    ("Startup to first page (local)", "startup_local_page", "event_ms", "ms", "lower"),
    ("Memory, 1 simple tab", "startup_local_page", "total_mb", "MB", "lower"),
    ("  of which: app process", "startup_local_page", "main_mb", "MB", "lower"),
    ("Memory, 10 real sites loaded", "tabs10_loaded", "total_mb", "MB", "lower"),
    ("CPU idle, 10 sites loaded", "tabs10_loaded", "cpu_pct", "%", "lower"),
    ("Memory, 30 real sites loaded", "tabs30_loaded", "total_mb", "MB", "lower"),
    ("Processes, 30 sites loaded", "tabs30_loaded", "procs", "", "lower"),
    ("Speedometer 3.1", "speedometer3.1", "score", "runs/min", "higher"),
    ("JetStream 2.2", "jetstream2.2", "score", "", "higher"),
]


def value(row: dict, field: str) -> float | None:
    ev = row.get("event") or {}
    if field == "event_ms":
        return ev.get("ms")
    if field == "score":
        raw = str(ev.get("value", "")).split()[0] if ev.get("value") else ""
        return float(raw) if raw else None
    return row.get(field)


def main() -> None:
    data: dict[tuple[str, str, str], list[float]] = defaultdict(list)
    for line in RAW.read_text().splitlines():
        row = json.loads(line)
        for _, scen, field, _, _ in ROWS:
            if row["scenario"] == scen and (v := value(row, field)) is not None:
                data[(row["app"], scen, field)].append(v)
    out = ["| Metric | A: WebKit | B: Chromium | Better | n (A/B) |", "|---|---|---|---|---|"]
    for label, scen, field, unit, better in ROWS:
        a, b = data.get(("A", scen, field), []), data.get(("B", scen, field), [])
        if not a and not b:
            continue
        ma = statistics.median(a) if a else None
        mb = statistics.median(b) if b else None
        win = "-"
        if ma is not None and mb is not None and ma != mb:
            win = "A" if (ma < mb) == (better == "lower") else "B"
        fmt = lambda m: "n/a" if m is None else f"{m:,.1f} {unit}".strip()  # noqa: E731
        out.append(f"| {label} | {fmt(ma)} | {fmt(mb)} | {win} | {len(a)}/{len(b)} |")
    OUT.write_text("\n".join(out) + "\n")
    print("\n".join(out))


if __name__ == "__main__":
    main()
