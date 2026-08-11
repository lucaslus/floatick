import Cocoa
import FlutterMacOS

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
  private var deadlineReminderController: DeadlineReminderPanelController?
  private var deadlineReminderNativeScheduler: DeadlineReminderNativeScheduler?

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
    engine.run(withEntrypoint: nil)
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
      case "showDeadlineReminder":
        guard
          let arguments = call.arguments as? [String: Any],
          let payload = DeadlineReminderPayload(arguments: arguments)
        else {
          result(
            FlutterError(
              code: "invalid_argument",
              message: "showDeadlineReminder expects a valid reminder payload.",
              details: nil
            )
          )
          return
        }
        self.ensureDeadlineReminderController().enqueue(payload)
        result(nil)
      case "synchronizeScheduledDeadlineReminders":
        guard let rawEntries = call.arguments as? [[String: Any]] else {
          result(
            FlutterError(
              code: "invalid_argument",
              message:
                "synchronizeScheduledDeadlineReminders expects a list.",
              details: nil
            )
          )
          return
        }
        let entries = rawEntries.compactMap(
          ScheduledDeadlineReminderEntry.init(arguments:)
        )
        guard entries.count == rawEntries.count else {
          result(
            FlutterError(
              code: "invalid_argument",
              message: "A scheduled deadline reminder is invalid.",
              details: nil
            )
          )
          return
        }
        self.ensureDeadlineReminderNativeScheduler().replace(with: entries)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    windowChannel = channel
  }

  private func ensureDeadlineReminderController()
    -> DeadlineReminderPanelController
  {
    if let deadlineReminderController {
      return deadlineReminderController
    }
    let controller = DeadlineReminderPanelController(
      appearance: preferredAppearance.nativeAppearance,
      collapsedIconFrameProvider: { [weak self] in
        self?.collapsedIconPanel?.frame
      },
      visibleFrameProvider: { [weak self] in
        guard let self else {
          return nil
        }
        return self.collapsedIconPanel?.screen?.visibleFrame
          ?? self.screen?.visibleFrame
      },
      onAction: { [weak self] action in
        self?.windowChannel?.invokeMethod(
          "deadlineReminderAction",
          arguments: action
        )
      }
    )
    deadlineReminderController = controller
    return controller
  }

  private func ensureDeadlineReminderNativeScheduler()
    -> DeadlineReminderNativeScheduler
  {
    if let deadlineReminderNativeScheduler {
      return deadlineReminderNativeScheduler
    }
    let scheduler = DeadlineReminderNativeScheduler(
      onDue: { [weak self] entry in
        guard let self else {
          return
        }
        self.ensureDeadlineReminderController().enqueue(entry.payload)
        self.windowChannel?.invokeMethod(
          "deadlineReminderDelivered",
          arguments: [
            "notificationId": entry.notificationId,
            "todoId": entry.payload.todoId,
            "deliveryKind": entry.deliveryKind,
          ]
        )
      }
    )
    deadlineReminderNativeScheduler = scheduler
    return scheduler
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
    deadlineReminderController?.setAppearance(nativeAppearance)
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
      self.deadlineReminderController?.updateCollapsedAnchor()
    }
    overlay.onDragEnded = { [weak self] in
      guard let self else {
        return
      }
      if let iconOrigin = self.collapsedIconPanel?.frame.origin {
        self.collapsedOrigin = iconOrigin
      }
      self.persistCollapsedOrigin()
      self.deadlineReminderController?.updateCollapsedAnchor()
    }
    iconView.addSubview(overlay)
    collapsedDragOverlay = overlay
  }

  private func requestCollapseIfNeeded() {
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
      deadlineReminderController?.updateCollapsedAnchor()
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
    deadlineReminderController?.updateCollapsedAnchor()
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

enum DeadlineReminderLayout {
  static let cardSize = NSSize(width: 368, height: 132)
  static let pillSize = NSSize(width: 112, height: 32)
  static let screenInset: CGFloat = 16
  static let slideOffset: CGFloat = 16
  static let pillSpacing: CGFloat = 8
  static let pillScreenInset: CGFloat = 8

  static func pillFrame(
    anchoredTo iconFrame: NSRect,
    within visibleFrame: NSRect
  ) -> NSRect {
    let minimumX = visibleFrame.minX + pillScreenInset
    let maximumX = max(
      minimumX,
      visibleFrame.maxX - pillSize.width - pillScreenInset
    )
    let centeredX = iconFrame.midX - pillSize.width / 2
    let originX = min(max(centeredX, minimumX), maximumX)

    let minimumY = visibleFrame.minY + pillScreenInset
    let maximumY = max(
      minimumY,
      visibleFrame.maxY - pillSize.height - pillScreenInset
    )
    let aboveY = iconFrame.maxY + pillSpacing
    let belowY = iconFrame.minY - pillSize.height - pillSpacing
    let preferredY = aboveY <= maximumY ? aboveY : belowY
    let originY = min(max(preferredY, minimumY), maximumY)

    return NSRect(
      origin: NSPoint(x: originX, y: originY),
      size: pillSize
    )
  }

  static func cardFrame(size: NSSize, within visibleFrame: NSRect) -> NSRect {
    let originX = max(
      visibleFrame.minX,
      visibleFrame.maxX - size.width - screenInset
    )
    let originY = max(
      visibleFrame.minY,
      visibleFrame.maxY - size.height - screenInset
    )
    return NSRect(origin: NSPoint(x: originX, y: originY), size: size)
  }
}

struct DeadlineReminderPayload {
  let notificationId: String
  let todoId: String
  let title: String
  let dueLabel: String
  let isOverdue: Bool
  let isAdvanceReminder: Bool
  let tagLabel: String?

  init?(arguments: [String: Any]) {
    guard
      let notificationId = arguments["notificationId"] as? String,
      !notificationId.isEmpty,
      let todoId = arguments["todoId"] as? String,
      !todoId.isEmpty,
      let title = arguments["title"] as? String,
      !title.isEmpty,
      let dueLabel = arguments["dueLabel"] as? String,
      let isOverdue = arguments["isOverdue"] as? Bool,
      let isAdvanceReminder = arguments["isAdvanceReminder"] as? Bool
    else {
      return nil
    }
    self.notificationId = notificationId
    self.todoId = todoId
    self.title = title
    self.dueLabel = dueLabel
    self.isOverdue = isOverdue
    self.isAdvanceReminder = isAdvanceReminder
    self.tagLabel = arguments["tagLabel"] as? String
  }
}

struct ScheduledDeadlineReminderEntry {
  private static let deliveryKinds = Set(["snoozed", "deadline", "advance"])

  let notificationId: String
  let triggerAt: Date
  let deliveryKind: String
  let payload: DeadlineReminderPayload

  init?(arguments: [String: Any]) {
    guard
      let notificationId = arguments["notificationId"] as? String,
      !notificationId.isEmpty,
      let triggerAtMilliseconds = arguments["triggerAtMilliseconds"]
        as? NSNumber,
      triggerAtMilliseconds.doubleValue.isFinite,
      let deliveryKind = arguments["deliveryKind"] as? String,
      Self.deliveryKinds.contains(deliveryKind),
      let payloadArguments = arguments["payload"] as? [String: Any],
      let payload = DeadlineReminderPayload(arguments: payloadArguments),
      payload.notificationId == notificationId
    else {
      return nil
    }
    self.notificationId = notificationId
    self.triggerAt = Date(
      timeIntervalSince1970: triggerAtMilliseconds.doubleValue / 1_000
    )
    self.deliveryKind = deliveryKind
    self.payload = payload
  }
}

final class DeadlineReminderNativeScheduler {
  typealias NowProvider = () -> Date
  typealias DueHandler = (ScheduledDeadlineReminderEntry) -> Void

  private let nowProvider: NowProvider
  private let onDue: DueHandler
  private let timerQueue = DispatchQueue(
    label: "io.github.lucaslushuo.floatick.deadline-reminder-timer",
    qos: .userInitiated
  )
  private var entries: [ScheduledDeadlineReminderEntry] = []
  private var deliveredNotificationIds = Set<String>()
  private var timer: DispatchSourceTimer?

  init(
    nowProvider: @escaping NowProvider = Date.init,
    onDue: @escaping DueHandler
  ) {
    self.nowProvider = nowProvider
    self.onDue = onDue
  }

  deinit {
    timer?.cancel()
  }

  func replace(with entries: [ScheduledDeadlineReminderEntry]) {
    let scheduledIds = Set(entries.map(\.notificationId))
    deliveredNotificationIds.formIntersection(scheduledIds)
    self.entries = entries
      .filter { !deliveredNotificationIds.contains($0.notificationId) }
      .sorted(by: Self.isOrderedBefore)
    processDueReminders()
  }

  func processDueReminders() {
    timer?.cancel()
    timer = nil

    let now = nowProvider()
    let firstPendingIndex = entries.firstIndex { $0.triggerAt > now }
      ?? entries.endIndex
    let dueEntries = Array(entries[..<firstPendingIndex])
    entries.removeFirst(firstPendingIndex)

    for entry in dueEntries
    where deliveredNotificationIds.insert(entry.notificationId).inserted {
      onDue(entry)
    }
    scheduleNext()
  }

  func cancel() {
    timer?.cancel()
    timer = nil
    entries.removeAll()
  }

  private func scheduleNext() {
    guard let nextEntry = entries.first else {
      return
    }
    let interval = nextEntry.triggerAt.timeIntervalSince(nowProvider())
    guard interval > 0 else {
      DispatchQueue.main.async { [weak self] in
        self?.processDueReminders()
      }
      return
    }
    let leewayMilliseconds = min(
      500,
      max(50, Int(interval * 10))
    )
    let timer = DispatchSource.makeTimerSource(queue: timerQueue)
    timer.schedule(
      deadline: .now() + interval,
      leeway: .milliseconds(leewayMilliseconds)
    )
    timer.setEventHandler { [weak self] in
      DispatchQueue.main.async {
        self?.processDueReminders()
      }
    }
    self.timer = timer
    timer.resume()
  }

  private static func isOrderedBefore(
    _ left: ScheduledDeadlineReminderEntry,
    _ right: ScheduledDeadlineReminderEntry
  ) -> Bool {
    if left.triggerAt == right.triggerAt {
      return left.notificationId < right.notificationId
    }
    return left.triggerAt < right.triggerAt
  }
}

private final class DeadlineReminderPanelController {
  private let panel: NSPanel
  private let collapsedIconFrameProvider: () -> NSRect?
  private let visibleFrameProvider: () -> NSRect?
  private let onAction: ([String: Any]) -> Void
  private var queue: [DeadlineReminderPayload] = []
  private var currentPayload: DeadlineReminderPayload?
  private var collapseTimer: Timer?
  private var isShowingPill = false

  init(
    appearance: NSAppearance?,
    collapsedIconFrameProvider: @escaping () -> NSRect?,
    visibleFrameProvider: @escaping () -> NSRect?,
    onAction: @escaping ([String: Any]) -> Void
  ) {
    panel = NSPanel(
      contentRect: NSRect(origin: .zero, size: DeadlineReminderLayout.cardSize),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    self.collapsedIconFrameProvider = collapsedIconFrameProvider
    self.visibleFrameProvider = visibleFrameProvider
    self.onAction = onAction
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = true
    panel.hidesOnDeactivate = false
    panel.isReleasedWhenClosed = false
    panel.level = .statusBar
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    panel.animationBehavior = .none
    panel.appearance = appearance
  }

  func setAppearance(_ appearance: NSAppearance?) {
    panel.appearance = appearance
  }

  func updateCollapsedAnchor() {
    guard isShowingPill else {
      return
    }
    panel.setFrame(collapsedPillFrame(), display: true)
  }

  func enqueue(_ payload: DeadlineReminderPayload) {
    if currentPayload?.notificationId == payload.notificationId ||
      queue.contains(where: {
        $0.notificationId == payload.notificationId
      })
    {
      return
    }
    queue.append(payload)
    showNextIfNeeded()
  }

  private func showNextIfNeeded() {
    guard currentPayload == nil, !queue.isEmpty else {
      return
    }
    let payload = queue.removeFirst()
    currentPayload = payload
    showCard(payload, animated: true)
  }

  private func showCard(
    _ payload: DeadlineReminderPayload,
    animated: Bool
  ) {
    collapseTimer?.invalidate()
    isShowingPill = false
    let cardView = DeadlineReminderCardView(payload: payload)
    cardView.onOpen = { [weak self] in self?.finish(action: "open") }
    cardView.onDismiss = { [weak self] in self?.finish(action: "dismiss") }
    panel.contentView = cardView
    let targetFrame = frame(size: DeadlineReminderLayout.cardSize)
    if animated {
      let startFrame = targetFrame.offsetBy(
        dx: DeadlineReminderLayout.slideOffset,
        dy: 0
      )
      panel.setFrame(startFrame, display: false)
      panel.alphaValue = 0
      panel.orderFrontRegardless()
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.18
        context.timingFunction = CAMediaTimingFunction(name: .easeOut)
        panel.animator().setFrame(targetFrame, display: true)
        panel.animator().alphaValue = 1
      }
    } else {
      panel.setFrame(targetFrame, display: true)
      panel.alphaValue = 1
      panel.orderFrontRegardless()
    }
    collapseTimer = Timer.scheduledTimer(
      withTimeInterval: 12,
      repeats: false
    ) { [weak self] _ in
      self?.collapseToPill()
    }
  }

  private func collapseToPill() {
    guard currentPayload != nil else {
      return
    }
    collapseTimer?.invalidate()
    let count = queue.count + 1
    let pill = DeadlineReminderPillView(count: count)
    pill.onOpen = { [weak self] in
      guard let self, let payload = self.currentPayload else {
        return
      }
      self.showCard(payload, animated: false)
    }
    panel.contentView = pill
    isShowingPill = true
    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.16
      context.timingFunction = CAMediaTimingFunction(name: .easeOut)
      panel.animator().setFrame(
        collapsedPillFrame(),
        display: true
      )
    }
  }

  private func finish(action: String) {
    guard let payload = currentPayload else {
      return
    }
    collapseTimer?.invalidate()
    isShowingPill = false
    let arguments: [String: Any] = [
      "action": action,
      "todoId": payload.todoId,
    ]
    onAction(arguments)
    currentPayload = nil
    NSAnimationContext.runAnimationGroup(
      { context in
        context.duration = 0.12
        panel.animator().alphaValue = 0
      },
      completionHandler: { [weak self] in
        guard let self else {
          return
        }
        self.panel.orderOut(nil)
        self.panel.alphaValue = 1
        self.showNextIfNeeded()
      }
    )
  }

  private func frame(size: NSSize) -> NSRect {
    let mouseLocation = NSEvent.mouseLocation
    let mouseScreenVisibleFrame = NSScreen.screens.first {
      NSMouseInRect(mouseLocation, $0.frame, false)
    }?.visibleFrame
    let visibleFrame = usableVisibleFrame(mouseScreenVisibleFrame)
      ?? usableVisibleFrame(visibleFrameProvider())
      ?? usableVisibleFrame(NSScreen.main?.visibleFrame)
      ?? usableVisibleFrame(NSScreen.screens.first?.visibleFrame)
      ?? NSRect(origin: .zero, size: size)
    return DeadlineReminderLayout.cardFrame(
      size: size,
      within: visibleFrame
    )
  }

  private func collapsedPillFrame() -> NSRect {
    guard let iconFrame = collapsedIconFrameProvider() else {
      return frame(size: DeadlineReminderLayout.pillSize)
    }
    let iconCenter = NSPoint(x: iconFrame.midX, y: iconFrame.midY)
    let iconScreenVisibleFrame = NSScreen.screens.first {
      $0.frame.contains(iconCenter)
    }?.visibleFrame
    let visibleFrame = usableVisibleFrame(iconScreenVisibleFrame)
      ?? usableVisibleFrame(visibleFrameProvider())
      ?? usableVisibleFrame(NSScreen.main?.visibleFrame)
      ?? NSRect(origin: iconFrame.origin, size: DeadlineReminderLayout.pillSize)
    return DeadlineReminderLayout.pillFrame(
      anchoredTo: iconFrame,
      within: visibleFrame
    )
  }

  private func usableVisibleFrame(_ frame: NSRect?) -> NSRect? {
    guard let frame, frame.width > 0, frame.height > 0 else {
      return nil
    }
    return frame
  }
}

