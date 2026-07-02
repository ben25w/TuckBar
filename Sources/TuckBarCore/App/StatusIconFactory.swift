import AppKit

enum StatusIconFactory {
    static func statusItemImage(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        NSColor.labelColor.setStroke()
        NSColor.labelColor.setFill()

        let lineWidth: CGFloat = 1.8
        for index in 0..<3 {
            let y = CGFloat(index) * 5.0 + 4.0
            let path = NSBezierPath()
            path.lineWidth = lineWidth
            path.lineCapStyle = .round
            path.move(to: NSPoint(x: 4.0, y: y))
            path.line(to: NSPoint(x: 14.0, y: y))
            path.stroke()
        }

        let dot = NSBezierPath(ovalIn: NSRect(x: 7.3, y: 7.3, width: 3.4, height: 3.4))
        dot.fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
