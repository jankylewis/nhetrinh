import AppKit
import Testing
@testable import NhetrinhReadback

/// R2 decides from a capture of the Dock item. These captures are drawn here, so the verdict is
/// known: the bare icon passes; a small icon on a dark tile, or an empty item, fails.
enum DockCapture: String, CaseIterable {
    case bareIconOnDock = "the icon alone on a plain Dock colour"
    case smallIconOnDarkTile = "the same icon smaller on a dark rounded tile"
    case blank = "a blank capture"

    var showsBareIcon: Bool { self == .bareIconOnDock }

    func draw() -> NSBitmapImageRep {
        bitmap(side: 128) { rect in
            NSColor(white: 0.85, alpha: 1).setFill()
            rect.fill()
            switch self {
            case .bareIconOnDock:
                drawIcon(in: rect.insetBy(dx: rect.width * 0.05, dy: rect.height * 0.05))
            case .smallIconOnDarkTile:
                NSColor(white: 0.08, alpha: 1).setFill()
                let tile = rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.08)
                NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.22, yRadius: tile.width * 0.22).fill()
                drawIcon(in: rect.insetBy(dx: rect.width * 0.22, dy: rect.height * 0.22))
            case .blank:
                break
            }
        }
    }
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

@Test(arguments: DockCapture.allCases)
func dockCaptureVerdict(capture: DockCapture) {
    let icon = bitmap(side: 256) { drawIcon(in: $0) }
    let match = IconMatch.measure(capture: capture.draw(), icon: icon)
    #expect(match.showsBareIcon == capture.showsBareIcon,
            "\(capture.rawValue): agreement \(match.agreement), scale \(match.scale)")
}
