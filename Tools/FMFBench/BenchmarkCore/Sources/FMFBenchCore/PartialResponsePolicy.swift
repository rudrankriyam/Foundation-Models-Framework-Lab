import Foundation
import FoundationModels

enum FMFBenchPartialResponsePolicy {
    static func shouldPreserve(
        _ response: String,
        after error: LanguageModelSession.GenerationError
    ) -> Bool {
        !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && FMFBenchSafetyClassifier.outcome(for: error) == nil
    }
}
