import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("Sources/TuckBarCore/Resources", isDirectory: true)
let iconset = resources.appendingPathComponent("AppIcon.iconset", isDirectory: true)
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let corner = size * 0.19
    let background = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.086, dy: size * 0.086), xRadius: corner, yRadius: corner)
    NSColor(calibratedRed: 0.05, green: 0.45, blue: 0.43, alpha: 1).setFill()
    background.fill()

    let overlay = NSGradient(colors: [
        NSColor(calibratedRed: 0.08, green: 0.58, blue: 0.84, alpha: 0.9),
        NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.14, alpha: 0.95)
    ])
    overlay?.draw(in: background, angle: -55)

    let rows = [0.30, 0.49, 0.68]
    for (index, row) in rows.enumerated() {
        let rowRect = NSRect(x: size * 0.232, y: size * row, width: size * 0.536, height: size * 0.102)
        let path = NSBezierPath(roundedRect: rowRect, xRadius: rowRect.height / 2, yRadius: rowRect.height / 2)
        NSColor.white.withAlphaComponent(0.96 - CGFloat(index) * 0.08).setFill()
        path.fill()
    }

    let outer = NSBezierPath(ovalIn: NSRect(x: size * 0.43, y: size * 0.43, width: size * 0.14, height: size * 0.14))
    NSColor(calibratedRed: 0.08, green: 0.72, blue: 0.65, alpha: 1).setFill()
    outer.fill()

    let inner = NSBezierPath(ovalIn: NSRect(x: size * 0.466, y: size * 0.466, width: size * 0.068, height: size * 0.068))
    NSColor.white.setFill()
    inner.fill()

    return image
}

for (name, size) in sizes {
    let image = drawIcon(size: size)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not render \(name)")
    }
    try png.write(to: iconset.appendingPathComponent(name))
}
