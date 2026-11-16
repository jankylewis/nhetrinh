import AppKit

/// Decides from pixels if a Dock item shows our icon as it is: no tile behind it, and large.
///
/// The capture is the Dock item grown by a ring on each side (`DockIcon.ringPoints`). The item is
/// sampled on a grid. A cell is "occupied" when its colour is far from the Dock's own background,
/// taken from the ring, outside the item: a tile inside the item never reaches it (NT-GAT-004).
/// The icon's transparency says which cells should be occupied for a given size and offset.
/// The best size and offset are searched;
/// `agreement` is the share of cells that match there, `scale` the icon size relative to the item.
/// A tile makes many cells occupied where the icon is transparent, or makes the icon small.
struct IconMatch {
    let agreement: Double
    let scale: Double

    static let grid = 48
    static let colourDistance = 30.0

    /// R2 passes only here: the shape matches the icon, and the icon fills most of the Dock item.
    var showsBareIcon: Bool { agreement >= 0.90 && scale >= 0.60 }

    /// `item`: the Dock item inside the capture, in pixels, origin top left. The rest is the ring.
    /// No ring (no pixel outside the item) is never a pass: the Dock colour is then unknown.
    static func measure(capture: NSBitmapImageRep, icon: NSBitmapImageRep, item: CGRect) -> IconMatch {
        guard let background = ringColour(of: capture, item: item), item.width >= 1, item.height >= 1 else {
            return IconMatch(agreement: 0, scale: 0)
        }
        let occupied = occupiedCells(of: capture, item: item, background: background)
        let opaque = opaqueTable(of: icon)
        var best = IconMatch(agreement: 0, scale: 0)
        for scale in stride(from: 0.40, through: 1.0, by: 0.02) {
            for dx in stride(from: -0.08, through: 0.08, by: 0.02) {
                for dy in stride(from: -0.08, through: 0.08, by: 0.02) {
                    let share = agreement(occupied, opaque, scale: scale, offset: CGPoint(x: dx, y: dy))
                    if share > best.agreement { best = IconMatch(agreement: share, scale: scale) }
                }
            }
        }
        return best
    }

    /// Which grid cells of the item differ from the Dock background.
    private static func occupiedCells(of capture: NSBitmapImageRep, item: CGRect, background: [Double]) -> [Bool] {
        (0..<grid * grid).map { index in
            let x = Int(item.minX + (Double(index % grid) + 0.5) * item.width / Double(grid))
            let y = Int(item.minY + (Double(index / grid) + 0.5) * item.height / Double(grid))
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

    private static func agreement(_ occupied: [Bool], _ opaque: [Bool], scale: Double, offset: CGPoint) -> Double {
        var matches = 0
        for index in 0..<grid * grid {
            let u = ((Double(index % grid) + 0.5) / Double(grid) - 0.5 - offset.x) / scale + 0.5
            let v = ((Double(index / grid) + 0.5) / Double(grid) - 0.5 - offset.y) / scale + 0.5
            let inside = u >= 0 && u < 1 && v >= 0 && v < 1
            let expected = inside && opaque[Int(v * 256) * 256 + Int(u * 256)]
            if expected == occupied[index] { matches += 1 }
        }
        return Double(matches) / Double(grid * grid)
    }

    /// The median colour of the ring: every pixel of the capture outside the item. Not the item's
    /// border or corners: a tile as large as the item covers its border, and a square tile its
    /// corners, and was then taken for the Dock (NT-GAT-004). Nil when there is no ring.
    private static func ringColour(of capture: NSBitmapImageRep, item: CGRect) -> [Double]? {
        var ring: [[Double]] = []
        for y in 0..<capture.pixelsHigh {
            for x in 0..<capture.pixelsWide where !item.contains(CGPoint(x: Double(x) + 0.5, y: Double(y) + 0.5)) {
                ring.append(rgb(capture, x, y))
            }
        }
        guard !ring.isEmpty else { return nil }
        return (0..<3).map { channel in ring.map { $0[channel] }.sorted()[ring.count / 2] }
    }

    private static func rgb(_ image: NSBitmapImageRep, _ x: Int, _ y: Int) -> [Double] {
        guard let colour = image.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { return [0, 0, 0] }
        return [colour.redComponent, colour.greenComponent, colour.blueComponent].map { Double($0) * 255 }
    }

    private static func distance(_ first: [Double], _ second: [Double]) -> Double {
        zip(first, second).map { ($0 - $1) * ($0 - $1) }.reduce(0, +).squareRoot()
    }
}
