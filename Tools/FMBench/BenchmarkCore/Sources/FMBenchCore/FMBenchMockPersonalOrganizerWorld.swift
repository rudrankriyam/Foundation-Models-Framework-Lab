import Foundation

actor FMBenchMockPersonalOrganizerWorld {
    enum ContactSearchOutcome: Sendable {
        case results([FMBenchPersonalOrganizerContact])
        case transientFailure
    }

    enum ReminderCreationOutcome: Sendable {
        case created(FMBenchPersonalOrganizerReminder)
        case duplicate(FMBenchPersonalOrganizerReminder)
        case hardFailure
    }

    private var contacts: [FMBenchPersonalOrganizerContact]
    private var reminders: [FMBenchPersonalOrganizerReminder]
    private var remainingSearchFailures: Int
    private var remainingCreateFailures: Int

    init() {
        let fixture = FMBenchPersonalOrganizerFixture.fixture(for: "personal-organizer-001")
        contacts = fixture.contacts
        reminders = fixture.reminders
        remainingSearchFailures = fixture.transientSearchFailures
        remainingCreateFailures = fixture.hardCreateFailures
    }

    func reset(for sampleID: String = "personal-organizer-001") {
        let fixture = FMBenchPersonalOrganizerFixture.fixture(for: sampleID)
        contacts = fixture.contacts
        reminders = fixture.reminders
        remainingSearchFailures = fixture.transientSearchFailures
        remainingCreateFailures = fixture.hardCreateFailures
    }

    func contacts(matching query: String) -> ContactSearchOutcome {
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

    func reminders(matchingTitle query: String) -> [FMBenchPersonalOrganizerReminder] {
        reminders.filter {
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

        let reminder = FMBenchPersonalOrganizerReminder(
            id: "reminder-\(reminders.count + 1)",
            title: title,
            dueDate: dueDate,
            notes: notes
        )
        reminders.append(reminder)
        return .created(reminder)
    }

    func snapshot() -> FMBenchStateSnapshot {
        var values: [String: FMBenchJSONValue] = [
            "reminders.count": .integer(reminders.count)
        ]
        if let latest = reminders.last {
            values["reminders.latest.id"] = .string(latest.id)
            values["reminders.latest.title"] = .string(latest.title)
            values["reminders.latest.dueDate"] = .string(latest.dueDate)
            values["reminders.latest.notes"] = .string(latest.notes)
        }
        return FMBenchStateSnapshot(values: values)
    }
}
