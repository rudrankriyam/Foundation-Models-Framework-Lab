import Foundation

// Report assembly is intentionally linear so Markdown section order remains explicit.
// swiftlint:disable function_body_length line_length
public struct FMFBenchReport: Sendable {
    public let result: FMFBenchRunResult

    public init(result: FMFBenchRunResult) {
        self.result = result
    }

    public func json(prettyPrinted: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = prettyPrinted ? [.prettyPrinted, .sortedKeys] : []
        let data = try encoder.encode(result)
        guard let value = String(data: data, encoding: .utf8) else {
            throw CocoaError(.coderInvalidValue)
        }
        return value
    }

    public func markdown() -> String {
        var lines = [
            "# Foundation Models FMFBench",
            "",
            "- Suite: \(result.suite.displayName)",
            "- Model: \(result.model.displayName)",
            "- Warmups: \(result.warmupCount)",
            "- Repetitions: \(result.repetitions)",
            "- Samples per scenario: \(result.sampleLimit.map(String.init) ?? "all")",
            "- Session mode: \(result.sessionMode.displayName)",
            "- Reasoning: \(result.reasoningLevel.displayName)",
            "- Fallback: \(result.fallbackMode.displayName)",
            "- Fallback trials: \(result.trials.count(where: \.usedFallback))",
            "- Connectivity label: \(result.connectivity.displayName)",
            "- Randomized order: \(result.randomizedOrder ? "yes" : "no") (seed \(result.randomSeed))",
            "- Model context size: \(result.modelContextSize.map(String.init) ?? "unknown") tokens",
            "- Started: \(result.startedAt.formatted(.iso8601))",
            "- Failures: \(result.failures.count)",
            "- Critical safety failures: \(result.criticalSafetyFailureCount)",
            "",
            "| Scenario | Prompt pass | Failure rate | Constraint score | Median / p90 TTFT | Median / p90 tok/s | Peak observed memory |",
            "| --- | ---: | ---: | ---: | ---: | ---: | ---: |"
        ]

        for summary in result.summaries {
            lines.append(
                "| \(summary.title) | \(percent(summary.promptPassRate)) | \(percent(summary.failureRate)) | "
                    + "\(percent(summary.meanConstraintScore)) | \(seconds(summary.timeToFirstToken.median)) / "
                    + "\(seconds(summary.timeToFirstToken.p90)) | \(number(summary.outputTokensPerSecond.median)) / "
                    + "\(number(summary.outputTokensPerSecond.p90)) | \(memory(summary.peakObservedResidentMemoryBytes.maximum)) |"
            )
        }

        let safetySummaries = result.summaries.filter { $0.safetyTrialCount > 0 }
        if !safetySummaries.isEmpty {
            lines.append("")
            lines.append("## Safety Guardrails")
            lines.append("")
            lines.append(
                "| Scenario | Safety pass | Explicit guardrail | Refusal | Critical failures |")
            lines.append("| --- | ---: | ---: | ---: | ---: |")
            for summary in safetySummaries {
                lines.append(
                    "| \(summary.title) | \(summary.safetyPassRate.map(percent) ?? "n/a") | "
                        + "\(summary.guardrailViolationCount) | \(summary.refusalCount) | "
                        + "\(summary.criticalSafetyFailureCount) |"
                )
            }
        }

        if let quota = result.quotaBefore {
            lines.append("")
            lines.append("## PCC Quota")
            lines.append(
                "- Before: \(quota.status)\(quota.isApproachingLimit == true ? " (approaching limit)" : "")"
            )
            lines.append("- After: \(result.quotaAfter?.status ?? "unknown")")
            lines.append(
                "- Reset: \(result.quotaAfter?.resetDate?.formatted(.iso8601) ?? "not reported")")
        }

        lines.append("")
        lines.append("## Environment")
        let environment = result.environment
        lines.append("- Device: \(environment.deviceName)")
        lines.append("- Hardware: \(environment.hardwareModel ?? "unknown")")
        lines.append("- Chip: \(environment.cpuModel ?? "unknown")")
        lines.append(
            "- OS: \(environment.systemName) \(environment.systemVersion) (\(environment.systemBuild ?? "unknown"))"
        )
        lines.append("- Memory: \(memory(environment.totalMemory))")
        lines.append("- Thermal state: \(environment.thermalState)")
        lines.append("- Low Power Mode: \(environment.lowPowerModeEnabled ? "on" : "off")")
        lines.append("- FMFBench commit: \(environment.fmfBenchCommit ?? "unknown")")

        return lines.joined(separator: "\n")
    }

    private func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(1)))
    }

    private func seconds(_ value: Double?) -> String {
        guard let value else { return "n/a" }
        return value.formatted(.number.precision(.fractionLength(3))) + "s"
    }

    private func number(_ value: Double?) -> String {
        guard let value else { return "n/a" }
        return value.formatted(.number.precision(.fractionLength(2)))
    }

    private func memory(_ bytes: UInt64?) -> String {
        guard let bytes else { return "unknown" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    private func memory(_ bytes: Double?) -> String {
        guard let bytes else { return "unknown" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}
// swiftlint:enable function_body_length line_length
