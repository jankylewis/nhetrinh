import AppKit
import Testing
@testable import Nhetrinh
import NhetrinhCore

/// NT-BUG-022 (found_by: headmate): with the Mac in dark mode and nhetrinh set to light, the dropdown painted a dark
/// background (the process's appearance) under black text (the view's appearance): nothing could be read.
/// The list's colours follow the view's own appearance, whatever the process's current one is.
@MainActor
struct SuggestionLookTests {
    private static let rows = [Suggestion(url: "https://a.test/", title: "A", tab: nil),
                               Suggestion(url: "https://b.test/", title: "B", tab: 2)]

    private func brightness(_ color: CGColor?) -> CGFloat {
        guard let rgb = color.flatMap({ NSColor(cgColor: $0)?.usingColorSpace(.sRGB) }) else { return -1 }
        return (rgb.redComponent + rgb.greenComponent + rgb.blueComponent) / 3
    }

    @Test(arguments: [(view: NSAppearance.Name.aqua, process: NSAppearance.Name.darkAqua, light: true),
                      (view: .darkAqua, process: .aqua, light: false)])
    func theBackgroundFollowsTheViewsAppearance(view: NSAppearance.Name, process: NSAppearance.Name, light: Bool) {
        let saved = NSAppearance.current
        defer { NSAppearance.current = saved }
        NSAppearance.current = NSAppearance(named: process)
        let list = SuggestionList(frame: NSRect(x: 0, y: 0, width: 600, height: 0))
        list.appearance = NSAppearance(named: view)
        list.show(Self.rows, icons: [])
        list.move(1)
        let back = brightness(list.layer?.backgroundColor)
        #expect(light ? back > 0.7 : (0...0.3).contains(back))
    }

    @Test func switchToTabSitsAtTheRowsEnd() throws {
        let row = SuggestionRow(Self.rows[1], icon: nil)
        row.frame = NSRect(x: 0, y: 0, width: 600, height: SuggestionList.rowHeight)
        row.layoutSubtreeIfNeeded()
        let label = try #require(row.descendants.compactMap { $0 as? NSTextField }
            .first { $0.stringValue == SuggestionRow.switchText })
        let end = label.convert(label.bounds, to: row).maxX
        #expect(end > 600 - 16)
    }
}

private extension NSView {
    var descendants: [NSView] { subviews + subviews.flatMap(\.descendants) }
}
