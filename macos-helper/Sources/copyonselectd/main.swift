import ApplicationServices
import Darwin
import Foundation
import IOKit.hid

// --selftest reports the permission and event-tap situation, then exits. It never daemonizes.
if CommandLine.arguments.contains("--selftest") {
  let ax = AXIsProcessTrusted()
  let hid = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
  let tap = Monitor().start()
  print(#"{"ax":\#(ax),"inputMonitoring":\#(hid),"tap":\#(tap)}"#)
  exit(0)
}

Support.makeDir()

/// Sends one request to an existing daemon. Returns nil when nothing answers.
func probe(_ command: String) -> String? {
  let fd = socket(AF_UNIX, SOCK_STREAM, 0)
  guard fd >= 0 else { return nil }
  defer { close(fd) }
  var addr = controlAddress()
  var timeout = timeval(tv_sec: 1, tv_usec: 0)
  setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
  let ok = withUnsafePointer(to: &addr) {
    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) == 0 }
  }
  guard ok else { return nil }
  _ = "{\"cmd\":\"\(command)\"}\n".withCString { write(fd, $0, strlen($0)) }
  var buf = [UInt8](repeating: 0, count: 1024)
  let n = read(fd, &buf, buf.count)
  guard n > 0 else { return nil }
  return String(bytes: buf[0..<n], encoding: .utf8)
}

// Single instance: a live daemon already owns the socket, so this process is redundant.
if probe("status") != nil { exit(0) }
unlink(Support.socketPath)

let listener = socket(AF_UNIX, SOCK_STREAM, 0)
guard listener >= 0 else { Support.log("listen_failed", "socket"); exit(1) }
var addr = controlAddress()
let bound = withUnsafePointer(to: &addr) {
  $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(listener, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) == 0 }
}
guard bound, listen(listener, 8) == 0 else { Support.log("listen_failed", "bind"); exit(1) }
chmod(Support.socketPath, 0o600)
Support.log("started")
State.shared.restore()

DispatchQueue.global().async {
  while true {
    let client = accept(listener, nil, nil)
    guard client >= 0 else { continue }
    var buf = [UInt8](repeating: 0, count: 1024)
    let n = read(client, &buf, buf.count)
    var reply = State.shared.handle("").json
    if n > 0,
       let text = String(bytes: buf[0..<n], encoding: .utf8),
       let data = text.data(using: .utf8),
       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let cmd = obj["cmd"] as? String {
      reply = State.shared.handle(cmd).json
    }
    _ = reply.withCString { write(client, $0, strlen($0)) }
    close(client)
  }
}

// Clean up the socket so a stale file never blocks the next launch.
for sig in [SIGTERM, SIGINT] {
  signal(sig, SIG_IGN)
  let src = DispatchSource.makeSignalSource(signal: sig, queue: .main)
  src.setEventHandler { unlink(Support.socketPath); exit(0) }
  src.resume()
  signalSources.append(src)
}

CFRunLoopRun()
