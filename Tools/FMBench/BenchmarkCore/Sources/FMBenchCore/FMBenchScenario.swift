import Foundation

public struct FMBenchSample: Codable, Identifiable, Sendable {
    public let id: String
    public let prompt: String
    public let checks: [FMBenchCheck]
    public let visualFixture: FMBenchVisualFixture?
    public let safetyExpectation: FMBenchSafetyExpectation?

    public init(
        id: String,
        prompt: String,
        checks: [FMBenchCheck],
        visualFixture: FMBenchVisualFixture? = nil,
        safetyExpectation: FMBenchSafetyExpectation? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.checks = checks
        self.visualFixture = visualFixture
        self.safetyExpectation = safetyExpectation
    }
}

public struct FMBenchScenario: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let category: FMBenchScenarioCategory
    public let inspiredBy: [String]
    public let instructions: String
    public let outputMode: FMBenchOutputMode
    public let maximumResponseTokens: Int
    public let toolSet: FMBenchToolSet
    public let requiresOS27: Bool
    public let samples: [FMBenchSample]

    public var prompt: String { samples.first?.prompt ?? "" }
    public var checks: [FMBenchCheck] { samples.first?.checks ?? [] }

    public init(
        id: String,
        title: String,
        summary: String,
        category: FMBenchScenarioCategory,
        inspiredBy: [String],
        instructions: String,
        prompt: String,
        outputMode: FMBenchOutputMode,
        maximumResponseTokens: Int,
        checks: [FMBenchCheck],
        toolSet: FMBenchToolSet = .none,
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
        category: FMBenchScenarioCategory,
        inspiredBy: [String],
        instructions: String,
        outputMode: FMBenchOutputMode,
        maximumResponseTokens: Int,
        toolSet: FMBenchToolSet = .none,
        requiresOS27: Bool = false,
        samples: [FMBenchSample]
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
