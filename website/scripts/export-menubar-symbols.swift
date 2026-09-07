import AppKit

guard CommandLine.arguments.count == 2 else {
    print("Usage: xcrun swift export-menubar-symbols.swift <output-directory>")
    exit(1)
}
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let symbols = [("wifi", "wifi"), ("battery.100percent", "battery"), ("magnifyingglass", "spotlight"), ("switch.2", "control-center")]
for (symbol, filename) in symbols {
    guard let source = NSImage(systemSymbolName: symbol, accessibilityDescription: nil),
          let configured = source.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)) else {
        fatalError("Missing symbol: \(symbol)")
    }
    let canvas = NSSize(width: 26, height: 20)
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 78, pixelsHigh: 60, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    bitmap.size = canvas
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSColor.clear.setFill()
    NSRect(origin: .zero, size: canvas).fill()
    let natural = configured.size
    let scale = min(23 / natural.width, 16 / natural.height)
    let size = NSSize(width: natural.width * scale, height: natural.height * scale)
    configured.draw(in: NSRect(x: (canvas.width-size.width)/2, y: (canvas.height-size.height)/2, width:size.width, height:size.height), from:.zero, operation:.sourceOver, fraction:1)
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(filename + ".png"))
}
