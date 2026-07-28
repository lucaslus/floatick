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
}
