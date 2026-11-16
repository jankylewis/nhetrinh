// lift.swift <in.png> <out.png>: cut the main subject out (Vision foreground mask),
// crop to it, center it on a transparent 1024x1024 canvas.
import AppKit
import CoreImage
import Vision

let args = CommandLine.arguments
let input = CIImage(contentsOf: URL(fileURLWithPath: args[1]))!
let req = VNGenerateForegroundInstanceMaskRequest()
let handler = VNImageRequestHandler(ciImage: input)
try handler.perform([req])
guard let obs = req.results?.first else { fatalError("no subject found") }
let buf = try obs.generateMaskedImage(ofInstances: obs.allInstances, from: handler, croppedToInstancesExtent: true)
let subject = CIImage(cvPixelBuffer: buf)

let side: CGFloat = 1024, pad: CGFloat = 24
let scale = (side - 2 * pad) / max(subject.extent.width, subject.extent.height)
let scaled = subject.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
let dx = (side - scaled.extent.width) / 2 - scaled.extent.minX
let dy = (side - scaled.extent.height) / 2 - scaled.extent.minY
let placed = scaled.transformed(by: CGAffineTransform(translationX: dx, y: dy))
let canvas = placed.composited(over: CIImage(color: .clear).cropped(to: CGRect(x: 0, y: 0, width: side, height: side)))

let ctx = CIContext()
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
try ctx.writePNGRepresentation(of: canvas, to: URL(fileURLWithPath: args[2]), format: .RGBA8, colorSpace: cs)
print("subject \(Int(subject.extent.width))x\(Int(subject.extent.height)) instances=\(obs.allInstances.count)")
