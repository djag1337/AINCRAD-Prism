// Draws AINCRAD Prism's icon in AINCRAD's style (same tile and sky, one glowing SAO button with
// a glass prism splitting light) into an asset-catalog icon set. Usage: swift scripts/make_icon.swift Prism/Assets.xcassets
import AppKit

func draw(_ px: Int) -> Data {
    let s = CGFloat(px) / 1024
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: s, y: s)
    let rgb = { (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) in CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a) }
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: rgb(0, 0, 0, 0.35))
    ctx.addPath(tilePath); ctx.setFillColor(rgb(20, 27, 38, 1)); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState(); ctx.addPath(tilePath); ctx.clip()
    let sky = CGGradient(colorsSpace: nil, colors: [rgb(58, 92, 138, 1), rgb(22, 30, 46, 1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(sky, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
    ctx.restoreGState()
    // The SAO button: white glass circle with an orange ring and glow.
    let c = CGPoint(x: 512, y: 512), r: CGFloat = 270
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 60, color: rgb(242, 165, 22, 0.85))
    ctx.setStrokeColor(rgb(242, 165, 22, 1)); ctx.setLineWidth(22)
    ctx.strokeEllipse(in: CGRect(x: c.x - r - 22, y: c.y - r - 22, width: 2 * (r + 22), height: 2 * (r + 22)))
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)); ctx.clip()
    let glass = CGGradient(colorsSpace: nil, colors: [rgb(255, 255, 255, 1), rgb(222, 224, 230, 1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(glass, start: CGPoint(x: 512, y: c.y + r), end: CGPoint(x: 512, y: c.y - r), options: [])
    ctx.restoreGState()
    // Prism: light comes in from the left, the glass triangle splits it into a spectrum on the right.
    let beam = rgb(255, 255, 255, 0.95)
    ctx.setStrokeColor(rgb(255, 255, 255, 0.9)); ctx.setLineWidth(16); ctx.setLineCap(.round)
    ctx.setShadow(offset: .zero, blur: 18, color: rgb(255, 255, 255, 0.6))
    ctx.move(to: CGPoint(x: 230, y: 506)); ctx.addLine(to: CGPoint(x: 398, y: 506)); ctx.strokePath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    let tri = CGMutablePath()
    tri.move(to: CGPoint(x: 512, y: 600)); tri.addLine(to: CGPoint(x: 360, y: 330)); tri.addLine(to: CGPoint(x: 664, y: 330)); tri.closeSubpath()
    ctx.saveGState(); ctx.addPath(tri); ctx.clip()
    let glassTri = CGGradient(colorsSpace: nil, colors: [rgb(255, 255, 255, 0.95), rgb(190, 214, 240, 0.85)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(glassTri, start: CGPoint(x: 512, y: 600), end: CGPoint(x: 512, y: 330), options: [])
    ctx.restoreGState()
    ctx.setStrokeColor(rgb(90, 94, 102, 1)); ctx.setLineWidth(18); ctx.setLineJoin(.round)
    ctx.addPath(tri); ctx.strokePath()
    // The spectrum fans out from the right face.
    let spectrum: [(CGFloat, CGFloat, CGFloat)] = [(230, 60, 60), (245, 140, 40), (250, 200, 40), (60, 180, 90), (50, 130, 220), (130, 80, 200)]
    for (i, c) in spectrum.enumerated() {
        let y = CGFloat(i) * 13 - 33
        ctx.setStrokeColor(rgb(c.0, c.1, c.2, 1)); ctx.setLineWidth(12)
        ctx.move(to: CGPoint(x: 596, y: 520)); ctx.addLine(to: CGPoint(x: 780, y: 520 + y * 1.4)); ctx.strokePath()
    }
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    return rep.representation(using: .png, properties: [:])!
}

let catalog = URL(fileURLWithPath: CommandLine.arguments[1])
let set = catalog.appendingPathComponent("AppIcon.appiconset")
try? FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)
try! #"{"info":{"author":"xcode","version":1}}"#.write(to: catalog.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
var images: [String] = []
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try! draw(size * scale).write(to: set.appendingPathComponent(name))
        images.append(#"{"idiom":"mac","size":"\#(size)x\#(size)","scale":"\#(scale)x","filename":"\#(name)"}"#)
    }
}
try! #"{"images":[\#(images.joined(separator: ","))],"info":{"author":"xcode","version":1}}"#.write(to: set.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("wrote \(set.path)")
