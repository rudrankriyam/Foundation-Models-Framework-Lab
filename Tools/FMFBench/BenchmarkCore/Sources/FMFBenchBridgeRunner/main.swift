import FMFBenchCore
import Foundation

@main
struct FMFBenchBridgeRunner {
    static func main() async throws {
        let options = try BridgeRunOptions.parse(CommandLine.arguments.dropFirst())
        let descriptor = try BridgeDescriptor.load(from: options.descriptorPath)
        let client = BridgeClient(descriptor: descriptor)
        let scenarios = FMFBenchScenarioCatalog.scenarios(for: .apps)
        let environment = EnvironmentSnapshot.capture()
        let startedAt = Date()

        var trials: [FMFBenchTrialResult] = []
        var failures: [FMFBenchFailure] = []

        for iteration in 1...options.repetitions {
            for scenario in scenarios {
                for sample in scenario.samples {
                    do {
                        let trial = try await client.run(
                            scenario: scenario,
                            sample: sample,
                            iteration: iteration,
                            environment: environment
                        )
                        trials.append(trial)
                        print("\(scenario.id) run \(iteration): \(trial.grade.promptPassed ? "pass" : "fail")")
                    } catch {
                        failures.append(
                            FMFBenchFailure(
                                scenarioID: scenario.id,
                                sampleID: sample.id,
                                iteration: iteration,
                                kind: "bridge-pcc",
                                message: error.localizedDescription
                            )
                        )
                        print("\(scenario.id) run \(iteration): execution failure - \(error.localizedDescription)")
                    }
                }
            }
        }

        let result = FMFBenchRunResult(
            suite: .apps,
            model: .privateCloudCompute,
            warmupCount: 0,
            repetitions: options.repetitions,
            sampleLimit: nil,
            sessionMode: .cold,
            reasoningLevel: .none,
            fallbackMode: .disabled,
            connectivity: .normal,
            randomizedOrder: false,
            randomSeed: 20_260_929,
            modelContextSize: nil,
            quotaBefore: nil,
            quotaAfter: nil,
            startedAt: startedAt,
            endedAt: Date(),
            environment: environment,
            trials: trials,
            failures: failures,
            scenarios: scenarios
        )
        let report = FMFBenchReport(result: result)
        try FileManager.default.createDirectory(
            at: options.outputDirectory,
            withIntermediateDirectories: true
        )
        let jsonURL = options.outputDirectory.appending(path: "apps-pcc-bridge.json")
        let markdownURL = options.outputDirectory.appending(path: "apps-pcc-bridge.md")
        try report.json().write(to: jsonURL, atomically: true, encoding: .utf8)
        try report.markdown().write(to: markdownURL, atomically: true, encoding: .utf8)

        print("")
        print(report.markdown())
        print("FMFBench bridge PCC JSON: \(jsonURL.path())")
        print("FMFBench bridge PCC Markdown: \(markdownURL.path())")
    }
}

private struct BridgeRunOptions {
    var descriptorPath = "\(NSHomeDirectory())/.afm/bridge/connection.json"
    var outputDirectory = URL(fileURLWithPath: "/tmp/fmfbench-apps-pcc")
    var repetitions = 1

    static func parse(_ arguments: ArraySlice<String>) throws -> Self {
        var options = Self()
        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--descriptor":
                guard let value = iterator.next() else { throw BridgeRunError.missingValue(argument) }
                options.descriptorPath = NSString(string: value).expandingTildeInPath
            case "--output":
                guard let value = iterator.next() else { throw BridgeRunError.missingValue(argument) }
                options.outputDirectory = URL(fileURLWithPath: NSString(string: value).expandingTildeInPath)
            case "--repetitions":
                guard let value = iterator.next() else { throw BridgeRunError.missingValue(argument) }
                guard let repetitions = Int(value), repetitions > 0 else {
                    throw BridgeRunError.invalidValue(argument: argument, value: value)
                }
                options.repetitions = repetitions
            default:
                throw BridgeRunError.unknownArgument(argument)
            }
        }
        return options
    }
}

private struct BridgeDescriptor: Decodable {
    struct Endpoint: Decodable {
        struct LoopbackTCP: Decodable {
            let host: String
            let port: Int
        }

        let loopbackTCP: LoopbackTCP
    }

    let endpoint: Endpoint
    let bearerToken: String
    let modelIdentifiers: [String]

    static func load(from path: String) throws -> Self {
        let url = URL(fileURLWithPath: path)
        let descriptor = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        guard descriptor.modelIdentifiers.contains("pcc") else {
            throw BridgeRunError.modelUnavailable
        }
        return descriptor
    }
}

private struct BridgeClient {
    let descriptor: BridgeDescriptor

    func run(
        scenario: FMFBenchScenario,
        sample: FMFBenchSample,
        iteration: Int,
        environment: EnvironmentSnapshot
    ) async throws -> FMFBenchTrialResult {
        let startedAt = Date()
        let response = try await chat(scenario: scenario, sample: sample)
        let endedAt = Date()
        let content = response.primaryContent
        let metrics = FMFBenchTrialMetrics(
            startedAt: startedAt,
            endedAt: endedAt,
            firstTokenAt: nil,
            inputTokenCount: response.usage.promptTokens,
            outputTokenCount: response.usage.completionTokens,
            firstStreamUpdateTokenCount: 0,
            tokenCountSource: .sessionUsage,
            responseCharacterCount: content.count,
            streamUpdateDates: [],
            reasoningTokenCount: response.usage.completionTokensDetails.reasoningTokens
        )
        return FMFBenchTrialResult(
            scenario: scenario,
            sample: sample,
            requestedModel: .privateCloudCompute,
            executedModel: .privateCloudCompute,
            iteration: iteration,
            response: content,
            grade: FMFBenchGrader.grade(response: content, checks: sample.checks),
            metrics: metrics,
            environment: environment
        )
    }

