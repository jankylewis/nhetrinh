import AppKit
import Testing
@testable import NhetrinhReadback

/// R2 decides from a capture of the Dock item. These captures are drawn here, so the verdict is
/// known: the bare icon passes; an icon on a dark tile, a small icon, or an empty item fails.
/// Each criterion has more than one case, on a light and on a dark Dock (NT-GAT-004).
enum DockCapture: String, CaseIterable {
    case bareIconOnDock = "the icon alone on a plain Dock colour"
    case smallIconOnDarkTile = "the same icon smaller on a dark rounded tile"
    case iconOnTileToTheEdge = "the icon at 76 % on a dark rounded tile as large as the item"
    case iconOnTileNearTheEdge = "the icon at 84 % on a dark rounded tile at 96 % of the item"
    case smallBareIcon = "the icon alone at 40 % of the item"
    case blank = "a blank capture"

    var showsBareIcon: Bool { self == .bareIconOnDock }

    func draw(dock: CGFloat) -> NSBitmapImageRep {
        bitmap(side: 128) { rect in
            NSColor(white: dock, alpha: 1).setFill()
            rect.fill()
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

/// A square RGBA bitmap, transparent at first, drawn into by `body`.
func bitmap(side: Int, _ body: (NSRect) -> Void) -> NSBitmapImageRep {
    guard let image = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
        let context = NSGraphicsContext(bitmapImageRep: image)
    else { fatalError("cannot make a \(side) px bitmap") }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    body(NSRect(x: 0, y: 0, width: side, height: side))
    NSGraphicsContext.restoreGraphicsState()
    return image
}

/// A light Dock and a dark Dock (the dark one is still far enough from the tile's colour).
@Test(arguments: DockCapture.allCases, [0.85, 0.25])
func dockCaptureVerdict(capture: DockCapture, dock: CGFloat) {
    let icon = bitmap(side: 256) { drawIcon(in: $0) }
    let match = IconMatch.measure(capture: capture.draw(dock: dock), icon: icon)
    #expect(match.showsBareIcon == capture.showsBareIcon,
            "\(capture.rawValue), Dock \(dock): agreement \(match.agreement), scale \(match.scale)")
}

/// P0-REV-1 gaps in the corner rule (NT-GAT-004). Each capture is 128 px; the icon is at 76 %.
enum CornerCase: String, CaseIterable {
    case squareTileToTheEdge = "a dark tile with square corners as large as the item"
    case paleTileOnLightDock = "a rounded tile 0.80 on a 0.85 Dock (within the colour distance)"
    case lightTileLightCornersBelow = "a light rounded tile on a dark Dock, 2 bottom corners light (outside the Dock)"
    case bareIconLightCornersBelow = "the bare icon on a dark Dock, 2 bottom corners light (outside the Dock)"

    var showsBareIcon: Bool { self == .bareIconLightCornersBelow }

    func draw() -> NSBitmapImageRep {
        bitmap(side: 128) { rect in
            let dock: CGFloat = self == .paleTileOnLightDock ? 0.85 : 0.25
            NSColor(white: dock, alpha: 1).setFill()
            rect.fill()
            let tile: CGFloat = self == .squareTileToTheEdge ? 0.08 : (self == .paleTileOnLightDock ? 0.80 : 0.92)
            NSColor(white: tile, alpha: 1).setFill()
            let radius = self == .squareTileToTheEdge ? 0 : rect.width * 0.22
            if self != .bareIconLightCornersBelow {
                NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            }
            if self == .lightTileLightCornersBelow || self == .bareIconLightCornersBelow {
                NSColor(white: 0.92, alpha: 1).setFill()
                NSRect(x: 0, y: 0, width: 6, height: 6).fill()
                NSRect(x: rect.width - 6, y: 0, width: 6, height: 6).fill()
            }
            drawIcon(in: rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.12))
        }
    }
}

@Test(arguments: CornerCase.allCases)
func dockCornerReviewGaps(capture: CornerCase) {
    let icon = bitmap(side: 256) { drawIcon(in: $0) }
    let match = IconMatch.measure(capture: capture.draw(), icon: icon)
    #expect(match.showsBareIcon == capture.showsBareIcon,
            "\(capture.rawValue): agreement \(match.agreement), scale \(match.scale)")
}
