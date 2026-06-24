import FoundationModels
import Testing
@testable import FoundationModelsKit

@Generable
private struct RuntimeCompatibilityPayload: RuntimeCompatibleGenerable {
  let value: String
}

@Suite("Generable Runtime Compatibility")
struct RuntimeCompatibleGenerableTests {
  @Test("Prompt and instruction witnesses execute on the installed runtime")
  func representationsUseClientWitnesses() {
    let payload = RuntimeCompatibilityPayload(value: "hello")

    #expect(!String(describing: payload.promptRepresentation).isEmpty)
    #expect(!String(describing: payload.instructionsRepresentation).isEmpty)
  }
}
