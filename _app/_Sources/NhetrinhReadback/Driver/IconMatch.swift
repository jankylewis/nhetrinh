import AppKit

/// Decides from pixels if a Dock item shows our icon as it is: no tile behind it, and large.
///
/// The capture is the item's own frame inside the Dock, never its neighbours (NT-GAT-015). The icon
/// is square, as long as the item along the Dock and centred on it across: only that square is scored,
/// on a grid. Beside it, inside the item, are the Dock, the running dot and what is past the Dock's
/// visible edge (NT-GAT-007): the Dock's colour is the one most of those pixels share, never the
/// square's border, where a tile is (NT-GAT-004). Lines along the Dock at the item's ends that are off
/// the Dock on 90 % of their length are past its edge and not scored, up to `edgeDepth` into the
/// square; deeper, they are a tile. A cell is "occupied" when far from the Dock's colour; the icon's
/// transparency says which cells should be. The best size and offset are searched: `agreement` is the
/// share of matching cells there, `scale` the icon size relative to the square. A tile makes many
/// cells occupied where the icon is transparent, or makes the icon small.
struct IconMatch {
    let agreement: Double
    let scale: Double
    /// The Dock's colour beside the square, sRGB 0-255; empty when there is none.
    var background: [Double] = []

    static let grid = 48
    static let colourDistance = 30.0
    /// How far past the Dock's edge may reach into the square, a share of its side.
    static let edgeDepth = 0.25

    /// R2 passes only here: the shape matches the icon, and the icon fills most of the Dock item.
    var showsBareIcon: Bool { agreement >= 0.90 && scale >= 0.60 }

    /// `item`: the Dock item in the capture, in pixels, origin top left, not clamped to the capture.
    /// No Dock beside the square inside the item is never a pass: the Dock colour is then unknown.
    static func measure(capture: NSBitmapImageRep, icon: NSBitmapImageRep, item: CGRect, axis: DockAxis) -> IconMatch {
        let pixels = ItemPixels(capture: capture, item: item, axis: axis)
        guard pixels.square.width >= 1, let dock = pixels.dockColour() else { return IconMatch(agreement: 0, scale: 0) }
        let occupied = pixels.occupiedCells(dock: dock)
        let opaque = opaqueTable(of: icon)
        var best = IconMatch(agreement: 0, scale: 0, background: [dock.x, dock.y, dock.z])
        for scale in stride(from: 0.40, through: 1.0, by: 0.02) {
            for dx in stride(from: -0.08, through: 0.08, by: 0.02) {
                for dy in stride(from: -0.08, through: 0.08, by: 0.02) {
                    let share = agreement(occupied, opaque, scale: scale, offset: CGPoint(x: dx, y: dy))
                    guard share > best.agreement else { continue }
                    best = IconMatch(agreement: share, scale: scale, background: best.background)
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

    /// The icon's opacity on a 256 x 256 table (true = the icon covers this point).
    private static func opaqueTable(of icon: NSBitmapImageRep) -> [Bool] {
        (0..<256 * 256).map { index in
            let x = (index % 256) * icon.pixelsWide / 256, y = (index / 256) * icon.pixelsHigh / 256
            return (icon.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.5
        }
    }

    /// The share of the scored cells that match; 0 when less than half the square is scored.
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
}

/// The item's pixels in the capture, by their place across the Dock and along it.
private struct ItemPixels {
    let capture: NSBitmapImageRep
    let vertical: Bool
    let square: CGRect
    /// Pixel indexes whose centre is inside the item and the capture; the square's, across the Dock.
    let across: Range<Int>, along: Range<Int>, squareAcross: Range<Int>

    init(capture: NSBitmapImageRep, item: CGRect, axis: DockAxis) {
        self.capture = capture
        vertical = axis == .vertical
        square = IconMatch.scoredSquare(item, axis: axis)
        let size = vertical ? (capture.pixelsWide, capture.pixelsHigh) : (capture.pixelsHigh, capture.pixelsWide)
        let centres = { (low: Double, high: Double) in
            Int((low - 0.5).rounded(.up))..<max(Int((low - 0.5).rounded(.up)), Int((high - 0.5).rounded(.up))) }
        across = (vertical ? centres(item.minX, item.maxX) : centres(item.minY, item.maxY)).clamped(to: 0..<size.0)
        along = (vertical ? centres(item.minY, item.maxY) : centres(item.minX, item.maxX)).clamped(to: 0..<size.1)
        squareAcross = vertical ? centres(square.minX, square.maxX) : centres(square.minY, square.maxY)
    }

    /// The colour most pixels beside the square share (within `colourDistance` of it), their median.
    func dockColour() -> SIMD3<Double>? {
        let beside = across.filter { !squareAcross.contains($0) }.flatMap { line in along.map { rgb(line, $0) } }
        let step = max(1, beside.count / 256)
        let near = { (centre: SIMD3<Double>) in beside.filter { distance($0, centre) <= IconMatch.colourDistance } }
        guard let centre = stride(from: 0, to: beside.count, by: step).map({ beside[$0] })
            .max(by: { near($0).count < near($1).count }) else { return nil }
        let shared = near(centre)
        let median = { (values: [Double]) in values.sorted()[values.count / 2] }
        return SIMD3(median(shared.map(\.x)), median(shared.map(\.y)), median(shared.map(\.z)))
    }

    /// Which grid cells of the square differ from the Dock; nil: not scored (off the item, past the edge).
    func occupiedCells(dock: SIMD3<Double>) -> [Bool?] {
        let scored = onDock(dock), grid = IconMatch.grid
        return (0..<grid * grid).map { index in
            let x = Int((square.minX + (Double(index % grid) + 0.5) * square.width / Double(grid)).rounded(.down))
            let y = Int((square.minY + (Double(index / grid) + 0.5) * square.height / Double(grid)).rounded(.down))
            let (line, place) = vertical ? (x, y) : (y, x)
            guard scored.contains(line), along.contains(place) else { return nil }
            return distance(rgb(line, place), dock) > IconMatch.colourDistance
        }
    }

    /// The lines of the square to score: without the lines at the item's ends that are off the Dock,
    /// when they reach at most `edgeDepth` into the square.
    private func onDock(_ dock: SIMD3<Double>) -> Range<Int> {
        let off = { (line: Int) in
            along.filter { distance(rgb(line, $0), dock) > IconMatch.colourDistance }.count * 10 >= along.count * 9
        }
        var low = across.lowerBound, high = across.upperBound
        while low < high, off(low) { low += 1 }
        while high > low, off(high - 1) { high -= 1 }
        let depth = Double(squareAcross.count) * IconMatch.edgeDepth
        let (start, end) = (squareAcross.lowerBound, squareAcross.upperBound)
        let first = Double(low - start) <= depth ? max(low, start) : start
        let last = Double(end - high) <= depth ? min(high, end) : end
        return (first..<max(first, last)).clamped(to: across)
    }

    private func rgb(_ line: Int, _ place: Int) -> SIMD3<Double> {
        let (x, y) = vertical ? (line, place) : (place, line)
        guard let colour = capture.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { return .zero }
        return SIMD3(Double(colour.redComponent), Double(colour.greenComponent), Double(colour.blueComponent)) * 255
    }

    private func distance(_ first: SIMD3<Double>, _ second: SIMD3<Double>) -> Double {
        ((first - second) * (first - second)).sum().squareRoot()
    }
}
