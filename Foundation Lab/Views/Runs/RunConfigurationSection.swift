//
//  RunConfigurationSection.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct RunConfigurationSection: View {
    let run: FoundationLabExperimentRun

    var body: some View {
        Section("Experiment") {
            LabeledContent("Experiment", value: experimentName)
            LabeledContent("Type", value: run.configuration.kind.displayName)
            LabeledContent("Level", value: run.configuration.level.displayName)
        }

        Section("Model") {
            LabeledContent("Runtime") {
                Label(
                    run.configuration.modelRuntime.displayName,
                    systemImage: run.configuration.modelRuntime.systemImage
                )
            }

            LabeledContent("Provider", value: run.provider)
            LabeledContent("Model", value: run.modelIdentifier)
            LabeledContent("Reasoning", value: run.configuration.reasoningLevel.displayName)
        }

        Section("Generation") {
            LabeledContent("Sampling", value: samplingDescription)
            LabeledContent("Temperature", value: temperatureDescription)
            LabeledContent("Maximum response tokens", value: maximumResponseTokensDescription)
        }
    }

    private var experimentName: String {
        run.configuration.name.isEmpty ? "Untitled Experiment" : run.configuration.name
    }

    private var samplingDescription: String {
        guard let sampling = run.configuration.generationOptions.sampling else {
            return "System Default"
        }

        switch sampling {
        case .greedy:
            return "Greedy"
        case .randomTop(let top, let seed):
            return "Top-K \(top)\(seedDescription(seed))"
        case .randomProbabilityThreshold(let threshold, let seed):
            let value = threshold.formatted(.number.precision(.fractionLength(2)))
            return "Top-P \(value)\(seedDescription(seed))"
        }
    }

    private var temperatureDescription: String {
        guard let temperature = run.configuration.generationOptions.temperature else {
            return "System Default"
        }
        return temperature.formatted(.number.precision(.fractionLength(2)))
    }

    private var maximumResponseTokensDescription: String {
        guard let maximumResponseTokens = run.configuration.generationOptions.maximumResponseTokens else {
            return "System Default"
        }
        return maximumResponseTokens.formatted()
    }

    private func seedDescription(_ seed: UInt64?) -> String {
        guard let seed else { return "" }
        return " · Seed \(seed)"
    }
}
