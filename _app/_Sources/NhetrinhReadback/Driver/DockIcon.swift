import AppKit

/// The app's item in the Dock: where it is, and a picture of it.
/// Only the item's own rectangle is captured, never the screen. The Dock is always on top, so
/// no window of another app can be inside that rectangle (NT-TG-002).
enum DockIcon {
    /// The rectangles (screen points, origin top left) of the Dock items with this title.
    static func itemFrames(title: String) throws -> [CGRect] {
        if UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "autohide") == true {
            throw StepError.cannotDrive("the Dock hides itself; a capture of its place could show other windows")
        }
        guard let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else {
            throw StepError.cannotDrive("the Dock is not running")
        }
        let root = AXNode.application(pid: dock.processIdentifier)
        let items = root.children.flatMap(\.children).filter { $0.title == title }
        return items.compactMap(\.frame).filter(isOnScreen)
    }

    private static func isOnScreen(_ frame: CGRect) -> Bool {
        guard frame.width > 8, frame.height > 8, let main = NSScreen.screens.first else { return false }
        // Accessibility uses a top-left origin on the main screen; NSScreen uses bottom-left.
        let flipped = CGRect(x: frame.minX, y: main.frame.height - frame.maxY, width: frame.width, height: frame.height)
        return NSScreen.screens.contains { $0.frame.contains(flipped) }
    }

    /// Capture that rectangle to a PNG file and read it back as a bitmap.
    static func capture(_ frame: CGRect, to file: URL) throws -> NSBitmapImageRep {
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
        return image
    }
}
