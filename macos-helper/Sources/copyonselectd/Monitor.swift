import AppKit
import ApplicationServices
import CopyOnSelectCore
import CoreGraphics
import IOKit.hid

/// Owns the event tap, the gesture classifier, and the synthetic copy.
final class Monitor {
  /// Time allowed for the target application to commit its selection before the check.
  private static let settleDelay = 0.06
  /// A later click in the same burst supersedes an earlier one. macOS defines the interval.
  private static let multiClickWindow = max(NSEvent.doubleClickInterval, 0.3)
  /// Time for the target application to place the copy on the pasteboard.
  private static let pasteboardSettle = 0.15
  private static let axTimeout: Float = 0.25

  private var tap: CFMachPort?
  private var source: CFRunLoopSource?
  private var gesture = Gesture()
  private var work = DispatchQueue(label: "copyonselect.eligibility")
  private var retriedTap = false
  private var generation: UInt64 = 0
  /// Identity of the last copied selection, so the same selection is not copied twice.
  private var lastCopy: Selection?

  var isRunning: Bool { tap != nil }

  /// Diagnostic: runs the full eligibility, duplicate, and copy path against the frontmost
  /// application, exactly as a completed selection gesture does.
  func probe() {
    let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier
    work.async { [weak self] in self?.evaluate(.multiClick, pid) }
  }

  static var hasPermissions: Bool {
    AXIsProcessTrusted() && IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
  }

