import AppKit

/// Steps that look at the system around the app: the Dock, its processes, its size.
enum SystemSteps {
    static var evidenceFolder = FileManager.default.temporaryDirectory
    static let seedKey = "NHT_BENCH_URLS"

    static func dockIconHasNoTile(_ app: AppSession) throws -> String {
        try app.requireAccessibility()
        try app.ensureRunning()
        var frames: [CGRect] = []
        waitUntil(5) {
            frames = (try? DockIcon.itemFrames(title: "nhetrinh")) ?? []
            return !frames.isEmpty
        }
        if frames.isEmpty { frames = try DockIcon.itemFrames(title: "nhetrinh") }
        guard let frame = frames.last else { throw StepError.fail("no Dock item named nhetrinh") }
        let iconFile = app.appURL.appendingPathComponent("Contents/Resources/AppIcon.png")
        guard let icon = NSBitmapImageRep(data: (try? Data(contentsOf: iconFile)) ?? Data()) else {
            throw StepError.fail("the app bundle has no AppIcon.png")
        }
        let capture = try DockIcon.capture(frame, to: evidenceFolder.appendingPathComponent("dock_icon.png"))
        let match = IconMatch.measure(capture: capture, icon: icon)
        let seen = String(format: "silhouette agreement %.0f %%, icon at %.0f %% of the Dock item",
                          match.agreement * 100, match.scale * 100)
        try expect(match.showsBareIcon, "the Dock item does not show the bare icon: \(seen)")
        return "captured only the Dock item (\(Int(frame.width)) x \(Int(frame.height)) pt): \(seen)"
    }

    static func unopenedTabsCostNothing(_ app: AppSession) throws -> String {
        try app.requireAccessibility()
        let urls = "https://example.com,https://example.org,https://example.net"
        try app.launch(env: [seedKey: urls])
        let three = waitUntil(10) { (try? app.rowCount()) == 3 }
        try expect(three, "started with 3 tabs; the sidebar has \((try? app.rowCount()) ?? -1) row(s)")
        waitUntil(15) { !Footprint.pageProcesses(of: app.pid).isEmpty }
        Thread.sleep(forTimeInterval: 4)
        let pages = Footprint.pageProcesses(of: app.pid).count
        try expect(pages == 1, "3 tabs, 1 selected: \(pages) page process(es) run, 1 is expected")
        return "started with 3 tabs (seeded by the launch environment; real restore comes with P1): "
            + "3 rows, 1 page process"
    }

    /// R8: 6 s after the page process starts, 5 memory samples 1 s apart; the median is judged
    /// (NT-PRF-002), the highest sample is shown. Then idle CPU over 5 s, and the bundle size.
    static func budgetHolds(_ app: AppSession) throws -> String {
        try app.launch(env: [seedKey: "https://example.com"])
        let started = waitUntil(15) { !Footprint.pageProcesses(of: app.pid).isEmpty }
        try expect(started, "no page process after 15 s")
        Thread.sleep(forTimeInterval: 6)
        let (memory, helpers) = memorySamples(of: app.pid)
        let cpu = Footprint.cpuPercent(of: app.pid, over: 5)
        let kilobytes = bundleKilobytes(app.appURL)
        let seen = String(format: "median of %d samples 1 s apart: app %.1f MB (max %.0f); app + %d helpers %.1f MB "
                          + "(max %.0f); highest sample: app %.1f MB, total %.1f MB; idle CPU %.1f %% (max %.0f); "
                          + "bundle %d KB (max %d)", memory.count, memory.app, Budget.appMegabytes, helpers,
                          memory.total, Budget.totalMegabytes, memory.highestApp, memory.highestTotal, cpu,
                          Budget.idleCpuPercent, kilobytes, Budget.bundleKilobytes)
        let holds = memory.holds && cpu <= Budget.idleCpuPercent && kilobytes <= Budget.bundleKilobytes
        try expect(memory.app > 0 && holds, "one simple tab (example.com): \(seen)")
        return "one simple tab (example.com), 6 s after load: \(seen)"
    }

    /// `Budget.sampleCount` samples, 1 s apart, and the most helper processes seen in one sample.
    private static func memorySamples(of pid: pid_t) -> (Budget.Reading, Int) {
        var samples: [Budget.Sample] = []
        var helpers = 0
        for index in 0..<Budget.sampleCount {
            if index > 0 { Thread.sleep(forTimeInterval: 1) }
            let processes = Footprint.processes(of: pid)
            let app = processes.first { $0.pid == pid }?.megabytes ?? 0
            samples.append(Budget.Sample(app: app, total: processes.reduce(0) { $0 + $1.megabytes }))
            helpers = max(helpers, processes.count - 1)
        }
        return (Budget.Reading(samples), helpers)
    }

    /// Size on disk (allocated blocks), the number `du -sk` prints.
    private static func bundleKilobytes(_ bundle: URL) -> Int {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .isRegularFileKey]
        let files = FileManager.default.enumerator(at: bundle, includingPropertiesForKeys: Array(keys))
        var bytes = 0
        while let file = files?.nextObject() as? URL {
            let values = try? file.resourceValues(forKeys: keys)
            if values?.isRegularFile == true { bytes += values?.totalFileAllocatedSize ?? 0 }
        }
        return (bytes + 1023) / 1024
    }
}
