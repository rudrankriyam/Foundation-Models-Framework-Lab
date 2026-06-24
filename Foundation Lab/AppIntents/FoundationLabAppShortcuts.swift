//
//  FoundationLabAppShortcuts.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/25/25.
//

import AppIntents

nonisolated struct FoundationLabAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GenerateBookRecommendationIntent(),
            phrases: [
                "Recommend a book in \(.applicationName)",
                "Get a book recommendation from \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Recommend Book", table: "Localizable"),
            systemImageName: "book.closed.fill"
        )
        AppShortcut(
            intent: GetWeatherIntent(),
            phrases: [
                "Get the weather in \(.applicationName)",
                "Check weather with \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Get Weather", table: "Localizable"),
            systemImageName: "cloud.sun.fill"
        )
        AppShortcut(
            intent: AnalyzeNutritionIntent(),
            phrases: [
                "Estimate meal nutrition in \(.applicationName)",
                "Get a meal estimate with \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Estimate Nutrition", table: "Localizable"),
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: SearchWebIntent(),
            phrases: [
                "Search the web in \(.applicationName)",
                "Look something up with \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Search Web", table: "Localizable"),
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: SearchContactsIntent(),
            phrases: [
                "Search contacts in \(.applicationName)",
                "Find someone with \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Search Contacts", table: "Localizable"),
            systemImageName: "person.crop.circle"
        )
        AppShortcut(
            intent: QueryCalendarIntent(),
            phrases: [
                "Check my calendar in \(.applicationName)",
                "Ask calendar with \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Query Calendar", table: "Localizable"),
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: ManageRemindersIntent(),
            phrases: [
                "Manage reminders in \(.applicationName)",
                "Create a reminder with \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Manage Reminders", table: "Localizable"),
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: GetCurrentLocationIntent(),
            phrases: [
                "Get my location in \(.applicationName)",
                "Check location with \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Get Location", table: "Localizable"),
            systemImageName: "location"
        )
        AppShortcut(
            intent: SearchMusicCatalogIntent(),
            phrases: [
                "Search music in \(.applicationName)",
                "Find music with \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Search Music", table: "Localizable"),
            systemImageName: "music.note"
        )
        AppShortcut(
            intent: QueryHealthDataIntent(),
            phrases: [
                "Read health data in \(.applicationName)",
                "Ask about health data with \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Read Health Data", table: "Localizable"),
            systemImageName: "heart.text.square"
        )
    }
}
