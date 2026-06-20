import Foundation

extension Task where Failure == Error {
    func valuePropagatingCancellation() async throws -> Success {
        try await withTaskCancellationHandler {
            try await value
        } onCancel: {
            cancel()
        }
    }
}
