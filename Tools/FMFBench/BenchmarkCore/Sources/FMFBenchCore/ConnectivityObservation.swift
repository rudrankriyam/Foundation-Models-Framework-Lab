import Foundation
import Network

enum FMFBenchConnectivityObservation: String, Sendable {
    case connected
    case disconnected
    case connectionRequired
    case unknown

    var verifiesOfflineExperiment: Bool {
        self == .disconnected
    }

    var displayName: String {
        switch self {
        case .connected:
            "an active network path"
        case .disconnected:
            "no active network path"
        case .connectionRequired:
            "a network path that can connect on demand"
        case .unknown:
            "an unknown network state"
        }
    }

    init(status: NWPath.Status) {
        switch status {
        case .satisfied:
            self = .connected
        case .unsatisfied:
            self = .disconnected
        case .requiresConnection:
            self = .connectionRequired
        @unknown default:
            self = .unknown
        }
    }
}

enum FMFBenchConnectivityObserver {
    static func observe() async -> FMFBenchConnectivityObservation {
        let monitor = NWPathMonitor()
        let state = FMFBenchConnectivityObservationState()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                state.install(continuation)
                monitor.pathUpdateHandler = { path in
                    state.complete(with: FMFBenchConnectivityObservation(status: path.status))
                    monitor.cancel()
                }
                monitor.start(queue: DispatchQueue(label: "FMFBenchConnectivityObserver"))
            }
        } onCancel: {
            state.complete(with: .unknown)
            monitor.cancel()
        }
    }
}

enum FMFBenchOfflineResultPolicy {
    static func isSuccess(connectivityVerified: Bool, model: FMFBenchModel) -> Bool {
        connectivityVerified && model == .onDevice
    }
}

private final class FMFBenchConnectivityObservationState: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<FMFBenchConnectivityObservation, Never>?
    private var completedObservation: FMFBenchConnectivityObservation?

    func install(
        _ continuation: CheckedContinuation<FMFBenchConnectivityObservation, Never>
    ) {
        lock.lock()
        if let completedObservation {
            lock.unlock()
            continuation.resume(returning: completedObservation)
        } else {
            self.continuation = continuation
            lock.unlock()
        }
    }

    func complete(with observation: FMFBenchConnectivityObservation) {
        lock.lock()
        guard completedObservation == nil else {
            lock.unlock()
            return
        }
        completedObservation = observation
        let continuation = continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(returning: observation)
    }
}
