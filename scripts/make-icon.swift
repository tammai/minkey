// Generates minkey's icon assets: Resources/icon.tiff (input-menu tile), Resources/icon-monochrome.tiff
// (template glyph for a status item) and Resources/AppIcon.icns. Run: swift scripts/make-icon.swift
import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - glyph metrics (unit space, y down)

private enum Mark {
    static let strokeWidth = 0.145
    static let stemX = 0.27
    static let capY = 0.30
    static let baselineY = 0.85
    static let vertexY = 0.79
    static let earCenter = (x: 0.20, y: 0.27)
    static let earRadius = 0.135
    static let eyes = [(x: 0.45, y: 0.40, r: 0.040), (x: 0.55, y: 0.40, r: 0.040)]
    static let nose = (x: 0.5, y: 0.53, r: 0.030)
}

/// Unit space (0…1, y down) to device space.
private func point(_ r: CGRect, _ x: Double, _ y: Double) -> CGPoint {
    CGPoint(x: r.minX + r.width * x, y: r.minY + r.height * (1 - y))
}

private func circle(_ r: CGRect, _ x: Double, _ y: Double, _ radius: Double) -> CGPath {
    let c = point(r, x, y)
    let rad = radius * r.width
    return CGPath(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2),
                  transform: nil)
}

/// Apple-style squircle: a superellipse sampled densely enough to read as smooth when rasterised.
private func squircle(_ r: CGRect, exponent: Double = 4.8, steps: Int = 360) -> CGPath {
    let path = CGMutablePath()
    let cx = r.midX, cy = r.midY, ax = r.width / 2, ay = r.height / 2
    for i in 0...steps {
        let t = Double(i) / Double(steps) * 2 * Double.pi
        let ct = cos(t), st = sin(t)
        let x = cx + ax * pow(abs(ct), 2 / exponent) * (ct < 0 ? -1 : 1)
        let y = cy + ay * pow(abs(st), 2 / exponent) * (st < 0 ? -1 : 1)
        if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    path.closeSubpath()
    return path
}

/// The M: outer stems from a flat baseline to the cap line, shoulders eared at the top terminals,
/// and the middle V descending to a vertex just above the baseline.
private func letterPath(_ g: CGRect) -> CGPath {
    let path = CGMutablePath()
    let points = [(Mark.stemX, Mark.baselineY), (Mark.stemX, Mark.capY), (0.5, Mark.vertexY),
                  (1 - Mark.stemX, Mark.capY), (1 - Mark.stemX, Mark.baselineY)]
    path.move(to: point(g, points[0].0, points[0].1))
    for p in points.dropFirst() { path.addLine(to: point(g, p.0, p.1)) }
    return path
}

private func earPath(_ g: CGRect) -> CGPath {
    let path = CGMutablePath()
    path.addPath(circle(g, Mark.earCenter.x, Mark.earCenter.y, Mark.earRadius))
    path.addPath(circle(g, 1 - Mark.earCenter.x, Mark.earCenter.y, Mark.earRadius))
    return path
}

private func facePath(_ g: CGRect) -> CGPath {
    let path = CGMutablePath()
    for eye in Mark.eyes { path.addPath(circle(g, eye.x, eye.y, eye.r)) }
    path.addPath(circle(g, Mark.nose.x, Mark.nose.y, Mark.nose.r))
    return path
}

// MARK: - drawing

private func drawGlyph(_ c: CGContext, in g: CGRect) {
    let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    c.addPath(earPath(g))
    c.setFillColor(black)
    c.fillPath()

    c.saveGState()
    // Clip to the baseline so the round stroke caps do not bulge below it.
    let baseline = point(g, 0, Mark.baselineY).y
    c.clip(to: CGRect(x: g.minX, y: baseline, width: g.width, height: g.maxY - baseline))
    c.setLineWidth(Mark.strokeWidth * g.width)
    c.setLineCap(.round)
    c.setLineJoin(.round)
    c.setStrokeColor(black)
    c.addPath(letterPath(g))
    c.strokePath()
    c.restoreGState()

    c.addPath(facePath(g))
    c.setFillColor(black)
    c.fillPath()
}

private func context(_ size: Int) -> CGContext {
    CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
              space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

/// "VI" cut out of a rounded box, like macOS's own input-source icons; a template image the menu bar tints.
private func renderTile(size: Int) -> CGImage {
    let c = context(size)
    let s = Double(size)
    let box = CGRect(x: s * 0.03, y: s * 0.12, width: s * 0.94, height: s * 0.76)
    c.addPath(CGPath(roundedRect: box, cornerWidth: s * 0.16, cornerHeight: s * 0.16, transform: nil))
    c.setFillColor(CGColor(gray: 0, alpha: 1))
    c.fillPath()
    let font = CTFontCreateWithName("SFCompact-Bold" as CFString, s * 0.56, nil)
    let text = NSAttributedString(string: "VI", attributes: [.font: font, .kern: s * 0.02])
    let line = CTLineCreateWithAttributedString(text)
    let bounds = CTLineGetImageBounds(line, c)
    c.textPosition = CGPoint(x: box.midX - bounds.width / 2 - bounds.minX, y: box.midY - bounds.height / 2 - bounds.minY)
    c.setBlendMode(.clear)
    CTLineDraw(line, c)
    return c.makeImage()!
}

/// Black glyph on transparency, for a template image that follows the menu bar's appearance.
private func renderMonochrome(size: Int) -> CGImage {
    let c = context(size)
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    drawGlyph(c, in: rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.04))
    return c.makeImage()!
}

private func renderAppIcon(size: Int) -> CGImage {
    let c = context(size)
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let tile = rect.insetBy(dx: rect.width * 0.09, dy: rect.height * 0.09)
    c.addPath(squircle(tile))
    c.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    c.fillPath()
    drawGlyph(c, in: tile.insetBy(dx: tile.width * 0.145, dy: tile.height * 0.145))
    return c.makeImage()!
}

// MARK: - output

private func writePNG(_ image: CGImage, to url: URL, dpi: Double = 72) {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString,
                                                     1, nil) else { return }
    CGImageDestinationAddImage(dest, image, [kCGImagePropertyDPIWidth: dpi,
                                             kCGImagePropertyDPIHeight: dpi] as CFDictionary)
    CGImageDestinationFinalize(dest)
}

