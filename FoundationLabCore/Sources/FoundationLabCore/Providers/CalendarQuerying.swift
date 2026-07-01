import Foundation
import FoundationModelsKit

public protocol CalendarQuerying: Sendable {
    func queryCalendar(for request: QueryCalendarRequest) async throws -> FoundationModelTextGenerationResult
}
