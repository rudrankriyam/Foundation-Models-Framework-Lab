import Foundation

enum AFMBridgeResponseAccumulator {
    static func data<Bytes: AsyncSequence>(
        from bytes: Bytes,
        maximumByteCount: Int
    ) async throws -> Data where Bytes.Element == UInt8 {
        var data = Data()
        for try await byte in bytes {
            guard data.count < maximumByteCount else {
                throw AFMBridgeClientError.responseTooLarge(maximumByteCount: maximumByteCount)
            }
            data.append(byte)
        }
        return data
    }
}
