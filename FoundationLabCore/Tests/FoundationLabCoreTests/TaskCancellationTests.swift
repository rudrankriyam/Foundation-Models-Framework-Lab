import XCTest
@testable import FoundationLabCore

final class TaskCancellationTests: XCTestCase {
    func testValuePropagatesCallerCancellationToOwnedTask() async {
        let ownedTask = Task<Void, Error> {
            try await Task.sleep(for: .seconds(30))
        }
        let caller = Task<Void, Error> {
            try await ownedTask.valuePropagatingCancellation()
        }

        await Task.yield()
        caller.cancel()

        do {
            try await caller.value
            XCTFail("Expected caller cancellation to throw")
        } catch is CancellationError {
            XCTAssertTrue(ownedTask.isCancelled)
        } catch {
            XCTFail("Expected CancellationError, received \(error)")
        }
    }
}
