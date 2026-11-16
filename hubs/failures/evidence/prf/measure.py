"""measure.py <label> <app> <proc> <url> <profile or -> [reps]      (NT-PRF-001)
Launch via open -n -F (NT-ENV-002), wait for the page process, settle 6 s (as R8), memsum, quit, wait clean.
Needs `memsum` next to this file: cc -O2 -o memsum hubs/product/rnd/_bench/measure/_memsum.c
LATE=1 adds a second sample 10 s later. Rows go to runs.jsonl next to this file. One instance at a time."""
import json, os, subprocess, sys, time
from pathlib import Path

S = Path(__file__).parent
label, app, proc, url, profile = sys.argv[1:6]
reps = int(sys.argv[6]) if len(sys.argv) > 6 else 3


def pids(name):
    return [int(p) for p in subprocess.run(["pgrep", "-x", name], capture_output=True, text=True).stdout.split()]


def wait_clean(name):
    for _ in range(120):
        if not pids(name):
            time.sleep(4)
            return
        time.sleep(0.5)
    raise SystemExit("did not exit")


for i in range(reps):
    wait_clean(proc)
    env = ["--env", f"NHT_BENCH_URLS={url}"] + (["--env", f"NHT_PROFILE={profile}"] if profile != "-" else [])
    subprocess.run(["open", "-n", "-F"] + env + [app], check=True)
    pid = None
    for _ in range(100):
        if pids(proc):
            pid = pids(proc)[-1]
            break
        time.sleep(0.1)
    time.sleep(1.5)
    # wait for a page process charged to the app (R8: up to 15 s), then settle 6 s as R8 does
    for _ in range(60):
        out = json.loads(subprocess.run([str(S / "memsum"), str(pid)], capture_output=True, text=True).stdout)
        if out["procs"] >= 4:
            break
        time.sleep(0.25)
    time.sleep(6)
    out = json.loads(subprocess.run([str(S / "memsum"), str(pid)], capture_output=True, text=True).stdout)
    late = None
    if os.environ.get("LATE"):
        time.sleep(10)
        late = json.loads(subprocess.run([str(S / "memsum"), str(pid)], capture_output=True, text=True).stdout)
    row = {"late": late, "label": label, "rep": i, "url": url, "profile": profile, **out}
    print(json.dumps(row), flush=True)
    with open(S / "runs.jsonl", "a") as f:
        f.write(json.dumps(row) + "\n")
    subprocess.run(["kill", str(pid)])
