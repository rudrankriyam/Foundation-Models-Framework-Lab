import FMBenchCore
import Foundation

// Argument parsing is a single exhaustive flag dispatch with shared validation.
// swiftlint:disable cyclomatic_complexity function_body_length
@main
struct FMBenchCLI {
    static func main() async {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            if arguments.first == "list" {
                printScenarioList()
                return
            }

            let options = try CLIOptions(arguments: arguments)
            printHeader(options: options)

            let configuration = FMBenchRunConfiguration(
                suite: options.suite,
                scenarios: options.selectedScenarios,
                model: options.model,
                warmupCount: options.warmups,
                repetitions: options.repetitions,
                sampleLimit: options.sampleLimit,
                sampleIDs: options.sampleID.map { [$0] },
                useAllSamples: options.useAllSamples,
                sessionMode: options.sessionMode,
                reasoningLevel: options.reasoningLevel,
                fallbackMode: options.fallbackMode,
                connectivity: options.connectivity,
                randomizeOrder: options.randomizeOrder,
                randomSeed: options.randomSeed
            )
            let result = try await FMBenchRunner(configuration: configuration).run()
            let report = FMBenchReport(result: result)

            print(report.markdown())
            try write(report: report, options: options)

            if !result.failures.isEmpty {
                print("\nFailures:")
                for failure in result.failures {
                    print(
                        "- \(failure.scenarioID)/\(failure.sampleID) run \(failure.iteration) "
                            + "[\(failure.kind)]: \(failure.message)"
                    )
                }
                exit(2)
            }
            if result.criticalSafetyFailureCount > 0 {
                print(
                    "\nCritical safety failures: \(result.criticalSafetyFailureCount). "
                        + "The guardrail suite did not meet its expected trigger behavior."
                )
                exit(3)
            }
        } catch {
            print("FMBench failed: \(error.localizedDescription)")
            printUsage()
            exit(1)
        }
    }

    private static func printHeader(options: CLIOptions) {
        print("Foundation Models FMBench")
        print(String(repeating: "=", count: 80))
        print("Suite: \(options.suite.displayName)")
        print("Model: \(options.model.displayName)")
        print("Warmups: \(options.warmups)")
        print("Repetitions: \(options.repetitions)")
        let samples = options.sampleID.map { "selected (\($0))" }
            ?? (options.useAllSamples
                ? "all" : options.sampleLimit.map(String.init) ?? "suite default")
        print("Samples: \(samples)")
        print("Session: \(options.sessionMode.displayName)")
        print("Reasoning: \(options.reasoningLevel.displayName)")
        print("Fallback: \(options.fallbackMode.displayName)")
        print("Connectivity: \(options.connectivity.displayName)")
        print("Randomized: \(options.randomizeOrder ? "yes" : "no") (seed \(options.randomSeed))")
        if let scenarioID = options.scenarioID {
            print("Scenario: \(scenarioID)")
        }
        if let sampleID = options.sampleID {
            print("Sample: \(sampleID)")
        }
        print()
    }

    private static func printScenarioList() {
        print("Foundation Models FMBench scenarios\n")
        for scenario in FMBenchScenarioCatalog.all {
            print("\(scenario.id)")
            print("  \(scenario.title)")
            print(
                "  \(scenario.category.displayName) • inspired by \(scenario.inspiredBy.joined(separator: ", "))"
            )
            print("  \(scenario.samples.count) samples\(scenario.requiresOS27 ? " • OS 27+" : "")")
            print()
        }
    }

    private static func write(report: FMBenchReport, options: CLIOptions) throws {
        if let jsonPath = options.jsonPath {
            try report.json().write(toFile: jsonPath, atomically: true, encoding: .utf8)
            print("\nJSON: \(jsonPath)")
        }
        if let markdownPath = options.markdownPath {
            try report.markdown().write(toFile: markdownPath, atomically: true, encoding: .utf8)
            print("Markdown: \(markdownPath)")
        }
    }

    private static func printUsage() {
        print(
            """

            Usage:
              ./fmbench list
              ./fmbench [run] [options]

            Options:
              --suite quick|full|agentic|guardrails|performance|context
              --model on-device|pcc
              --scenario <scenario-id>
              --sample <sample-id>
              --warmups <count>
              --repetitions <count>
              --samples <count>
              --all-samples
              --session cold|warm
              --reasoning none|light|moderate|deep
              --fallback disabled|on-device
              --connectivity normal|offline
              --seed <unsigned-integer>
              --no-randomize
              --json <path>
              --markdown <path>
            """)
    }
}

private struct CLIOptions {
    enum Error: Swift.Error, LocalizedError {
        case missingValue(String)
        case invalidValue(flag: String, value: String)
        case conflictingArguments(String, String)
        case unknownArgument(String)
        case unknownScenario(String)
        case unknownSample(String)

