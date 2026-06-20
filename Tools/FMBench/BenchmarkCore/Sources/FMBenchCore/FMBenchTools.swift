import Foundation
import FoundationModels

actor FMBenchToolRecorder {
    private var calls: [FMBenchToolCall] = []

    func record(_ call: FMBenchToolCall) {
        calls.append(call)
    }

    func reset() {
        calls.removeAll(keepingCapacity: true)
    }

    func snapshot() -> [FMBenchToolCall] {
        calls
    }
}

@Generable
struct KnowledgeLookupArguments {
    @Guide(description: "The exact topic requested by the user")
    let topic: String

    @Guide(description: "The exact source ID requested by the user")
    let sourceID: String
}

struct KnowledgeLookupTool: Tool {
    let name = "lookupKnowledge"
    let description = "Returns a short trusted explanation for a topic and source ID."
    let recorder: FMBenchToolRecorder

    func call(arguments: KnowledgeLookupArguments) async throws -> String {
        await recorder.record(
            FMBenchToolCall(
                name: name,
                arguments: [
                    "topic": .string(arguments.topic),
                    "sourceID": .string(arguments.sourceID)
                ]
            )
        )

        let normalized = arguments.topic.lowercased()
        let fact: String
        switch normalized {
        case "mitochondria":
            fact = "Mitochondria convert nutrients into usable cellular energy."
        case "plate tectonics":
            fact = "Earth's surface is divided into moving plates whose interactions shape crust."
        case "compound interest":
            fact = "Compound interest earns interest on both principal and accumulated interest."
        case "photosynthesis":
            fact = "Photosynthesis uses light energy to turn carbon dioxide and water into sugars."
        case "binary search":
            fact = "Binary search repeatedly halves a sorted collection to locate a target."
        default:
            fact = "No trusted fact is available for this topic."
        }
        return "[\(arguments.sourceID)] \(fact)"
    }
}

@Generable
struct ExerciseSubstitutionArguments {
    @Guide(description: "The exact exercise that cannot be performed")
    let unavailableExercise: String

    @Guide(description: "The exact user limitation")
    let limitation: String

    @Guide(description: "The exact available equipment")
    let equipment: String
}

struct ExerciseCatalogTool: Tool {
    let name = "findExerciseSubstitute"
    let description =
        "Returns one exercise substitute matching a limitation and available equipment."
    let recorder: FMBenchToolRecorder

    func call(arguments: ExerciseSubstitutionArguments) async throws -> String {
        await recorder.record(
            FMBenchToolCall(
                name: name,
                arguments: [
                    "unavailableExercise": .string(arguments.unavailableExercise),
                    "limitation": .string(arguments.limitation),
                    "equipment": .string(arguments.equipment)
                ]
            )
        )

        let key = arguments.unavailableExercise.lowercased()
        switch key {
        case "barbell squat":
            return "goblet squat"
        case "running":
            return "cycling"
        case "pull-up":
            return "band row"
        case "push-up":
            return "dumbbell floor press"
        case "box jump":
            return "reverse lunge"
        default:
            return "No compatible substitute found."
        }
    }
}

struct FMBenchSessionBundle: Sendable {
    let session: LanguageModelSession
    let recorder: FMBenchToolRecorder
    let mockWorld: FMBenchMockPersonalOrganizerWorld?
}

struct FMBenchToolRuntime: Sendable {
    let tools: [any Tool]
    let mockWorld: FMBenchMockPersonalOrganizerWorld?
}

func fmBenchToolRuntime(
    for toolSet: FMBenchToolSet,
    recorder: FMBenchToolRecorder
) -> FMBenchToolRuntime {
    switch toolSet {
    case .none:
        return FMBenchToolRuntime(tools: [], mockWorld: nil)
    case .knowledge:
        return FMBenchToolRuntime(
            tools: [KnowledgeLookupTool(recorder: recorder)],
            mockWorld: nil
        )
    case .exerciseCatalog:
        return FMBenchToolRuntime(
            tools: [ExerciseCatalogTool(recorder: recorder)],
            mockWorld: nil
        )
    case .personalOrganizer:
        let world = FMBenchMockPersonalOrganizerWorld()
        return FMBenchToolRuntime(
            tools: [
                FMBenchSearchContactsTool(world: world, recorder: recorder),
                FMBenchListRemindersTool(world: world, recorder: recorder),
                FMBenchCreateReminderTool(world: world, recorder: recorder)
            ],
            mockWorld: world
        )
    }
}
