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
            LabeledContent("Type") {
                Text(LocalizedStringKey(run.configuration.kind.displayName))
            }
            LabeledContent("Level") {
                Text(LocalizedStringKey(run.configuration.level.displayName))
            }
        }

        Section("Model") {
            LabeledContent("Runtime") {
                Label {
                    Text(LocalizedStringKey(run.configuration.modelRuntime.displayName))
                } icon: {
                    Image(systemName: run.configuration.modelRuntime.systemImage)
                }
            }

            LabeledContent("Provider", value: run.provider)
            LabeledContent("Model", value: run.modelIdentifier)
            LabeledContent("Reasoning") {
                Text(LocalizedStringKey(run.configuration.reasoningLevel.displayName))
            }
        }

        Section("Generation") {
            LabeledContent("Sampling", value: samplingDescription)
            LabeledContent("Temperature", value: temperatureDescription)
            LabeledContent("Maximum response tokens", value: maximumResponseTokensDescription)
        }
    }

    private var experimentName: String {
        run.configuration.name.isEmpty ? String(localized: "Untitled Experiment") : run.configuration.name
    }

    private var samplingDescription: String {
        guard let sampling = run.configuration.generationOptions.sampling else {
            return String(localized: "System Default")
        }

        switch sampling {
        case .greedy:
            return String(localized: "Greedy")
        case .randomTop(let top, let seed):
            return String(localized: "Top-K \(top)") + seedDescription(seed)
        case .randomProbabilityThreshold(let threshold, let seed):
            let value = threshold.formatted(.number.precision(.fractionLength(2)))
            return String(localized: "Top-P \(value)") + seedDescription(seed)
        }
    }

    private var temperatureDescription: String {
        guard let temperature = run.configuration.generationOptions.temperature else {
            return String(localized: "System Default")
        }
        return temperature.formatted(.number.precision(.fractionLength(2)))
    }

    private var maximumResponseTokensDescription: String {
        guard let maximumResponseTokens = run.configuration.generationOptions.maximumResponseTokens else {
            return String(localized: "System Default")
        }
        return maximumResponseTokens.formatted()
    }

    private func seedDescription(_ seed: UInt64?) -> String {
        guard let seed else { return "" }
        return " · " + String(localized: "Seed \(seed)")
    }
}
