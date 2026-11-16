import Darwin
import Foundation

@_silgen_name("responsibility_get_pid_responsible_for_pid")
private func responsiblePid(_ pid: pid_t) -> pid_t

struct ProcessUsage {
    let pid: pid_t
    let name: String
    let megabytes: Double
    let cpuTicks: UInt64
}

/// Memory and CPU of an app and of every process it is responsible for.
/// WebKit's helpers (page, network, GPU) are XPC services, not children: macOS charges them to
/// the responsible app, and so does this (NT-ENV-002). Memory is the physical footprint, the
/// number Activity Monitor shows.
enum Footprint {
    static func processes(of app: pid_t) -> [ProcessUsage] {
        var pids = [pid_t](repeating: 0, count: 8192)
        let count = Int(proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size)))
        return pids.prefix(max(count, 0)).filter { $0 > 0 && belongs($0, to: app) }.compactMap(usage)
    }

    static func pageProcesses(of app: pid_t) -> [ProcessUsage] {
        processes(of: app).filter { $0.name.hasPrefix("com.apple.WebKit.WebContent") }
    }

    /// CPU use of the app and its processes, in percent of one core, averaged over `seconds`.
    static func cpuPercent(of app: pid_t, over seconds: Double) -> Double {
        let before = Dictionary(uniqueKeysWithValues: processes(of: app).map { ($0.pid, $0.cpuTicks) })
        Thread.sleep(forTimeInterval: seconds)
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        let ticks = processes(of: app).reduce(0.0) { sum, now in
            sum + Double(now.cpuTicks &- (before[now.pid] ?? now.cpuTicks))
        }
        let nanoseconds = ticks * Double(timebase.numer) / Double(timebase.denom)
        return nanoseconds / (seconds * 1e9) * 100
    }

    private static func belongs(_ pid: pid_t, to app: pid_t) -> Bool {
        if pid == app || responsiblePid(pid) == app { return true }
        var parent = pid
        for _ in 0..<8 where parent > 1 {
            var info = proc_bsdinfo()
            let size = Int32(MemoryLayout<proc_bsdinfo>.size)
            guard proc_pidinfo(parent, PROC_PIDTBSDINFO, 0, &info, size) == size else { return false }
            parent = pid_t(info.pbi_ppid)
            if parent == app { return true }
        }
        return false
    }

    private static func usage(_ pid: pid_t) -> ProcessUsage? {
        var info = rusage_info_v4()
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
            }
        }
        guard status == 0 else { return nil }
        var name = [CChar](repeating: 0, count: 256)
        proc_name(pid, &name, UInt32(name.count))
        return ProcessUsage(pid: pid, name: String(cString: name),
                            megabytes: Double(info.ri_phys_footprint) / 1_048_576,
                            cpuTicks: info.ri_user_time + info.ri_system_time)
    }
}
