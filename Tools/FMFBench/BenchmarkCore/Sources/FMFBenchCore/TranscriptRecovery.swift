import Foundation
import FoundationModels

enum FMFBenchTranscriptRecovery {
    static func latestResponse(
        from transcript: Transcript,
        startingAt startIndex: Transcript.Index
    ) -> String? {
        guard transcript.indices.contains(startIndex) || startIndex == transcript.endIndex else {
            return nil
        }

        for entry in transcript[startIndex...].reversed() {
            guard case .response(let response) = entry else { continue }
            let text = response.segments.compactMap { segment -> String? in
                guard case .text(let textSegment) = segment else { return nil }
                return textSegment.content
            }.joined()
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return text
            }
        }
        return nil
    }
}
