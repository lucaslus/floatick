import Cocoa
import XCTest
@testable import Floatick

class RunnerTests: XCTestCase {

  func testCollapsedIconIsAnAccessibleButton() {
    let overlay = CollapsedDragOverlayView(
      frame: NSRect(x: 0, y: 0, width: 72, height: 72)
    )

    XCTAssertTrue(overlay.isAccessibilityElement())
    XCTAssertEqual(overlay.accessibilityRole(), .button)
    XCTAssertFalse((overlay.accessibilityLabel() ?? "").isEmpty)
  }

  func testAccessibilityPressExpandsTheApp() {
    let overlay = CollapsedDragOverlayView(
      frame: NSRect(x: 0, y: 0, width: 72, height: 72)
    )
    var pressCount = 0
    overlay.onClick = {
      pressCount += 1
    }

    XCTAssertTrue(overlay.accessibilityPerformPress())
    XCTAssertEqual(pressCount, 1)
  }

  func testDefaultFloatingIconOriginUsesBottomRightOfVisibleFrame() {
    let visibleFrame = NSRect(x: 100, y: 50, width: 1_200, height: 800)

    let origin = MainFlutterWindow.defaultCollapsedOrigin(in: visibleFrame)

    XCTAssertEqual(origin.x, 1_204)
    XCTAssertEqual(origin.y, 74)
  }

  func testReminderPillAnchorsAboveFloatingIcon() {
    let iconFrame = NSRect(x: 1_100, y: 80, width: 72, height: 72)
    let visibleFrame = NSRect(x: 0, y: 0, width: 1_440, height: 900)

    let pillFrame = DeadlineReminderLayout.pillFrame(
      anchoredTo: iconFrame,
      within: visibleFrame
    )

    XCTAssertEqual(pillFrame.midX, iconFrame.midX)
    XCTAssertEqual(
      pillFrame.minY,
      iconFrame.maxY + DeadlineReminderLayout.pillSpacing
    )
  }

  func testReminderPillFallsBelowIconAtTopScreenEdge() {
    let iconFrame = NSRect(x: 1_340, y: 828, width: 72, height: 72)
    let visibleFrame = NSRect(x: 0, y: 0, width: 1_440, height: 900)

    let pillFrame = DeadlineReminderLayout.pillFrame(
      anchoredTo: iconFrame,
      within: visibleFrame
    )

    XCTAssertEqual(
      pillFrame.minY,
      iconFrame.minY
        - DeadlineReminderLayout.pillSize.height
        - DeadlineReminderLayout.pillSpacing
    )
    XCTAssertLessThanOrEqual(
      pillFrame.maxX,
      visibleFrame.maxX - DeadlineReminderLayout.pillScreenInset
    )
  }

  func testDeadlineReminderCardUsesTopRightOfVisibleFrame() {
    let visibleFrame = NSRect(x: -1_440, y: 24, width: 1_440, height: 876)

    let cardFrame = DeadlineReminderLayout.cardFrame(
      size: DeadlineReminderLayout.cardSize,
      within: visibleFrame
    )

    XCTAssertEqual(
      cardFrame.maxX,
      visibleFrame.maxX - DeadlineReminderLayout.screenInset
    )
    XCTAssertEqual(
      cardFrame.maxY,
      visibleFrame.maxY - DeadlineReminderLayout.screenInset
    )
  }

  func testDeadlineReminderCardCanBeConstructedWithActionButtons() {
    guard
      let payload = DeadlineReminderPayload(
        arguments: [
          "notificationId": "todo-1:deadline:card",
          "todoId": "todo-1",
          "title": "Test reminder",
          "dueLabel": "Due now",
          "isOverdue": true,
          "isAdvanceReminder": false,
        ]
      )
    else {
      XCTFail("Expected a valid deadline reminder payload.")
      return
    }

    let card = DeadlineReminderCardView(payload: payload)

    XCTAssertEqual(card.frame.size, DeadlineReminderLayout.cardSize)
  }

