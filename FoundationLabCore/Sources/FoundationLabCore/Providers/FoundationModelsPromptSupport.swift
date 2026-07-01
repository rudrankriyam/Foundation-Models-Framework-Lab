import Foundation
import FoundationModelsKit

enum FoundationModelsPromptSupport {
    static func combinedSystemPrompt(_ parts: [String?]) -> String? {
        let combined = parts
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        return combined.isEmpty ? nil : combined
    }

    static func resolvedTimeZone(identifier: String) -> TimeZone {
        TimeZone(identifier: identifier) ?? .current
    }

    static func isoTimestamp(_ date: Date, timeZoneIdentifier: String) -> String {
        let timeZone = resolvedTimeZone(identifier: timeZoneIdentifier)
        let formatter = Date.ISO8601FormatStyle(
            includingFractionalSeconds: false,
            timeZone: timeZone
        )
        return date.formatted(formatter)
    }

    static func displayDate(
        _ date: Date,
        timeZoneIdentifier: String,
        localeIdentifier: String?
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.timeZone = resolvedTimeZone(identifier: timeZoneIdentifier)
        if let localeIdentifier {
            formatter.locale = Locale(identifier: localeIdentifier)
        }
        return formatter.string(from: date)
    }

    static func reminderDateString(_ date: Date, timeZoneIdentifier: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = resolvedTimeZone(identifier: timeZoneIdentifier)
        return formatter.string(from: date)
    }

    static func isoDayString(_ date: Date, timeZoneIdentifier: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = resolvedTimeZone(identifier: timeZoneIdentifier)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
