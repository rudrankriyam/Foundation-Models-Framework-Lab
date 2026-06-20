import FMBenchCore
import Observation
import SwiftUI

@MainActor
@Observable
final class FMBenchViewModel {
    var selectedSuite: FMBenchSuite = .quick {
        didSet {
            guard selectedSuite != oldValue else { return }
            applySampleDefaults(for: selectedSuite)
        }
    }
    var selectedModel: FMBenchModel = .onDevice
    var selectedSessionMode: FMBenchSessionMode = .cold
    var selectedReasoningLevel: FMBenchReasoningLevel = .none
    var selectedFallbackMode: FMBenchFallbackMode = .disabled
    var selectedConnectivity: FMBenchConnectivity = .normal
    var warmupCount = 5
    var repetitions = 20
    var samplesPerScenario = 1
    var useAllSamples = false
    var randomizeOrder = true
    var randomSeed: UInt64 = 20_260_929
    var isRunning = false
    var result: FMBenchRunResult?
    var errorMessage = ""
    var showError = false

    var selectedScenarios: [FMBenchScenario] {
        FMBenchScenarioCatalog.scenarios(for: selectedSuite)
    }

    func run() {
        guard !isRunning else { return }

        isRunning = true
        result = nil

        let configuration = makeConfiguration()

        Task {
            do {
                result = try await FMBenchRunner(configuration: configuration).run()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isRunning = false
        }
    }

    func makeConfiguration() -> FMBenchRunConfiguration {
        FMBenchRunConfiguration(
            suite: selectedSuite,
            model: selectedModel,
            warmupCount: warmupCount,
            repetitions: repetitions,
            sampleLimit: samplesPerScenario,
            useAllSamples: useAllSamples,
            sessionMode: selectedSessionMode,
            reasoningLevel: selectedReasoningLevel,
            fallbackMode: selectedFallbackMode,
            connectivity: selectedConnectivity,
            randomizeOrder: randomizeOrder,
            randomSeed: randomSeed
        )
    }

    func copyMarkdown() {
        guard let result else { return }
        let markdown = FMBenchReport(result: result).markdown()

        #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(markdown, forType: .string)
        #else
            UIPasteboard.general.string = markdown
        #endif
    }

    private func applySampleDefaults(for suite: FMBenchSuite) {
        if let sampleLimit = suite.defaultSampleLimit {
            samplesPerScenario = sampleLimit
            useAllSamples = false
        } else {
            useAllSamples = true
        }
    }
}
