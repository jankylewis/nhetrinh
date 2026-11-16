import AppKit
import Testing
@testable import NhetrinhReadback

/// P0-REV-1 gaps in the corner rule (NT-GAT-004), and the item at the Dock's bottom edge, where
/// the ring has no strip below. The icon is at 76 %.
enum CornerCase: String, CaseIterable {
    case squareTileToTheEdge = "a dark tile with square corners as large as the item"
    case paleTileOnLightDock = "a rounded tile 0.80 on a 0.85 Dock (within the colour distance)"
    case lightTileLightCornersBelow = "a light rounded tile on a dark Dock, light below the item (not Dock colour)"
    case bareIconLightCornersBelow = "the bare icon on a dark Dock, light below the item (not Dock colour)"
    case squareTileAtDockEdge = "a dark square tile as large as the item, no ring below (the Dock's edge)"
    case bareIconAtDockEdge = "the bare icon, no ring below (the Dock's edge)"

    var showsBareIcon: Bool { self == .bareIconLightCornersBelow || self == .bareIconAtDockEdge }

    func draw() -> Capture {
        let edge = self == .squareTileAtDockEdge || self == .bareIconAtDockEdge
        let lightBelow = self == .lightTileLightCornersBelow || self == .bareIconLightCornersBelow
        return capture(dock: self == .paleTileOnLightDock ? 0.85 : 0.25, below: edge ? 0 : 12,
                       outside: lightBelow ? 0.92 : nil) { rect in
            let tile: CGFloat = self == .paleTileOnLightDock ? 0.80 : (lightBelow ? 0.92 : 0.08)
            let square = self == .squareTileToTheEdge || self == .squareTileAtDockEdge
            NSColor(white: tile, alpha: 1).setFill()
            let radius = square ? 0 : rect.width * 0.22
            if !showsBareIcon { NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill() }
            if lightBelow {
                NSColor(white: 0.92, alpha: 1).setFill()
                NSRect(x: rect.minX, y: rect.minY, width: 6, height: 6).fill()
                NSRect(x: rect.maxX - 6, y: rect.minY, width: 6, height: 6).fill()
            }
            drawIcon(in: rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.12))
        }
    }
}

@Test(arguments: CornerCase.allCases)
func dockCornerReviewGaps(capture: CornerCase) {
    let drawn = capture.draw()
    let match = IconMatch.measure(capture: drawn.image, icon: bitmap(side: 256) { drawIcon(in: $0) }, item: drawn.item)
    let verdict = "\(capture.rawValue): agreement \(match.agreement), scale \(match.scale)"
    guard capture == .paleTileOnLightDock else {
        #expect(match.showsBareIcon == capture.showsBareIcon, "\(verdict)")
        return
    }
    // Known limit (NT-GAT-004): the tile is 22 from the Dock colour, under `colourDistance` (30),
    // so it reads as Dock and the icon on it passes. A smaller distance tells it apart here, but
    // no real Dock capture exists to show that the Dock's blurred material stays within it.
    withKnownIssue("a pale tile on a light Dock passes R2") {
        #expect(match.showsBareIcon == capture.showsBareIcon, "\(verdict)")
    }
}

/// A Dock list frame on a 1000 x 800 screen, and items at its middle, its edges and outside it.
private let dock = CGRect(x: 300, y: 716, width: 400, height: 80)

let dockItems: [CGRect] = [
    CGRect(x: 400, y: 724, width: 64, height: 64), CGRect(x: 300, y: 724, width: 64, height: 64),
    CGRect(x: 636, y: 724, width: 64, height: 64), CGRect(x: 400, y: 716, width: 64, height: 80),
    CGRect(x: 300, y: 732, width: 64, height: 64), CGRect(x: 280, y: 724, width: 64, height: 64),
    CGRect(x: 690, y: 700, width: 64, height: 120), CGRect(x: 100, y: 724, width: 64, height: 64),
]

/// No pixel outside the Dock is ever captured (NT-TG-002): the ring is clamped to the Dock's frame.
@Test(arguments: dockItems)
func ringNeverLeavesTheDock(item: CGRect) {
    guard let rect = DockIcon.captureRect(around: item, dock: dock) else {
        #expect(item.intersection(dock).isNull, "only an item outside the Dock has no capture")
        return
    }
    #expect(dock.contains(rect), "\(rect) leaves the Dock \(dock)")
}

