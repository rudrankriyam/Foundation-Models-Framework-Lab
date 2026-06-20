import Foundation
import FoundationModels

@Generable
struct FMBenchListRemindersArguments {
    @Guide(description: "The exact proposed reminder title")
    let title: String
}

struct FMBenchListRemindersTool: Tool {
    let name = "listReminders"
    let description =
        "Lists matching reminders in the benchmark's synthetic store before creation."
    let world: FMBenchMockPersonalOrganizerWorld
    let recorder: FMBenchToolRecorder

    func call(arguments: FMBenchListRemindersArguments) async throws -> String {
        await recorder.record(
            FMBenchToolCall(
                name: name,
                arguments: ["title": .string(arguments.title)]
            )
        )

        let reminders = await world.reminders(matchingTitle: arguments.title)
        guard !reminders.isEmpty else {
            return "status=ok; matches=0"
        }
        let records = reminders.map {
            "id=\($0.id); title=\($0.title); dueDate=\($0.dueDate); notes=\($0.notes)"
        }.joined(separator: "\n")
        return "status=ok; matches=\(reminders.count)\n\(records)"
    }
}
