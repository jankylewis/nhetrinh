import AppKit
import Testing
@testable import NhetrinhReadback

/// R2 decides from a capture of the Dock item's own frame, longer across the Dock than the icon
/// (NT-GAT-015). These captures are drawn here, so the verdict is known: the bare icon passes; an icon
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

/// A 128 px icon square on a `dock` colour; the item is 152 px across the Dock (12 px above and below
/// the square), 128 along it. `below` is the item under the square inside the capture (0: the capture
/// ends at the square), `outside` the colour of its far half (not the Dock: past its visible edge).
func capture(dock: CGFloat, below: Int = 12, outside: CGFloat? = nil, _ item: (NSRect) -> Void) -> Capture {
    let image = bitmap(wide: 152, high: 140 + below) { rect in
        NSColor(white: dock, alpha: 1).setFill()
        rect.fill()
        NSColor(white: outside ?? dock, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: rect.width, height: CGFloat(below) / 2).fill()
        item(NSRect(x: 12, y: below, width: 128, height: 128))
    }
    return Capture(image: image, item: CGRect(x: 12, y: 0, width: 128, height: 152))
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

/// NT-GAT-015. The 13:57 capture, cropped to what R2 captures now: the item's own frame inside the
/// Dock, no neighbour, no running dot, nothing past the item (`Fixtures/_R2_1357_ITEM.png`). Left
/// Dock x 10 y 197 w 34 h 814 pt, tilesize 20, magnification on; item x 13.6 y 467.0 w 34 h 22 pt;
/// capture x 14 y 467 w 30 h 22 pt = 60 x 44 px; the item in it x -0.8 y 0 w 68 h 44 px. Column 49
/// is the Dock's rim; columns 50-59, past its visible edge, are a drawn plain grey strip (P3 60 60 60),
/// not the screen there (public repository). The bare icon: R2 said 80 % on the old 34 x 33 pt ring.
enum Capture1357: String, CaseIterable {
    case bare = "the 13:57 item as captured: the bare icon"
    case darkTile = "the 13:57 item with a dark tile painted behind the icon"
    case paleTile = "the 13:57 item with a pale tile painted behind the icon"

    static let item = CGRect(x: -0.8, y: 0, width: 68, height: 44)
    static let dock = [42.0, 76, 107]  // the Dock's colour R2 noted at 13:57

    /// The fixture; a tile: every Dock-coloured pixel in the rounded icon square takes the tile's colour.
    func load(_ app: URL) -> NSBitmapImageRep? {
        let file = app.appendingPathComponent("Tests/NhetrinhReadbackTests/Fixtures/_R2_1357_ITEM.png")
        guard let data = try? Data(contentsOf: file), let image = NSBitmapImageRep(data: data) else { return nil }
        guard self != .bare else { return image }
        let square = IconMatch.scoredSquare(Self.item, axis: .vertical), high = image.pixelsHigh
        let tile = NSBezierPath(roundedRect: square, xRadius: square.width * 0.22, yRadius: square.width * 0.22)
        return bitmap(wide: image.pixelsWide, high: high) { rect in
            image.draw(in: rect)
            NSColor(white: self == .darkTile ? 0.08 : 0.92, alpha: 1).setFill()
            for x in 0..<image.pixelsWide {
                for y in 0..<high where tile.contains(NSPoint(x: Double(x) + 0.5, y: Double(y) + 0.5)) {
                    guard let colour = image.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
                    let rgb = [colour.redComponent, colour.greenComponent, colour.blueComponent].map { $0 * 255 }
                    let near = zip(rgb, Self.dock).map { ($0 - $1) * ($0 - $1) }.reduce(0, +).squareRoot() < 30
                    if near { NSRect(x: x, y: high - 1 - y, width: 1, height: 1).fill() }  // AppKit: bottom left
                }
            }
        }
    }
}

@Test(arguments: Capture1357.allCases)
func r2JudgesThe1357ItemOnItsOwnFrame(capture: Capture1357) throws {
    let app = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
    let iconFile = app.appendingPathComponent("assets/_icon/bundle/_DockIcon.png")  // = the installed AppIcon.png
    let image = try #require(capture.load(app))
    let icon = try #require(NSBitmapImageRep(data: Data(contentsOf: iconFile)))
    let match = IconMatch.measure(capture: image, icon: icon, item: Capture1357.item, axis: .vertical)
    #expect(match.showsBareIcon == (capture == .bare),
            "\(capture.rawValue): agreement \(match.agreement), scale \(match.scale)")
}
