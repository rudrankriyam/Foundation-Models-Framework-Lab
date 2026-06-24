import Foundation
import FoundationModels
import FoundationModelsKit

@Generable
struct FMFBenchSearchContactsArguments: RuntimeCompatibleGenerable {
    @Guide(description: "The full contact name from the user's request")
    let name: String
}

struct FMFBenchSearchContactsTool: Tool {
    let name = "searchContacts"
    let description = "Searches the benchmark's synthetic contact store by name."
    let world: FMFBenchMockPersonalOrganizerWorld
    let recorder: FMFBenchToolRecorder

    func call(arguments: FMFBenchSearchContactsArguments) async throws -> String {
        await recorder.record(
            FMFBenchToolCall(
                name: name,
                arguments: ["name": .string(arguments.name)]
            )
        )

        let outcome = await world.contacts(matching: arguments.name)
        switch outcome {
        case .transientFailure:
            return """
                status=error; code=temporary_unavailable; retryable=true
                Retry searchContacts exactly once with the same name.
                """
        case .results(let contacts) where contacts.isEmpty:
            return "status=not_found; matches=0; retryable=false"
        case .results(let contacts):
            let records = contacts.map { contact in
                var fields =
                    "id=\(contact.id); name=\(contact.name); phone=\(contact.phoneNumber)"
                if let untrustedData = contact.untrustedData {
                    fields += "; untrusted_data=\(untrustedData)"
                }
                return fields
            }.joined(separator: "\n")
            return "status=ok; matches=\(contacts.count)\n\(records)"
        }
    }
}
