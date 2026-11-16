import AppKit

/// The Dock's long axis: its items sit one after another along it (NT-GAT-007).
enum DockAxis {
    case horizontal, vertical

    static func of(_ dock: CGRect) -> DockAxis { dock.width >= dock.height ? .horizontal : .vertical }
}

/// Decides from pixels if a Dock item shows our icon as it is: no tile behind it, and large.
///
/// The capture is the Dock item grown by a ring on each side (`DockIcon.ringPoints`). The icon is
/// square, as long as the item along the Dock and centred on it across the Dock: only that square
/// is scored, on a grid. An item can be wider across the Dock than its icon and reach past the
/// Dock's visible edge (NT-GAT-007). A cell is "occupied" when its colour is far from the Dock's
/// background on its line across the Dock, read from the ring before and after the item along the
/// Dock: never across it, where the running dot and the Dock's edge are, and never inside the
/// item, where a tile is (NT-GAT-004). The icon's transparency says which cells should be occupied
/// for a given size and offset. The best size and offset are searched;
/// `agreement` is the share of cells that match there, `scale` the icon size relative to the square.
/// A tile makes many cells occupied where the icon is transparent, or makes the icon small.
struct IconMatch {
    let agreement: Double
    let scale: Double
    /// The Dock's colour read from the ring (median of its lines), sRGB 0-255; empty when there is no ring.
    var background: [Double] = []

    static let grid = 48
    static let colourDistance = 30.0

    /// R2 passes only here: the shape matches the icon, and the icon fills most of the Dock item.
    var showsBareIcon: Bool { agreement >= 0.90 && scale >= 0.60 }

    /// `item`: the Dock item in the capture, in pixels, origin top left, not clamped to the capture.
    /// No ring before or after the item on a line of the square is never a pass: the Dock colour
    /// is then unknown there.
    static func measure(capture: NSBitmapImageRep, icon: NSBitmapImageRep, item: CGRect, axis: DockAxis) -> IconMatch {
        let square = scoredSquare(item, axis: axis)
        guard square.width >= 1, let lines = lineColours(of: capture, item: item, square: square, axis: axis) else {
            return IconMatch(agreement: 0, scale: 0)
        }
        let occupied = occupiedCells(of: capture, square: square, axis: axis, lines: lines)
        let opaque = opaqueTable(of: icon)
        let background = (0..<3).map { channel in median(lines.values.map { $0[channel] }) }
        var best = IconMatch(agreement: 0, scale: 0, background: background)
        for scale in stride(from: 0.40, through: 1.0, by: 0.02) {
            for dx in stride(from: -0.08, through: 0.08, by: 0.02) {
                for dy in stride(from: -0.08, through: 0.08, by: 0.02) {
                    let share = agreement(occupied, opaque, scale: scale, offset: CGPoint(x: dx, y: dy))
                    guard share > best.agreement else { continue }
                    best = IconMatch(agreement: share, scale: scale, background: background)
                }
            }
        }
        return best
    }

    /// The square the icon is drawn in: the item's length along the Dock, centred on the item.
    static func scoredSquare(_ item: CGRect, axis: DockAxis) -> CGRect {
        axis == .horizontal
            ? CGRect(x: item.minX, y: item.midY - item.width / 2, width: item.width, height: item.width)
            : CGRect(x: item.midX - item.height / 2, y: item.minY, width: item.height, height: item.height)
    }

    /// Which grid cells of the square differ from the background of their line; nil: off the capture.
    private static func occupiedCells(of capture: NSBitmapImageRep, square: CGRect, axis: DockAxis,
                                      lines: [Int: [Double]]) -> [Bool?] {
        (0..<grid * grid).map { index in
            let x = Int((square.minX + (Double(index % grid) + 0.5) * square.width / Double(grid)).rounded(.down))
            let y = Int((square.minY + (Double(index / grid) + 0.5) * square.height / Double(grid)).rounded(.down))
            guard let background = lines[axis == .vertical ? x : y],
                  (0..<capture.pixelsWide).contains(x), (0..<capture.pixelsHigh).contains(y) else { return nil }
            return distance(rgb(capture, x, y), background) > colourDistance
        }
    }

    /// The icon's opacity on a 256 x 256 table (true = the icon covers this point).
    private static func opaqueTable(of icon: NSBitmapImageRep) -> [Bool] {
        (0..<256 * 256).map { index in
            let x = (index % 256) * icon.pixelsWide / 256, y = (index / 256) * icon.pixelsHigh / 256
            return (icon.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.5
        }
    }

    /// The share of the scored cells that match; 0 when less than half the square is on the capture.
    private static func agreement(_ occupied: [Bool?], _ opaque: [Bool], scale: Double, offset: CGPoint) -> Double {
        var matches = 0, scored = 0
        for index in 0..<grid * grid {
            guard let seen = occupied[index] else { continue }
            let u = ((Double(index % grid) + 0.5) / Double(grid) - 0.5 - offset.x) / scale + 0.5
            let v = ((Double(index / grid) + 0.5) / Double(grid) - 0.5 - offset.y) / scale + 0.5
            let inside = u >= 0 && u < 1 && v >= 0 && v < 1
            let expected = inside && opaque[Int(v * 256) * 256 + Int(u * 256)]
            scored += 1
            if expected == seen { matches += 1 }
        }
        return scored * 2 < grid * grid ? 0 : Double(matches) / Double(scored)
    }

    /// The Dock's colour on each line across the Dock that the square covers, inside the capture:
    /// the median of the ring pixels on that line before and after the item along the Dock. Not the
    /// item's border or corners: a tile as large as the item covers them (NT-GAT-004). Not the ring
    /// across the Dock: the running dot is there, and past the Dock's visible edge another colour
    /// (NT-GAT-007). A neighbour's tile takes less than half of a line. Nil when a line has no ring.
    private static func lineColours(of capture: NSBitmapImageRep, item: CGRect, square: CGRect,
                                    axis: DockAxis) -> [Int: [Double]]? {
        let vertical = axis == .vertical
        let span = vertical ? (square.minX, square.maxX, capture.pixelsWide)
            : (square.minY, square.maxY, capture.pixelsHigh)
        let along = vertical ? (item.minY, item.maxY, capture.pixelsHigh) : (item.minX, item.maxX, capture.pixelsWide)
        let first = max(0, Int(span.0.rounded(.down))), last = min(span.2, Int(span.1.rounded(.up)))
        guard first < last else { return nil }
        var lines: [Int: [Double]] = [:]
        for line in first..<last {
            let ring = (0..<along.2).filter { Double($0) + 0.5 < along.0 || Double($0) + 0.5 >= along.1 }
                .map { vertical ? rgb(capture, line, $0) : rgb(capture, $0, line) }
            guard !ring.isEmpty else { return nil }
            lines[line] = (0..<3).map { channel in median(ring.map { $0[channel] }) }
        }
        return lines
    }

    private static func median(_ values: [Double]) -> Double { values.sorted()[values.count / 2] }

    private static func rgb(_ image: NSBitmapImageRep, _ x: Int, _ y: Int) -> [Double] {
        guard let colour = image.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { return [0, 0, 0] }
        return [colour.redComponent, colour.greenComponent, colour.blueComponent].map { Double($0) * 255 }
    }

    private static func distance(_ first: [Double], _ second: [Double]) -> Double {
        zip(first, second).map { ($0 - $1) * ($0 - $1) }.reduce(0, +).squareRoot()
    }
}