final class DeadlineReminderCardView: NSView {
  private enum ActionIdentifier {
    static let open = NSUserInterfaceItemIdentifier("deadline-reminder-open")
  }

  var onOpen: (() -> Void)?
  var onDismiss: (() -> Void)?

  init(payload: DeadlineReminderPayload) {
    super.init(
      frame: NSRect(origin: .zero, size: DeadlineReminderLayout.cardSize)
    )
    wantsLayer = true
    layer?.backgroundColor = NSColor(
      calibratedRed: 25 / 255,
      green: 33 / 255,
      blue: 36 / 255,
      alpha: 0.98
    ).cgColor
    layer?.cornerRadius = 11
    layer?.borderWidth = 1
    layer?.borderColor = NSColor.white.withAlphaComponent(0.11).cgColor
    layer?.masksToBounds = true

    let accentColor = NSColor(
      calibratedRed: 34 / 255,
      green: 184 / 255,
      blue: 167 / 255,
      alpha: 1
    )
    let accentRail = NSView()
    accentRail.translatesAutoresizingMaskIntoConstraints = false
    accentRail.wantsLayer = true
    accentRail.layer?.backgroundColor = accentColor.cgColor

    let statusIcon = NSImageView()
    statusIcon.translatesAutoresizingMaskIntoConstraints = false
    statusIcon.image = Self.symbolImage(
      named: "alarm",
      accessibilityDescription: nil,
      pointSize: 13,
      weight: .regular
    )
    statusIcon.imageScaling = .scaleProportionallyDown
    statusIcon.contentTintColor = accentColor
    statusIcon.setAccessibilityElement(false)

    let nowLabel = makeLabel(NativeCopy.now, size: 9.5, weight: .regular)
    nowLabel.textColor = NSColor.white.withAlphaComponent(0.43)
    let closeButton = iconButton(
      symbolName: "xmark",
      fallbackTitle: "×",
      accessibilityLabel: NativeCopy.dismiss,
      action: #selector(closePressed)
    )

    let titleLabel = makeLabel(payload.title, size: 13.5, weight: .semibold)
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.maximumNumberOfLines = 1

    let duePrefix = payload.isOverdue ? NativeCopy.overdue : NativeCopy.due
    var metadata = "\(duePrefix) \(payload.dueLabel)"
    if let tagLabel = payload.tagLabel, !tagLabel.isEmpty {
      metadata += "  ·  \(tagLabel)"
    }
    let metadataLabel = makeLabel(metadata, size: 10, weight: .regular)
    metadataLabel.textColor = payload.isOverdue
      ? NSColor(calibratedRed: 241 / 255, green: 120 / 255, blue: 66 / 255, alpha: 1)
      : NSColor.white.withAlphaComponent(0.48)

    let openButton = DeadlineReminderActionButton(
      symbolName: "arrow.up.right",
      fallbackTitle: "↗",
      accessibilityLabel: NativeCopy.open,
      identifier: ActionIdentifier.open,
      target: self,
      action: #selector(openPressed)
    )

    [accentRail, statusIcon, nowLabel, closeButton, titleLabel,
     metadataLabel, openButton].forEach(addSubview)

    NSLayoutConstraint.activate([
      accentRail.leadingAnchor.constraint(equalTo: leadingAnchor),
      accentRail.topAnchor.constraint(equalTo: topAnchor),
      accentRail.bottomAnchor.constraint(equalTo: bottomAnchor),
      accentRail.widthAnchor.constraint(equalToConstant: 3),

      statusIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
      statusIcon.topAnchor.constraint(equalTo: topAnchor, constant: 12),
      statusIcon.widthAnchor.constraint(equalToConstant: 18),
      statusIcon.heightAnchor.constraint(equalToConstant: 18),

      nowLabel.leadingAnchor.constraint(equalTo: statusIcon.trailingAnchor, constant: 7),
      nowLabel.centerYAnchor.constraint(equalTo: statusIcon.centerYAnchor),
      nowLabel.trailingAnchor.constraint(
        lessThanOrEqualTo: closeButton.leadingAnchor,
        constant: -8
      ),
      closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      closeButton.centerYAnchor.constraint(equalTo: statusIcon.centerYAnchor),
      closeButton.widthAnchor.constraint(equalToConstant: 24),
      closeButton.heightAnchor.constraint(equalToConstant: 24),

      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
      titleLabel.topAnchor.constraint(equalTo: statusIcon.bottomAnchor, constant: 8),
      metadataLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      metadataLabel.trailingAnchor.constraint(lessThanOrEqualTo: titleLabel.trailingAnchor),
      metadataLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),

      openButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      openButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
      openButton.widthAnchor.constraint(equalToConstant: 30),
      openButton.heightAnchor.constraint(equalToConstant: 30),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("DeadlineReminderCardView is created programmatically.")
  }

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

  @objc private func openPressed() { onOpen?() }
  @objc private func closePressed() { onDismiss?() }

  private func makeLabel(
    _ text: String,
    size: CGFloat,
    weight: NSFont.Weight
  ) -> NSTextField {
    let label = NSTextField(labelWithString: text)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: size, weight: weight)
    label.textColor = NSColor.white.withAlphaComponent(0.92)
    return label
  }

