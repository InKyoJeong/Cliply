import AppKit

// Renders the Cliply app icon: a clipboard on a blue→indigo gradient.
// Usage: swift Scripts/generate_icon.swift <output.iconset dir>

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
    NSColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: 1)
}

func rounded(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawIcon(side: CGFloat) -> NSBitmapImageRep {
    let s = side / 1024.0
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(side), pixelsHigh: Int(side),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: side, height: side)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    func S(_ v: CGFloat) -> CGFloat { v * s }

    // Background squircle with vertical gradient.
    let bg = rounded(NSRect(x: 0, y: 0, width: side, height: side), S(230))
    let gradient = NSGradient(colors: [color(95, 145, 255), color(108, 84, 255)])!
    gradient.draw(in: bg, angle: -90)

    // Clipboard board (white) with a soft shadow.
    let board = rounded(NSRect(x: S(282), y: S(170), width: S(460), height: S(610)), S(56))
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowBlurRadius = S(36)
    shadow.shadowOffset = NSSize(width: 0, height: S(-18))
    shadow.set()
    color(255, 255, 255).setFill()
    board.fill()

    // Reset shadow for foreground details.
    NSShadow().set()

    // Clip head at the top of the board.
    let clipBody = rounded(NSRect(x: S(432), y: S(720), width: S(160), height: S(120)), S(34))
    color(120, 135, 165).setFill()
    clipBody.fill()
    let clipHole = rounded(NSRect(x: S(482), y: S(792), width: S(60), height: S(26)), S(13))
    color(236, 240, 248).setFill()
    clipHole.fill()

    // Content lines: top one accent-colored, the rest light gray.
    let lineX = S(352)
    color(95, 145, 255).setFill()
    rounded(NSRect(x: lineX, y: S(560), width: S(300), height: S(46)), S(23)).fill()
    color(214, 221, 233).setFill()
    rounded(NSRect(x: lineX, y: S(470), width: S(338), height: S(46)), S(23)).fill()
    color(214, 221, 233).setFill()
    rounded(NSRect(x: lineX, y: S(380), width: S(250), height: S(46)), S(23)).fill()
    color(214, 221, 233).setFill()
    rounded(NSRect(x: lineX, y: S(290), width: S(320), height: S(46)), S(23)).fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func write(_ rep: NSBitmapImageRep, to url: URL) {
    guard let data = rep.representation(using: .png, properties: [:]) else { return }
    try? data.write(to: url)
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write("usage: generate_icon.swift <iconset dir>\n".data(using: .utf8)!)
    exit(1)
}
let dir = URL(fileURLWithPath: args[1])
try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

// (filename, pixel size)
let entries: [(String, CGFloat)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for (name, px) in entries {
    write(drawIcon(side: px), to: dir.appendingPathComponent(name))
}
print("Wrote \(entries.count) icon sizes to \(dir.path)")