  static func requestPermissions() {
    _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)
    _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
  }

  @discardableResult
  func start() -> Bool {
    guard tap == nil else { return true }
    let mask = (1 << CGEventType.leftMouseDown.rawValue)
      | (1 << CGEventType.leftMouseDragged.rawValue)
      | (1 << CGEventType.leftMouseUp.rawValue)
    guard let tap = CGEvent.tapCreate(
      tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
      eventsOfInterest: CGEventMask(mask),
      callback: { _, type, event, ctx in
        Unmanaged<Monitor>.fromOpaque(ctx!).takeUnretainedValue().receive(type, event)
        return nil  // listen-only: the event is never modified or withheld
      },
      userInfo: Unmanaged.passUnretained(self).toOpaque()
    ) else {
      Support.log("tap_create_failed")
      return false
    }
    self.tap = tap
    source = CFMachPortCreateRunLoopSource(nil, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
    retriedTap = false
    Support.log("tap_started")
    return true
  }

  func stop() {
    guard let tap else { return }
    CGEvent.tapEnable(tap: tap, enable: false)
    if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
    CFMachPortInvalidate(tap)
    self.tap = nil
    source = nil
    gesture.reset()
    generation &+= 1
    lastCopy = nil
    Support.log("tap_stopped")
  }

  /// Runs inside the tap callback. It must return immediately and never block input.
  private func receive(_ type: CGEventType, _ event: CGEvent) {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      guard !retriedTap, Self.hasPermissions, let tap else { return stop() }
      retriedTap = true
      CGEvent.tapEnable(tap: tap, enable: true)
      Support.log("tap_reenabled")
      return
    }
    let p = event.location
    let clicks = Int(event.getIntegerValueField(.mouseEventClickState))
    let input: Gesture.Input
    switch type {
    case .leftMouseDown: input = .down(x: p.x, y: p.y, clickCount: clicks)
    case .leftMouseDragged: input = .dragged(x: p.x, y: p.y)
    case .leftMouseUp: input = .up(x: p.x, y: p.y, clickCount: clicks)
    default: return
    }
    guard let candidate = gesture.handle(input) else { return }
    let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier

    // A double- or triple-click arrives as a burst of separate gestures. Each click in the
    // burst selects more text than the last. Wait out the burst and copy only the final
    // selection, so one user gesture produces exactly one copy.
    generation &+= 1
    let mine = generation
    let delay = candidate == .multiClick ? Self.multiClickWindow : Self.settleDelay
    work.asyncAfter(deadline: .now() + delay) { [weak self] in
      guard let self, self.generation == mine else { return }
      self.evaluate(candidate, pid)
    }
  }

  /// Off the tap callback: confirm the target still has focus, then apply the safety gate.
  private func evaluate(_ candidate: Gesture.Candidate, _ pid: pid_t?) {
    guard let pid, AXIsProcessTrusted() else { return DispatchQueue.main.async { State.shared.permissionLost() } }
    guard NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else {
      return Support.log("candidate_cancelled", "focus_changed")
    }
    guard let range = eligibleRange(pid) else {
      return Support.log("candidate_skipped", String(describing: candidate))
    }
    // Only the pasteboard counter is read here, never the pasteboard content.
    let current = Selection(pid: pid, location: range.location, length: range.length,
                            changeCount: NSPasteboard.general.changeCount)
    guard !current.repeats(lastCopy) else { return Support.log("candidate_skipped", "duplicate") }
    postCopy()
    // The target application handles Command-C asynchronously. Record the pasteboard
    // counter once the copy lands, otherwise the stored value is always the previous one.
    work.asyncAfter(deadline: .now() + Self.pasteboardSettle) { [weak self] in
      self?.lastCopy = Selection(pid: pid, location: range.location, length: range.length,
                                 changeCount: NSPasteboard.general.changeCount)
    }
  }

  /// Fails closed: any Accessibility error, any secure field, or no selection evidence skips
  /// the copy. Returns the selected range so a repeat selection can be recognized.
  private func eligibleRange(_ pid: pid_t) -> CFRange? {
    let app = AXUIElementCreateApplication(pid)
    AXUIElementSetMessagingTimeout(app, Self.axTimeout)
    var focused: CFTypeRef?
    guard AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
          CFGetTypeID(focused) == AXUIElementGetTypeID()
    else { return nil }
    let element = focused as! AXUIElement

    // Reject a secure text field at the focused element or at any of four ancestors.
    var node: AXUIElement? = element
    for _ in 0..<5 {
      guard let current = node else { break }
      var subrole: CFTypeRef?
      if AXUIElementCopyAttributeValue(current, kAXSubroleAttribute as CFString, &subrole) == .success,
         (subrole as? String) == (kAXSecureTextFieldSubrole as String) {
        Support.log("candidate_skipped", "secure_field")
        return nil
      }
      var parent: CFTypeRef?
      guard AXUIElementCopyAttributeValue(current, kAXParentAttribute as CFString, &parent) == .success,
            CFGetTypeID(parent) == AXUIElementGetTypeID()
      else { break }
      node = (parent as! AXUIElement)
    }

    // Require positive evidence of a non-empty selection, without reading the text.
    var rangeValue: CFTypeRef?
    if AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeValue) == .success,
       CFGetTypeID(rangeValue) == AXValueGetTypeID() {
      var range = CFRange()
      if AXValueGetValue(rangeValue as! AXValue, .cfRange, &range) {
        return range.length > 0 ? range : nil
      }
    }
    var selected: CFTypeRef?
    if AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selected) == .success {
      // Length only. The value is never logged, stored, or inspected further.
      guard let length = (selected as? String)?.count, length > 0 else { return nil }
      return CFRange(location: -1, length: length)
    }
    return nil  // no usable selection metadata: skip rather than copy blindly
  }

  /// Posts one Command-C. The target application produces the pasteboard content, as it does for a real key press.
  private func postCopy() {
    let src = CGEventSource(stateID: .hidSystemState)
    guard let down = CGEvent(keyboardEventSource: src, virtualKey: 8, keyDown: true),
          let up = CGEvent(keyboardEventSource: src, virtualKey: 8, keyDown: false)
    else { return Support.log("copy_failed", "event_create") }
    down.flags = .maskCommand
    up.flags = .maskCommand
    down.post(tap: .cgSessionEventTap)
    up.post(tap: .cgSessionEventTap)
    Support.log("copy_posted")
  }
}
