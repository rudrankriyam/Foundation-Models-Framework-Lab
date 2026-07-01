import Foundation
import FoundationModelsKit

public struct FoundationLabExperimentConfiguration: Codable, Hashable, Sendable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case summary
        case prompt
        case instructions
        case kind
        case modelRuntime
        case reasoningLevel
        case generationOptions
        case selectedTools
        case createdAt
        case modifiedAt
    }

    public var id: UUID
    public var name: String
    public var summary: String
    public var prompt: String
    public var instructions: String
    public var kind: FoundationLabExperimentKind
    public var modelRuntime: FoundationModelRuntime
    public var reasoningLevel: FoundationModelReasoningLevel
    public var generationOptions: FoundationModelGenerationOptions
    public var selectedTools: [FoundationLabBuiltInTool]
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        summary: String = "",
        prompt: String = "",
        instructions: String = "",
        kind: FoundationLabExperimentKind = .conversation,
        modelRuntime: FoundationModelRuntime = .onDevice,
        reasoningLevel: FoundationModelReasoningLevel = .none,
        generationOptions: FoundationModelGenerationOptions = FoundationModelGenerationOptions(),
        selectedTools: [FoundationLabBuiltInTool] = [],
        createdAt: Date = .now,
        modifiedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.prompt = prompt
        self.instructions = instructions
        self.kind = kind
        self.modelRuntime = modelRuntime
        self.reasoningLevel = reasoningLevel
        self.generationOptions = generationOptions
        self.selectedTools = selectedTools
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt ?? createdAt
        normalize()
    }

    public func asNewExperiment(at date: Date = .now) -> FoundationLabExperimentConfiguration {
        var copy = self
        copy.id = UUID()
        copy.createdAt = date
        copy.modifiedAt = date
        copy.normalize()
        return copy
    }

    /// Returns a copy that is safe to execute and persist.
    ///
    /// Public stored properties intentionally remain mutable for SwiftUI bindings, so callers
    /// crossing an execution or persistence boundary should use this normalized value.
    public var normalized: FoundationLabExperimentConfiguration {
        var copy = self
        copy.normalize()
        return copy
    }

    /// Repairs combinations that Foundation Models cannot execute and removes invalid option values.
    public mutating func normalize() {
        if modelRuntime == .onDevice {
            reasoningLevel = .none
        }

        selectedTools = Self.uniqued(selectedTools)
        generationOptions = Self.normalized(generationOptions)

        if !createdAt.timeIntervalSinceReferenceDate.isFinite {
            createdAt = .now
        }
        if !modifiedAt.timeIntervalSinceReferenceDate.isFinite || modifiedAt < createdAt {
            modifiedAt = createdAt
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? .now

        self.init(
            id: (try? container.decode(UUID.self, forKey: .id)) ?? UUID(),
            name: (try? container.decode(String.self, forKey: .name)) ?? "Untitled Experiment",
            summary: (try? container.decode(String.self, forKey: .summary)) ?? "",
            prompt: (try? container.decode(String.self, forKey: .prompt)) ?? "",
            instructions: (try? container.decode(String.self, forKey: .instructions)) ?? "",
            kind: (try? container.decode(FoundationLabExperimentKind.self, forKey: .kind)) ?? .conversation,
            modelRuntime: (try? container.decode(FoundationModelRuntime.self, forKey: .modelRuntime)) ?? .onDevice,
            reasoningLevel: (try? container.decode(FoundationModelReasoningLevel.self, forKey: .reasoningLevel)) ?? .none,
            generationOptions: (try? container.decode(FoundationModelGenerationOptions.self, forKey: .generationOptions))
                ?? FoundationModelGenerationOptions(),
            selectedTools: (try? container.decode([FoundationLabBuiltInTool].self, forKey: .selectedTools)) ?? [],
            createdAt: createdAt,
            modifiedAt: try? container.decode(Date.self, forKey: .modifiedAt)
        )
    }

    private static func uniqued(_ tools: [FoundationLabBuiltInTool]) -> [FoundationLabBuiltInTool] {
        var seenTools: Set<FoundationLabBuiltInTool> = []
        return tools.filter { seenTools.insert($0).inserted }
    }

    private static func normalized(
        _ options: FoundationModelGenerationOptions
    ) -> FoundationModelGenerationOptions {
        let sampling: FoundationModelGenerationOptions.SamplingMode?
        switch options.sampling {
        case .greedy:
            sampling = .greedy
        case .randomTop(let top, let seed):
            sampling = .randomTop(max(1, top), seed: seed)
        case .randomProbabilityThreshold(let threshold, let seed):
            let validThreshold = threshold.isFinite ? min(max(threshold, 0), 1) : 0.9
            sampling = .randomProbabilityThreshold(validThreshold, seed: seed)
        case nil:
            sampling = nil
        }

        let temperature = options.temperature.flatMap { value in
            value.isFinite ? min(max(0, value), 2) : nil
        }
        let maximumResponseTokens = options.maximumResponseTokens.flatMap { value in
            value > 0 ? value : nil
        }

        return FoundationModelGenerationOptions(
            sampling: sampling,
            temperature: temperature,
            maximumResponseTokens: maximumResponseTokens
        )
    }
}
