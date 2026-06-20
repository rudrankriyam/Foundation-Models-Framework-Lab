import Foundation

public struct FMFBenchSample: Codable, Identifiable, Sendable {
    public let id: String
    public let prompt: String
    public let checks: [FMFBenchCheck]
    public let visualFixture: FMFBenchVisualFixture?
    public let safetyExpectation: FMFBenchSafetyExpectation?

    public init(
        id: String,
        prompt: String,
        checks: [FMFBenchCheck],
        visualFixture: FMFBenchVisualFixture? = nil,
        safetyExpectation: FMFBenchSafetyExpectation? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.checks = checks
        self.visualFixture = visualFixture
        self.safetyExpectation = safetyExpectation
    }
}

public struct FMFBenchScenario: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let category: FMFBenchScenarioCategory
    public let inspiredBy: [String]
    public let instructions: String
    public let outputMode: FMFBenchOutputMode
    public let maximumResponseTokens: Int
    public let toolSet: FMFBenchToolSet
    public let requiresOS27: Bool
    public let samples: [FMFBenchSample]

    public var prompt: String { samples.first?.prompt ?? "" }
    public var checks: [FMFBenchCheck] { samples.first?.checks ?? [] }

    public init(
        id: String,
        title: String,
        summary: String,
        category: FMFBenchScenarioCategory,
        inspiredBy: [String],
        instructions: String,
        prompt: String,
        outputMode: FMFBenchOutputMode,
        maximumResponseTokens: Int,
        checks: [FMFBenchCheck],
        toolSet: FMFBenchToolSet = .none,
        requiresOS27: Bool = false
    ) {
        self.init(
            id: id,
            title: title,
            summary: summary,
            category: category,
            inspiredBy: inspiredBy,
            instructions: instructions,
            outputMode: outputMode,
            maximumResponseTokens: maximumResponseTokens,
            toolSet: toolSet,
            requiresOS27: requiresOS27,
            samples: [.init(id: "\(id)-001", prompt: prompt, checks: checks)]
        )
    }

    public init(
        id: String,
        title: String,
        summary: String,
        category: FMFBenchScenarioCategory,
        inspiredBy: [String],
        instructions: String,
        outputMode: FMFBenchOutputMode,
        maximumResponseTokens: Int,
        toolSet: FMFBenchToolSet = .none,
        requiresOS27: Bool = false,
        samples: [FMFBenchSample]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.category = category
        self.inspiredBy = inspiredBy
        self.instructions = instructions
        self.outputMode = outputMode
        self.maximumResponseTokens = maximumResponseTokens
        self.toolSet = toolSet
        self.requiresOS27 = requiresOS27
        self.samples = samples
    }
}