private func writeTIFF(_ images: [CGImage], to url: URL, dpi: Double) {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.tiff.identifier as CFString,
                                                     images.count, nil) else { return }
    for image in images {
        CGImageDestinationAddImage(dest, image, [kCGImagePropertyDPIWidth: dpi,
                                                 kCGImagePropertyDPIHeight: dpi,
                                                 kCGImagePropertyTIFFCompression: 5] as CFDictionary)
    }
    CGImageDestinationFinalize(dest)
}

private func writeICNS(to url: URL, from render: (Int) -> CGImage) {
    let fm = FileManager.default
    let iconset = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("minkey-\(UUID().uuidString).iconset")
    try? fm.createDirectory(at: iconset, withIntermediateDirectories: true)
    let variants: [(name: String, size: Int)] = [
        ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
        ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256),
        ("icon_256x256@2x", 512), ("icon_512x512", 512), ("icon_512x512@2x", 1024),
    ]
    for v in variants {
        writePNG(render(v.size), to: iconset.appendingPathComponent("\(v.name).png"))
    }
    let iconutil = Process()
    iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    iconutil.arguments = ["-c", "icns", iconset.path, "-o", url.path]
    try? iconutil.run()
    iconutil.waitUntilExit()
    try? fm.removeItem(at: iconset)
}

// MARK: - entry

private let resources = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Resources")
let tiffSizes = [16, 32, 64, 128]
writeTIFF(tiffSizes.map(renderTile), to: resources.appendingPathComponent("icon.tiff"), dpi: 72)
writeTIFF(tiffSizes.map(renderMonochrome), to: resources.appendingPathComponent("icon-monochrome.tiff"),
          dpi: 72)
writeICNS(to: resources.appendingPathComponent("AppIcon.icns"), from: renderAppIcon)
print("wrote Resources/icon.tiff, Resources/icon-monochrome.tiff, Resources/AppIcon.icns")
