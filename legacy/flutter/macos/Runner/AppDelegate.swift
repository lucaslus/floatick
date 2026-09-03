import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    if let mainWindow = sender.windows.first(where: { $0 is MainFlutterWindow })
      as? MainFlutterWindow
    {
      return mainWindow.handleApplicationReopen()
    }
    return super.applicationShouldHandleReopen(
      sender,
      hasVisibleWindows: flag
    )
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
