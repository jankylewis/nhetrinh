"""gpu_samples.py <app> <runs>      (NT-PRF-002)
R8 settings (example.com, profile readback); per run, memsum every 1 s for 30 s from launch; quit; wait clean.
Needs `memsum` next to this file: cc -O2 -o memsum hubs/product/rnd/_bench/measure/_memsum.c
Rows go to gpu.jsonl next to this file. One app instance at a time."""
import json, subprocess, sys, time
from pathlib import Path

S = Path(__file__).parent
app, runs = sys.argv[1], int(sys.argv[2])


def pids(name):
    return [int(p) for p in subprocess.run(["pgrep", "-x", name], capture_output=True, text=True).stdout.split()]


def memsum(pid):
    out = subprocess.run([str(S / "memsum"), str(pid)], capture_output=True, text=True).stdout
    return json.loads(out) if out else None


for run in range(runs):
    while pids("nhetrinh"):
        time.sleep(0.5)
    time.sleep(4)
    t0 = time.time()
    subprocess.run(["open", "-n", "-F", "--env", "NHT_BENCH_URLS=https://example.com",
                    "--env", "NHT_PROFILE=readback", app], check=True)
    while not pids("nhetrinh"):
        time.sleep(0.1)
    pid = pids("nhetrinh")[-1]
    samples = []
    for second in range(1, 31):
        time.sleep(max(0, t0 + second - time.time()))
        m = memsum(pid) or {}
        by = {p["name"].replace("com.apple.WebKit.", ""): p["mb"] for p in m.get("by_proc", [])}
        samples.append({"s": second, "main": m.get("main_mb"), "total": m.get("total_mb"),
                        "gpu": by.get("GPU"), "web": by.get("WebContent")})
    subprocess.run(["kill", str(pid)])
    row = {"run": run, "samples": samples}
    with open(S / "gpu.jsonl", "a") as f:
        f.write(json.dumps(row) + "\n")
    print(run, " ".join(f"{x['gpu']}" for x in samples), flush=True)
