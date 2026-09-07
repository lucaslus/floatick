import Cocoa
import FlutterMacOS
import Sparkle

final class UpdateService {
  private static let feedRequestTimeout: TimeInterval = 8

  private let updaterController: SPUStandardUpdaterController
  private var channel: FlutterMethodChannel?

  init() {
    updaterController = SPUStandardUpdaterController(
      startingUpdater: true,
      updaterDelegate: nil,
      userDriverDelegate: nil
    )
  }

  func configure(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "floatick/update",
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "updater_unavailable",
            message: "The Floatick updater is no longer available.",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case "loadSettings":
        result(self.settingsSnapshot())
      case "setAutomaticallyChecksForUpdates":
        guard let enabled = call.arguments as? Bool else {
          result(
            FlutterError(
              code: "invalid_argument",
              message:
                "setAutomaticallyChecksForUpdates expects a Boolean argument.",
              details: nil
            )
          )
          return
        }
        self.updaterController.updater.automaticallyChecksForUpdates = enabled
        result(nil)
      case "checkForUpdates":
        self.checkForUpdates(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  private func checkForUpdates(result: @escaping FlutterResult) {
    let updater = updaterController.updater
    guard updater.canCheckForUpdates else {
      result(
        FlutterError(
          code: "updater_not_ready",
          message: "Floatick cannot check for updates right now.",
          details: nil
        )
      )
      return
    }
    guard let feedURL = updater.feedURL else {
      result(
        FlutterError(
          code: "update_feed_unavailable",
          message: "The Floatick update feed is not available yet.",
          details: nil
        )
      )
      return
    }

    var request = URLRequest(url: feedURL)
    request.httpMethod = "HEAD"
    request.cachePolicy = .reloadIgnoringLocalCacheData
    request.timeoutInterval = Self.feedRequestTimeout

    URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
      DispatchQueue.main.async {
        guard let self else {
          result(
            FlutterError(
              code: "updater_unavailable",
              message: "The Floatick updater is no longer available.",
              details: nil
            )
          )
          return
        }

        if let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 404
        {
          result(
            FlutterError(
              code: "update_feed_unavailable",
              message: "The Floatick update feed is not available yet.",
              details: nil
            )
          )
          return
        }

        guard error == nil,
          let httpResponse = response as? HTTPURLResponse,
          (200..<300).contains(httpResponse.statusCode)
        else {
          result(
            FlutterError(
              code: "update_feed_request_failed",
              message: "Floatick could not reach the update feed.",
              details: nil
            )
          )
          return
        }

        guard self.updaterController.updater.canCheckForUpdates else {
          result(
            FlutterError(
              code: "updater_not_ready",
              message: "Floatick cannot check for updates right now.",
              details: nil
            )
          )
          return
        }

        NSApp.activate(ignoringOtherApps: true)
        self.updaterController.checkForUpdates(nil)
        result(nil)
      }
    }.resume()
  }

  private func settingsSnapshot() -> [String: Any] {
    let version =
      Bundle.main.object(
        forInfoDictionaryKey: "CFBundleShortVersionString"
      ) as? String ?? "—"
    return [
      "automaticallyChecksForUpdates":
        updaterController.updater.automaticallyChecksForUpdates,
      "currentVersion": version,
    ]
  }
}
