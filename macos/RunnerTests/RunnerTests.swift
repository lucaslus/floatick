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
}
