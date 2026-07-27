import Cocoa
import FlutterMacOS
import multiview_desktop

final class MainFlutterWindow: NSWindow {
  private enum Layout {
    static let collapsedSize = NSSize(width: 72, height: 72)
    static let legacyCollapsedSize = NSSize(width: 116, height: 116)
    static let expandedSize = NSSize(width: 440, height: 700)
    static let screenPadding: CGFloat = 8
  }

  private enum ExpansionAnchor: String {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
  }

  private enum DefaultsKey {
    static let collapsedOriginX = "floatick.collapsedOrigin.x"
    static let collapsedOriginY = "floatick.collapsedOrigin.y"
    static let collapsedWidth = "floatick.collapsedSize.width"
    static let collapsedHeight = "floatick.collapsedSize.height"
  }

  private var isExpanded = false
  private var collapsedOrigin = NSPoint.zero
  private var pendingExpansionAnchor: ExpansionAnchor?
  private var collapsedDragOverlay: CollapsedDragOverlayView?
  private weak var flutterContentView: NSView?
  private var windowChannel: FlutterMethodChannel?
  private var updateService: UpdateService?
  private var appliedAlwaysOnTop: Bool?

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  override func sendEvent(_ event: NSEvent) {
    if
      isExpanded,
      event.type == .leftMouseDown,
      !isKeyWindow
    {
      NSApp.activate(ignoringOtherApps: true)
      makeKey()
      _ = focusFlutterContent()
    }
    super.sendEvent(event)
  }

  override func awakeFromNib() {
    let engine = FlutterEngine(
      name: "floatick_main_engine",
      project: nil,
      allowHeadlessExecution: true
    )
    MultiviewDesktopPlugin.prepareEngine(engine, window: self)
    let flutterViewController = FlutterViewController(
      engine: engine,
      nibName: nil,
      bundle: nil
    )
    flutterViewController.backgroundColor = .clear

    configureWindow()
    contentViewController = flutterViewController
    flutterContentView = flutterViewController.view
    RegisterGeneratedPlugins(registry: flutterViewController)
    configureWindowChannel(for: flutterViewController)
    configureUpdateService(for: flutterViewController)
    configureDragOverlay(for: flutterViewController.view)

    let origin = restoredCollapsedOrigin() ?? defaultCollapsedOrigin()
    collapsedOrigin = clampedOrigin(
      origin,
      for: Layout.collapsedSize,
      on: screen(containing: origin)
    )
    setFrame(
      NSRect(origin: collapsedOrigin, size: Layout.collapsedSize),
      display: true
    )
    orderFrontRegardless()

    super.awakeFromNib()
  }

  private func configureWindow() {
    styleMask = [.borderless]
    backgroundColor = .clear
    isOpaque = false
    hasShadow = false
    level = .statusBar
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    animationBehavior = .none
    isMovable = false
    isMovableByWindowBackground = false
    acceptsMouseMovedEvents = true
    hidesOnDeactivate = false
    isRestorable = false
    title = "Floatick"
  }

