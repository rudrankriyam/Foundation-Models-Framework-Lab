import Foundation

enum ChatGenerationOutcome: Equatable {
    case succeeded(String)
    case cancelled
    case failed(String)
    case notStarted
}
