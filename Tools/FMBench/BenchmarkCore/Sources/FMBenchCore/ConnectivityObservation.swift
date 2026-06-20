import Foundation
import Network

enum FMBenchConnectivityObservation: String, Sendable {
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

enum FMBenchConnectivityObserver {
    static func observe() async -> FMBenchConnectivityObservation {
        let monitor = NWPathMonitor()
        let state = FMBenchConnectivityObservationState()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                state.install(continuation)
                monitor.pathUpdateHandler = { path in
                    state.complete(with: FMBenchConnectivityObservation(status: path.status))
                    monitor.cancel()
                }
                monitor.start(queue: DispatchQueue(label: "FMBenchConnectivityObserver"))
            }
        } onCancel: {
            state.complete(with: .unknown)
            monitor.cancel()
        }
    }
}

enum FMBenchOfflineResultPolicy {
    static func isSuccess(connectivityVerified: Bool, model: FMBenchModel) -> Bool {
        connectivityVerified && model == .onDevice
    }
}

private final class FMBenchConnectivityObservationState: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<FMBenchConnectivityObservation, Never>?
    private var completedObservation: FMBenchConnectivityObservation?

    func install(
        _ continuation: CheckedContinuation<FMBenchConnectivityObservation, Never>
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

    func complete(with observation: FMBenchConnectivityObservation) {
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
