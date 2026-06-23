import FoundationModels

/// A deterministic, read-only tool for labs that need an observable tool call without external data.
public struct FoundationLabSessionObservabilityTool: Tool {
    public let name = "readFoundationLabFact"
    public let description = "Read a fixed Foundation Lab fact from an in-memory catalog"

    public init() {}

    @Generable
    public struct Arguments {
        @Guide(description: "The Foundation Lab topic to read")
        public let topic: Topic

        public init(topic: Topic) {
            self.topic = topic
        }
    }

    @Generable
    public enum Topic {
        case transcript
        case tools
        case privacy

        public var canonicalName: String {
            switch self {
            case .transcript:
                "transcript"
            case .tools:
                "tools"
            case .privacy:
                "privacy"
            }
        }

        fileprivate var fact: String {
            switch self {
            case .transcript:
                "A session transcript records instructions, prompts, tool calls, tool outputs, responses, and supported reasoning."
            case .tools:
                "A Tool exposes app code to the model; the app still owns validation, authorization, and side-effect policy."
            case .privacy:
                "This lab tool reads only a fixed in-memory catalog and never accesses files, accounts, sensors, or the network."
            }
        }
    }

    public func call(arguments: Arguments) async throws -> GeneratedContent {
        GeneratedContent(properties: [
            "topic": arguments.topic.canonicalName,
            "fact": arguments.topic.fact,
            "source": "Foundation Lab in-memory catalog"
        ])
    }
}