  private func iconButton(
    symbolName: String,
    fallbackTitle: String,
    accessibilityLabel: String,
    action: Selector
  ) -> NSButton {
    let button = NSButton(title: "", target: self, action: action)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.isBordered = false
    button.contentTintColor = NSColor.white.withAlphaComponent(0.58)
    if let image = Self.symbolImage(
      named: symbolName,
      accessibilityDescription: accessibilityLabel,
      pointSize: 12,
      weight: .medium
    ) {
      button.image = image
      button.imagePosition = .imageOnly
      button.imageScaling = .scaleProportionallyDown
    } else {
      button.title = fallbackTitle
      button.font = .systemFont(ofSize: 17, weight: .regular)
    }
    button.toolTip = accessibilityLabel
    button.setAccessibilityLabel(accessibilityLabel)
    return button
  }

  private static func symbolImage(
    named symbolName: String,
    accessibilityDescription: String?,
    pointSize: CGFloat,
    weight: NSFont.Weight
  ) -> NSImage? {
    guard #available(macOS 11.0, *) else {
      return nil
    }
    let configuration = NSImage.SymbolConfiguration(
      pointSize: pointSize,
      weight: weight
    )
    return NSImage(
      systemSymbolName: symbolName,
      accessibilityDescription: accessibilityDescription
    )?.withSymbolConfiguration(configuration)
  }
}

