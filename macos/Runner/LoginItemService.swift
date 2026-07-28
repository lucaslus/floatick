import FlutterMacOS
import ServiceManagement

final class LoginItemService {
  private enum Status: String {
    case disabled
    case enabled
    case requiresApproval
    case unsupported
  }

  private var channel: FlutterMethodChannel?

  func configure(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "floatick/login_item",
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "login_item_unavailable",
            message: "The Floatick login item service is unavailable.",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case "loadStatus":
        result(self.currentStatus().rawValue)
      case "setEnabled":
        guard let enabled = call.arguments as? Bool else {
          result(
            FlutterError(
              code: "invalid_argument",
              message: "setEnabled expects a Boolean argument.",
              details: nil
            )
          )
          return
        }
        do {
          result(try self.setEnabled(enabled).rawValue)
        } catch {
          result(
            FlutterError(
              code: "login_item_update_failed",
              message: "Floatick could not update its login item.",
              details: nil
            )
          )
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  private func currentStatus() -> Status {
    guard #available(macOS 13.0, *) else {
      return .unsupported
    }
    return status(for: SMAppService.mainApp)
  }

  @available(macOS 13.0, *)
  private func status(for service: SMAppService) -> Status {
    switch service.status {
    case .enabled:
      return .enabled
    case .requiresApproval:
      return .requiresApproval
    case .notFound, .notRegistered:
      return .disabled
    @unknown default:
      return .disabled
    }
  }

  private func setEnabled(_ enabled: Bool) throws -> Status {
    guard #available(macOS 13.0, *) else {
      return .unsupported
    }

    let service = SMAppService.mainApp
    if enabled {
      switch service.status {
      case .enabled, .requiresApproval:
        break
      case .notFound, .notRegistered:
        try service.register()
      @unknown default:
        try service.register()
      }
    } else {
      switch service.status {
      case .enabled, .requiresApproval:
        try service.unregister()
      case .notFound, .notRegistered:
        break
      @unknown default:
        try service.unregister()
      }
    }
    return status(for: service)
  }
}
