import Foundation

actor FMFBenchMockPersonalOrganizerWorld {
    enum ContactSearchOutcome: Sendable {
        case results([FMFBenchPersonalOrganizerContact])
        case transientFailure
    }

    enum ReminderCreationOutcome: Sendable {
        case created(FMFBenchPersonalOrganizerReminder)
        case duplicate(FMFBenchPersonalOrganizerReminder)
        case hardFailure
    }

    private var contacts: [FMFBenchPersonalOrganizerContact]
    private var reminders: [FMFBenchPersonalOrganizerReminder]
    private var remainingSearchFailures: Int
    private var remainingCreateFailures: Int

    init() {
        let fixture = FMFBenchPersonalOrganizerFixture.fixture(for: "personal-organizer-001")
        contacts = fixture.contacts
        reminders = fixture.reminders
        remainingSearchFailures = fixture.transientSearchFailures
        remainingCreateFailures = fixture.hardCreateFailures
    }

    func reset(for sampleID: String = "personal-organizer-001") {
        let fixture = FMFBenchPersonalOrganizerFixture.fixture(for: sampleID)
        contacts = fixture.contacts
        reminders = fixture.reminders
        remainingSearchFailures = fixture.transientSearchFailures
        remainingCreateFailures = fixture.hardCreateFailures
    }

    func contacts(matching query: String) -> ContactSearchOutcome {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return .results([])
        }

        if remainingSearchFailures > 0 {
            remainingSearchFailures -= 1
            return .transientFailure
        }

        let results = contacts.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || query.localizedCaseInsensitiveContains($0.name)
        }
        return .results(results)
    }

    func reminders(matchingTitle query: String) -> [FMFBenchPersonalOrganizerReminder] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return []
        }

        return reminders.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || query.localizedCaseInsensitiveContains($0.title)
        }
    }

    func createReminder(
        title: String,
        dueDate: String,
        notes: String
    ) -> ReminderCreationOutcome {
        if remainingCreateFailures > 0 {
            remainingCreateFailures -= 1
            return .hardFailure
        }

        if let duplicate = reminders.first(where: {
            $0.title.compare(title, options: [.caseInsensitive, .diacriticInsensitive])
                == .orderedSame && $0.dueDate == dueDate
        }) {
            return .duplicate(duplicate)
        }

        let reminder = FMFBenchPersonalOrganizerReminder(
            id: "reminder-\(reminders.count + 1)",
            title: title,
            dueDate: dueDate,
            notes: notes
        )
        reminders.append(reminder)
        return .created(reminder)
    }

    func snapshot() -> FMFBenchStateSnapshot {
        var values: [String: FMFBenchJSONValue] = [
            "reminders.count": .integer(reminders.count)
        ]
        if let latest = reminders.last {
            values["reminders.latest.id"] = .string(latest.id)
            values["reminders.latest.title"] = .string(latest.title)
            values["reminders.latest.dueDate"] = .string(latest.dueDate)
            values["reminders.latest.notes"] = .string(latest.notes)
        }
        return FMFBenchStateSnapshot(values: values)
    }
}
