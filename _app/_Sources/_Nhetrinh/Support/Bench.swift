import Foundation
import WebKit

/// Measurement hooks. Inert unless these environment variables are set:
///   NHT_BENCH_URLS=u1,u2,...   open these tabs at launch instead of the home page
///   NHT_BENCH_LOADALL=1        load every tab, one at a time (idle unloading is then off)
///   NHT_BENCH_LOAD_GAP_S=3     seconds between two tab loads
///   NHT_BENCH_OUT=path         append JSON-line events (first_load, score) to this file
///   NHT_BENCH_POLL_JS=expr     poll this JavaScript in the selected tab; "SCORE:<x>" is recorded
enum Bench {
    private static let env = ProcessInfo.processInfo.environment
    private static var firstLoadReported = false

    static var urls: [URL] {
        (env["NHT_BENCH_URLS"] ?? "").split(separator: ",").compactMap { URL(string: String($0)) }
    }

    static var loadAll: Bool { env["NHT_BENCH_LOADALL"] == "1" }
    static var loadGap: TimeInterval { TimeInterval(env["NHT_BENCH_LOAD_GAP_S"] ?? "") ?? 3 }

    /// Milliseconds since the kernel started this process.
    static func msSinceProcessStart() -> Double {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0 else { return -1 }
        let start = info.kp_proc.p_un.__p_starttime
        var now = timeval()
        gettimeofday(&now, nil)
        return Double(now.tv_sec - start.tv_sec) * 1000 + Double(now.tv_usec - start.tv_usec) / 1000
    }

    static func event(_ name: String, _ extra: String = "") {
        guard let path = env["NHT_BENCH_OUT"] else { return }
        let line = Data("{\"event\":\"\(name)\",\"ms\":\(msSinceProcessStart())\(extra)}\n".utf8)
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(line)
            handle.closeFile()
        } else if !FileManager.default.createFile(atPath: path, contents: line) {
            Log.app.error("bench: cannot write the event file")
        }
    }

    static func reportFirstLoad() {
        guard !firstLoadReported else { return }
        firstLoadReported = true
        event("first_load")
    }

    static func startPolling(_ current: @escaping () -> WKWebView?) {
        guard let script = env["NHT_BENCH_POLL_JS"] else { return }
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            current()?.evaluateJavaScript(script) { result, _ in
                guard let text = result as? String, text.hasPrefix("SCORE:") else { return }
                timer.invalidate()
                event("score", ",\"value\":\"\(text.dropFirst(6))\"")
            }
        }
    }
}
