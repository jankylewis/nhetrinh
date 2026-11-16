import AppKit

/// Decides from pixels if a Dock item shows our icon as it is: no tile behind it, and large.
///
/// The Dock item is sampled on a grid. A cell is "occupied" when its colour is far from the
/// Dock's own background (taken from the item's border). The icon's transparency says which
/// cells should be occupied for a given size and offset. The best size and offset are searched;
/// `agreement` is the share of cells that match there, `scale` the icon size relative to the item.
/// A tile makes many cells occupied where the icon is transparent, or makes the icon small.
struct IconMatch {
    let agreement: Double
    let scale: Double

    static let grid = 48
    static let colourDistance = 30.0

    static func measure(capture: NSBitmapImageRep, icon: NSBitmapImageRep) -> IconMatch {
        let occupied = occupiedCells(of: capture)
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

    /// Which grid cells of the capture differ from the Dock background.
    private static func occupiedCells(of capture: NSBitmapImageRep) -> [Bool] {
        let background = borderColour(of: capture)
        return (0..<grid * grid).map { index in
            let x = (index % grid * 2 + 1) * capture.pixelsWide / (grid * 2)
            let y = (index / grid * 2 + 1) * capture.pixelsHigh / (grid * 2)
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

    /// The median colour of the capture's outer ring: the Dock's own background.
    private static func borderColour(of capture: NSBitmapImageRep) -> [Double] {
        let wide = capture.pixelsWide, high = capture.pixelsHigh
        var ring: [[Double]] = []
        for x in stride(from: 0, to: wide, by: 2) { ring += [rgb(capture, x, 1), rgb(capture, x, high - 2)] }
        for y in stride(from: 0, to: high, by: 2) { ring += [rgb(capture, 1, y), rgb(capture, wide - 2, y)] }
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
