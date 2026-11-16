// shrink.swift <in.png> <out.png> <side>
// Scale a pixel-art PNG to side x side with nearest-neighbour, so the pixels stay hard.
// The app sets its Dock icon at runtime; a 1024 px icon cost about 33 MB in the app process,
// a 256 px one about nothing (NT-PRF-001). The Dock gets the small one.
import AppKit

func must<T>(_ value: T?, _ what: String) -> T {
    guard let value else { fatalError(what) }
    return value
}

let args = CommandLine.arguments
guard args.count == 4, let side = Int(args[3]), side > 0 else { fatalError("usage: shrink <in.png> <out.png> <side>") }
let source = must(NSBitmapImageRep(data: try Data(contentsOf: URL(fileURLWithPath: args[1]))), "not an image")
let space = must(CGColorSpace(name: CGColorSpace.sRGB), "no sRGB color space")
let canvas = must(CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue), "no context")
canvas.interpolationQuality = .none
canvas.draw(must(source.cgImage, "no image"), in: CGRect(x: 0, y: 0, width: side, height: side))
let output = NSBitmapImageRep(cgImage: must(canvas.makeImage(), "no output image"))
try must(output.representation(using: .png, properties: [:]), "cannot encode PNG")
    .write(to: URL(fileURLWithPath: args[2]))
