import Foundation
import FoundationModels

enum FMBenchPartialResponsePolicy {
    static func shouldPreserve(
        _ response: String,
        after error: LanguageModelSession.GenerationError
    ) -> Bool {
        !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && FMBenchSafetyClassifier.outcome(for: error) == nil
    }
}
