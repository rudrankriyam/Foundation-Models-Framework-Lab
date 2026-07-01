import Foundation
import FoundationModelsTools
import FoundationModelsKit

public struct FoundationModelsCalendarQuerier: CalendarQuerying {
    private let toolInvoker: FoundationModelsToolInvoker

    public init(toolInvoker: FoundationModelsToolInvoker = FoundationModelsToolInvoker()) {
        self.toolInvoker = toolInvoker
    }

    public func queryCalendar(for request: QueryCalendarRequest) async throws -> FoundationModelTextGenerationResult {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing query")
        }

        let localeIdentifier = request.context.localeIdentifier ?? Locale.current.identifier
        let timeZone = FoundationModelsPromptSupport.resolvedTimeZone(identifier: request.timeZoneIdentifier)
        let currentTimestamp = FoundationModelsPromptSupport.isoTimestamp(
            request.referenceDate,
            timeZoneIdentifier: request.timeZoneIdentifier
        )
        let contextualInstructions = """
        The user's current time zone is \(timeZone.identifier).
        The user's current locale identifier is \(localeIdentifier).
        The current local date and time is \(currentTimestamp).
        Use this information when interpreting relative dates like "today" or "tomorrow".
        """

        return try await toolInvoker.respond(
            to: query,
            using: CalendarTool(),
            systemPrompt: FoundationModelsPromptSupport.combinedSystemPrompt([
                request.systemPrompt,
                contextualInstructions
            ]),
            modelUseCase: request.modelUseCase,
            guardrails: request.guardrails
        )
    }
}
