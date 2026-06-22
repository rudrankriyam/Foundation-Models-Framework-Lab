import Darwin
import Dispatch

final class AFMTerminationSignal: @unchecked Sendable {
    private let stream: AsyncStream<Int32>
    private let continuation: AsyncStream<Int32>.Continuation
    private let sources: [DispatchSourceSignal]

    init() {
        let pair = AsyncStream.makeStream(of: Int32.self)
        stream = pair.stream
        continuation = pair.continuation

        let handledSignals = [SIGINT, SIGTERM]
        for signalNumber in handledSignals {
            Darwin.signal(signalNumber, SIG_IGN)
        }
        sources = handledSignals.map { signalNumber in
            let source = DispatchSource.makeSignalSource(signal: signalNumber)
            source.setEventHandler {
                pair.continuation.yield(signalNumber)
            }
            source.resume()
            return source
        }
    }

    deinit {
        for source in sources {
            source.cancel()
        }
        continuation.finish()
    }

    func wait() async {
        for await _ in stream {
            return
        }
    }
}
