import AppKit

/// One Dock item and the Dock list that holds it (screen points, origin top left).
struct DockItem {
    let frame: CGRect
    let dock: CGRect
}

/// The app's item in the Dock: where it is, and a picture of it.
/// Only the item and a ring of at most 6 pt around it are captured, clamped to the Dock's own
/// frame: no pixel outside the Dock, never the screen. The Dock is always on top, so no window of
/// another app can be inside it (NT-TG-002). The picture is a temporary file, deleted at once.
enum DockIcon {
    /// The Dock items with this title, each with the frame of the Dock list that holds it.
    static func items(title: String) throws -> [DockItem] {
        if UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "autohide") == true {
            throw StepError.cannotDrive("the Dock hides itself; a capture of its place could show other windows")
        }
        guard let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else {
            throw StepError.cannotDrive("the Dock is not running")
        }
        let lists = AXNode.application(pid: dock.processIdentifier).children
        return lists.flatMap { list -> [DockItem] in
            guard let dock = list.frame else { return [] }
            let frames = list.children.filter { $0.title == title }.compactMap(\.frame).filter(isOnScreen)
            return frames.map { DockItem(frame: $0, dock: dock) }
        }
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
    /// touches the Dock's edge, the ring there is smaller. Nil when nothing is left inside the Dock.
    static func captureRect(around item: CGRect, dock: CGRect) -> CGRect? {
        let rect = item.insetBy(dx: -ringPoints, dy: -ringPoints).intersection(dock)
        return rect.isNull || rect.width < 1 || rect.height < 1 ? nil : rect
    }

    /// Capture the item and its ring to a temporary PNG, read it, delete it. Returns the bitmap
    /// and the item inside it, in pixels, origin top left. Nothing is kept on disk.
    static func capture(_ item: DockItem) throws -> (image: NSBitmapImageRep, item: CGRect) {
        guard let frame = captureRect(around: item.frame, dock: item.dock) else {
            throw StepError.cannotDrive("the Dock item is outside the Dock's frame")
        }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-r2-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: file) }
        let region = [frame.minX, frame.minY, frame.width, frame.height].map { String(Int($0.rounded())) }
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