        var errorDescription: String? {
            switch self {
            case .missingValue(let flag):
                "Missing value for \(flag)."
            case .invalidValue(let flag, let value):
                "Invalid value “\(value)” for \(flag)."
            case .conflictingArguments(let first, let second):
                "\(first) and \(second) cannot be used together."
            case .unknownArgument(let value):
                "Unknown argument “\(value)”."
            case .unknownScenario(let value):
                "Unknown scenario “\(value)”."
            case .unknownSample(let value):
                "Unknown sample “\(value)”."
            }
        }
    }

    var suite: FMBenchSuite = .quick
    var model: FMBenchModel = .onDevice
    var scenarioID: String?
    var sampleID: String?
    var warmups = 5
    var repetitions = 20
    var sampleLimit: Int?
    var useAllSamples = false
    var sessionMode: FMBenchSessionMode = .cold
    var reasoningLevel: FMBenchReasoningLevel = .none
    var fallbackMode: FMBenchFallbackMode = .disabled
    var connectivity: FMBenchConnectivity = .normal
    var randomizeOrder = true
    var randomSeed: UInt64 = 20_260_929
    var jsonPath: String?
    var markdownPath: String?

    init(arguments: [String]) throws {
        var index = arguments.first == "run" ? 1 : 0
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--suite":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard let suite = FMBenchSuite(rawValue: value) else {
                    throw Error.invalidValue(flag: argument, value: value)
                }
                self.suite = suite
            case "--model":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                switch value {
                case "on-device":
                    model = .onDevice
                case "pcc":
                    model = .privateCloudCompute
                default:
                    throw Error.invalidValue(flag: argument, value: value)
                }
            case "--scenario":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard FMBenchScenarioCatalog.all.contains(where: { $0.id == value }) else {
                    throw Error.unknownScenario(value)
                }
                scenarioID = value
            case "--sample":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard FMBenchScenarioCatalog.all.contains(where: { scenario in
                    scenario.samples.contains { $0.id == value }
                }) else {
                    throw Error.unknownSample(value)
                }
                sampleID = value
            case "--warmups":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard let count = Int(value), count >= 0 else {
                    throw Error.invalidValue(flag: argument, value: value)
                }
                warmups = count
            case "--repetitions":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard let count = Int(value), count > 0 else {
                    throw Error.invalidValue(flag: argument, value: value)
                }
                repetitions = count
            case "--samples":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard let count = Int(value), count > 0 else {
                    throw Error.invalidValue(flag: argument, value: value)
                }
                sampleLimit = count
            case "--all-samples":
                useAllSamples = true
            case "--session":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard let mode = FMBenchSessionMode(rawValue: value) else {
                    throw Error.invalidValue(flag: argument, value: value)
                }
                sessionMode = mode
            case "--reasoning":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard let level = FMBenchReasoningLevel(rawValue: value) else {
                    throw Error.invalidValue(flag: argument, value: value)
                }
                reasoningLevel = level
            case "--fallback":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                switch value {
                case "disabled":
                    fallbackMode = .disabled
                case "on-device":
                    fallbackMode = .onDevice
                default:
                    throw Error.invalidValue(flag: argument, value: value)
                }
            case "--connectivity":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard let connectivity = FMBenchConnectivity(rawValue: value) else {
                    throw Error.invalidValue(flag: argument, value: value)
                }
                self.connectivity = connectivity
            case "--seed":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard let seed = UInt64(value) else {
                    throw Error.invalidValue(flag: argument, value: value)
                }
                randomSeed = seed
            case "--no-randomize":
                randomizeOrder = false
            case "--json":
                jsonPath = try Self.value(after: argument, at: &index, in: arguments)
            case "--markdown":
                markdownPath = try Self.value(after: argument, at: &index, in: arguments)
            default:
                throw Error.unknownArgument(argument)
            }
            index += 1
        }

        if sampleLimit != nil, useAllSamples {
            throw Error.conflictingArguments("--samples", "--all-samples")
        }
        if sampleID != nil, scenarioID != nil {
            throw Error.conflictingArguments("--sample", "--scenario")
        }
        if sampleID != nil, sampleLimit != nil {
            throw Error.conflictingArguments("--sample", "--samples")
        }
        if sampleID != nil, useAllSamples {
            throw Error.conflictingArguments("--sample", "--all-samples")
        }
    }

    var selectedScenarios: [FMBenchScenario]? {
        if let sampleID {
            return FMBenchScenarioCatalog.all.filter { scenario in
                scenario.samples.contains { $0.id == sampleID }
            }
        }
        return scenarioID.map { id in
            FMBenchScenarioCatalog.all.filter { $0.id == id }
        }
    }

    private static func value(
        after flag: String,
        at index: inout Int,
        in arguments: [String]
    ) throws -> String {
        index += 1
        guard index < arguments.count else {
            throw Error.missingValue(flag)
        }
        return arguments[index]
    }
}
// swiftlint:enable cyclomatic_complexity function_body_length