  private func configureWindowChannel(
    for flutterViewController: FlutterViewController
  ) {
    let channel = FlutterMethodChannel(
      name: "floatick/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "window_unavailable",
            message: "The Floatick window is no longer available.",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case "preferredExpansionAnchor":
        let anchor = self.preferredExpansionAnchor()
        self.pendingExpansionAnchor = anchor
        result(anchor.rawValue)
      case "setExpanded":
        guard let expanded = call.arguments as? Bool else {
          result(
            FlutterError(
              code: "invalid_argument",
              message: "setExpanded expects a Boolean argument.",
              details: nil
            )
          )
          return
        }
        self.setExpanded(expanded, completion: { result(nil) })
      case "setPreferredLanguage":
        let languageCode: String?
        if call.arguments == nil || call.arguments is NSNull {
          languageCode = nil
        } else if
          let argument = call.arguments as? String,
          argument == "zh" || argument == "en"
        {
          languageCode = argument
        } else {
          result(
            FlutterError(
              code: "invalid_argument",
              message: "setPreferredLanguage expects null, \"zh\", or \"en\".",
              details: nil
            )
          )
          return
        }
        NativeCopy.preferredLanguageCode = languageCode
        self.collapsedDragOverlay?.refreshLocalizedContent()
        result(nil)
      case "setAlwaysOnTop":
        guard let alwaysOnTop = call.arguments as? Bool else {
          result(
            FlutterError(
              code: "invalid_argument",
              message: "setAlwaysOnTop expects a Boolean argument.",
              details: nil
            )
          )
          return
        }
        self.setAlwaysOnTop(alwaysOnTop)
        result(nil)
      case "configureBorderlessSecondaryWindow":
        guard
          let viewIdentifier = (call.arguments as? NSNumber)?.int64Value
        else {
          result(
            FlutterError(
              code: "invalid_argument",
              message: "configureBorderlessSecondaryWindow expects a view ID.",
              details: nil
            )
          )
          return
        }
        guard self.configureBorderlessSecondaryWindow(
          viewIdentifier: viewIdentifier
        ) else {
          result(
            FlutterError(
              code: "window_unavailable",
              message: "The secondary Flutter window could not be found.",
              details: viewIdentifier
            )
          )
          return
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    windowChannel = channel
  }

  private func configureBorderlessSecondaryWindow(
    viewIdentifier: Int64
  ) -> Bool {
    guard
      let targetWindow = NSApp.windows.first(where: { window in
        guard
          window !== self,
          let controller = window.contentViewController
            as? FlutterViewController
        else {
          return false
        }
        return controller.viewIdentifier == viewIdentifier
      }),
      let flutterViewController = targetWindow.contentViewController
        as? FlutterViewController
    else {
      return false
    }

    flutterViewController.backgroundColor = .clear
    let existingFrame = targetWindow.frame
    targetWindow.styleMask = [.borderless, .resizable]
    targetWindow.setFrame(existingFrame, display: true)
    targetWindow.backgroundColor = .clear
    targetWindow.isOpaque = false
    targetWindow.hasShadow = false
    targetWindow.preservesContentDuringLiveResize = true
    targetWindow.contentView?.wantsLayer = true
    targetWindow.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    targetWindow.contentView?.layerContentsRedrawPolicy = .onSetNeedsDisplay
    targetWindow.contentView?.layerContentsPlacement = .scaleAxesIndependently
    if isExpanded {
      DispatchQueue.main.async { [weak self] in
        guard let self, self.isExpanded else {
          return
        }
        self.activateAndFocusFlutterContent()
      }
    }
    return true
  }

  private func setAlwaysOnTop(_ alwaysOnTop: Bool) {
    let targetLevel: NSWindow.Level = alwaysOnTop ? .statusBar : .normal
    guard
      appliedAlwaysOnTop != alwaysOnTop ||
      level != targetLevel
    else {
      return
    }
    appliedAlwaysOnTop = alwaysOnTop
    level = targetLevel
    if alwaysOnTop {
      orderFrontRegardless()
    }
  }

  private func configureUpdateService(
    for flutterViewController: FlutterViewController
  ) {
    let updateService = UpdateService()
    updateService.configure(
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    self.updateService = updateService
  }

  private func configureDragOverlay(for view: NSView) {
    let overlay = CollapsedDragOverlayView(frame: view.bounds)
    overlay.autoresizingMask = [.width, .height]
    overlay.onClick = { [weak self] in
      guard let self else {
        return
      }
      let anchor = self.preferredExpansionAnchor()
      self.pendingExpansionAnchor = anchor
      self.windowChannel?.invokeMethod(
        "requestExpand",
        arguments: anchor.rawValue
      )
    }
    overlay.onDrag = {
      [weak self] startMouseLocation, startWindowOrigin, mouseLocation in
      guard let self, !self.isExpanded else {
        return
      }
      let proposedOrigin = NSPoint(
        x: startWindowOrigin.x + mouseLocation.x - startMouseLocation.x,
        y: startWindowOrigin.y + mouseLocation.y - startMouseLocation.y
      )
      let targetScreen = self.screen(containing: mouseLocation)
      let origin = self.clampedOrigin(
        proposedOrigin,
        for: Layout.collapsedSize,
        on: targetScreen
      )
      self.setFrameOrigin(origin)
      self.collapsedOrigin = origin
      self.pendingExpansionAnchor = nil
    }
    overlay.onDragEnded = { [weak self] in
      guard let self else {
        return
      }
      self.collapsedOrigin = self.frame.origin
      self.persistCollapsedOrigin()
    }
    view.addSubview(overlay)
    collapsedDragOverlay = overlay
  }

  private func setExpanded(
    _ expanded: Bool,
    completion: @escaping () -> Void
  ) {
    guard expanded != isExpanded else {
      if expanded {
        activateAndFocusFlutterContent()
      }
      completion()
      return
    }

    if expanded {
      collapsedOrigin = frame.origin
      persistCollapsedOrigin()
    }
    isExpanded = expanded
    collapsedDragOverlay?.isHidden = expanded

    if expanded {
      let anchor = pendingExpansionAnchor ?? preferredExpansionAnchor()
      pendingExpansionAnchor = nil
      setFrame(expandedFrame(for: anchor), display: true)
      activateAndFocusFlutterContent()
    } else {
      let targetScreen = screen(containing: collapsedOrigin)
      collapsedOrigin = clampedOrigin(
        collapsedOrigin,
        for: Layout.collapsedSize,
        on: targetScreen
      )
      setFrame(
        NSRect(origin: collapsedOrigin, size: Layout.collapsedSize),
        display: true
      )
      orderFrontRegardless()
      resignKey()
    }
    completion()
  }

  private func activateAndFocusFlutterContent() {
    NSApp.activate(ignoringOtherApps: true)
    makeKeyAndOrderFront(nil)
    _ = focusFlutterContent()

    // Expansion begins from acceptsFirstMouse on the collapsed overlay, so
    // activation can finish on the next AppKit run-loop turn. Reassert the
    // Flutter view afterwards to keep keyboard input off the overlay/window.
    DispatchQueue.main.async { [weak self] in
      guard let self, self.isExpanded else {
        return
      }
      self.makeKeyAndOrderFront(nil)
      if !self.focusFlutterContent() {
        NSLog("Floatick could not focus the Flutter content view.")
      }
    }
  }

  @discardableResult
  private func focusFlutterContent() -> Bool {
    guard let flutterContentView else {
      return false
    }
    return makeFirstResponder(flutterContentView)
  }

  private func preferredExpansionAnchor() -> ExpansionAnchor {
    let collapsedFrame = NSRect(
      origin: collapsedOrigin,
      size: Layout.collapsedSize
    )
    let targetScreen = screen(
      containing: NSPoint(x: collapsedFrame.midX, y: collapsedFrame.midY)
    )
    let visibleFrame = targetScreen.visibleFrame.insetBy(
      dx: Layout.screenPadding,
      dy: Layout.screenPadding
    )

    let spaceToRight = visibleFrame.maxX - collapsedFrame.minX
    let spaceToLeft = collapsedFrame.maxX - visibleFrame.minX
    let prefersRight = collapsedFrame.midX < visibleFrame.midX
    let expandsRight = choosePreferredDirection(
      prefersFirst: prefersRight,
      firstSpace: spaceToRight,
      secondSpace: spaceToLeft,
      requiredSpace: Layout.expandedSize.width
    )

    let spaceDown = collapsedFrame.maxY - visibleFrame.minY
    let spaceUp = visibleFrame.maxY - collapsedFrame.minY
    let prefersDown = collapsedFrame.midY >= visibleFrame.midY
    let expandsDown = choosePreferredDirection(
      prefersFirst: prefersDown,
      firstSpace: spaceDown,
      secondSpace: spaceUp,
      requiredSpace: Layout.expandedSize.height
    )

    switch (expandsRight, expandsDown) {
    case (true, true):
      return .topLeft
    case (false, true):
      return .topRight
    case (true, false):
      return .bottomLeft
    case (false, false):
      return .bottomRight
    }
  }

  private func choosePreferredDirection(
    prefersFirst: Bool,
    firstSpace: CGFloat,
    secondSpace: CGFloat,
    requiredSpace: CGFloat
  ) -> Bool {
    let preferredSpace = prefersFirst ? firstSpace : secondSpace
    let alternativeSpace = prefersFirst ? secondSpace : firstSpace
    if preferredSpace >= requiredSpace {
      return prefersFirst
    }
    if alternativeSpace >= requiredSpace {
      return !prefersFirst
    }
    return firstSpace >= secondSpace
  }

  private func expandedFrame(for anchor: ExpansionAnchor) -> NSRect {
    let collapsedFrame = NSRect(
      origin: collapsedOrigin,
      size: Layout.collapsedSize
    )
    let originX: CGFloat
    let originY: CGFloat

    switch anchor {
    case .topLeft, .bottomLeft:
      originX = collapsedFrame.minX
    case .topRight, .bottomRight:
      originX = collapsedFrame.maxX - Layout.expandedSize.width
    }

    switch anchor {
    case .topLeft, .topRight:
      originY = collapsedFrame.maxY - Layout.expandedSize.height
    case .bottomLeft, .bottomRight:
      originY = collapsedFrame.minY
    }

    let proposedOrigin = NSPoint(x: originX, y: originY)
    let targetScreen = screen(
      containing: NSPoint(x: collapsedFrame.midX, y: collapsedFrame.midY)
    )
    let origin = clampedOrigin(
      proposedOrigin,
      for: Layout.expandedSize,
      on: targetScreen
    )
    return NSRect(origin: origin, size: Layout.expandedSize)
  }

  private func defaultCollapsedOrigin() -> NSPoint {
    let visibleFrame = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
    return NSPoint(
      x: visibleFrame.maxX - Layout.collapsedSize.width - 24,
      y: visibleFrame.maxY - Layout.collapsedSize.height - 24
    )
  }

  private func restoredCollapsedOrigin() -> NSPoint? {
    let defaults = UserDefaults.standard
    guard
      defaults.object(forKey: DefaultsKey.collapsedOriginX) != nil,
      defaults.object(forKey: DefaultsKey.collapsedOriginY) != nil
    else {
      return nil
    }

    let storedSize = NSSize(
      width: defaults.object(forKey: DefaultsKey.collapsedWidth) == nil
        ? Layout.legacyCollapsedSize.width
        : defaults.double(forKey: DefaultsKey.collapsedWidth),
      height: defaults.object(forKey: DefaultsKey.collapsedHeight) == nil
        ? Layout.legacyCollapsedSize.height
        : defaults.double(forKey: DefaultsKey.collapsedHeight)
    )
    let storedOrigin = NSPoint(
      x: defaults.double(forKey: DefaultsKey.collapsedOriginX),
      y: defaults.double(forKey: DefaultsKey.collapsedOriginY)
    )
    return NSPoint(
      x: storedOrigin.x + (storedSize.width - Layout.collapsedSize.width) / 2,
      y: storedOrigin.y + (storedSize.height - Layout.collapsedSize.height) / 2
    )
  }

  private func persistCollapsedOrigin() {
    let defaults = UserDefaults.standard
    defaults.set(collapsedOrigin.x, forKey: DefaultsKey.collapsedOriginX)
    defaults.set(collapsedOrigin.y, forKey: DefaultsKey.collapsedOriginY)
    defaults.set(Layout.collapsedSize.width, forKey: DefaultsKey.collapsedWidth)
    defaults.set(Layout.collapsedSize.height, forKey: DefaultsKey.collapsedHeight)
  }

  private func screen(containing point: NSPoint) -> NSScreen {
    return NSScreen.screens.first(where: { $0.frame.contains(point) })
      ?? self.screen
      ?? NSScreen.main
      ?? NSScreen.screens[0]
  }

  private func clampedOrigin(
    _ origin: NSPoint,
    for size: NSSize,
    on screen: NSScreen
  ) -> NSPoint {
    let visibleFrame = screen.visibleFrame.insetBy(
      dx: Layout.screenPadding,
      dy: Layout.screenPadding
    )
    let maximumX = max(visibleFrame.minX, visibleFrame.maxX - size.width)
    let maximumY = max(visibleFrame.minY, visibleFrame.maxY - size.height)
    return NSPoint(
      x: min(max(origin.x, visibleFrame.minX), maximumX),
      y: min(max(origin.y, visibleFrame.minY), maximumY)
    )
  }
}

private enum NativeCopy {
  static var preferredLanguageCode: String?

  private static var usesChinese: Bool {
    if let preferredLanguageCode {
      return preferredLanguageCode == "zh"
    }
    guard let preferredLanguage = Locale.preferredLanguages.first else {
      return false
    }
    return preferredLanguage.lowercased().hasPrefix("zh")
  }

  static var openFloatick: String {
    usesChinese ? "打开 Floatick" : "Open Floatick"
  }

  static var quitFloatick: String {
    usesChinese ? "退出 Floatick" : "Quit Floatick"
  }
}

private final class CollapsedDragOverlayView: NSView {
  private static let dragThreshold: CGFloat = 4

  var onClick: (() -> Void)?
  var onDrag: ((NSPoint, NSPoint, NSPoint) -> Void)?
  var onDragEnded: (() -> Void)?

  private var startMouseLocation: NSPoint?
  private var startWindowOrigin: NSPoint?
  private var didDrag = false

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setAccessibilityElement(true)
    setAccessibilityRole(.button)
    refreshLocalizedContent()
  }

  func refreshLocalizedContent() {
    setAccessibilityLabel(NativeCopy.openFloatick)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("CollapsedDragOverlayView is created programmatically.")
  }

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    return true
  }

  override func rightMouseDown(with event: NSEvent) {
    let menu = NSMenu(title: "Floatick")
    menu.autoenablesItems = false

    let quitItem = NSMenuItem(
      title: NativeCopy.quitFloatick,
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q"
    )
    quitItem.target = NSApp
    quitItem.keyEquivalentModifierMask = [.command]
    menu.addItem(quitItem)

    NSMenu.popUpContextMenu(menu, with: event, for: self)
  }

  override func resetCursorRects() {
    addCursorRect(bounds, cursor: .openHand)
  }

  override func mouseDown(with event: NSEvent) {
    startMouseLocation = NSEvent.mouseLocation
    startWindowOrigin = window?.frame.origin
    didDrag = false
    NSCursor.closedHand.set()
  }

  override func mouseDragged(with event: NSEvent) {
    guard
      let startMouseLocation,
      let startWindowOrigin
    else {
      return
    }

    let mouseLocation = NSEvent.mouseLocation
    let distance = hypot(
      mouseLocation.x - startMouseLocation.x,
      mouseLocation.y - startMouseLocation.y
    )
    if distance >= Self.dragThreshold {
      didDrag = true
    }
    guard didDrag else {
      return
    }
    onDrag?(startMouseLocation, startWindowOrigin, mouseLocation)
  }

  override func mouseUp(with event: NSEvent) {
    NSCursor.openHand.set()
    if didDrag {
      onDragEnded?()
    } else {
      onClick?()
    }
    startMouseLocation = nil
    startWindowOrigin = nil
    didDrag = false
  }

  override func accessibilityPerformPress() -> Bool {
    onClick?()
    return true
  }
}