  func testDeadlineReminderCardUsesOnlyBorderlessOpenAction() {
    guard
      let payload = DeadlineReminderPayload(
        arguments: [
          "notificationId": "todo-1:deadline:icon-actions",
          "todoId": "todo-1",
          "title": "Test reminder",
          "dueLabel": "Due now",
          "isOverdue": false,
          "isAdvanceReminder": false,
        ]
      )
    else {
      XCTFail("Expected a valid deadline reminder payload.")
      return
    }
    let card = DeadlineReminderCardView(payload: payload)
    XCTAssertNil(button(with: "deadline-reminder-complete", in: card))
    XCTAssertNil(button(with: "deadline-reminder-snooze", in: card))
    guard let openButton = button(with: "deadline-reminder-open", in: card)
    else {
      XCTFail("Expected the open action button.")
      return
    }
    XCTAssertEqual(openButton.title, "")
    XCTAssertNotNil(openButton.image)
    XCTAssertFalse(openButton.isBordered)
    XCTAssertEqual(openButton.layer?.borderWidth, 0)
    XCTAssertFalse((openButton.toolTip ?? "").isEmpty)
    XCTAssertFalse((openButton.accessibilityLabel() ?? "").isEmpty)
  }

  func testNativeReminderSchedulerDeliversWhileFlutterWindowIsInactive() {
    var now = Date(timeIntervalSince1970: 1_786_329_600)
    guard
      let entry = ScheduledDeadlineReminderEntry(
        arguments: scheduledReminderArguments(
          notificationId: "todo-1:deadline:1786329660000000",
          payloadNotificationId: "todo-1:deadline:1786329660000000",
          triggerAt: now.addingTimeInterval(60)
        )
      )
    else {
      XCTFail("Expected a valid scheduled reminder entry.")
      return
    }
    var deliveredNotificationIds: [String] = []
    let scheduler = DeadlineReminderNativeScheduler(
      nowProvider: { now },
      onDue: { deliveredNotificationIds.append($0.notificationId) }
    )

    scheduler.replace(with: [entry])
    XCTAssertTrue(deliveredNotificationIds.isEmpty)

    now.addTimeInterval(61)
    scheduler.processDueReminders()

    XCTAssertEqual(
      deliveredNotificationIds,
      ["todo-1:deadline:1786329660000000"]
    )

    scheduler.replace(with: [entry])
    scheduler.processDueReminders()
    XCTAssertEqual(deliveredNotificationIds.count, 1)
    scheduler.cancel()
  }

  func testNativeReminderTimerFiresWhileWindowRemainsHidden() {
    let hiddenWindow = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 200, height: 120),
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    hiddenWindow.orderOut(nil)
    let notificationId = "todo-1:deadline:hidden-window"
    guard
      let entry = ScheduledDeadlineReminderEntry(
        arguments: scheduledReminderArguments(
          notificationId: notificationId,
          payloadNotificationId: notificationId,
          triggerAt: Date().addingTimeInterval(0.15)
        )
      )
    else {
      XCTFail("Expected a valid scheduled reminder entry.")
      return
    }
    let deliveryExpectation = expectation(
      description: "The native timer fires while the window stays hidden."
    )
    let scheduler = DeadlineReminderNativeScheduler { deliveredEntry in
      XCTAssertEqual(deliveredEntry.notificationId, notificationId)
      XCTAssertFalse(hiddenWindow.isVisible)
      deliveryExpectation.fulfill()
    }

    scheduler.replace(with: [entry])