private final class DeadlineReminderActionButton: NSButton {
  private var pointerTrackingArea: NSTrackingArea?

  init(
    symbolName: String,
    fallbackTitle: String,
    accessibilityLabel: String,
    identifier: NSUserInterfaceItemIdentifier,
    target: AnyObject?,
    action: Selector
  ) {
    super.init(frame: .zero)
    self.identifier = identifier
    self.target = target
    self.action = action
    translatesAutoresizingMaskIntoConstraints = false
    isBordered = false
    wantsLayer = true
    layer?.cornerRadius = 6
    layer?.borderWidth = 0
    if #available(macOS 11.0, *),
      let image = NSImage(
        systemSymbolName: symbolName,
        accessibilityDescription: accessibilityLabel
      )?.withSymbolConfiguration(
        NSImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
      )
    {
      self.image = image
      imagePosition = .imageOnly
      imageScaling = .scaleProportionallyDown
      title = ""
    } else {
      title = fallbackTitle
      font = .systemFont(ofSize: 17, weight: .semibold)
    }
    toolTip = accessibilityLabel
    setAccessibilityLabel(accessibilityLabel)
    applyAppearance(isHovered: false)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("DeadlineReminderActionButton is created programmatically.")
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let pointerTrackingArea {
      removeTrackingArea(pointerTrackingArea)
    }
    let trackingArea = NSTrackingArea(
      rect: bounds,
      options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(trackingArea)
    pointerTrackingArea = trackingArea
  }

  override func mouseEntered(with event: NSEvent) {
    applyAppearance(isHovered: true)
  }

  override func mouseExited(with event: NSEvent) {
    applyAppearance(isHovered: false)
  }

  override func resetCursorRects() {
    addCursorRect(bounds, cursor: .pointingHand)
  }

  private func applyAppearance(isHovered: Bool) {
    let iconColor = NSColor(
      calibratedRed: 34 / 255,
      green: 184 / 255,
      blue: 167 / 255,
      alpha: isHovered ? 1 : 0.92
    )
    layer?.backgroundColor = iconColor.withAlphaComponent(
      isHovered ? 0.16 : 0
    ).cgColor
    contentTintColor = iconColor
    layer?.borderWidth = 0
    if image == nil {
      attributedTitle = NSAttributedString(
        string: title,
        attributes: [
          .font: NSFont.systemFont(ofSize: 17, weight: .semibold),
          .foregroundColor: iconColor,
        ]
      )
    }
  }
}

private final class DeadlineReminderPillView: NSView {
  var onOpen: (() -> Void)?

