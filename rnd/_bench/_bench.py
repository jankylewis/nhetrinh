"""nhetrinh R&D benchmark: MVP A (WebKit) vs MVP B (Chromium/CEF).

One app at a time, A/B alternating per repetition, each launch via LaunchServices (`open`)
like a Dock click. Before every launch, wait until the previous instance and all of its
helper processes are gone. Results: results/raw.jsonl (one line per measurement).

Usage: python3 -I _bench.py [scenario ...]   (default: all)
"""

from __future__ import annotations

import http.server
import json
import os
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
RND = HERE.parent
RESULTS = HERE / "results"
EVENTS = RESULTS / "events.jsonl"
RAW = RESULTS / "raw.jsonl"
MEMSUM = HERE / "memsum"

APPS = {
    # The R&D run compared MVP A (WebKit) and MVP B (Chromium); their code is in commit ff3ae8c.
    # Today the harness measures the real app for the lightness budget.
    "A": {"bundle": RND.parent / "_app/build/nhetrinh.app", "proc": "nhetrinh", "helper": None},
}

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
WIKI = ["WebKit", "Chromium_(web_browser)", "Safari_(web_browser)", "Google_Chrome", "Firefox",
        "Rust_(programming_language)", "Swift_(programming_language)", "MacOS", "Apple_silicon",
        "HTML", "CSS", "JavaScript", "WebAssembly", "HTTP", "Domain_Name_System",
        "Transport_Layer_Security", "Unicode", "Linux", "Git", "Vietnam"]
SITES_30 = SITES_10 + [f"https://en.wikipedia.org/wiki/{w}" for w in WIKI]

SPEEDOMETER = "https://browserbench.org/Speedometer3.1/?startAutomatically=true"
SPEEDO_JS = "(function(){var r=document.getElementById('result-number');return r&&r.textContent?'SCORE:'+r.textContent:'wait'})()"
JETSTREAM = "https://browserbench.org/JetStream2.2/"
JETSTREAM_JS = ("(function(){var s=document.querySelector('#result-summary .score');if(s)return 'SCORE:'+s.textContent;"
                "var a=document.querySelector('#status a');if(a&&!window.__nht){window.__nht=1;a.click();return 'started'}"
                "return 'wait'})()")


# region process control

def pids(name: str) -> list[int]:
    out = subprocess.run(["pgrep", "-x", name], capture_output=True, text=True).stdout
    return [int(p) for p in out.split()]


def helper_pids(app: dict) -> list[int]:
    if not app["helper"]:
        return []
    out = subprocess.run(["pgrep", "-f", app["helper"]], capture_output=True, text=True).stdout
    return [int(p) for p in out.split()]


def wait_clean(app: dict, timeout: float = 60) -> None:
    end = time.time() + timeout
    while time.time() < end:
        if not pids(app["proc"]) and not helper_pids(app):
            time.sleep(3)  # let WebKit XPC services exit too
            return
        time.sleep(0.5)
    raise RuntimeError(f"{app['proc']} did not exit")


def kill(app: dict) -> None:
    for p in pids(app["proc"]) + helper_pids(app):
        try:
            os.kill(p, signal.SIGKILL)
        except ProcessLookupError:
            pass
    wait_clean(app)


def launch(app: dict, env: dict[str, str]) -> int:
    EVENTS.unlink(missing_ok=True)
    cmd = ["open", "-n", "-F"]
    for k, v in {"NHT_BENCH_OUT": str(EVENTS), **env}.items():
        cmd += ["--env", f"{k}={v}"]
    subprocess.run(cmd + [str(app["bundle"])], check=True, timeout=30)
    for _ in range(100):
        if found := pids(app["proc"]):
            return found[-1]
        time.sleep(0.1)
    raise RuntimeError("app did not start")


def wait_event(name: str, timeout: float) -> dict | None:
    end = time.time() + timeout
    while time.time() < end:
        if EVENTS.exists():
            for line in EVENTS.read_text().splitlines():
                ev = json.loads(line)
                if ev["event"] == name:
                    return ev
        time.sleep(0.25)
    return None


def memsum(pid: int, cpu_s: float = 0) -> dict:
    args = [str(MEMSUM), str(pid)] + ([str(cpu_s)] if cpu_s else [])
    out = subprocess.run(args, capture_output=True, text=True, timeout=cpu_s + 30).stdout
    return json.loads(out)

# endregion


def record(row: dict) -> None:
    print(json.dumps(row), flush=True)
    with RAW.open("a") as f:
        f.write(json.dumps(row) + "\n")


def run_once(key: str, scenario: str, env: dict[str, str], settle: float,
             event: str = "first_load", event_timeout: float = 60, cpu_s: float = 0) -> None:
    app = APPS[key]
    wait_clean(app)
    pid = launch(app, env)
    ev = wait_event(event, event_timeout)
    time.sleep(settle)
    mem = memsum(pid, cpu_s) if pids(app["proc"]) else {}
    kill(app)
    record({"app": key, "scenario": scenario, "event": ev,
            **{k: mem.get(k) for k in ("total_mb", "main_mb", "procs", "cpu_pct")}})


def scenarios(reps: int) -> dict:
    urls = lambda us: ",".join(us)  # noqa: E731
    return {
        "startup": lambda k: run_once(k, "startup_local_page", {"NHT_BENCH_URLS": LOCAL}, settle=5),
        "tabs10": lambda k: run_once(k, "tabs10_loaded", {"NHT_BENCH_URLS": urls(SITES_10), "NHT_BENCH_LOADALL": "1"},
                                     settle=30, cpu_s=10),
        "tabs30": lambda k: run_once(k, "tabs30_loaded", {"NHT_BENCH_URLS": urls(SITES_30), "NHT_BENCH_LOADALL": "1"},
                                     settle=60),
        "speedometer": lambda k: run_once(k, "speedometer3.1", {"NHT_BENCH_URLS": SPEEDOMETER, "NHT_BENCH_POLL_JS": SPEEDO_JS},
                                          settle=0, event="score", event_timeout=600),
        "jetstream": lambda k: run_once(k, "jetstream2.2", {"NHT_BENCH_URLS": JETSTREAM, "NHT_BENCH_POLL_JS": JETSTREAM_JS},
                                        settle=0, event="score", event_timeout=900),
    }


REPS = {"startup": 5, "tabs10": 3, "tabs30": 3, "speedometer": 3, "jetstream": 2}


def serve_local() -> None:
    site = HERE / "site"
    handler = lambda *a: http.server.SimpleHTTPRequestHandler(*a, directory=str(site))  # noqa: E731
    http.server.HTTPServer.log_message = lambda *a: None
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 8765), handler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()


def main() -> None:
    RESULTS.mkdir(exist_ok=True)
    serve_local()
    chosen = sys.argv[1:] or list(REPS)
    for k in APPS:
        kill(APPS[k])
    for name in chosen:
        for rep in range(REPS[name]):
            for key in APPS:
                scenarios(REPS[name])[name](key)


if __name__ == "__main__":
    main()
