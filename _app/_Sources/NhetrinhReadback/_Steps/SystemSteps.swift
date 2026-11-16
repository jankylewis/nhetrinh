import AppKit

/// Steps that look at the system around the app: the Dock, its processes, its size.
enum SystemSteps {
    static let seedKey = "NHT_BENCH_URLS"

    static func dockIconHasNoTile(_ app: AppSession) throws -> String {
        try app.requireAccessibility()
        try app.ensureRunning()
        // Only the launched app's own item: a pinned copy that is not running is on a tile (NT-GAT-005).
        waitUntil(5) { (try? DockIcon.launchedItem(DockIcon.items(), app: app.appURL)) != nil }
        let item = try DockIcon.launchedItem(DockIcon.items(), app: app.appURL)
        let iconFile = app.appURL.appendingPathComponent("Contents/Resources/AppIcon.png")
        guard let icon = NSBitmapImageRep(data: (try? Data(contentsOf: iconFile)) ?? Data()) else {
            throw StepError.fail("the app bundle has no AppIcon.png")
        }
        let capture = try DockIcon.capture(item)
        let match = IconMatch.measure(capture: capture.image, icon: icon, item: capture.item,
                                      axis: DockAxis.of(item.dock))
        let seen = String(format: "silhouette agreement %.0f %%, icon at %.0f %% of the Dock item",
                          match.agreement * 100, match.scale * 100)
            + kept(capture.png, DockIcon.note(match, item: item), in: app)
        try expect(match.showsBareIcon, "the Dock item does not show the bare icon: \(seen)")
        let size = "\(Int(item.frame.width)) x \(Int(item.frame.height)) pt"
        return "captured the Dock item (\(size)) and a ring inside the Dock, "
            + (app.keepCapture == nil ? "not kept: " : "") + seen
    }

    /// With `--keep-capture`, write R2's capture and its numbers there and say so, never the path.
    private static func kept(_ png: Data, _ note: String, in app: AppSession) -> String {
        guard let folder = app.keepCapture else { return "" }
        do {
            try DockIcon.keepFile(png, as: "r2-capture.png", in: folder)
            try DockIcon.keepFile(Data(note.utf8), as: "r2-capture.txt", in: folder)
            return "; capture and numbers kept (--keep-capture)"
        } catch {
            return "; the capture could not be kept (--keep-capture): " + Report.tilde(error.localizedDescription)
        }
    }

    static func unopenedTabsCostNothing(_ app: AppSession) throws -> String {
        try app.requireAccessibility()
        let urls = "https://example.com,https://example.org,https://example.net"
        try app.launch(env: [seedKey: urls])
        let three = waitUntil(10) { (try? app.rowCount()) == 3 }
        let rows = three ? 3 : try app.rowCount()  // a refused read is NOT READ BACK, never -1 rows
        try expect(rows == 3, "started with 3 tabs; the sidebar has \(rows) row(s)")
        waitUntil(15) { !Footprint.pageProcesses(of: app.pid).isEmpty }
        Thread.sleep(forTimeInterval: 4)
        let pages = Footprint.pageProcesses(of: app.pid).count
        try expect(pages == 1, "3 tabs, 1 selected: \(pages) page process(es) run, 1 is expected")
        return "started with 3 tabs (seeded by the launch environment; real restore comes with P1): "
            + "3 rows, 1 page process"
    }

    /// R8: 6 s after the page process starts, 9 memory samples 1 s apart, judged by `Budget.Reading`
    /// (NT-PRF-002): the app on its highest sample, the total on its median and the last-4 rule.
    /// Then idle CPU over 5 s, and the bundle size.
    static func budgetHolds(_ app: AppSession) throws -> String {
        try app.launch(env: [seedKey: "https://example.com"])
        let started = waitUntil(15) { !Footprint.pageProcesses(of: app.pid).isEmpty }
        try expect(started, "no page process after 15 s")
        Thread.sleep(forTimeInterval: 6)
        let (memory, helpers) = memorySamples(of: app.pid)
        if let why = memory.noReading { throw StepError.cannotDrive("one simple tab (example.com): \(why)") }
        let cpu = Footprint.cpuPercent(of: app.pid, over: 5)
        let kilobytes = bundleKilobytes(app.appURL)
        let rest = String(format: "; idle CPU %.1f %% (max %.0f); bundle %d KB (max %d)",
                          cpu, Budget.idleCpuPercent, kilobytes, Budget.bundleKilobytes)
        let seen = memory.line(helpers: helpers) + rest
        let holds = memory.holds && cpu <= Budget.idleCpuPercent && kilobytes <= Budget.bundleKilobytes
        try expect(holds, "one simple tab (example.com): \(seen)")
        return "one simple tab (example.com), 6 s after load: \(seen)"
    }

    /// `Budget.sampleCount` samples, 1 s apart, and the most helper processes seen in one sample.
    private static func memorySamples(of pid: pid_t) -> (Budget.Reading, Int) {
        var samples: [Budget.Sample] = []
        var helpers = 0
        for index in 0..<Budget.sampleCount {
            if index > 0 { Thread.sleep(forTimeInterval: 1) }
            let processes = Footprint.processes(of: pid)
            let app = processes.first { $0.pid == pid }?.megabytes ?? 0  // 0: not found, no reading
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
