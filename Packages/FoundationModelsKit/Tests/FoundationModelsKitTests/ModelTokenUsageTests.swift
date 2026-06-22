import Foundation
import FoundationModels
import Testing
@testable import FoundationModelsKit

@Suite("Model Token Usage Tests")
struct ModelTokenUsageTests {
  @Test("Unavailable cached and reasoning counts stay absent through Codable")
  func unavailableDetailsStayAbsent() throws {
    let usage = ModelTokenUsage(
      inputTokenCount: 42,
      measurement: .tokenized
    )

    let data = try JSONEncoder().encode(usage)
    let object = try #require(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    let input = try #require(object["input"] as? [String: Any])

    #expect(input["totalTokenCount"] as? Int == 42)
    #expect(input["cachedTokenCount"] == nil)
    #expect(object["output"] == nil)
    #expect(object["totalTokenCount"] as? Int == 42)
    #expect(try JSONDecoder().decode(ModelTokenUsage.self, from: data) == usage)
  }

  @Test("Input and output totals are encoded with explicit provenance")
  func totalsAndProvenanceAreEncoded() throws {
    let usage = ModelTokenUsage(
      input: .init(totalTokenCount: 30, cachedTokenCount: 20),
      output: .init(totalTokenCount: 15, reasoningTokenCount: 4),
      measurement: .observed,
      scope: .response
    )

    let data = try JSONEncoder().encode(usage)
    let object = try #require(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )

    #expect(object["measurement"] as? String == "observed")
    #expect(object["scope"] as? String == "response")
    #expect(object["totalTokenCount"] as? Int == 45)
    #expect(try JSONDecoder().decode(ModelTokenUsage.self, from: data) == usage)
  }

  #if compiler(>=6.4)
  @Test("Observed zero cached and reasoning counts remain explicit")
  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  func observedZerosRemainExplicit() throws {
    let runtimeUsage = LanguageModelSession.Usage(
      input: .init(totalTokenCount: 8, cachedTokenCount: 0),
      output: .init(totalTokenCount: 3, reasoningTokenCount: 0)
    )
    let usage = ModelTokenUsage(observing: runtimeUsage)

    let data = try JSONEncoder().encode(usage)
    let object = try #require(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    let input = try #require(object["input"] as? [String: Any])
    let output = try #require(object["output"] as? [String: Any])

    #expect(input["cachedTokenCount"] as? Int == 0)
    #expect(output["reasoningTokenCount"] as? Int == 0)
    #expect(usage.measurement == .observed)
    #expect(usage.scope == .response)
  }
  #endif
}
