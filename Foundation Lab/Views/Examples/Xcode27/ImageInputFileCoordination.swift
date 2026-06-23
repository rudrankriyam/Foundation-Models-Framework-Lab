//
//  ImageInputFileCoordination.swift
//  FoundationLab
//

#if compiler(>=6.4)
import Foundation

nonisolated final class ImageInputFileCoordination: @unchecked Sendable {
    let coordinator = NSFileCoordinator()
    let intent: NSFileAccessIntent
    let queue: OperationQueue

    private let lock = NSLock()
    private var isCancelled = false

    init(url: URL) {
        intent = NSFileAccessIntent.readingIntent(with: url, options: [])

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "ImageInputFileCoordination"
        self.queue = queue
    }

    func cancel() {
        lock.lock()
        isCancelled = true
        lock.unlock()
        coordinator.cancel()
    }

    func checkCancellation() throws {
        try Task.checkCancellation()

        lock.lock()
        let wasCancelled = isCancelled
        lock.unlock()
        if wasCancelled {
            throw CancellationError()
        }
    }
}
#endif
