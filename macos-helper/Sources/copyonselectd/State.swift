import AppKit
import Foundation

/// Single owner of the enabled flag. Every mutation runs on one serial queue, so rapid
/// toggles produce one deterministic transition each.
final class State {
  static let shared = State()
  private let queue = DispatchQueue(label: "copyonselect.state")
  private let monitor = Monitor()
  private var enabled = false
  private var promptedOnce = false

  private init() {}

  func restore() {
    queue.sync {
      guard Support.loadEnabled(), Monitor.hasPermissions else { return }
      enabled = monitor.start()
    }
  }

  struct Reply {
    let ok: Bool
    let enabled: Bool
    let error: String?
    let message: String?

    var json: String {
      var obj: [String: Any] = ["ok": ok, "enabled": enabled, "version": Support.version,
                                "binaryVersion": Support.version]
      if let error { obj["error"] = error }
      if let message { obj["message"] = message }
      let data = (try? JSONSerialization.data(withJSONObject: obj)) ?? Data()
      return (String(data: data, encoding: .utf8) ?? "{}") + "\n"
    }
  }

  func handle(_ command: String) -> Reply {
    queue.sync {
      switch command {
      case "status":
        return Reply(ok: true, enabled: enabled, error: nil, message: nil)

      case "toggle":
        if enabled {
          monitor.stop()
          enabled = false
          Support.saveEnabled(false)
          return Reply(ok: true, enabled: false, error: nil, message: nil)
        }
        guard Monitor.hasPermissions else {
          if !promptedOnce {
            promptedOnce = true
            Monitor.requestPermissions()
            openSettings()
          }
          Support.log("toggle_denied", "permissions")
          return Reply(ok: false, enabled: false, error: "permissions",
                       message: "Grant Accessibility and Input Monitoring to copyonselectd in System Settings > Privacy & Security, then run the command again.")
        }
        guard monitor.start() else {
          return Reply(ok: false, enabled: false, error: "internal", message: "The event tap could not start.")
        }
        enabled = true
        Support.saveEnabled(true)
        return Reply(ok: true, enabled: true, error: nil, message: nil)

      default:
        return Reply(ok: false, enabled: enabled, error: "bad_request", message: "Unknown command.")
      }
    }
  }

  /// Accessibility was revoked while running. Tear down rather than run degraded.
  func permissionLost() {
    queue.async {
      guard self.enabled else { return }
      self.monitor.stop()
      self.enabled = false
      Support.saveEnabled(false)
      Support.log("disabled", "permission_revoked")
    }
  }

  private func openSettings() {
    for pane in ["Privacy_Accessibility", "Privacy_ListenEvent"] {
      if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") {
        NSWorkspace.shared.open(url)
      }
    }
  }
}
