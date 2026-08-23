import Foundation
import FoundationModels
import FoundationModelsTools
import FoundationModelsKit

public enum FoundationLabBuiltInTool: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case weather
    case web
    case contacts
    case calendar
    case reminders
    case location
    case health
    case music
    case webMetadata

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .weather:
            String(localized: "Weather")
        case .web:
            String(localized: "Web Search")
        case .contacts:
            String(localized: "Contacts")
        case .calendar:
            String(localized: "Calendar")
        case .reminders:
            String(localized: "Reminders")
        case .location:
            String(localized: "Location")
        case .health:
            String(localized: "Health")
        case .music:
            String(localized: "Music")
        case .webMetadata:
            String(localized: "Web Metadata")
        }
    }

    public var summary: String {
        switch self {
        case .weather:
            String(localized: "Look up current weather conditions for a city.")
        case .web:
            String(localized: "Search the web for current sources and information.")
        case .contacts:
            String(localized: "Search, read, and create contacts with permission.")
        case .calendar:
            String(localized: "Query, create, and update calendar events.")
        case .reminders:
            String(localized: "Create and manage reminders and reminder lists.")
        case .location:
            String(localized: "Use location, geocoding, place search, and distance calculations.")
        case .health:
            String(localized: "Read permitted activity and health information.")
        case .music:
            String(localized: "Search Apple Music and control playback.")
        case .webMetadata:
            String(localized: "Extract titles and preview metadata from web pages.")
        }
    }

    public var systemImage: String {
        switch self {
        case .weather:
            "cloud.sun"
        case .web:
            "globe"
        case .contacts:
            "person.crop.circle"
        case .calendar:
            "calendar"
        case .reminders:
            "checklist"
        case .location:
            "location"
        case .health:
            "heart.text.square"
        case .music:
            "music.note"
        case .webMetadata:
            "link"
        }
    }

    public var toolNames: [String] {
        switch self {
        case .weather:
            ["getWeather"]
        case .web:
            ["searchWeb"]
        case .contacts:
            ["manageContacts"]
        case .calendar:
            ["readCalendar", "mutateCalendar"]
        case .reminders:
            ["readReminders", "mutateReminders"]
        case .location:
            ["accessLocation"]
        case .health:
            ["accessHealth"]
        case .music:
            ["controlMusic"]
        case .webMetadata:
            ["getWebMetadata"]
        }
    }

    @MainActor
    public func makeTools(
        mutationConfirmation: (any ToolMutationConfirming)? = nil
    ) -> [any Tool] {
        switch self {
        case .weather:
            [WeatherTool()]
        case .web:
            [Search1WebSearchTool()]
        case .contacts:
            [ContactsTool()]
        case .calendar:
            calendarTools(mutationConfirmation: mutationConfirmation)
        case .reminders:
            reminderTools(mutationConfirmation: mutationConfirmation)
        case .location:
            [LocationTool()]
        case .health:
            [HealthTool()]
        case .music:
            [MusicTool()]
        case .webMetadata:
            [WebMetadataTool()]
        }
    }

    @MainActor
    private func calendarTools(
        mutationConfirmation: (any ToolMutationConfirming)?
    ) -> [any Tool] {
        let service = EventKitCalendarService()
        var tools: [any Tool] = [CalendarReadTool(service: service)]
        if let mutationConfirmation {
            tools.append(
                CalendarMutationTool(
                    service: service,
                    confirmation: mutationConfirmation
                )
            )
        }
        return tools
    }

    @MainActor
    private func reminderTools(
        mutationConfirmation: (any ToolMutationConfirming)?
    ) -> [any Tool] {
        let service = EventKitRemindersService()
        var tools: [any Tool] = [RemindersReadTool(service: service)]
        if let mutationConfirmation {
            tools.append(
                RemindersMutationTool(
                    service: service,
                    confirmation: mutationConfirmation
                )
            )
        }
        return tools
    }
}
