import FoundationLabCore
import XCTest

final class FoundationLabToolTrajectoryEvaluationTests: XCTestCase {
    private let expected = [
        FoundationLabToolTrajectoryEvaluation.Call(
            id: "expected",
            name: "readFoundationLabFact",
            arguments: #"{"topic":"transcript"}"#
        )
    ]

    func testExactMatchCanonicalizesJSONFormatting() {
        let observed = [
            FoundationLabToolTrajectoryEvaluation.Call(
                id: "observed",
                name: "readFoundationLabFact",
                arguments: #"{ "topic" : "transcript" }"#
            )
        ]

        let result = FoundationLabToolTrajectoryEvaluation(
            expected: expected,
            observed: observed,
            forbiddenToolNames: ["deleteItem", "sendMessage"]
        )

        XCTAssertEqual(result.verdict, .exactMatch)
        XCTAssertTrue(result.mismatches.isEmpty)
        XCTAssertTrue(result.extraCalls.isEmpty)
        XCTAssertTrue(result.missingCalls.isEmpty)
    }

    func testArgumentsMismatchIsReportedAtObservedPosition() {
        let observed = [
            FoundationLabToolTrajectoryEvaluation.Call(
                id: "observed",
                name: "readFoundationLabFact",
                arguments: #"{"topic":"privacy"}"#
            )
        ]

        let result = FoundationLabToolTrajectoryEvaluation(
            expected: expected,
            observed: observed,
            forbiddenToolNames: []
        )

        XCTAssertEqual(result.verdict, .differentPath)
        XCTAssertEqual(result.mismatches.map(\.kind), [.arguments])
        XCTAssertEqual(result.mismatches.map(\.position), [0])
    }

    func testExtraCallIsNotCollapsedIntoANameMismatch() {
        let repeated = expected + [
            FoundationLabToolTrajectoryEvaluation.Call(
                id: "extra",
                name: "readFoundationLabFact",
                arguments: #"{"topic":"transcript"}"#
            )
        ]

        let result = FoundationLabToolTrajectoryEvaluation(
            expected: expected,
            observed: repeated,
            forbiddenToolNames: []
        )

        XCTAssertEqual(result.verdict, .differentPath)
        XCTAssertEqual(result.extraCalls.map(\.id), ["extra"])
        XCTAssertTrue(result.mismatches.isEmpty)
    }

    func testForbiddenCallTakesPriorityOverOtherDifferences() {
        let observed = [
            FoundationLabToolTrajectoryEvaluation.Call(
                id: "forbidden",
                name: "deleteItem",
                arguments: "{}"
            )
        ]

        let result = FoundationLabToolTrajectoryEvaluation(
            expected: expected,
            observed: observed,
            forbiddenToolNames: ["deleteItem"]
        )

        XCTAssertEqual(result.verdict, .forbiddenCall)
        XCTAssertEqual(result.forbiddenCalls.map(\.name), ["deleteItem"])
        XCTAssertEqual(result.mismatches.map(\.kind), [.toolName])
    }
}
