import Foundation

/// Pure selection-gesture classifier. No macOS event types, so it is unit-testable.
public struct Gesture {
  public enum Input {
    case down(x: Double, y: Double, clickCount: Int)
    case dragged(x: Double, y: Double)
    case up(x: Double, y: Double, clickCount: Int)
  }

  public enum Candidate: Equatable { case drag, multiClick }

  /// Pointer travel, in points, that separates a click from a drag-selection.
  public static let dragThreshold = 6.0

  private var origin: (x: Double, y: Double)?
  private var movedEnough = false
  private var downClicks = 0

  public init() {}

  public mutating func reset() {
    origin = nil
    movedEnough = false
    downClicks = 0
  }

  public mutating func handle(_ input: Input) -> Candidate? {
    switch input {
    case let .down(x, y, clicks):
      origin = (x, y)
      movedEnough = false
      downClicks = clicks
      return nil

    case let .dragged(x, y):
      guard let o = origin, !movedEnough else { return nil }
      movedEnough = hypot(x - o.x, y - o.y) > Self.dragThreshold
      return nil

    case let .up(x, y, clicks):
      guard let o = origin else { return nil }
      let moved = movedEnough || hypot(x - o.x, y - o.y) > Self.dragThreshold
      let clickCount = max(clicks, downClicks)
      reset()
      if moved { return .drag }
      if clickCount >= 2 { return .multiClick }
      return nil
    }
  }
}

/// Identifies one copied selection, so the same selection is not copied again.
/// It holds no text: only the process, the character range, and the pasteboard counter.
public struct Selection: Equatable {
  public let pid: Int32
  public let location: Int
  public let length: Int
  public let changeCount: Int

  public init(pid: Int32, location: Int, length: Int, changeCount: Int) {
    self.pid = pid
    self.location = location
    self.length = length
    self.changeCount = changeCount
  }

  /// A repeat of the last copy is skipped, so repeated clicks do not fill the clipboard
  /// history. A different pasteboard counter means something else copied since, so the
  /// same selection is allowed to copy again.
  public func repeats(_ last: Selection?) -> Bool {
    guard let last else { return false }
    return last.pid == pid && last.location == location && last.length == length
      && last.changeCount == changeCount
  }
}
