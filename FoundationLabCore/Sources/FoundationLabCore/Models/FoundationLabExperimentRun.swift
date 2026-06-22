import Foundation
import FoundationModelsKit

public struct FoundationLabExperimentRun: Codable, Hashable, Sendable, Identifiable {
    public enum Status: String, Codable, Hashable, Sendable {
        case succeeded
        case failed
        case cancelled
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case configuration
        case prompt
        case response
        case startedAt
        case duration
        case provider
        case modelIdentifier
        case tokenCount
        case tokenUsage
        case errorMessage
        case status
        case events
    }

    public let id: UUID
    public let configuration: FoundationLabExperimentConfiguration
    public let prompt: String
    public let response: String
    public let startedAt: Date
    public let duration: TimeInterval
    public let provider: String
    public let modelIdentifier: String
    public let tokenCount: Int?
    public let tokenUsage: ModelTokenUsage?
    public let errorMessage: String?
    public let status: Status
    public let events: [FoundationLabExperimentEvent]

    public var succeeded: Bool {
        status == .succeeded
    }

    public init(
        id: UUID = UUID(),
        configuration: FoundationLabExperimentConfiguration,
        prompt: String,
        response: String,
        startedAt: Date,
        duration: TimeInterval,
        provider: String,
        modelIdentifier: String,
        tokenCount: Int? = nil,
        tokenUsage: ModelTokenUsage? = nil,
        errorMessage: String? = nil,
        status: Status? = nil,
        events: [FoundationLabExperimentEvent]? = nil
    ) {
        var configurationSnapshot = configuration.normalized
        configurationSnapshot.prompt = prompt

        self.id = id
        self.configuration = configurationSnapshot
        self.prompt = prompt
        self.response = response
        self.startedAt = startedAt.timeIntervalSinceReferenceDate.isFinite
            ? startedAt
            : configurationSnapshot.modifiedAt
        self.duration = duration.isFinite ? max(0, duration) : 0
        self.provider = provider.isEmpty ? "Apple Foundation Models" : provider
        self.modelIdentifier = modelIdentifier.isEmpty
            ? Self.defaultModelIdentifier(for: configurationSnapshot.modelRuntime)
            : modelIdentifier
        self.tokenCount = tokenCount.flatMap { $0 >= 0 ? $0 : nil }
        self.tokenUsage = tokenUsage
        self.errorMessage = errorMessage
        self.status = status ?? (errorMessage == nil ? .succeeded : .failed)
        self.events = events ?? Self.defaultEvents(
            prompt: prompt,
            response: response,
            startedAt: self.startedAt
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let configuration = (try? container.decode(
            FoundationLabExperimentConfiguration.self,
            forKey: .configuration
        )) ?? FoundationLabExperimentConfiguration(name: "Untitled Experiment")
        let prompt = (try? container.decode(String.self, forKey: .prompt)) ?? configuration.prompt

        self.init(
            id: (try? container.decode(UUID.self, forKey: .id)) ?? UUID(),
            configuration: configuration,
            prompt: prompt,
            response: (try? container.decode(String.self, forKey: .response)) ?? "",
            startedAt: (try? container.decode(Date.self, forKey: .startedAt)) ?? configuration.modifiedAt,
            duration: (try? container.decode(TimeInterval.self, forKey: .duration)) ?? 0,
            provider: (try? container.decode(String.self, forKey: .provider)) ?? "Apple Foundation Models",
            modelIdentifier: (try? container.decode(String.self, forKey: .modelIdentifier))
                ?? Self.defaultModelIdentifier(for: configuration.modelRuntime),
            tokenCount: try? container.decode(Int.self, forKey: .tokenCount),
            tokenUsage: try? container.decode(ModelTokenUsage.self, forKey: .tokenUsage),
            errorMessage: try? container.decode(String.self, forKey: .errorMessage),
            status: try? container.decode(Status.self, forKey: .status),
            events: try? container.decode([FoundationLabExperimentEvent].self, forKey: .events)
        )
    }

    private static func defaultEvents(
        prompt: String,
        response: String,
        startedAt: Date
    ) -> [FoundationLabExperimentEvent] {
        var events = [
            FoundationLabExperimentEvent(
                role: .user,
                text: prompt,
                timestamp: startedAt
            )
        ]
        if !response.isEmpty {
            events.append(
                FoundationLabExperimentEvent(
                    role: .assistant,
                    text: response
                )
            )
        }
        return events
    }

    private static func defaultModelIdentifier(for runtime: FoundationLabModelRuntime) -> String {
        switch runtime {
        case .onDevice:
            "SystemLanguageModel"
        case .privateCloudCompute:
            "PrivateCloudComputeLanguageModel"
        }
    }
}
