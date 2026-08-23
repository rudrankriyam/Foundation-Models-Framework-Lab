import Foundation
import FoundationModelsTools
import Observation

@MainActor
@Observable
final class ToolMutationApprovalCoordinator {
    private(set) var currentRequest: ToolMutationRequest?

    var isPresentingRequest: Bool {
        get { currentRequest != nil }
        set {
            if !newValue {
                denyCurrentRequest()
            }
        }
    }

    @ObservationIgnored private var activeRequest: PendingRequest?
    @ObservationIgnored private var queuedRequests = [PendingRequest]()

    func confirmation(for request: ToolMutationRequest) async throws -> ToolMutationDecision {
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                enqueue(request, continuation: continuation)
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.cancel(requestID: request.id)
            }
        }
    }

    func approveCurrentRequest() {
        resolveCurrentRequest(with: .approved())
    }

    func denyCurrentRequest() {
        resolveCurrentRequest(
            with: .denied(reason: String(localized: "Denied by the user"))
        )
    }

    func cancelAll() {
        let requests = [activeRequest].compactMap { $0 } + queuedRequests
        activeRequest = nil
        queuedRequests.removeAll()
        currentRequest = nil
        requests.forEach { $0.continuation.resume(throwing: CancellationError()) }
    }

    private func enqueue(
        _ request: ToolMutationRequest,
        continuation: CheckedContinuation<ToolMutationDecision, any Error>
    ) {
        let pendingRequest = PendingRequest(
            request: request,
            continuation: continuation
        )
        guard activeRequest == nil else {
            queuedRequests.append(pendingRequest)
            return
        }

        present(pendingRequest)
    }

    private func resolveCurrentRequest(with decision: ToolMutationDecision) {
        guard let activeRequest else { return }
        self.activeRequest = nil
        currentRequest = nil
        activeRequest.continuation.resume(returning: decision)
        presentNextRequest()
    }

    private func cancel(requestID: UUID) {
        if activeRequest?.request.id == requestID {
            guard let activeRequest else { return }
            self.activeRequest = nil
            currentRequest = nil
            activeRequest.continuation.resume(throwing: CancellationError())
            presentNextRequest()
            return
        }

        guard let index = queuedRequests.firstIndex(where: { $0.request.id == requestID }) else {
            return
        }
        let request = queuedRequests.remove(at: index)
        request.continuation.resume(throwing: CancellationError())
    }

    private func presentNextRequest() {
        guard !queuedRequests.isEmpty else { return }
        present(queuedRequests.removeFirst())
    }

    private func present(_ request: PendingRequest) {
        activeRequest = request
        currentRequest = request.request
    }
}

private struct PendingRequest {
    let request: ToolMutationRequest
    let continuation: CheckedContinuation<ToolMutationDecision, any Error>
}
