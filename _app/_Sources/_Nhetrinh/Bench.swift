import Foundation
import WebKit

/// Benchmark hooks, driven by env vars (same contract as MVP B):
///   NHT_BENCH_URLS=u1,u2,...  open these tabs at launch (instead of the home page)
///   NHT_BENCH_LOADALL=1       load every tab now (disables lazy loading + unloading)
///   NHT_BENCH_OUT=path        append JSON-line events (first_load) to this file
enum Bench {
    static let env = ProcessInfo.processInfo.environment
    static let outPath = env["NHT_BENCH_OUT"]
    static var firstLoadReported = false

    static var urls: [URL] {
        (env["NHT_BENCH_URLS"] ?? "").split(separator: ",").compactMap { URL(string: String($0)) }
    }

    static var loadAll: Bool { env["NHT_BENCH_LOADALL"] == "1" }

    /// Milliseconds since this process was started by the kernel.
    static func msSinceProcessStart() -> Double {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0 else { return -1 }
        let start = info.kp_proc.p_un.__p_starttime
        var now = timeval()
        gettimeofday(&now, nil)
        let s = Double(now.tv_sec - start.tv_sec) * 1000
        return s + Double(now.tv_usec - start.tv_usec) / 1000
    }

    static func event(_ name: String, _ extra: String = "") {
        guard let path = outPath else { return }
        let line = "{\"event\":\"\(name)\",\"ms\":\(msSinceProcessStart())\(extra)}\n"
        if let h = FileHandle(forWritingAtPath: path) {
            h.seekToEndOfFile()
            h.write(line.data(using: .utf8)!)
            h.closeFile()
        } else {
            FileManager.default.createFile(atPath: path, contents: line.data(using: .utf8))
        }
    }

    /// NHT_BENCH_POLL_JS: JS expression polled every 2 s in the selected tab; a result
    /// "SCORE:<x>" is written as a score event and polling stops.
    static func startPolling(_ current: @escaping () -> WKWebView?) {
        guard let js = env["NHT_BENCH_POLL_JS"] else { return }
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            current()?.evaluateJavaScript(js) { result, _ in
                guard let s = result as? String, s.hasPrefix("SCORE:") else { return }
                timer.invalidate()
                event("score", ",\"value\":\"\(s.dropFirst(6))\"")
            }
        }
    }

    static func reportFirstLoad() {
        guard !firstLoadReported else { return }
        firstLoadReported = true
        event("first_load")
    }
}
