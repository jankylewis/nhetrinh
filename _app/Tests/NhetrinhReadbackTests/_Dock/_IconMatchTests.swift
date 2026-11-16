import AppKit
import Testing
@testable import NhetrinhReadback

/// R2 decides from a capture of the Dock item and a ring around it (`DockIcon.ringPoints`, 12 px
/// at 2x). These captures are drawn here, so the verdict is known: the bare icon passes; an icon
/// on a dark tile, a small icon, or an empty item fails. Each criterion has more than one case,
/// on a light and on a dark Dock (NT-GAT-004).
enum DockCapture: String, CaseIterable {
    case bareIconOnDock = "the icon alone on a plain Dock colour"
    case smallIconOnDarkTile = "the same icon smaller on a dark rounded tile"
    case iconOnTileToTheEdge = "the icon at 76 % on a dark rounded tile as large as the item"
    case iconOnTileNearTheEdge = "the icon at 84 % on a dark rounded tile at 96 % of the item"
    case smallBareIcon = "the icon alone at 40 % of the item"
    case blank = "a blank capture"

    var showsBareIcon: Bool { self == .bareIconOnDock }

    func draw(dock: CGFloat) -> Capture {
        capture(dock: dock) { rect in
            switch self {
            case .bareIconOnDock: drawIcon(in: rect.insetBy(dx: rect.width * 0.05, dy: rect.height * 0.05))
            case .smallIconOnDarkTile: drawTile(rect, tile: 0.08, icon: 0.22)
            case .iconOnTileToTheEdge: drawTile(rect, tile: 0, icon: 0.12)
            case .iconOnTileNearTheEdge: drawTile(rect, tile: 0.02, icon: 0.08)
            case .smallBareIcon: drawIcon(in: rect.insetBy(dx: rect.width * 0.30, dy: rect.height * 0.30))
            case .blank: break
            }
        }
    }
}

/// A dark rounded tile inset by `tile`, and the icon on it inset by `icon` (shares of the side).
func drawTile(_ rect: NSRect, tile: CGFloat, icon: CGFloat) {
    NSColor(white: 0.08, alpha: 1).setFill()
    let shape = rect.insetBy(dx: rect.width * tile, dy: rect.height * tile)
    NSBezierPath(roundedRect: shape, xRadius: shape.width * 0.22, yRadius: shape.width * 0.22).fill()
    drawIcon(in: rect.insetBy(dx: rect.width * icon, dy: rect.height * icon))
}

/// A figure that is not a square: a round head on a narrower body, the rest transparent.
func drawIcon(in rect: NSRect) {
    NSColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 1).setFill()
    let unit = rect.width / 10
    NSBezierPath(ovalIn: NSRect(x: rect.minX + 3 * unit, y: rect.minY + 6 * unit, width: 4 * unit, height: 4 * unit))
        .fill()
    NSRect(x: rect.minX + 2 * unit, y: rect.minY, width: 6 * unit, height: 5 * unit).fill()
}

struct Capture {
    let image: NSBitmapImageRep
    let item: CGRect
}

/// A 128 px Dock item on a `dock` colour, with a 12 px ring; `below` is the ring under the item
/// (0 at the Dock's bottom edge), `outside` the colour of that strip (not the Dock).
func capture(dock: CGFloat, below: Int = 12, outside: CGFloat? = nil, _ item: (NSRect) -> Void) -> Capture {
    let image = bitmap(wide: 152, high: 140 + below) { rect in
        NSColor(white: dock, alpha: 1).setFill()
        rect.fill()
        NSColor(white: outside ?? dock, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: rect.width, height: CGFloat(below)).fill()
        item(NSRect(x: 12, y: below, width: 128, height: 128))
    }
    return Capture(image: image, item: CGRect(x: 12, y: 12, width: 128, height: 128))
}

/// An RGBA bitmap, transparent at first, drawn into by `body`.
func bitmap(side: Int, _ body: (NSRect) -> Void) -> NSBitmapImageRep { bitmap(wide: side, high: side, body) }

func bitmap(wide: Int, high: Int, _ body: (NSRect) -> Void) -> NSBitmapImageRep {
    guard let image = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: wide, pixelsHigh: high, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
        let context = NSGraphicsContext(bitmapImageRep: image)
    else { fatalError("cannot make a \(wide) x \(high) px bitmap") }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    body(NSRect(x: 0, y: 0, width: wide, height: high))
    NSGraphicsContext.restoreGraphicsState()
    return image
}

/// A light Dock and a dark Dock (the dark one is still far enough from the tile's colour).
@Test(arguments: DockCapture.allCases, [0.85, 0.25])
func dockCaptureVerdict(capture: DockCapture, dock: CGFloat) {
    let drawn = capture.draw(dock: dock)
    let match = IconMatch.measure(capture: drawn.image, icon: bitmap(side: 256) { drawIcon(in: $0) }, item: drawn.item,
                                  axis: .horizontal)
    #expect(match.showsBareIcon == capture.showsBareIcon,
            "\(capture.rawValue), Dock \(dock): agreement \(match.agreement), scale \(match.scale)")
}
