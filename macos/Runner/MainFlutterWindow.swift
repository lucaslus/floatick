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

  private enum PreferredAppearance: String {
    case system
    case light
    case dark

    var nativeAppearance: NSAppearance? {
      switch self {
      case .system:
        return nil
      case .light:
        return NSAppearance(named: .aqua)
      case .dark:
        return NSAppearance(named: .darkAqua)
      }
    }
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
  private var collapsedIconPanel: NSPanel?
  private var collapsedIconView: FloatingTodoIconView?
  private var collapsedDragOverlay: CollapsedDragOverlayView?
  private weak var flutterContentView: NSView?
  private var windowChannel: FlutterMethodChannel?
  private var updateService: UpdateService?
  private var loginItemService: LoginItemService?
  private var appliedAlwaysOnTop: Bool?
  private var preferredAppearance = PreferredAppearance.system
  private var isCollapseRequestPending = false
  private var secondaryWindowKeyObserver: NSObjectProtocol?
  private let configuredSecondaryWindows = NSHashTable<NSWindow>.weakObjects()
  private let initialSecondaryWindows = NSHashTable<NSWindow>.weakObjects()

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  override func makeKeyAndOrderFront(_ sender: Any?) {
    guard isExpanded else {
      orderOut(nil)
      collapsedIconPanel?.orderFrontRegardless()
      return
    }
    super.makeKeyAndOrderFront(sender)
  }

  override func orderFront(_ sender: Any?) {
    guard isExpanded else {
      orderOut(nil)
      collapsedIconPanel?.orderFrontRegardless()
      return
    }
    super.orderFront(sender)
  }

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

  override func resignKey() {
    super.resignKey()
    guard isExpanded else {
      return
    }
    DispatchQueue.main.async { [weak self] in
      self?.requestCollapseIfNeeded()
    }
  }

  func handleApplicationReopen() -> Bool {
    if isExpanded {
      activateAndFocusFlutterContent()
    } else {
      orderOut(nil)
      collapsedIconPanel?.orderFrontRegardless()
      collapsedIconView?.playAttentionAnimation()
    }
    return true
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
    configureRoundedFlutterSurface(
      in: flutterViewController,
      cornerRadius: 26
    )
    RegisterGeneratedPlugins(registry: flutterViewController)
    configureWindowChannel(for: flutterViewController)
    configureUpdateService(for: flutterViewController)
    configureLoginItemService(for: flutterViewController)
    observeInitialSecondaryWindowPresentation()

    let origin = restoredCollapsedOrigin() ?? defaultCollapsedOrigin()
    collapsedOrigin = clampedOrigin(
      origin,
      for: Layout.collapsedSize,
      on: screen(containing: origin)
    )
    let initialAnchor = preferredExpansionAnchor()
    setFrame(
      expandedFrame(for: initialAnchor),
      display: false
    )
    lockMainWindowSize()
    orderOut(nil)
    configureCollapsedIconWindow()

    super.awakeFromNib()
    DispatchQueue.main.async { [weak self] in
      guard let self, !self.isExpanded else {
        return
      }
      self.orderOut(nil)
      self.collapsedIconPanel?.orderFrontRegardless()
    }
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
    alphaValue = 1
    lockMainWindowSize()
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
      case "synchronizeCollapsedState":
        self.synchronizeCollapsedState()
        result(nil)
      case "preferredExpansionAnchor":
        let anchor = self.preferredExpansionAnchor()
        self.pendingExpansionAnchor = anchor
        result(anchor.rawValue)
      case "setExpanded":
        guard
          let arguments = call.arguments as? [String: Any],
          let expanded = arguments["expanded"] as? Bool,
          let animated = arguments["animated"] as? Bool
        else {
          result(
            FlutterError(
              code: "invalid_argument",
              message:
                "setExpanded expects expanded and animated Boolean values.",
              details: nil
            )
          )
          return
        }
        self.setExpanded(
          expanded,
          animated: animated,
          completion: { result(nil) }
        )
      case "setFloatingIconCount":
        guard
          let activeCount = (call.arguments as? NSNumber)?.intValue,
          activeCount >= 0
        else {
          result(
            FlutterError(
              code: "invalid_argument",
              message:
                "setFloatingIconCount expects a non-negative count.",
              details: nil
            )
          )
          return
        }
        self.collapsedIconView?.setActiveCount(activeCount)
        result(nil)
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
      case "setPreferredTheme":
        guard
          let rawPreference = call.arguments as? String,
          let preference = PreferredAppearance(rawValue: rawPreference)
        else {
          result(
            FlutterError(
              code: "invalid_argument",
              message:
                "setPreferredTheme expects \"system\", \"light\", or \"dark\".",
              details: nil
            )
          )
          return
        }
        self.setPreferredAppearance(preference)
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
          let arguments = call.arguments as? [String: Any],
          let viewIdentifier = (arguments["viewId"] as? NSNumber)?.int64Value,
          let positionAdjacentToMainWindow =
            arguments["positionAdjacentToMainWindow"] as? Bool
        else {
          result(
            FlutterError(
              code: "invalid_argument",
              message:
                "configureBorderlessSecondaryWindow expects a view ID and positioning preference.",
              details: nil
            )
          )
          return
        }
        guard self.configureBorderlessSecondaryWindow(
          viewIdentifier: viewIdentifier,
          positionAdjacentToMainWindow: positionAdjacentToMainWindow
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
      case "revealBorderlessSecondaryWindow":
        guard
          let viewIdentifier = (call.arguments as? NSNumber)?.int64Value
        else {
          result(
            FlutterError(
              code: "invalid_argument",
              message:
                "revealBorderlessSecondaryWindow expects a view ID.",
              details: nil
            )
          )
          return
        }
        guard self.revealBorderlessSecondaryWindow(
          viewIdentifier: viewIdentifier
        ) else {
          result(
            FlutterError(
              code: "window_unavailable",
              message:
                "The configured secondary Flutter window could not be found.",
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
    viewIdentifier: Int64,
    positionAdjacentToMainWindow: Bool
  ) -> Bool {
    guard
      let targetWindow = NSApp.windows.first(where: { window in
        guard
          window !== self,
          let controller = self.flutterViewController(in: window)
        else {
          return false
        }
        return controller.viewIdentifier == viewIdentifier
      }),
      let flutterViewController = flutterViewController(in: targetWindow)
    else {
      return false
    }

    targetWindow.alphaValue = 0
    configureTransparentRoundedWindow(
      targetWindow,
      flutterViewController: flutterViewController
    )
    let existingFrame = targetWindow.frame
    targetWindow.styleMask = [.borderless, .resizable]
    targetWindow.setFrame(existingFrame, display: false)
    targetWindow.preservesContentDuringLiveResize = true
    targetWindow.contentView?.layerContentsRedrawPolicy = .onSetNeedsDisplay
    targetWindow.contentView?.layerContentsPlacement = .scaleAxesIndependently
    targetWindow.appearance = preferredAppearance.nativeAppearance
    if positionAdjacentToMainWindow {
      positionSecondaryWindowAdjacentToMainWindow(targetWindow)
    }
    if isExpanded {
      DispatchQueue.main.async { [weak self] in
        guard let self, self.isExpanded else {
          return
        }
        self.activateAndFocusFlutterContent()
      }
    }
    configuredSecondaryWindows.add(targetWindow)
    return true
  }

  private func revealBorderlessSecondaryWindow(
    viewIdentifier: Int64
  ) -> Bool {
    guard
      let targetWindow = NSApp.windows.first(where: { window in
        guard
          window !== self,
          let controller = self.flutterViewController(in: window)
        else {
          return false
        }
        return controller.viewIdentifier == viewIdentifier
      }),
      configuredSecondaryWindows.contains(targetWindow)
    else {
      return false
    }

    targetWindow.displayIfNeeded()
    targetWindow.alphaValue = 1
    targetWindow.orderFrontRegardless()
    return true
  }

  private func observeInitialSecondaryWindowPresentation() {
    secondaryWindowKeyObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.didBecomeKeyNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard
        let self,
        let targetWindow = notification.object as? NSWindow,
        targetWindow !== self,
        !self.configuredSecondaryWindows.contains(targetWindow),
        let flutterViewController = self.flutterViewController(
          in: targetWindow
        )
      else {
        return
      }

      // multiview_desktop orders a new NSWindow on screen before Dart can
      // apply its WindowOptions. Keep that initial native surface invisible;
      // the coordinator reveals it only after configuration, positioning and
      // Flutter's first completed frame.
      self.initialSecondaryWindows.add(targetWindow)
      targetWindow.alphaValue = 0
      self.configureTransparentRoundedWindow(
        targetWindow,
        flutterViewController: flutterViewController
      )
      DispatchQueue.main.async { [weak self, weak targetWindow] in
        guard let self, let targetWindow else {
          return
        }
        defer {
          self.initialSecondaryWindows.remove(targetWindow)
        }
        guard self.isExpanded else {
          return
        }
        // Creating a pinned board briefly makes its hidden native window key.
        // Restore the main window so that this programmatic handoff is not
        // mistaken for an outside click.
        self.activateAndFocusFlutterContent()
      }
    }
  }

  private func configureTransparentRoundedWindow(
    _ targetWindow: NSWindow,
    flutterViewController: FlutterViewController
  ) {
    targetWindow.backgroundColor = .clear
    targetWindow.isOpaque = false
    targetWindow.hasShadow = false
    targetWindow.invalidateShadow()
    targetWindow.contentView?.wantsLayer = true
    targetWindow.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    targetWindow.contentView?.layer?.isOpaque = false
    configureRoundedFlutterSurface(
      in: flutterViewController,
      cornerRadius: 22
    )
  }

  private func positionSecondaryWindowAdjacentToMainWindow(
    _ targetWindow: NSWindow
  ) {
    let mainFrame = frame
    let targetSize = targetWindow.frame.size
    let targetScreen = screen(
      containing: NSPoint(x: mainFrame.midX, y: mainFrame.midY)
    )
    let visibleFrame = targetScreen.visibleFrame.insetBy(
      dx: Layout.screenPadding,
      dy: Layout.screenPadding
    )
    let gap: CGFloat = 12
    let rightOriginX = mainFrame.maxX + gap
    let leftOriginX = mainFrame.minX - targetSize.width - gap
    let fitsOnRight = rightOriginX + targetSize.width <= visibleFrame.maxX
    let fitsOnLeft = leftOriginX >= visibleFrame.minX

    let originX: CGFloat
    if fitsOnRight && !fitsOnLeft {
      originX = rightOriginX
    } else if fitsOnLeft && !fitsOnRight {
      originX = leftOriginX
    } else if visibleFrame.maxX - mainFrame.maxX >=
      mainFrame.minX - visibleFrame.minX
    {
      originX = rightOriginX
    } else {
      originX = leftOriginX
    }

    let centeredOriginY = mainFrame.midY - targetSize.height / 2
    let maximumX = max(
      visibleFrame.minX,
      visibleFrame.maxX - targetSize.width
    )
    let maximumY = max(
      visibleFrame.minY,
      visibleFrame.maxY - targetSize.height
    )
    targetWindow.setFrameOrigin(
      NSPoint(
        x: min(max(originX, visibleFrame.minX), maximumX),
        y: min(max(centeredOriginY, visibleFrame.minY), maximumY)
      )
    )
  }

  private func flutterViewController(
    in window: NSWindow
  ) -> FlutterViewController? {
    return flutterViewController(in: window.contentViewController)
  }

  private func flutterViewController(
    in controller: NSViewController?
  ) -> FlutterViewController? {
    guard let controller else {
      return nil
    }
    if let flutterViewController = controller as? FlutterViewController {
      return flutterViewController
    }
    for child in controller.children {
      if let flutterViewController = flutterViewController(in: child) {
        return flutterViewController
      }
    }
    return nil
  }

  private func configureRoundedFlutterSurface(
    in flutterViewController: FlutterViewController,
    cornerRadius: CGFloat
  ) {
    let rootView = flutterViewController.view
    rootView.wantsLayer = true
    rootView.layer?.backgroundColor = NSColor.clear.cgColor
    rootView.layer?.isOpaque = false
    rootView.layer?.cornerRadius = cornerRadius
    rootView.layer?.cornerCurve = .continuous
    rootView.layer?.masksToBounds = true
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
    collapsedIconPanel?.level = targetLevel
    if alwaysOnTop {
      if isExpanded {
        orderFrontRegardless()
      } else {
        collapsedIconPanel?.orderFrontRegardless()
      }
    }
  }

  private func setPreferredAppearance(_ preference: PreferredAppearance) {
    guard preferredAppearance != preference else {
      return
    }
    preferredAppearance = preference
    let nativeAppearance = preference.nativeAppearance
    appearance = nativeAppearance
    collapsedIconPanel?.appearance = nativeAppearance
    for window in NSApp.windows where window !== self {
      guard flutterViewController(in: window) != nil else {
        continue
      }
      window.appearance = nativeAppearance
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

  private func configureLoginItemService(
    for flutterViewController: FlutterViewController
  ) {
    let loginItemService = LoginItemService()
    loginItemService.configure(
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    self.loginItemService = loginItemService
  }

  private func configureCollapsedIconWindow() {
    let iconPanel = NSPanel(
      contentRect: NSRect(origin: collapsedOrigin, size: Layout.collapsedSize),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    iconPanel.backgroundColor = .clear
    iconPanel.isOpaque = false
    iconPanel.hasShadow = false
    iconPanel.hidesOnDeactivate = false
    iconPanel.isReleasedWhenClosed = false
    iconPanel.collectionBehavior = collectionBehavior
    iconPanel.level = level
    iconPanel.animationBehavior = .none

    let iconView = FloatingTodoIconView(
      frame: NSRect(origin: .zero, size: Layout.collapsedSize),
      activeCount: 0
    )
    iconPanel.contentView = iconView
    collapsedIconPanel = iconPanel
    collapsedIconView = iconView
    configureDragOverlay(for: iconView)
    iconPanel.orderFrontRegardless()
  }

  private func configureDragOverlay(for iconView: NSView) {
    let overlay = CollapsedDragOverlayView(frame: iconView.bounds)
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
      self.collapsedIconPanel?.setFrameOrigin(origin)
      self.collapsedOrigin = origin
      self.pendingExpansionAnchor = nil
    }
    overlay.onDragEnded = { [weak self] in
      guard let self else {
        return
      }
      if let iconOrigin = self.collapsedIconPanel?.frame.origin {
        self.collapsedOrigin = iconOrigin
      }
      self.persistCollapsedOrigin()
    }
    iconView.addSubview(overlay)
    collapsedDragOverlay = overlay
  }

  private func requestCollapseIfNeeded() {
    if
      let keyWindow = NSApp.keyWindow,
      initialSecondaryWindows.contains(keyWindow)
    {
      return
    }
    guard
      isExpanded,
      !isKeyWindow,
      !isCollapseRequestPending,
      let windowChannel
    else {
      return
    }
    isCollapseRequestPending = true
    windowChannel.invokeMethod(
      "requestCollapse",
      arguments: nil
    ) { [weak self] _ in
      self?.isCollapseRequestPending = false
    }
  }

  private func setExpanded(
    _ expanded: Bool,
    animated: Bool,
    completion: @escaping () -> Void
  ) {
    guard expanded != isExpanded else {
      if expanded {
        activateAndFocusFlutterContent()
      }
      completion()
      return
    }

    isExpanded = expanded

    if expanded {
      let anchor = pendingExpansionAnchor ?? preferredExpansionAnchor()
      pendingExpansionAnchor = nil
      lockMainWindowSize()
      setFrame(expandedFrame(for: anchor), display: false)
      alphaValue = animated ? 0 : 1
      activateAndFocusFlutterContent()
      collapsedIconPanel?.orderFrontRegardless()
      transitionWindows(
        showMainWindow: true,
        animated: animated,
        completion: completion
      )
    } else {
      let targetScreen = screen(containing: collapsedOrigin)
      collapsedOrigin = clampedOrigin(
        collapsedOrigin,
        for: Layout.collapsedSize,
        on: targetScreen
      )
      collapsedIconPanel?.setFrame(
        NSRect(origin: collapsedOrigin, size: Layout.collapsedSize),
        display: false
      )
      collapsedIconPanel?.alphaValue = animated ? 0 : 1
      collapsedIconPanel?.orderFrontRegardless()
      transitionWindows(
        showMainWindow: false,
        animated: animated,
        completion: completion
      )
    }
  }

  private func synchronizeCollapsedState() {
    isExpanded = false
    isCollapseRequestPending = false
    pendingExpansionAnchor = nil
    lockMainWindowSize()
    alphaValue = 1
    orderOut(nil)
    resignKey()

    let targetScreen = screen(containing: collapsedOrigin)
    collapsedOrigin = clampedOrigin(
      collapsedOrigin,
      for: Layout.collapsedSize,
      on: targetScreen
    )
    collapsedIconPanel?.setFrame(
      NSRect(origin: collapsedOrigin, size: Layout.collapsedSize),
      display: false
    )
    collapsedIconPanel?.alphaValue = 1
    collapsedIconPanel?.orderFrontRegardless()
  }

  private func lockMainWindowSize() {
    styleMask = [.borderless]
    minSize = Layout.expandedSize
    maxSize = Layout.expandedSize
    contentMinSize = Layout.expandedSize
    contentMaxSize = Layout.expandedSize
  }

  private func transitionWindows(
    showMainWindow: Bool,
    animated: Bool,
    completion: @escaping () -> Void
  ) {
    let changes = { [weak self] in
      guard let self else {
        return
      }
      self.alphaValue = showMainWindow ? 1 : 0
      self.collapsedIconPanel?.alphaValue = showMainWindow ? 0 : 1
    }
    let finished = { [weak self] in
      guard let self else {
        completion()
        return
      }
      if showMainWindow {
        self.collapsedIconPanel?.orderOut(nil)
        self.collapsedIconPanel?.alphaValue = 1
        self.activateAndFocusFlutterContent()
      } else {
        self.orderOut(nil)
        self.alphaValue = 1
        self.resignKey()
      }
      completion()
    }

    guard animated else {
      changes()
      finished()
      return
    }
    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.12
      context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      animator().alphaValue = showMainWindow ? 1 : 0
      collapsedIconPanel?.animator().alphaValue = showMainWindow ? 0 : 1
    } completionHandler: {
      finished()
    }
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
    return Self.defaultCollapsedOrigin(in: visibleFrame)
  }

  static func defaultCollapsedOrigin(in visibleFrame: NSRect) -> NSPoint {
    return NSPoint(
      x: visibleFrame.maxX - Layout.collapsedSize.width - 24,
      y: visibleFrame.minY + 24
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

final class FloatingTodoIconView: NSView {
  private enum Metrics {
    static let brandFrame = NSRect(x: 10, y: 10, width: 52, height: 52)
    static let badgeHeight: CGFloat = 20
    static let badgeRightEdge: CGFloat = 65
    static let badgeTop: CGFloat = 7
    static let attentionIconAnimationKey = "floatick-attention-icon"
    static let attentionGlowAnimationKey = "floatick-attention-glow"
    static let attentionDuration: CFTimeInterval = 0.52
    static let reducedMotionAttentionDuration: CFTimeInterval = 0.24
    static let attentionMaximumScale: CGFloat = 1.1
    static let attentionGlowLineWidth: CGFloat = 2
    static let attentionGlowShadowRadius: CGFloat = 4
    static let attentionGlowFrame = brandFrame.insetBy(dx: 1.5, dy: 1.5)
  }

  private var activeCount: Int
  private(set) var attentionGlowLayer = CAShapeLayer()

  override var isFlipped: Bool { true }
  override var isOpaque: Bool { false }

  init(frame frameRect: NSRect, activeCount: Int) {
    self.activeCount = activeCount
    super.init(frame: frameRect)
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
    layer?.masksToBounds = false
    configureAttentionGlow()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("FloatingTodoIconView is created programmatically.")
  }

  func setActiveCount(_ activeCount: Int) {
    guard self.activeCount != activeCount else {
      return
    }
    self.activeCount = activeCount
    needsDisplay = true
  }

  func playAttentionAnimation(
    reduceMotion: Bool =
      NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
  ) {
    guard let layer else {
      return
    }

    layer.removeAnimation(forKey: Metrics.attentionIconAnimationKey)
    attentionGlowLayer.removeAnimation(
      forKey: Metrics.attentionGlowAnimationKey
    )

    let glowOpacity = CAKeyframeAnimation(keyPath: "opacity")
    glowOpacity.values = [0, 0.7, 0.35, 0]
    glowOpacity.keyTimes = [0, 0.24, 0.68, 1]

    let glowAnimation = CAAnimationGroup()
    glowAnimation.animations = [glowOpacity]
    glowAnimation.duration = reduceMotion
      ? Metrics.reducedMotionAttentionDuration
      : Metrics.attentionDuration
    glowAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
    attentionGlowLayer.add(
      glowAnimation,
      forKey: Metrics.attentionGlowAnimationKey
    )

    guard !reduceMotion else {
      return
    }

    let scale = CAKeyframeAnimation(keyPath: "transform.scale")
    scale.values = [1, Metrics.attentionMaximumScale, 0.98, 1.04, 1]
    scale.keyTimes = [0, 0.24, 0.46, 0.72, 1]

    let iconAnimation = CAAnimationGroup()
    iconAnimation.animations = [scale]
    iconAnimation.duration = Metrics.attentionDuration
    iconAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
    layer.add(
      iconAnimation,
      forKey: Metrics.attentionIconAnimationKey
    )
  }

  override func layout() {
    super.layout()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    attentionGlowLayer.frame = bounds
    CATransaction.commit()
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    drawBrandMark()
    if activeCount > 0 {
      drawBadge()
    }
  }

  private func drawBrandMark() {
    let brandPath = NSBezierPath(ovalIn: Metrics.brandFrame)
    NSGradient(
      starting: NSColor(
        calibratedRed: 36 / 255,
        green: 56 / 255,
        blue: 60 / 255,
        alpha: 1
      ),
      ending: NSColor(
        calibratedRed: 23 / 255,
        green: 35 / 255,
        blue: 38 / 255,
        alpha: 1
      )
    )?.draw(in: brandPath, angle: -45)

    NSColor(
      calibratedRed: 64 / 255,
      green: 87 / 255,
      blue: 90 / 255,
      alpha: 0.92
    ).setStroke()
    brandPath.lineWidth = 1.2
    brandPath.stroke()

    drawCheck(
      start: point(x: 0.22, y: 0.50),
      firstControl: point(x: 0.27, y: 0.54),
      secondControl: point(x: 0.31, y: 0.59),
      middle: point(x: 0.36, y: 0.64),
      thirdControl: point(x: 0.41, y: 0.59),
      fourthControl: point(x: 0.47, y: 0.52),
      end: point(x: 0.53, y: 0.46),
      color: NSColor(
        calibratedRed: 29 / 255,
        green: 179 / 255,
        blue: 168 / 255,
        alpha: 1
      )
    )
    drawCheck(
      start: point(x: 0.38, y: 0.50),
      firstControl: point(x: 0.43, y: 0.55),
      secondControl: point(x: 0.47, y: 0.60),
      middle: point(x: 0.52, y: 0.64),
      thirdControl: point(x: 0.60, y: 0.55),
      fourthControl: point(x: 0.68, y: 0.46),
      end: point(x: 0.77, y: 0.37),
      color: NSColor(
        calibratedRed: 44 / 255,
        green: 204 / 255,
        blue: 189 / 255,
        alpha: 1
      )
    )
  }

  private func configureAttentionGlow() {
    let glowColor = NSColor(
      calibratedRed: 44 / 255,
      green: 204 / 255,
      blue: 189 / 255,
      alpha: 1
    )
    let glowPath = CGPath(
      ellipseIn: Metrics.attentionGlowFrame,
      transform: nil
    )
    attentionGlowLayer.frame = bounds
    attentionGlowLayer.path = glowPath
    attentionGlowLayer.fillColor = NSColor.clear.cgColor
    attentionGlowLayer.strokeColor = glowColor.withAlphaComponent(0.9).cgColor
    attentionGlowLayer.lineWidth = Metrics.attentionGlowLineWidth
    attentionGlowLayer.shadowColor = glowColor.cgColor
    attentionGlowLayer.shadowPath = glowPath
    attentionGlowLayer.shadowOffset = .zero
    attentionGlowLayer.shadowOpacity = 0.95
    attentionGlowLayer.shadowRadius = Metrics.attentionGlowShadowRadius
    attentionGlowLayer.opacity = 0
    attentionGlowLayer.actions = [
      "bounds": NSNull(),
      "frame": NSNull(),
      "opacity": NSNull(),
      "position": NSNull(),
    ]
    layer?.addSublayer(attentionGlowLayer)
  }

  private func point(x: CGFloat, y: CGFloat) -> NSPoint {
    NSPoint(
      x: Metrics.brandFrame.minX + (Metrics.brandFrame.width * x),
      y: Metrics.brandFrame.minY + (Metrics.brandFrame.height * y)
    )
  }

  private func drawCheck(
    start: NSPoint,
    firstControl: NSPoint,
    secondControl: NSPoint,
    middle: NSPoint,
    thirdControl: NSPoint,
    fourthControl: NSPoint,
    end: NSPoint,
    color: NSColor
  ) {
    let path = NSBezierPath()
    path.move(to: start)
    path.curve(
      to: middle,
      controlPoint1: firstControl,
      controlPoint2: secondControl
    )
    path.curve(
      to: end,
      controlPoint1: thirdControl,
      controlPoint2: fourthControl
    )
    path.lineWidth = Metrics.brandFrame.width * 0.07
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    color.setStroke()
    path.stroke()
  }

  private func drawBadge() {
    let label = activeCount > 99 ? "99+" : "\(activeCount)"
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: 9, weight: .bold),
      .foregroundColor: NSColor.white,
    ]
    let labelSize = (label as NSString).size(withAttributes: attributes)
    let badgeWidth = max(20, labelSize.width + 9)
    let badgeFrame = NSRect(
      x: Metrics.badgeRightEdge - badgeWidth,
      y: Metrics.badgeTop,
      width: badgeWidth,
      height: Metrics.badgeHeight
    )

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowBlurRadius = 5
    shadow.shadowOffset = NSSize(width: 0, height: -2)
    shadow.set()
    NSColor(
      calibratedRed: 241 / 255,
      green: 120 / 255,
      blue: 66 / 255,
      alpha: 1
    ).setFill()
    NSBezierPath(
      roundedRect: badgeFrame,
      xRadius: Metrics.badgeHeight / 2,
      yRadius: Metrics.badgeHeight / 2
    ).fill()
    NSGraphicsContext.restoreGraphicsState()

    let labelFrame = NSRect(
      x: badgeFrame.minX,
      y: badgeFrame.midY - (labelSize.height / 2),
      width: badgeFrame.width,
      height: labelSize.height
    )
    (label as NSString).draw(
      in: labelFrame,
      withAttributes: attributes.merging(
        [.paragraphStyle: centeredParagraphStyle],
        uniquingKeysWith: { current, _ in current }
      )
    )
  }

  private var centeredParagraphStyle: NSParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    return style
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

final class CollapsedDragOverlayView: NSView {
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
