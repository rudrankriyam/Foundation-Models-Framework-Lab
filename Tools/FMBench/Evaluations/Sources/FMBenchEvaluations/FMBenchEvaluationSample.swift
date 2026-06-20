import Evaluations
import FoundationModels

@available(macOS 27.0, *)
public struct FMBenchEvaluationSample:
  ModelSampleProtocol,
  Codable,
  Sendable {
  public typealias Expectation = TrajectoryExpectation

  public let recordID: String
  public let input: ModelSampleInput
  public let output: ModelSampleOutput<String, TrajectoryExpectation>

  public var expected: String? {
    output.value
  }

  public var promptDescription: String {
    input.promptDescription
  }

  public var generationSchema: GenerationSchema? {
    input.generationSchema
  }

  public init(
    recordID: String,
    prompt: Prompt,
    instructions: Instructions? = nil,
    generationSchema: GenerationSchema? = nil,
    expectations: TrajectoryExpectation? = nil
  ) {
    self.recordID = recordID
    input = ModelSampleInput(
      prompt: prompt,
      instructions: instructions,
      generationSchema: generationSchema
    )
    output = ModelSampleOutput(
      value: nil,
      expectations: expectations
    )
  }
}
