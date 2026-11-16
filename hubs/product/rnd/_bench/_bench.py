"""nhetrinh lightness benchmark: the R&D record, safe for a machine that is in use.

One app instance at a time, started through LaunchServices like a Dock click. Before every
launch the previous instance and all its helpers must be gone. Memory is the footprint of the
app and every process it is responsible for (measure/memsum).

Tabs load one after another (NHT_BENCH_LOADALL + NHT_BENCH_LOAD_GAP_S), never in a burst, and
a scenario holds at most MAX_TABS tabs (NT-ENV-001: a 30-tab burst once loaded the machine).

The 2026-11-16 run compared MVP A (WebKit) with MVP B (Chromium). That code is in commit
ff3ae8c and its numbers are in results/. Today this harness measures the real app.

Usage: python3 _bench.py [scenario ...]      default: startup tabs10
       speedometer and jetstream hold a CPU core for minutes: ask the headmate first.
"""

from __future__ import annotations

import http.server
import json
import sys
import threading
import time
from pathlib import Path

import procs

HERE = Path(__file__).resolve().parent
RAW = HERE / "results" / "raw.jsonl"
REPO = HERE.parents[3]
APP = {"bundle": REPO / "_app/build/nhetrinh.app", "proc": "nhetrinh", "helper": None}

MAX_TABS = 10
LOAD_GAP_S = 3
LOCAL = "http://127.0.0.1:8765/_startup.html"
SITES_10 = [
    "https://en.wikipedia.org/wiki/Web_browser",
    "https://github.com/torvalds/linux",
    "https://www.youtube.com/",
    "https://developer.mozilla.org/en-US/",
    "https://stackoverflow.com/questions",
    "https://www.bbc.com/news",
    "https://www.apple.com/",
    "https://news.ycombinator.com/",
    "https://www.theverge.com/",
    "https://docs.python.org/3/",
]
SPEEDOMETER = "https://browserbench.org/Speedometer3.1/?startAutomatically=true"
SPEEDO_JS = (
    "(function(){var r=document.getElementById('result-number');"
    "return r&&r.textContent?'SCORE:'+r.textContent:'wait'})()"
)
JETSTREAM = "https://browserbench.org/JetStream2.2/"
JETSTREAM_JS = (
    "(function(){var s=document.querySelector('#result-summary .score');"
    "if(s)return 'SCORE:'+s.textContent;"
    "var a=document.querySelector('#status a');"
    "if(a&&!window.__nht){window.__nht=1;a.click();return 'started'}return 'wait'})()"
)

# name -> (repetitions, environment, settle seconds, event to wait for, event timeout, CPU window)
SCENARIOS: dict[str, tuple] = {
    "startup": (5, {"NHT_BENCH_URLS": LOCAL}, 5, "first_load", 60, 0),
    "tabs10": (3, {"NHT_BENCH_URLS": ",".join(SITES_10), "NHT_BENCH_LOADALL": "1",
                   "NHT_BENCH_LOAD_GAP_S": str(LOAD_GAP_S)}, MAX_TABS * LOAD_GAP_S + 20, "first_load", 60, 10),
    "speedometer": (3, {"NHT_BENCH_URLS": SPEEDOMETER, "NHT_BENCH_POLL_JS": SPEEDO_JS}, 0, "score", 600, 0),
    "jetstream": (2, {"NHT_BENCH_URLS": JETSTREAM, "NHT_BENCH_POLL_JS": JETSTREAM_JS}, 0, "score", 900, 0),
}
DEFAULT = ["startup", "tabs10"]


def record(row: dict) -> None:
    print(json.dumps(row), flush=True)
    with RAW.open("a") as out:
        out.write(json.dumps(row) + "\n")


def run_once(name: str) -> None:
    _, env, settle, event, event_timeout, cpu_s = SCENARIOS[name]
    tabs = env.get("NHT_BENCH_URLS", "").count(",") + 1
    if tabs > MAX_TABS:
        raise ValueError(f"{name}: {tabs} tabs, the cap is {MAX_TABS}")
    procs.wait_clean(APP)
    pid = procs.launch(APP, env)
    seen = procs.wait_event(event, event_timeout)
    time.sleep(settle)
    mem = procs.memsum(pid, cpu_s) if procs.pids(APP["proc"]) else {}
    procs.kill(APP)
    keys = ("total_mb", "main_mb", "procs", "cpu_pct")
    record({"app": "nhetrinh", "scenario": name, "event": seen, **{k: mem.get(k) for k in keys}})


def serve_local() -> None:
    site = str(HERE / "site")

    class Quiet(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *args) -> None:
            super().__init__(*args, directory=site)

        def log_message(self, *args) -> None:
            pass

    server = http.server.ThreadingHTTPServer(("127.0.0.1", 8765), Quiet)
    threading.Thread(target=server.serve_forever, daemon=True).start()


def main() -> None:
    RAW.parent.mkdir(exist_ok=True)
    serve_local()
    procs.kill(APP)
    for name in sys.argv[1:] or DEFAULT:
        for _ in range(SCENARIOS[name][0]):
            run_once(name)


if __name__ == "__main__":
    main()
