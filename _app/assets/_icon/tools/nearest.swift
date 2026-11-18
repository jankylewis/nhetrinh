// nearest.swift draw <master.png> <out.png> <side>   one icon size, nearest-neighbour from the 80 px grid
// nearest.swift check <master.png> <iconset dir>     every size from 128 up is that drawing, pixel for pixel
// The master (_AppIcon.png, 1024 px) is an 80 x 80 grid scaled nearest-neighbour (_pixelate.swift). Its grid
// is read back from the centre of each block; drawing it at 1024 gives the master again (checked first).
// Sizes from 128 up are upscales of the grid, so they keep the hard pixels; 16, 32 and 64 stay smoothed
// (make_icns.sh, NT-PRF-005). The PNG is written with the ImageIO filter that gives the smallest file.
import AppKit
import ImageIO
import UniformTypeIdentifiers

let grid = 80
let shipped = ["128x128": 128, "128x128@2x": 256, "256x256": 256, "256x256@2x": 512,
               "512x512": 512, "512x512@2x": 1024]

func must<T>(_ value: T?, _ what: String) -> T {
    guard let value else { fatalError(what) }
    return value
}

/// The pixels of `image` drawn at `side` x `side` without smoothing, premultiplied RGBA in sRGB.
func pixels(_ image: CGImage, _ side: Int) -> [UInt8] {
    var data = [UInt8](repeating: 0, count: side * side * 4)
    let space = must(CGColorSpace(name: CGColorSpace.sRGB), "no sRGB color space")
    let context = must(CGContext(data: &data, width: side, height: side, bitsPerComponent: 8,
                                 bytesPerRow: side * 4, space: space,
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue), "no context")
    context.interpolationQuality = .none
    context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
    return data
}

func image(_ data: [UInt8], _ side: Int) -> CGImage {
    var copy = data
    let space = must(CGColorSpace(name: CGColorSpace.sRGB), "no sRGB color space")
    let context = must(CGContext(data: &copy, width: side, height: side, bitsPerComponent: 8,
                                 bytesPerRow: side * 4, space: space,
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue), "no context")
    return must(context.makeImage(), "no image")
}

func load(_ path: String) -> CGImage {
    let source = must(CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil), "cannot read \(path)")
    return must(CGImageSourceCreateImageAtIndex(source, 0, nil), "not an image: \(path)")
}

/// The 80 x 80 grid behind the master: the centre pixel of each block.
func gridOf(_ masterPath: String) -> CGImage {
    let master = pixels(load(masterPath), 1024)
    var cells = [UInt8](repeating: 0, count: grid * grid * 4)
    let block = 1024.0 / Double(grid)
    for y in 0..<grid {
        for x in 0..<grid {
            let source = (Int((Double(y) + 0.5) * block) * 1024 + Int((Double(x) + 0.5) * block)) * 4
            for channel in 0..<4 { cells[(y * grid + x) * 4 + channel] = master[source + channel] }
        }
    }
    let cellImage = image(cells, grid)
    guard pixels(cellImage, 1024) == master else { fatalError("the master is not an 80 px grid scaled up") }
    return cellImage
}

/// PNG bytes with each ImageIO filter tried (none, sub, up, average, Paeth, adaptive); the smallest wins.
func smallestPNG(_ picture: CGImage) -> Data {
    let filters = [0x08, 0x10, 0x20, 0x40, 0x80, 0xF8]
    let encoded = filters.map { filter -> Data in
        let out = NSMutableData()
        let destination = must(CGImageDestinationCreateWithData(out, UTType.png.identifier as CFString, 1, nil),
                               "no PNG writer")
        let options = [kCGImagePropertyPNGDictionary: [kCGImagePropertyPNGCompressionFilter: filter]]
        CGImageDestinationAddImage(destination, picture, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { fatalError("PNG writing failed") }
        return out as Data
    }
    return must(encoded.min { $0.count < $1.count }, "no PNG")
}

func draw(_ masterPath: String, _ outPath: String, _ side: Int) throws {
    let picture = image(pixels(gridOf(masterPath), side), side)
    try smallestPNG(picture).write(to: URL(fileURLWithPath: outPath))
}

/// Every shipped size from 128 up equals the grid drawn at that size; exits 1 on the first difference.
func check(_ masterPath: String, _ iconset: String) {
    let cells = gridOf(masterPath)
    for (name, side) in shipped.sorted(by: { $0.key < $1.key }) {
        let file = load("\(iconset)/icon_\(name).png")
        guard file.width == side, pixels(file, side) == pixels(cells, side) else {
            print("check: icon_\(name).png is not the 80 px grid drawn at \(side) px")
            exit(1)
        }
    }
    print("check: master = 80 px grid scaled; \(shipped.count) sizes from 128 px up equal it, pixel for pixel")
}

let args = CommandLine.arguments
switch (args.count, args.count > 1 ? args[1] : "") {
case (5, "draw"): try draw(args[2], args[3], must(Int(args[4]), "side must be a number"))
case (4, "check"): check(args[2], args[3])
default: fatalError("usage: nearest draw <master.png> <out.png> <side> | nearest check <master.png> <iconset>")
}
