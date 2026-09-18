import XCTest
@testable import CopyOnSelectCore

final class GestureTests: XCTestCase {
  /// Feed a whole gesture and collect every candidate it produces.
  private func run(_ inputs: [Gesture.Input]) -> [Gesture.Candidate] {
    var g = Gesture()
    return inputs.compactMap { g.handle($0) }
  }

  private func drag(from: Double, to: Double, clicks: Int = 1) -> [Gesture.Input] {
    [.down(x: from, y: 0, clickCount: clicks), .dragged(x: to, y: 0), .up(x: to, y: 0, clickCount: clicks)]
  }

  func testPlainClickProducesNothing() {
    XCTAssertEqual(run([.down(x: 10, y: 10, clickCount: 1), .up(x: 10, y: 10, clickCount: 1)]), [])
  }

  func testSubThresholdJitterProducesNothing() {
    XCTAssertEqual(run(drag(from: 0, to: Gesture.dragThreshold - 1)), [])
  }

  func testOverThresholdDragProducesOneDragCandidate() {
    XCTAssertEqual(run(drag(from: 0, to: Gesture.dragThreshold + 1)), [.drag])
  }

  func testBackwardDragProducesOneDragCandidate() {
    XCTAssertEqual(run(drag(from: 100, to: 0)), [.drag])
  }

  func testDoubleClickProducesMultiClickCandidate() {
    XCTAssertEqual(run([.down(x: 5, y: 5, clickCount: 2), .up(x: 5, y: 5, clickCount: 2)]), [.multiClick])
  }

  func testTripleClickProducesMultiClickCandidate() {
    XCTAssertEqual(run([.down(x: 5, y: 5, clickCount: 3), .up(x: 5, y: 5, clickCount: 3)]), [.multiClick])
  }

  func testDoubleClickThatDragsCountsAsDragOnly() {
    XCTAssertEqual(run(drag(from: 0, to: 80, clicks: 2)), [.drag])
  }

  func testStrayMouseUpAfterCompletedGestureProducesNothing() {
    var g = Gesture()
    _ = g.handle(.down(x: 0, y: 0, clickCount: 1))
    _ = g.handle(.dragged(x: 50, y: 0))
    XCTAssertEqual(g.handle(.up(x: 50, y: 0, clickCount: 1)), .drag)
    XCTAssertNil(g.handle(.up(x: 50, y: 0, clickCount: 1)))
  }

  func testDragEmitsAtMostOneCandidateAcrossManyDragEvents() {
    var inputs: [Gesture.Input] = [.down(x: 0, y: 0, clickCount: 1)]
    inputs += (1...20).map { .dragged(x: Double($0) * 5, y: 0) }
    inputs.append(.up(x: 100, y: 0, clickCount: 1))
    XCTAssertEqual(run(inputs), [.drag])
  }

  func testResetClearsInFlightGesture() {
    var g = Gesture()
    _ = g.handle(.down(x: 0, y: 0, clickCount: 1))
    _ = g.handle(.dragged(x: 90, y: 0))
    g.reset()
    XCTAssertNil(g.handle(.up(x: 90, y: 0, clickCount: 1)))
  }
}

final class SelectionTests: XCTestCase {
  private func sel(_ pid: Int32 = 1, _ loc: Int = 0, _ len: Int = 5, _ cc: Int = 10) -> Selection {
    Selection(pid: pid, location: loc, length: len, changeCount: cc)
  }

  func testFirstCopyIsNeverARepeat() {
    XCTAssertFalse(sel().repeats(nil))
  }

  func testIdenticalSelectionRepeats() {
    XCTAssertTrue(sel().repeats(sel()))
  }

  func testDifferentRangeDoesNotRepeat() {
    XCTAssertFalse(sel(1, 16, 7).repeats(sel(1, 0, 5)))
  }

  func testSameRangeInAnotherAppDoesNotRepeat() {
    XCTAssertFalse(sel(2).repeats(sel(1)))
  }

  func testSelectionRepeatsOnlyWhileTheClipboardIsUntouched() {
    // Something else copied in between, so the same selection must copy again.
    XCTAssertFalse(sel(1, 0, 5, 11).repeats(sel(1, 0, 5, 10)))
  }
}
