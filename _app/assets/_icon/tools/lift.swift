// lift.swift <in.png> <out.png>
// Cut the main subject out of a photo (Vision foreground mask), crop to it, and center it on a
// transparent 1024 x 1024 canvas.
import AppKit
import CoreImage
import Vision

/// Stop with a clear message when a step that cannot fail on a good input fails.
func must<T>(_ value: T?, _ what: String) -> T {
    guard let value else { fatalError(what) }
    return value
}

let args = CommandLine.arguments
guard args.count == 3 else { fatalError("usage: lift <in.png> <out.png>") }
let input = must(CIImage(contentsOf: URL(fileURLWithPath: args[1])), "cannot read \(args[1])")
let request = VNGenerateForegroundInstanceMaskRequest()
let handler = VNImageRequestHandler(ciImage: input)
try handler.perform([request])
let observation = must(request.results?.first, "no subject found")
let buffer = try observation.generateMaskedImage(
    ofInstances: observation.allInstances, from: handler, croppedToInstancesExtent: true)
let subject = CIImage(cvPixelBuffer: buffer)

let side: CGFloat = 1024, pad: CGFloat = 24
let scale = (side - 2 * pad) / max(subject.extent.width, subject.extent.height)
let scaled = subject.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
let dx = (side - scaled.extent.width) / 2 - scaled.extent.minX
let dy = (side - scaled.extent.height) / 2 - scaled.extent.minY
let placed = scaled.transformed(by: CGAffineTransform(translationX: dx, y: dy))
let clear = CIImage(color: .clear).cropped(to: CGRect(x: 0, y: 0, width: side, height: side))
let canvas = placed.composited(over: clear)

let colorSpace = must(CGColorSpace(name: CGColorSpace.sRGB), "no sRGB color space")
try CIContext().writePNGRepresentation(
    of: canvas, to: URL(fileURLWithPath: args[2]), format: .RGBA8, colorSpace: colorSpace)
print("subject \(Int(subject.extent.width))x\(Int(subject.extent.height))")
