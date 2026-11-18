import AppKit
import Testing
@testable import NhetrinhReadback

/// NT-GAT-007. The 19:40 capture (kept outside the repository, never copied in): the Dock on the
/// left, 34 pt wide; the item 34 x 22 pt, wider than the icon and past the Dock's visible edge;
/// the bare icon, no tile. R2 failed at 76 %: the item took in a lighter strip past the Dock's
/// edge, and the square icon was stretched over a 34 x 22 item. Drawn here at 2x, same geometry,
/// on a left, a bottom and a right Dock: the running dot on the screen-edge side, the lighter strip
/// on the other side, and neighbour tiles touching the item along the Dock, as on a 20 pt Dock with
/// magnification (NT-GAT-015: at 13:57 they filled the ring R2 read the Dock's colour from).
enum AxisCase: String, CaseIterable {
    case bareLeft = "left Dock: the bare icon"
    case tiledLeft = "left Dock: the icon on a dark tile"
    case bareBottom = "bottom Dock: the bare icon"
    case tiledBottom = "bottom Dock: the icon on a dark tile"
    case bareRight = "right Dock: the bare icon"
    case tiledRight = "right Dock: the icon on a dark tile"

    var axis: DockAxis { self == .bareBottom || self == .tiledBottom ? .horizontal : .vertical }
    var tiled: Bool { self == .tiledLeft || self == .tiledBottom || self == .tiledRight }
    var mirrored: Bool { self != .bareLeft && self != .tiledLeft }  // across 0 at the right or the bottom
}

/// A rect given along the Dock and across it (across 0 is the screen edge), in pixels, top left.
private func place(_ along: ClosedRange<Double>, _ across: ClosedRange<Double>, _ shape: AxisCase) -> CGRect {
    let width = along.upperBound - along.lowerBound, depth = across.upperBound - across.lowerBound
    let start = shape.mirrored ? 68 - across.upperBound : across.lowerBound  // 68: Dock depth
    return shape.axis == .vertical
        ? CGRect(x: start, y: along.lowerBound, width: depth, height: width)
        : CGRect(x: along.lowerBound, y: start, width: width, height: depth)
}

/// Fill `rect` (top-left pixels) in a bitmap `high` pixels tall: AppKit draws from the bottom left.
private func fill(_ rect: CGRect, white: CGFloat, high: Int, round: Bool = false) {
    let flipped = NSRect(x: rect.minX, y: CGFloat(high) - rect.maxY, width: rect.width, height: rect.height)
    NSColor(white: white, alpha: 1).setFill()
    let radius = round ? min(rect.width, rect.height) * 0.22 : 0
    NSBezierPath(roundedRect: flipped, xRadius: radius, yRadius: radius).fill()
}

/// The capture: 66 px along the Dock and 68 px across it. The item is 44 px along (22 pt) and
/// 68 px across, from 7 px, so it runs past the capture's far side. Returns the item unclamped.
func axisCapture(_ shape: AxisCase) -> (image: NSBitmapImageRep, item: CGRect) {
    let axis = shape.axis
    let wide = axis == .vertical ? 68 : 66, high = axis == .vertical ? 66 : 68
    let image = bitmap(wide: wide, high: high) { _ in
        fill(place(0...66, 0...68, shape), white: 0.30, high: high)  // the Dock
        for step in 0..<5 {  // the lighter, uneven strip past the Dock's visible edge
            let across = Double(58 + 2 * step)...Double(60 + 2 * step)
            fill(place(0...66, across, shape), white: 0.42 + 0.02 * CGFloat(step), high: high)
        }
        fill(place(-20...10, 8...44, shape), white: 0.08, high: high, round: true)  // neighbour before, touching
        fill(place(54...90, 8...44, shape), white: 0.08, high: high, round: true)  // neighbour after, touching
        fill(place(28...36, 0...4, shape), white: 0.80, high: high, round: true)  // the running dot
        let square = place(10...54, 19...63, shape)  // the icon's square, centred on the item
        if shape.tiled { fill(square, white: 0.08, high: high, round: true) }
        let icon = square.insetBy(dx: square.width * 0.12, dy: square.height * 0.12)
        drawIcon(in: NSRect(x: icon.minX, y: CGFloat(high) - icon.maxY, width: icon.width, height: icon.height))
    }
    return (image, place(10...54, 7...75, shape))
}

