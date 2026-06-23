//
//  ToolCallingExperimentMode.swift
//  FoundationLab
//

import Foundation
#if compiler(>=6.4)
import FoundationModels
#endif

nonisolated enum ToolCallingExperimentMode: String, CaseIterable, Identifiable, Sendable {
    case allowed
    case required
    case disallowed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .allowed:
            String(localized: "Allowed")
        case .required:
            String(localized: "Required")
        case .disallowed:
            String(localized: "Disallowed")
        }
    }

    var explanation: String {
        switch self {
        case .allowed:
            String(localized: "The model may call the local tool, but the mode does not guarantee a call.")
        case .required:
            String(
                localized: "The first generation step requires a tool call; the profile then switches to allowed so the model can answer."
            )
        case .disallowed:
            String(localized: "The tool remains registered, but the model is prevented from calling it for this response.")
        }
    }

    var code: String {
        if self == .required {
            return Self.requiredCode
        }

        return """
        let profile = LanguageModelSession.Profile {
            Instructions("Use the read-only local record when it is available.")
            LocalReleaseRecordTool(recorder: recorder)
        }
        .toolCallingMode(.\(rawValue))

        let session = LanguageModelSession(profile: profile)
        let response = try await session.respond(to: prompt)
        inspect(session.transcript)
        """
    }

    #if compiler(>=6.4)
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    var frameworkValue: GenerationOptions.ToolCallingMode {
        switch self {
        case .allowed:
            .allowed
        case .required:
            .required
        case .disallowed:
            .disallowed
        }
    }
    #endif

    private static let requiredCode = """
    extension SessionPropertyValues {
        @SessionPropertyEntry
        var toolCallingLabCallCount = 0
    }

    struct RequiredToolProfile: LanguageModelSession.DynamicProfile {
        let tool: LocalReleaseRecordTool

        @SessionProperty(\\.toolCallingLabCallCount)
        private var callCount

        var body: some LanguageModelSession.DynamicProfile {
            LanguageModelSession.Profile { tool }
                .toolCallingMode(callCount == 0 ? .required : .allowed)
                .onToolCall { callCount += 1 }
        }
    }

    let session = LanguageModelSession(profile: RequiredToolProfile(tool: tool))
    let response = try await session.respond(to: prompt)
    inspect(session.transcript)
    """
}
