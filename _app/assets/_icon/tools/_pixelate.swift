// pixelate.swift <in.png> <out.png> [grid=64]: pixel-art version of a transparent icon.
// Crop to the subject, fit it into a grid x grid canvas (area-averaged), make alpha hard
// (fully opaque or fully clear), then scale to 1024 with nearest-neighbour.
import AppKit

let a = CommandLine.arguments
let grid = a.count > 3 ? Int(a[3])! : 64
let src = NSBitmapImageRep(data: try Data(contentsOf: URL(fileURLWithPath: a[1])))!
var minX = src.pixelsWide, minY = src.pixelsHigh, maxX = 0, maxY = 0
for y in 0..<src.pixelsHigh { for x in 0..<src.pixelsWide where src.colorAt(x: x, y: y)!.alphaComponent > 0.05 {
    minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y) } }
let crop = src.cgImage!.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))!

func context(_ n: Int) -> CGContext {
    CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: n * 4,
              space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}
// 1) subject -> grid (fill height, centered)
let small = context(grid)
small.interpolationQuality = .high
let s = CGFloat(grid) / CGFloat(max(crop.width, crop.height))
let w = CGFloat(crop.width) * s, h = CGFloat(crop.height) * s
small.draw(crop, in: CGRect(x: (CGFloat(grid) - w) / 2, y: (CGFloat(grid) - h) / 2, width: w, height: h))
// 2) hard alpha
let px = small.data!.bindMemory(to: UInt8.self, capacity: grid * grid * 4)
for i in 0..<(grid * grid) {
    let al = Double(px[i * 4 + 3])
    if al < 215 { for c in 0..<4 { px[i * 4 + c] = 0 }; continue }  // drop mostly-background edge pixels (blue fringe)
    for c in 0..<3 { px[i * 4 + c] = UInt8(min(255, Double(px[i * 4 + c]) * 255 / al)) }
    px[i * 4 + 3] = 255
}
// 3) nearest-neighbour up to 1024
let big = context(1024)
big.interpolationQuality = .none
big.draw(small.makeImage()!, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
let rep = NSBitmapImageRep(cgImage: big.makeImage()!)
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[2]))