/// The ring is 6 pt on each side inside the Dock, and smaller where the item touches its edge.
@Test func ringIsSmallerAtTheDocksEdge() {
    #expect(DockIcon.captureRect(around: CGRect(x: 400, y: 724, width: 64, height: 64), dock: dock)
            == CGRect(x: 394, y: 718, width: 76, height: 76))
    #expect(DockIcon.captureRect(around: CGRect(x: 300, y: 732, width: 64, height: 64), dock: dock)
            == CGRect(x: 300, y: 726, width: 70, height: 70))
}

@Test func noRingIsNeverAPass() {
    let drawn = bitmap(side: 128) { drawIcon(in: $0.insetBy(dx: 6, dy: 6)) }
    let icon = bitmap(side: 256) { drawIcon(in: $0) }
    #expect(!IconMatch.measure(capture: drawn, icon: icon, item: CGRect(x: 0, y: 0, width: 128, height: 128))
        .showsBareIcon)
}

/// P0-REV-2 gap. `DockIcon.capture` rounds x, y, width and height one by one before it hands them
/// to `screencapture -R`, so a Dock frame on a half point grows by up to 1 pt past the Dock's edge.
/// The rect must already be whole points, inside the Dock, so the rounding changes nothing.
/// Not proven: that the Dock's Accessibility frames are ever fractional on a real display.
@Test(arguments: [CGRect(x: 300.5, y: 724.25, width: 64, height: 64), CGRect(x: 635.5, y: 724, width: 64, height: 64)])
func ringIsWholePointsInsideTheDock(item: CGRect) {
    let halfPointDock = CGRect(x: 300.5, y: 716.25, width: 399, height: 79.5)
    guard let rect = DockIcon.captureRect(around: item, dock: halfPointDock) else {
        Issue.record("an item inside the Dock has a capture")
        return
    }
    #expect(rect == rect.integral && halfPointDock.contains(rect), "\(rect) in \(halfPointDock)")
}

/// NT-GAT-005. R2 took the last Dock item titled nhetrinh: a pinned copy that is not running shows
/// its bundle icon on a tile, and R2 measured it. Only the launched app's item counts: running,
/// and of the launched bundle (`AXURL`). None: NOT READ BACK. More than one: FAIL.
enum ItemChoice: String, CaseIterable {
    case pinnedCopyAfterRunningApp = "the running app, then a pinned copy not running (P0-RUN-1)"
    case appNotRunning = "the launched app pinned but not running, and a pinned copy"
    case copyAlsoRunning = "the running app and a running copy of another bundle"
    case twoRunning = "two running items of the launched bundle"
    case runningWithoutURL = "a running item without a bundle URL"
    case none = "no Dock item"

    static let app = URL(fileURLWithPath: "/Users/someone/Applications/nhetrinh.app")

    /// The Dock items, and the y of the item R2 must take; nil: NOT READ BACK; -1: FAIL.
    var setup: (items: [DockItem], chosen: CGFloat?) {
        let dock = CGRect(x: 0, y: 100, width: 40, height: 800)
        func item(_ y: CGFloat, _ running: Bool, _ url: URL?) -> DockItem {
            DockItem(frame: CGRect(x: 4, y: y, width: 32, height: 32), dock: dock, isRunning: running, url: url)
        }
        let appItem = URL(string: "file:///Users/someone/Applications/nhetrinh.app/")  // AXURL ends with a slash
        let copy = URL(fileURLWithPath: "/private/tmp/F/nhetrinh.app")
        switch self {
        case .pinnedCopyAfterRunningApp: return ([item(200, true, appItem), item(300, false, copy)], 200)
        case .appNotRunning: return ([item(200, false, appItem), item(300, false, copy)], nil)
        case .copyAlsoRunning: return ([item(200, true, appItem), item(300, true, copy)], 200)
        case .twoRunning: return ([item(200, true, appItem), item(300, true, Self.app)], -1)
        case .runningWithoutURL: return ([item(200, true, nil)], nil)
        case .none: return ([], nil)
        }
    }
}

@Test(arguments: ItemChoice.allCases)
func r2MeasuresOnlyTheLaunchedApp(choice: ItemChoice) {
    do {
        let item = try DockIcon.launchedItem(choice.setup.items, app: ItemChoice.app)
        #expect(item.frame.minY == choice.setup.chosen, "chose the item at y \(item.frame.minY)")
    } catch StepError.cannotDrive(let why) {
        #expect(choice.setup.chosen == nil, "NOT READ BACK: \(why)")
    } catch StepError.fail(let why) {
        #expect(choice.setup.chosen == -1, "FAIL: \(why)")
    } catch {
        Issue.record("unexpected error: \(error)")
    }
}