    private func chat(scenario: FMFBenchScenario, sample: FMFBenchSample) async throws -> BridgeChatResponse {
        var body: [String: Any] = [
            "model": "pcc",
            "messages": [
                ["role": "system", "content": scenario.instructions],
                ["role": "user", "content": sample.prompt]
            ],
            "max_completion_tokens": scenario.maximumResponseTokens
        ]
        if let responseFormat = responseFormat(for: scenario.outputMode) {
            body["response_format"] = responseFormat
        }

        let requestBody = try JSONSerialization.data(withJSONObject: body, options: [])
        var request = URLRequest(url: baseURL.appending(path: "/v1/chat/completions"))
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("Bearer \(descriptor.bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBody

        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw BridgeRunError.invalidHTTPResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
            throw BridgeRunError.httpFailure(httpResponse.statusCode, body)
        }
        return try JSONDecoder().decode(BridgeChatResponse.self, from: data)
    }

    private var baseURL: URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = descriptor.endpoint.loopbackTCP.host
        components.port = descriptor.endpoint.loopbackTCP.port
        return components.url!
    }

    private func responseFormat(for outputMode: FMFBenchOutputMode) -> [String: Any]? {
        guard case .guided(let schema) = outputMode else { return nil }
        return [
            "type": "json_schema",
            "json_schema": [
                "name": schema.responseFormatName,
                "strict": true,
                "schema": schema.jsonSchema
            ]
        ]
    }
}

private struct BridgeChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
            let refusal: String?
        }

        let message: Message
    }

    struct Usage: Decodable {
        struct CompletionTokensDetails: Decodable {
            let reasoningTokens: Int?

            private enum CodingKeys: String, CodingKey {
                case reasoningTokens = "reasoning_tokens"
            }
        }

        let promptTokens: Int
        let completionTokens: Int
        let completionTokensDetails: CompletionTokensDetails

        private enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case completionTokensDetails = "completion_tokens_details"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            promptTokens = try container.decode(Int.self, forKey: .promptTokens)
            completionTokens = try container.decode(Int.self, forKey: .completionTokens)
            completionTokensDetails =
                try container.decodeIfPresent(
                    CompletionTokensDetails.self,
                    forKey: .completionTokensDetails
                ) ?? .init(reasoningTokens: nil)
        }
    }

    let choices: [Choice]
    let usage: Usage

    var primaryContent: String {
        for choice in choices {
            if let content = choice.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
               !content.isEmpty {
                return content
            }
            if let refusal = choice.message.refusal?.trimmingCharacters(in: .whitespacesAndNewlines),
               !refusal.isEmpty {
                return refusal
            }
        }
        return ""
    }
}

private enum BridgeRunError: LocalizedError {
    case missingValue(String)
    case invalidValue(argument: String, value: String)
    case unknownArgument(String)
    case modelUnavailable
    case invalidHTTPResponse
    case httpFailure(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingValue(let argument):
            "Missing value for \(argument)."
        case .invalidValue(let argument, let value):
            "Invalid value '\(value)' for \(argument)."
        case .unknownArgument(let argument):
            "Unknown argument \(argument)."
        case .modelUnavailable:
            "The active bridge descriptor does not advertise the pcc model."
        case .invalidHTTPResponse:
            "The bridge returned a response that was not HTTP."
        case .httpFailure(let status, let body):
            "The bridge request failed with HTTP \(status): \(body)"
        }
    }
}

private extension FMFBenchSchema {
    var responseFormatName: String {
        switch self {
        case .task: "TaskCapture"
        case .classification: "Classification"
        case .workout: "WorkoutPlan"
        case .groundedAnswer: "GroundedAnswer"
        case .citation: "Citation"
        }
    }

    var jsonSchema: [String: Any] {
        switch self {
        case .task:
            object([
                "title": string("Exact task title"),
                "list": string("Destination list"),
                "dueDate": string("Date formatted as YYYY-MM-DD HH:mm"),
                "tags": stringArray("Lowercase tags", minimum: 2, maximum: 2)
            ])
        case .classification:
            object([
                "category": [
                    "description": "The single best category",
                    "enum": ["health", "learning", "productivity", "relationships"]
                ]
            ])
        case .workout:
            object([
                "focus": string("Workout focus"),
                "durationMinutes": integer("Total workout duration"),
                "exercises": stringArray("Exercise names", minimum: 4, maximum: 4)
            ])
        case .groundedAnswer:
            object([
                "answer": string("Exact concise answer"),
                "citations": stringArray("Supporting document IDs", minimum: 1, maximum: 3)
            ])
        case .citation:
            object([
                "author": string("Author name exactly as supplied"),
                "title": string("Work title exactly as supplied"),
                "year": integer("Publication year"),
                "venue": string("Publication venue exactly as supplied")
            ])
        }
    }

    func object(_ properties: [String: Any]) -> [String: Any] {
        [
            "type": "object",
            "properties": properties,
            "required": properties.keys.sorted(),
            "additionalProperties": false
        ]
    }

    func string(_ description: String) -> [String: Any] {
        ["type": "string", "description": description]
    }

    func integer(_ description: String) -> [String: Any] {
        ["type": "integer", "description": description]
    }

    func stringArray(_ description: String, minimum: Int, maximum: Int) -> [String: Any] {
        [
            "type": "array",
            "description": description,
            "items": ["type": "string"],
            "minItems": minimum,
            "maxItems": maximum
        ]
    }
}
