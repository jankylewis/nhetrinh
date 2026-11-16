import AppKit
import Testing
@testable import Nhetrinh

/// P2-REVIEW: gaps found by the adversarial review of p2/sidebar, red until the code is fixed.
/// No app is launched and nothing goes to the network: every tab's page is `about:blank?<n>`.
@MainActor
struct ReviewGapsTests {
    private func browser(_ count: Int, selected: Int) -> BrowserWindowController {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.tabs = (1...count).map { Tab(url: page($0), title: "t\($0)") }
        browser.selected = selected
        browser.refreshChrome()
        return browser
    }

    private func page(_ number: Int) -> URL? { URL(string: "about:blank?\(number)") }

    /// A row closed before the background slot (its button, its menu, a middle click) must move the
    /// slot with it: the next background tab still goes right after the selected tab and its run.
    /// On cc8affe `close(at:)` left `backgroundSlot` as it was: the next one landed a row too far (NT-UIX-003).
    @Test(arguments: [
        // 3 tabs, t1 selected; background 8; close row `closed`; background 9.
        (0, 1, [1, 9, 2, 3]),     // the background tab itself closed: 9 goes after t1
        (1, 0, [2, 8, 9, 3]),     // t2 selected, t1 (before it) closed: 9 goes after 8
        (1, 3, [1, 2, 8, 9]),     // t2 selected, t3 (after the run) closed: 9 goes after 8
    ])
    func closingARowKeepsTheBackgroundSlotInPlace(selected: Int, closed: Int, expected: [Int]) {
        let browser = browser(3, selected: selected)
        page(8).map(browser.openInBackground)
        browser.close(at: closed)
        page(9).map(browser.openInBackground)
        #expect(browser.tabs.map(\.url) == expected.map(page))
    }

    /// A small file can hold a huge image: 4000 x 4000 pixels in a few KB of PNG, under the 512 KB cap.
    /// `Favicons.small` draws the whole image (measured: a 437 KB, 5000 px PNG peaks at 106 MB, budget
    /// 40 MB). An icon larger than 2048 px on a side is refused before it is decoded (NT-PRF-003).
    @Test(arguments: [(4000, false), (2049, false), (2048, true), (64, true)])
    func anIconOfHugePixelSizeIsRefusedBeforeItIsDecoded(side: Int, kept: Bool) throws {
        let rep = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 1, samplesPerPixel: 1,
            hasAlpha: false, isPlanar: false, colorSpaceName: .deviceWhite, bytesPerRow: 0, bitsPerPixel: 0))
        let png = try #require(rep.representation(using: .png, properties: [:]))
        #expect(png.count < 512 * 1024, "the file passes the size cap: \(png.count) bytes")
        #expect(Favicons.fits(png) == kept)
        #expect((Favicons.small(png) != nil) == kept)
    }
}
