import Foundation

enum Support {
  static let version = "1.0.0"

  static let dir: URL = FileManager.default
    .homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/CopyOnSelect", isDirectory: true)

  static let socketPath = dir.appendingPathComponent("control.sock").path
  static let statePath = dir.appendingPathComponent("state.json")
  static let logPath = dir.appendingPathComponent("copyonselect.log")

  static func makeDir() {
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
  }

  /// Reads the last explicitly chosen state. Defaults to off.
  static func loadEnabled() -> Bool {
    guard let data = try? Data(contentsOf: statePath),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return false }
    return obj["enabled"] as? Bool ?? false
  }

  /// Atomic write, so an abrupt termination never leaves an ambiguous state.
  static func saveEnabled(_ enabled: Bool) {
    let obj: [String: Any] = ["enabled": enabled, "schema": 1, "version": version]
    guard let data = try? JSONSerialization.data(withJSONObject: obj) else { return }
    try? data.write(to: statePath, options: .atomic)
  }

  private static let stamp: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
  }()

  /// Content-free diagnostics only. Never selected text, clipboard data, or app identity.
  static func log(_ event: String, _ code: String = "") {
    let line = "\(stamp.string(from: Date())) \(event)\(code.isEmpty ? "" : " code=\(code)") v=\(version)\n"
    if let size = try? FileManager.default.attributesOfItem(atPath: logPath.path)[.size] as? Int, size > 262_144 {
      try? Data().write(to: logPath)
    }
    guard let data = line.data(using: .utf8) else { return }
    if let fh = try? FileHandle(forWritingTo: logPath) {
      defer { try? fh.close() }
      _ = try? fh.seekToEnd()
      try? fh.write(contentsOf: data)
    } else {
      try? data.write(to: logPath)
    }
  }
}