    wait(for: [deliveryExpectation], timeout: 1)
    XCTAssertFalse(hiddenWindow.isVisible)
    scheduler.cancel()
  }

  func testScheduledReminderRejectsMismatchedNotificationId() {
    let entry = ScheduledDeadlineReminderEntry(
      arguments: scheduledReminderArguments(
        notificationId: "outer-id",
        payloadNotificationId: "payload-id",
        triggerAt: Date(timeIntervalSince1970: 1_786_329_660)
      )
    )

    XCTAssertNil(entry)
  }

  func testFloatingIconAttentionAnimationIncludesScaleAndGlow() {
    let iconView = FloatingTodoIconView(
      frame: NSRect(x: 0, y: 0, width: 72, height: 72),
      activeCount: 2
    )

    iconView.playAttentionAnimation(reduceMotion: false)

    let iconAnimation = iconView.layer?.animation(
      forKey: "floatick-attention-icon"
    ) as? CAAnimationGroup
    let iconKeyPaths = iconAnimation?.animations?
      .compactMap { ($0 as? CAPropertyAnimation)?.keyPath }
    let glowAnimation = iconView.attentionGlowLayer.animation(
      forKey: "floatick-attention-glow"
    ) as? CAAnimationGroup
    let glowKeyPaths = glowAnimation?.animations?
      .compactMap { ($0 as? CAPropertyAnimation)?.keyPath }

    XCTAssertEqual(Set(iconKeyPaths ?? []), Set(["transform.scale"]))
    XCTAssertEqual(Set(glowKeyPaths ?? []), Set(["opacity"]))
  }

  func testFloatingIconGlowFitsInsideTransparentWindowBoundary() {
    let iconView = FloatingTodoIconView(
      frame: NSRect(x: 0, y: 0, width: 72, height: 72),
      activeCount: 2
    )

    let glowLayer = iconView.attentionGlowLayer
    let glowBounds = glowLayer.shadowPath?.boundingBox ?? .zero
    let maximumVisibleRadius = (
      (glowBounds.width / 2)
        + (glowLayer.lineWidth / 2)
        + glowLayer.shadowRadius
    ) * 1.1

    XCTAssertEqual(
      glowBounds,
      NSRect(x: 11.5, y: 11.5, width: 49, height: 49)
    )
    XCTAssertTrue(
      glowLayer.path?.contains(CGPoint(x: 36, y: 36)) == true
    )
    XCTAssertTrue(
      glowLayer.path?.contains(CGPoint(x: 11.5, y: 11.5)) == false
    )
    XCTAssertLessThan(maximumVisibleRadius, iconView.bounds.width / 2)
    XCTAssertNil(iconView.layer?.shadowPath)
  }

  func testFloatingIconAttentionRespectsReducedMotion() {
    let iconView = FloatingTodoIconView(
      frame: NSRect(x: 0, y: 0, width: 72, height: 72),
      activeCount: 0
    )

    iconView.playAttentionAnimation(reduceMotion: true)

    let glowAnimation = iconView.attentionGlowLayer.animation(
      forKey: "floatick-attention-glow"
    ) as? CAAnimationGroup
    let glowKeyPaths = glowAnimation?.animations?
      .compactMap { ($0 as? CAPropertyAnimation)?.keyPath }

    XCTAssertNil(
      iconView.layer?.animation(forKey: "floatick-attention-icon")
    )
    XCTAssertEqual(Set(glowKeyPaths ?? []), Set(["opacity"]))
  }

  private func scheduledReminderArguments(
    notificationId: String,
    payloadNotificationId: String,
    triggerAt: Date
  ) -> [String: Any] {
    [
      "notificationId": notificationId,
      "triggerAtMilliseconds": NSNumber(
        value: triggerAt.timeIntervalSince1970 * 1_000
      ),
      "deliveryKind": "deadline",
      "payload": [
        "notificationId": payloadNotificationId,
        "todoId": "todo-1",
        "title": "Test reminder",
        "dueLabel": "Due now",
        "isOverdue": false,
        "isAdvanceReminder": false,
      ],
    ]
  }

  private func button(with identifier: String, in view: NSView) -> NSButton? {
    if
      let button = view as? NSButton,
      button.identifier?.rawValue == identifier
    {
      return button
    }
    for subview in view.subviews {
      if let button = button(with: identifier, in: subview) {
        return button
      }
    }
    return nil
  }
}
