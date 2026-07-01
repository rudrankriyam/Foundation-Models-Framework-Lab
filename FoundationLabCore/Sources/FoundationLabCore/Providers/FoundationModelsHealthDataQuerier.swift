import Foundation
import FoundationModelsTools
import FoundationModelsKit

public struct FoundationModelsHealthDataQuerier: HealthDataQuerying {
    private let toolInvoker: FoundationModelsToolInvoker

    public init(toolInvoker: FoundationModelsToolInvoker = FoundationModelsToolInvoker()) {
        self.toolInvoker = toolInvoker
    }

    public func queryHealthData(for request: QueryHealthDataRequest) async throws -> FoundationModelTextGenerationResult {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing query")
        }

        let calendar = Calendar.current
        let today = request.referenceDate
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let todayString = FoundationModelsPromptSupport.isoDayString(
            today,
            timeZoneIdentifier: request.timeZoneIdentifier
        )
        let yesterdayString = FoundationModelsPromptSupport.isoDayString(
            yesterday,
            timeZoneIdentifier: request.timeZoneIdentifier
        )
        let weekAgoString = FoundationModelsPromptSupport.isoDayString(
            weekAgo,
            timeZoneIdentifier: request.timeZoneIdentifier
        )

        let healthPrompt = """
        \(query)

        Today's date is: \(todayString)

        Please use the Health tool (`accessHealth`) with the appropriate `dataType`, `startDate`, and `endDate`
        based on the query above.

        Important:
        - Do NOT include an `action` argument (the tool does not support it).
        - `dataType` must be one of: steps, heartRate, workouts, sleep, activeEnergy, distance.

        IMPORTANT: Pay attention to time periods in the query:
        - "today" means use startDate="\(todayString)" and endDate="\(todayString)"
        - "yesterday" means use startDate="\(yesterdayString)" and endDate="\(yesterdayString)"
        - "this week" means last 7 days: startDate="\(weekAgoString)" and endDate="\(todayString)"
        - If no time period specified, default to last 7 days: startDate="\(weekAgoString)" and endDate="\(todayString)"

        Examples:
        - steps today: dataType="steps", startDate="\(todayString)", endDate="\(todayString)"
        - heartRate (last 7 days): dataType="heartRate", startDate="\(weekAgoString)", endDate="\(todayString)"
        - workouts (last 7 days): dataType="workouts", startDate="\(weekAgoString)", endDate="\(todayString)"
        - sleep (last 7 days): dataType="sleep", startDate="\(weekAgoString)", endDate="\(todayString)"
        - activeEnergy (last 7 days): dataType="activeEnergy", startDate="\(weekAgoString)", endDate="\(todayString)"
        - distance (last 7 days): dataType="distance", startDate="\(weekAgoString)", endDate="\(todayString)"
        """

        return try await toolInvoker.respond(
            to: healthPrompt,
            using: HealthTool(),
            systemPrompt: request.systemPrompt,
            modelUseCase: request.modelUseCase,
            guardrails: request.guardrails
        )
    }
}
