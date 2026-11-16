import AppKit

/// One Dock item and the Dock list that holds it (screen points, origin top left), whether its app
/// runs (`AXIsApplicationRunning`) and the bundle it stands for (`AXURL`; nil for a separator).
struct DockItem {
    let frame: CGRect
    let dock: CGRect
    var isRunning = false
    var url: URL?
}

/// The app's item in the Dock: where it is, and a picture of it.
/// Only the item and a ring of at most 6 pt around it are captured, clamped to the Dock's own
/// frame: no pixel outside the Dock, never the screen. The Dock is always on top, so no window of
/// another app can be inside it (NT-TG-002). The picture is a temporary file, deleted at once.
enum DockIcon {
    /// Every Dock item on screen, each with the frame of the Dock list that holds it.
    static func items() throws -> [DockItem] {
        if UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "autohide") == true {
            throw StepError.cannotDrive("the Dock hides itself; a capture of its place could show other windows")
        }
        guard let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else {
            throw StepError.cannotDrive("the Dock is not running")
        }
        let lists = AXNode.application(pid: dock.processIdentifier).children
        return lists.flatMap { list -> [DockItem] in
            guard let dock = list.frame else { return [] }
            return list.children.compactMap { node in
                guard let frame = node.frame, isOnScreen(frame) else { return nil }
                return DockItem(frame: frame, dock: dock, isRunning: node.flag("AXIsApplicationRunning"), url: node.url)
            }
        }
    }

    /// The one item of the launched app: running, and of its bundle. A pinned copy of the app has
    /// the same title but is not running; it shows its bundle icon on a tile (NT-GAT-005).
    /// None is NOT READ BACK; more than one is a FAIL. The reasons hold counts, never a path.
    static func launchedItem(_ items: [DockItem], app: URL) throws -> DockItem {
        let ours = items.filter { $0.url.map { sameBundle($0, app) } ?? false }
        let running = ours.filter(\.isRunning)
        if running.count > 1 {
            throw StepError.fail("\(running.count) running Dock items of the launched app; one is expected")
        }
        guard let item = running.first else {
            throw StepError.cannotDrive("no running Dock item of the launched app: \(ours.count) of its bundle "
                + "(none running), \(items.filter(\.isRunning).count) running of \(items.count) items read")
        }
        return item
    }

    /// `AXURL` ends a bundle with a slash; the launched app's URL may not.
    private static func sameBundle(_ first: URL, _ second: URL) -> Bool {
        let path = { (url: URL) in url.standardizedFileURL.resolvingSymlinksInPath().path }
        return path(first) == path(second)
    }

    private static func isOnScreen(_ frame: CGRect) -> Bool {
        guard frame.width > 8, frame.height > 8, let main = NSScreen.screens.first else { return false }
        // Accessibility uses a top-left origin on the main screen; NSScreen uses bottom-left.
        let flipped = CGRect(x: frame.minX, y: main.frame.height - frame.maxY, width: frame.width, height: frame.height)
        return NSScreen.screens.contains { $0.frame.contains(flipped) }
    }

    /// R2 reads the Dock's colour from a ring this wide around the item (NT-GAT-004).
    static let ringPoints: CGFloat = 6

    /// The item grown by `ringPoints` on each side, clamped to the Dock's frame: where the item
    /// touches the Dock's edge, the ring there is smaller. Rounded inward to whole points, because
    /// `screencapture -R` takes whole points: rounding outward could pass the Dock's edge (P0-REV-2).
    /// Nil when nothing is left inside the Dock.
    static func captureRect(around item: CGRect, dock: CGRect) -> CGRect? {
        let rect = item.insetBy(dx: -ringPoints, dy: -ringPoints).intersection(dock)
        guard !rect.isNull else { return nil }
        let minX = rect.minX.rounded(.up), minY = rect.minY.rounded(.up)
        let width = rect.maxX.rounded(.down) - minX, height = rect.maxY.rounded(.down) - minY
        return width < 1 || height < 1 ? nil : CGRect(x: minX, y: minY, width: width, height: height)
    }

    /// Capture the item and its ring to a temporary PNG, read it, delete it. Returns the bitmap
    /// and the item inside it, in pixels, origin top left. Nothing is kept on disk.
    static func capture(_ item: DockItem) throws -> (image: NSBitmapImageRep, item: CGRect) {
        guard let frame = captureRect(around: item.frame, dock: item.dock) else {
            throw StepError.cannotDrive("the Dock item is outside the Dock's frame")
        }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-r2-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: file) }
        let region = [frame.minX, frame.minY, frame.width, frame.height].map { String(Int($0)) }  // whole points
        let tool = Process()
        tool.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        tool.arguments = ["-x", "-R", region.joined(separator: ","), file.path]
        try tool.run()
        tool.waitUntilExit()
        guard tool.terminationStatus == 0, let data = try? Data(contentsOf: file),
              let image = NSBitmapImageRep(data: data) else {
            throw StepError.cannotDrive("the Dock item could not be captured (Screen Recording permission?)")
        }
        let scale = Double(image.pixelsWide) / frame.width, inner = item.frame.intersection(frame)
        let inside = CGRect(x: (inner.minX - frame.minX) * scale, y: (inner.minY - frame.minY) * scale,
                            width: inner.width * scale, height: inner.height * scale)
        return (image, inside)
    }
}
