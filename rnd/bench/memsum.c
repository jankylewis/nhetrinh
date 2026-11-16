// memsum <pid> [cpu_seconds]
// Sums phys_footprint (Activity Monitor "Memory") over the app and every process
// it is responsible for: WebKit XPC services (responsible pid = app) and Chromium
// helpers (children). With cpu_seconds, also reports CPU% averaged over that window.
// Output: one JSON line.
#include <libproc.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <unistd.h>
#include <mach/mach_time.h>

extern pid_t responsibility_get_pid_responsible_for_pid(pid_t);

#define MAXP 8192

static int belongs(pid_t p, pid_t app) {
    if (p == app) return 1;
    if (responsibility_get_pid_responsible_for_pid(p) == app) return 1;
    // walk parents (Chromium helpers are children of the app)
    for (int depth = 0; depth < 8 && p > 1; depth++) {
        struct proc_bsdinfo bi;
        if (proc_pidinfo(p, PROC_PIDTBSDINFO, 0, &bi, sizeof bi) != sizeof bi) return 0;
        p = (pid_t)bi.pbi_ppid;
        if (p == app) return 1;
    }
    return 0;
}

typedef struct { pid_t pid; uint64_t foot; uint64_t cpu_ns; char name[64]; } Row;

static int collect(pid_t app, Row *rows) {
    static pid_t pids[MAXP];
    int n = proc_listallpids(pids, sizeof pids) ;
    int k = 0;
    for (int i = 0; i < n && k < 512; i++) {
        if (pids[i] <= 0 || !belongs(pids[i], app)) continue;
        struct rusage_info_v4 ri;
        if (proc_pid_rusage(pids[i], RUSAGE_INFO_V4, (rusage_info_t *)&ri) != 0) continue;
        rows[k].pid = pids[i];
        rows[k].foot = ri.ri_phys_footprint;
        rows[k].cpu_ns = ri.ri_user_time + ri.ri_system_time;  // mach abs units
        proc_name(pids[i], rows[k].name, sizeof rows[k].name);
        k++;
    }
    return k;
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: memsum <pid> [cpu_seconds]\n"); return 2; }
    pid_t app = (pid_t)atoi(argv[1]);
    double cpu_s = argc > 2 ? atof(argv[2]) : 0;
    static Row a[512], b[512];
    int na = collect(app, a);
    if (na == 0) { fprintf(stderr, "no such process %d\n", app); return 1; }
    uint64_t total = 0, main_foot = 0;
    for (int i = 0; i < na; i++) { total += a[i].foot; if (a[i].pid == app) main_foot = a[i].foot; }
    printf("{\"total_mb\":%.1f,\"main_mb\":%.1f,\"procs\":%d", total / 1048576.0, main_foot / 1048576.0, na);
    if (cpu_s > 0) {
        mach_timebase_info_data_t tb; mach_timebase_info(&tb);
        usleep((useconds_t)(cpu_s * 1e6));
        int nb = collect(app, b);
        double used_ns = 0;
        for (int i = 0; i < nb; i++)
            for (int j = 0; j < na; j++)
                if (a[j].pid == b[i].pid) used_ns += (double)(b[i].cpu_ns - a[j].cpu_ns) * tb.numer / tb.denom;
        printf(",\"cpu_pct\":%.2f", used_ns / (cpu_s * 1e9) * 100.0);
    }
    printf(",\"by_proc\":[");
    for (int i = 0; i < na; i++)
        printf("%s{\"name\":\"%s\",\"mb\":%.1f}", i ? "," : "", a[i].name, a[i].foot / 1048576.0);
    printf("]}\n");
    return 0;
}
