import Foundation
import FoundationModelsKit

public struct QueryCalendarUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "foundation-models.query-calendar",
        displayName: "Query Calendar",
        summary: "Queries calendar events using shared Foundation Models orchestration."
    )

    private let querier: any CalendarQuerying

    public init(querier: any CalendarQuerying = FoundationModelsCalendarQuerier()) {
        self.querier = querier
    }

    public func execute(_ request: QueryCalendarRequest) async throws -> FoundationModelTextGenerationResult {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing query")
        }

        return try await querier.queryCalendar(for: request)
    }
}
