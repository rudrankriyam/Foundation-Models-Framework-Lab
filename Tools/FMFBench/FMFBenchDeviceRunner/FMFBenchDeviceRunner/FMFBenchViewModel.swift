import FMFBenchCore
import Observation
import SwiftUI

@MainActor
@Observable
final class FMFBenchViewModel {
    var selectedSuite: FMFBenchSuite = .quick {
        didSet {
            guard selectedSuite != oldValue else { return }
            applySampleDefaults(for: selectedSuite)
        }
    }
    var selectedModel: FMFBenchModel = .onDevice
    var selectedSessionMode: FMFBenchSessionMode = .cold
    var selectedReasoningLevel: FMFBenchReasoningLevel = .none
    var selectedFallbackMode: FMFBenchFallbackMode = .disabled
    var selectedConnectivity: FMFBenchConnectivity = .normal
    var warmupCount = 5
    var repetitions = 20
    var samplesPerScenario = 1
    var useAllSamples = false
    var randomizeOrder = true
    var randomSeed: UInt64 = 20_260_929
    var isRunning = false
    var result: FMFBenchRunResult?
    var errorMessage = ""
    var showError = false

    var selectedScenarios: [FMFBenchScenario] {
        FMFBenchScenarioCatalog.scenarios(for: selectedSuite)
    }

    func run() {
        guard !isRunning else { return }

        isRunning = true
        result = nil

        let configuration = makeConfiguration()

        Task {
            do {
                result = try await FMFBenchRunner(configuration: configuration).run()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isRunning = false
        }
    }

    func makeConfiguration() -> FMFBenchRunConfiguration {
        FMFBenchRunConfiguration(
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
        let markdown = FMFBenchReport(result: result).markdown()

        #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(markdown, forType: .string)
        #else
            UIPasteboard.general.string = markdown
        #endif
    }

    private func applySampleDefaults(for suite: FMFBenchSuite) {
        if let sampleLimit = suite.defaultSampleLimit {
            samplesPerScenario = sampleLimit
            useAllSamples = false
        } else {
            useAllSamples = true
        }
    }
}
