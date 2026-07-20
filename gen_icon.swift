#!/usr/bin/env swift

import Foundation
import AppKit
import CoreGraphics

// Icon sizes required for .icns
let sizes: [(width: Int, height: Int, name: String)] = [
    (16, 16, "icon_16x16.png"),
    (32, 32, "icon_16x16@2x.png"),
    (32, 32, "icon_32x32.png"),
    (64, 64, "icon_32x32@2x.png"),
    (128, 128, "icon_128x128.png"),
    (256, 256, "icon_128x128@2x.png"),
    (256, 256, "icon_256x256.png"),
    (512, 512, "icon_256x256@2x.png"),
    (512, 512, "icon_512x512.png"),
    (1024, 1024, "icon_512x512@2x.png"),
]

func drawShieldIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let rect = CGRect(x: 0, y: 0, width: s, height: s)
    let image = NSImage(size: rect.size)

    image.lockFocus()

    // Background gradient (blue-purple)
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let colors = [
        CGColor(red: 0.2, green: 0.4, blue: 0.95, alpha: 1.0),  // top
        CGColor(red: 0.35, green: 0.25, blue: 0.85, alpha: 1.0), // bottom
    ]
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 1])!

    // Rounded rect background
    let bgPath = NSBezierPath(
        roundedRect: rect.insetBy(dx: s * 0.08, dy: s * 0.08),
        xRadius: s * 0.22,
        yRadius: s * 0.22
    )

    let ctx = NSGraphicsContext.current!.cgContext
    ctx.saveGState()
    bgPath.addClip()
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: s / 2, y: 0),
        end: CGPoint(x: s / 2, y: s),
        options: []
    )
    ctx.restoreGState()

    // Draw shield shape outline
    let shieldInset = s * 0.2
    let shieldRect = rect.insetBy(dx: shieldInset, dy: shieldInset * 1.1)

    let shieldPath = NSBezierPath()
    let sw = shieldRect.width
    let sh = shieldRect.height
    let sx = shieldRect.minX
    let sy = shieldRect.minY

    // Shield shape: top curve, sloping sides, pointed bottom
    shieldPath.move(to: NSPoint(x: sx + sw * 0.25, y: sy + sh))
    shieldPath.line(to: NSPoint(x: sx, y: sy + sh * 0.4))
    shieldPath.curve(
        to: NSPoint(x: sx + sw * 0.15, y: sy),
        controlPoint1: NSPoint(x: sx, y: sy + sh * 0.15),
        controlPoint2: NSPoint(x: sx + sw * 0.05, y: sy)
    )
    shieldPath.line(to: NSPoint(x: sx + sw * 0.85, y: sy))
    shieldPath.curve(
        to: NSPoint(x: sx + sw, y: sy + sh * 0.4),
        controlPoint1: NSPoint(x: sx + sw * 0.95, y: sy),
        controlPoint2: NSPoint(x: sx + sw, y: sy + sh * 0.15)
    )
    shieldPath.line(to: NSPoint(x: sx + sw * 0.75, y: sy + sh))
    shieldPath.close()

    // Fill shield with white-ish semi-transparent
    NSColor.white.withAlphaComponent(0.95).setFill()
    shieldPath.fill()

    // Shield border
    NSColor.white.setStroke()
    shieldPath.lineWidth = s * 0.03
    shieldPath.stroke()

    // Checkmark inside shield
    let checkSize = sw * 0.35
    let checkX = sx + sw * 0.5 - checkSize * 0.45
    let checkY = sy + sh * 0.5 - checkSize * 0.3

    let checkPath = NSBezierPath()
    checkPath.move(to: NSPoint(x: checkX, y: checkY + checkSize * 0.5))
    checkPath.line(to: NSPoint(x: checkX + checkSize * 0.35, y: checkY + checkSize * 0.85))
    checkPath.line(to: NSPoint(x: checkX + checkSize, y: checkY))
    checkPath.lineWidth = s * 0.06
    checkPath.lineCapStyle = .round
    checkPath.lineJoinStyle = .round

    // Checkmark gradient color
    let checkColor = NSColor(red: 0.15, green: 0.45, blue: 0.95, alpha: 1.0)
    checkColor.setStroke()
    checkPath.stroke()

    image.unlockFocus()
    return image
}

// Create iconset directory
let iconsetDir = "AppIcon.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetDir)
try fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

for (width, height, name) in sizes {
    let image = drawShieldIcon(size: width)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(name)")
        continue
    }
    let path = "\(iconsetDir)/\(name)"
    try png.write(to: URL(fileURLWithPath: path))
    print("  Created \(name) (\(width)x\(height))")
}

// Use iconutil to create .icns
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconsetDir]
iconutil.currentDirectoryURL = URL(fileURLWithPath: fm.currentDirectoryPath)
try iconutil.run()
iconutil.waitUntilExit()

if iconutil.terminationStatus == 0 {
    print("\n✅ AppIcon.icns created successfully")
    // Clean up iconset
    try? fm.removeItem(atPath: iconsetDir)
} else {
    print("\n❌ iconutil failed with status \(iconutil.terminationStatus)")
}
