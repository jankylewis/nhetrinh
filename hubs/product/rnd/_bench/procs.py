"""Process control for the benchmark: launch like a Dock click, wait until really gone, measure."""

from __future__ import annotations

import json
import os
import signal
import subprocess
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
EVENTS = HERE / "results" / "events.jsonl"
MEMSUM = HERE / "measure" / "memsum"


def pids(name: str) -> list[int]:
    out = subprocess.run(["pgrep", "-x", name], capture_output=True, text=True).stdout
    return [int(p) for p in out.split()]


def helper_pids(app: dict) -> list[int]:
    if not app["helper"]:
        return []
    out = subprocess.run(["pgrep", "-f", app["helper"]], capture_output=True, text=True).stdout
    return [int(p) for p in out.split()]


def wait_clean(app: dict, timeout: float = 60) -> None:
    """Return when the app and its helpers are gone (NT-ENV-003), or raise."""
    end = time.time() + timeout
    while time.time() < end:
        if not pids(app["proc"]) and not helper_pids(app):
            time.sleep(3)  # let WebKit's XPC services exit too
            return
        time.sleep(0.5)
    raise RuntimeError(f"{app['proc']} did not exit")


def kill(app: dict) -> None:
    for pid in pids(app["proc"]) + helper_pids(app):
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    wait_clean(app)


def launch(app: dict, env: dict[str, str]) -> int:
    """Start through LaunchServices so the app is responsible for its helpers (NT-ENV-002)."""
    EVENTS.unlink(missing_ok=True)
    cmd = ["open", "-n", "-F"]
    for key, value in {"NHT_BENCH_OUT": str(EVENTS), **env}.items():
        cmd += ["--env", f"{key}={value}"]
    subprocess.run(cmd + [str(app["bundle"])], check=True, timeout=30)
    for _ in range(100):
        found = pids(app["proc"])
        if found:
            return found[-1]
        time.sleep(0.1)
    raise RuntimeError("app did not start")


def wait_event(name: str, timeout: float) -> dict | None:
    end = time.time() + timeout
    while time.time() < end:
        if EVENTS.exists():
            for line in EVENTS.read_text().splitlines():
                event = json.loads(line)
                if event["event"] == name:
                    return event
        time.sleep(0.25)
    return None


def memsum(pid: int, cpu_s: float = 0) -> dict:
    """Footprint of the app and every process it is responsible for; optional CPU % window."""
    args = [str(MEMSUM), str(pid)] + ([str(cpu_s)] if cpu_s else [])
    out = subprocess.run(args, capture_output=True, text=True, timeout=cpu_s + 30).stdout
    return json.loads(out)
