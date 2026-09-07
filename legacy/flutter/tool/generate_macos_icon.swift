import AppKit

private enum Icon {
  static let canvasSize = NSSize(width: 1024, height: 1024)
  static let sourcePath = "tool/floatick_app_icon.svg"
  static let appIconsetPath = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
  static let assetNames = [
    "app_icon_16.png",
    "app_icon_32.png",
    "app_icon_64.png",
    "app_icon_128.png",
    "app_icon_256.png",
    "app_icon_512.png",
    "app_icon_1024.png",
  ]
  static let solidAlphaThreshold = 0.5
}

private enum IconGenerationError: Error, CustomStringConvertible {
  case cannotLoadImage(String)
  case cannotCreateBitmap(String)
  case cannotActivateGraphicsContext
  case cannotFindSolidBounds(String)
  case cannotEncodePNG(String)

  var description: String {
    switch self {
    case .cannotLoadImage(let path):
      return "Could not load \(path)."
    case .cannotCreateBitmap(let name):
      return "Could not create a bitmap for \(name)."
    case .cannotActivateGraphicsContext:
      return "Could not activate the icon graphics context."
    case .cannotFindSolidBounds(let name):
      return "Could not find the solid icon bounds in \(name)."
    case .cannotEncodePNG(let name):
      return "Could not encode \(name) as PNG."
    }
  }
}

private func makeBitmap(width: Int, height: Int, name: String) throws -> NSBitmapImageRep {
  guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
  ) else {
    throw IconGenerationError.cannotCreateBitmap(name)
  }
  bitmap.size = NSSize(width: width, height: height)
  return bitmap
}

private func withGraphicsContext(
  for bitmap: NSBitmapImageRep,
  draw: () throws -> Void
) throws {
  guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
    throw IconGenerationError.cannotCreateBitmap("graphics context")
  }

  NSGraphicsContext.saveGraphicsState()
  defer { NSGraphicsContext.restoreGraphicsState() }
  NSGraphicsContext.current = graphicsContext
  guard let context = NSGraphicsContext.current?.cgContext else {
    throw IconGenerationError.cannotActivateGraphicsContext
  }

  context.setShouldAntialias(true)
  context.setAllowsAntialiasing(true)
  try draw()
}

private func writePNG(_ bitmap: NSBitmapImageRep, to outputURL: URL) throws {
  guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    throw IconGenerationError.cannotEncodePNG(outputURL.lastPathComponent)
  }
  try pngData.write(to: outputURL, options: .atomic)
}

private func renderSource(_ sourceImage: NSImage, to outputURL: URL) throws {
  let width = Int(Icon.canvasSize.width)
  let height = Int(Icon.canvasSize.height)
  let bitmap = try makeBitmap(width: width, height: height, name: outputURL.lastPathComponent)

  try withGraphicsContext(for: bitmap) {
    sourceImage.draw(
      in: NSRect(origin: .zero, size: Icon.canvasSize),
      from: .zero,
      operation: .copy,
      fraction: 1
    )
  }

  try writePNG(bitmap, to: outputURL)
}

private func solidBounds(
  in bitmap: NSBitmapImageRep,
  name: String
) throws -> NSRect {
  var minX = bitmap.pixelsWide
  var minY = bitmap.pixelsHigh
  var maxX = -1
  var maxY = -1

  for y in 0..<bitmap.pixelsHigh {
    for x in 0..<bitmap.pixelsWide {
      guard let color = bitmap.colorAt(x: x, y: y) else { continue }
      if color.alphaComponent >= Icon.solidAlphaThreshold {
        minX = min(minX, x)
        minY = min(minY, y)
        maxX = max(maxX, x)
        maxY = max(maxY, y)
      }
    }
  }

  guard maxX >= minX, maxY >= minY else {
    throw IconGenerationError.cannotFindSolidBounds(name)
  }

  return NSRect(
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1
  )
}

private func regenerateAppIconset(
  sourceImage: NSImage,
  at appIconsetURL: URL
) throws {
  for assetName in Icon.assetNames {
    let assetURL = appIconsetURL.appendingPathComponent(assetName)
    let assetData = try Data(contentsOf: assetURL)
    guard
      let templateBitmap = NSBitmapImageRep(data: assetData),
      let templateImage = NSImage(contentsOf: assetURL)
    else {
      throw IconGenerationError.cannotLoadImage(assetURL.path)
    }

    let width = templateBitmap.pixelsWide
    let height = templateBitmap.pixelsHigh
    let canvasRect = NSRect(x: 0, y: 0, width: width, height: height)
    let artRect = try solidBounds(in: templateBitmap, name: assetName)
    let outputBitmap = try makeBitmap(width: width, height: height, name: assetName)

    try withGraphicsContext(for: outputBitmap) {
      // The existing asset contributes only its alpha silhouette. Filling the
      // canvas with black first creates a neutral shadow and prevents RGB
      // pixels from a reference mask from becoming a light fringe.
      NSColor.black.setFill()
      canvasRect.fill()

      sourceImage.draw(
        in: artRect,
        from: .zero,
        operation: .copy,
        fraction: 1
      )

      templateImage.draw(
        in: canvasRect,
        from: .zero,
        operation: .destinationIn,
        fraction: 1
      )
    }

    try writePNG(outputBitmap, to: assetURL)
  }
}

private func printUsage() {
  fputs(
    """
    Usage:
      swift tool/generate_macos_icon.swift <output.png>
      swift tool/generate_macos_icon.swift --appiconset [path]

    """,
    stderr
  )
}

let workingDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceURL = workingDirectoryURL.appendingPathComponent(Icon.sourcePath)

do {
  guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    throw IconGenerationError.cannotLoadImage(Icon.sourcePath)
  }

  let arguments = Array(CommandLine.arguments.dropFirst())
  if arguments.count == 1, arguments[0] != "--appiconset" {
    try renderSource(
      sourceImage,
      to: URL(fileURLWithPath: arguments[0], relativeTo: workingDirectoryURL)
    )
  } else if arguments == ["--appiconset"] {
    try regenerateAppIconset(
      sourceImage: sourceImage,
      at: workingDirectoryURL.appendingPathComponent(Icon.appIconsetPath)
    )
  } else if arguments.count == 2, arguments[0] == "--appiconset" {
    try regenerateAppIconset(
      sourceImage: sourceImage,
      at: URL(fileURLWithPath: arguments[1], relativeTo: workingDirectoryURL)
    )
  } else {
    printUsage()
    exit(64)
  }
} catch {
  fputs("\(error)\n", stderr)
  exit(1)
}