@Test(arguments: AxisCase.allCases)
func r2JudgesTheIconNotItsNeighbours(shape: AxisCase) {
    let drawn = axisCapture(shape)
    let match = IconMatch.measure(capture: drawn.image, icon: bitmap(side: 256) { drawIcon(in: $0) },
                                  item: drawn.item, axis: shape.axis)
    #expect(match.showsBareIcon == !shape.tiled,
            "\(shape.rawValue): agreement \(match.agreement), scale \(match.scale)")
}

/// The 19:40 Dock frame (left, 34 x 770 pt) is vertical; a bottom Dock is horizontal.
@Test func dockAxisFollowsTheDocksLongSide() {
    #expect(DockAxis.of(CGRect(x: 10, y: 219, width: 34, height: 770)) == .vertical)
    #expect(DockAxis.of(CGRect(x: 300, y: 716, width: 400, height: 80)) == .horizontal)
}

/// The scored square: the item's length along the Dock, centred on the whole item across it.
@Test func scoredSquareIsTheItemsLengthCentred() {
    let item = CGRect(x: 7.2, y: 10, width: 68, height: 44)  // the 19:40 item in pixels
    let square = IconMatch.scoredSquare(item, axis: .vertical)
    #expect(abs(square.minX - 19.2) < 0.001 && square.minY == 10 && square.width == 44 && square.height == 44)
    let lying = CGRect(x: 10, y: -7, width: 44, height: 68)
    #expect(IconMatch.scoredSquare(lying, axis: .horizontal) == CGRect(x: 10, y: 5, width: 44, height: 44))
}

/// NT-TG-002 ruling: no pixel outside the Dock frame, ever. The 19:40 left Dock: the item reaches
/// 3.6 pt past the frame's far side; the capture stays inside the frame.
@Test(arguments: [CGRect(x: 13.6, y: 489, width: 34, height: 22), CGRect(x: 13.6, y: 219, width: 34, height: 22),
                  CGRect(x: 13.6, y: 967, width: 34, height: 22), CGRect(x: 4, y: 600, width: 50, height: 22)])
func narrowLeftDockCaptureStaysInTheFrame(item: CGRect) {
    let dock = CGRect(x: 10, y: 219, width: 34, height: 770)
    guard let rect = DockIcon.captureRect(of: item, dock: dock) else {
        Issue.record("an item on the Dock has a capture")
        return
    }
    #expect(dock.contains(rect), "\(rect) leaves the Dock \(dock)")
}

/// When the clamp cuts the icon's square, only the part on the capture is scored: the left Dock
/// fixture cut 12 px short across the Dock (the square loses 7 of 44 px).
@Test(arguments: [AxisCase.bareLeft, .tiledLeft])
func cutSquareIsScoredInsideTheCapture(shape: AxisCase) {
    let drawn = axisCapture(shape)
    let cut = CGRect(x: 0, y: 0, width: 56, height: 66)
    guard let whole = drawn.image.cgImage, let part = whole.cropping(to: cut) else {
        Issue.record("cannot crop the fixture")
        return
    }
    let icon = bitmap(side: 256) { drawIcon(in: $0) }
    let capture = NSBitmapImageRep(cgImage: part)
    let match = IconMatch.measure(capture: capture, icon: icon, item: drawn.item, axis: .vertical)
    #expect(match.showsBareIcon == !shape.tiled,
            "\(shape.rawValue): agreement \(match.agreement), scale \(match.scale)")
}

/// NT-GAT-015: only the item's own frame, never a ring: at 13:57 the ring held the neighbours.
@Test func captureIsTheItemInsideTheDock() {
    let bottom = CGRect(x: 300, y: 716, width: 400, height: 80)
    #expect(DockIcon.captureRect(of: CGRect(x: 400, y: 724, width: 64, height: 64), dock: bottom)
            == CGRect(x: 400, y: 724, width: 64, height: 64))
    #expect(DockIcon.captureRect(of: CGRect(x: 690, y: 700, width: 64, height: 120), dock: bottom)
            == CGRect(x: 690, y: 716, width: 10, height: 80))
    let left = CGRect(x: 10, y: 197, width: 34, height: 814)  // 13:57: the item past the Dock's far side
    #expect(DockIcon.captureRect(of: CGRect(x: 13.6, y: 467, width: 34, height: 22), dock: left)
            == CGRect(x: 14, y: 467, width: 30, height: 22))
}
