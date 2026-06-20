import FMBenchEvaluations
import Evaluations
import Testing

@available(macOS 27.0, *)
private let attachmentEvaluation: FMBenchReplayEvaluation = {
  do {
    return try FMBenchReplayEvaluation(
      run: FMBenchRecordedRun(
        info: ["Purpose": "Verify Xcode evaluation attachment export"],
        records: [
          FMBenchEvaluationRecord(
            scenarioID: "attachment",
            scenarioTitle: "Attachment",
            sampleID: "attachment-001",
            prompt: "Return alpha.",
            instructions: "Return the requested word.",
            checks: [.contains("alpha")],
            response: "alpha",
            duration: 0.1,
            timeToFirstToken: 0.05,
            outputTokensPerSecond: 20
          )
        ]
      )
    )
  } catch {
    preconditionFailure("Invalid attachment evaluation fixture: \(error)")
  }
}()

@available(macOS 27.0, *)
@Test(
  "FMBench evaluation attachment",
  .evaluates(
    attachmentEvaluation,
    info: ["Purpose": "Verify Xcode evaluation attachment export"]
  )
)
func fmBenchEvaluationAttachment() async throws {
  let result = EvaluationContext.current.result
  #expect(
    result.aggregateValue(
      .mean(of: attachmentEvaluation.promptPass)
    ) == 1
  )
}
