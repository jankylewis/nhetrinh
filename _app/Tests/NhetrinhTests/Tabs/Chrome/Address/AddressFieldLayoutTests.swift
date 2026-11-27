import AppKit
import Testing
@testable import Nhetrinh

/// NT-BUG-023 (found_by: headmate): after a while the address field was gone; ⌘L found nothing to edit. The field
/// had no width of its own and the toolbar row's other views hugged as hard as it did: the layout was ambiguous and
/// a later layout could give the field no width. The field takes the row's free width at every window width.
@MainActor
struct AddressFieldLayoutTests {
    private func laidOut(width: CGFloat) -> ToolbarView {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: 300), styleMask: [.titled],
                              backing: .buffered, defer: true)
        let toolbar = ToolbarView(frame: NSRect(x: 0, y: 0, width: width, height: 38))
        window.contentView?.addSubview(toolbar)
        toolbar.showZoom("125 %")
        toolbar.layoutSubtreeIfNeeded()
        return toolbar
    }

    @Test(arguments: [480, 900, 1600] as [CGFloat])
    func theFieldFillsTheRowAndIsNotAmbiguous(width: CGFloat) {
        let toolbar = laidOut(width: width)
        #expect(!toolbar.address.hasAmbiguousLayout)
        #expect(toolbar.address.frame.width > width - 300)
    }

    @Test func theFieldKeepsAWidthAfterTheWindowNarrowsAndWidensAgain() {
        let toolbar = laidOut(width: 1200)
        for width in [200, 1200] as [CGFloat] {
            toolbar.setFrameSize(NSSize(width: width, height: 38))
            toolbar.layoutSubtreeIfNeeded()
        }
        #expect(toolbar.address.frame.width > 900)
    }

    /// NT-BUG-030 (found_by: headmate), red first: a long address stays on one line, cut at the end; it never wraps
    /// onto a second line that the bar's height cuts in half.
    @Test(arguments: [60, 500] as [Int])
    func aLongAddressStaysOnOneLine(length: Int) throws {
        let toolbar = laidOut(width: 900)
        toolbar.update(url: URL(string: "https://example.com/" + String(repeating: "a/b?c=d&", count: length / 8)),
                       canBack: false, canForward: false)
        let cell = try #require(toolbar.address.cell)
        let oneLine = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: 10_000, height: 10_000)).height
        let shown = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: toolbar.address.frame.width, height: 10_000))
        #expect(shown.height == oneLine, "one line: \(oneLine) pt, shown: \(shown.height) pt")
        #expect(cell.lineBreakMode == .byTruncatingTail)
    }
}
