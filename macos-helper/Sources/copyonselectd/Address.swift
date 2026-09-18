import Darwin
import Foundation

/// Builds the `sockaddr_un` for the control socket.
func controlAddress() -> sockaddr_un {
  var addr = sockaddr_un()
  addr.sun_family = sa_family_t(AF_UNIX)
  let limit = MemoryLayout.size(ofValue: addr.sun_path) - 1
  withUnsafeMutablePointer(to: &addr.sun_path) { path in
    let dst = UnsafeMutableRawPointer(path).assumingMemoryBound(to: CChar.self)
    Support.socketPath.withCString { strncpy(dst, $0, limit) }
  }
  return addr
}
