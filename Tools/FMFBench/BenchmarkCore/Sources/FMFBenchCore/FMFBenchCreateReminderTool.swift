import Foundation
import FoundationModels
import FoundationModelsKit

@Generable
struct FMFBenchCreateReminderArguments: RuntimeCompatibleGenerable {
    @Guide(description: "A concise reminder title")
    let title: String

    @Guide(description: "The due date formatted exactly as YYYY-MM-DD HH:mm")
    let dueDate: String

    @Guide(description: "Reminder notes containing any requested contact information")
    let notes: String
}

struct FMFBenchCreateReminderTool: Tool {
    let name = "createReminder"
    let description = "Creates a reminder in the benchmark's synthetic reminder store."
    let world: FMFBenchMockPersonalOrganizerWorld
    let recorder: FMFBenchToolRecorder

    func call(arguments: FMFBenchCreateReminderArguments) async throws -> String {
        await recorder.record(
            FMFBenchToolCall(
                name: name,
                arguments: [
                    "title": .string(arguments.title),
                    "dueDate": .string(arguments.dueDate),
                    "notes": .string(arguments.notes)
                ]
            )
        )
        let outcome = await world.createReminder(
            title: arguments.title,
            dueDate: arguments.dueDate,
            notes: arguments.notes
        )
        switch outcome {
        case .created(let reminder):
            return "status=created; reminder_created=true; id=\(reminder.id)"
        case .duplicate(let reminder):
            return """
                status=duplicate; reminder_created=false; retryable=false
                existing_id=\(reminder.id)
                """
        case .hardFailure:
            return """
                status=error; code=write_denied; reminder_created=false; retryable=false
                Report that the reminder could not be created. Do not retry.
                """
        }
    }
}