  init(count: Int) {
    super.init(
      frame: NSRect(origin: .zero, size: DeadlineReminderLayout.pillSize)
    )
    wantsLayer = true
    layer?.backgroundColor = NSColor(
      calibratedRed: 29 / 255,
      green: 37 / 255,
      blue: 41 / 255,
      alpha: 0.98
    ).cgColor
    layer?.cornerRadius = 9
    layer?.borderWidth = 1
    layer?.borderColor = NSColor.white.withAlphaComponent(0.10).cgColor
    let dot = NSView()
    dot.translatesAutoresizingMaskIntoConstraints = false
    dot.wantsLayer = true
    dot.layer?.cornerRadius = 2.5
    dot.layer?.backgroundColor = NSColor(
      calibratedRed: 34 / 255,
      green: 184 / 255,
      blue: 167 / 255,
      alpha: 1
    ).cgColor
    let labelText = NativeCopy.overdueCount(count)
    let label = NSTextField(labelWithString: labelText)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 10.5, weight: .semibold)
    label.textColor = NSColor(
      calibratedRed: 34 / 255,
      green: 184 / 255,
      blue: 167 / 255,
      alpha: 1
    )
    let stack = NSStackView(views: [dot, label])
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.orientation = .horizontal
    stack.alignment = .centerY
    stack.spacing = 6
    addSubview(stack)
    setAccessibilityElement(true)
    setAccessibilityRole(.button)
    setAccessibilityLabel(labelText)
    NSLayoutConstraint.activate([
      dot.widthAnchor.constraint(equalToConstant: 5),
      dot.heightAnchor.constraint(equalToConstant: 5),
      stack.centerXAnchor.constraint(equalTo: centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("DeadlineReminderPillView is created programmatically.")
  }

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

  override func mouseDown(with event: NSEvent) {
    onOpen?()
  }

  override func resetCursorRects() {
    addCursorRect(bounds, cursor: .pointingHand)
  }

  override func accessibilityPerformPress() -> Bool {
    onOpen?()
    return true
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

  static var now: String { usesChinese ? "刚刚" : "now" }
  static var due: String { usesChinese ? "截止" : "Due" }
  static var overdue: String { usesChinese ? "逾期" : "Overdue" }
  static var open: String { usesChinese ? "打开" : "Open" }
  static var dismiss: String { usesChinese ? "关闭" : "Dismiss" }

  static func overdueCount(_ count: Int) -> String {
    if usesChinese {
      return "\(count) 个提醒"
    }
    return count == 1 ? "1 reminder" : "\(count) reminders"
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
