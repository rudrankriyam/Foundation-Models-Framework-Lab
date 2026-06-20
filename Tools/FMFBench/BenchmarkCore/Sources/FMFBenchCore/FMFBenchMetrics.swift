import Foundation

public enum FMFBenchTokenCountSource: String, Codable, Sendable {
    case sessionUsage
    case systemTokenizer
    case characterEstimate
}

public struct FMFBenchTrialMetrics: Codable, Sendable {
    public let startedAt: Date
    public let endedAt: Date
    public let duration: TimeInterval
    public let timeToFirstToken: TimeInterval?
    public let decodeDuration: TimeInterval?
    public let inputTokenCount: Int
    public let outputTokenCount: Int
    public let firstStreamUpdateTokenCount: Int
    public let tokenCountSource: FMFBenchTokenCountSource
    public let outputTokensPerSecond: Double?
    public let outputCharactersPerSecond: Double?
    public let streamUpdateCount: Int
    public let maximumStreamUpdateGap: TimeInterval?
    public let reasoningTokenCount: Int?
    public let contextSize: Int?
    public let contextUtilization: Double?
    public let startingResidentMemoryBytes: UInt64?
    public let peakObservedResidentMemoryBytes: UInt64?
    public let endingResidentMemoryBytes: UInt64?
    public let startingThermalState: String
    public let endingThermalState: String
    public let worstObservedThermalState: String

    public init(
        startedAt: Date,
        endedAt: Date,
        firstTokenAt: Date?,
        inputTokenCount: Int,
        outputTokenCount: Int,
        firstStreamUpdateTokenCount: Int,
        tokenCountSource: FMFBenchTokenCountSource,
        responseCharacterCount: Int,
        streamUpdateDates: [Date],
        reasoningTokenCount: Int? = nil,
        contextSize: Int? = nil,
        resourceSnapshots: [FMFBenchResourceSnapshot] = []
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = endedAt.timeIntervalSince(startedAt)
        self.timeToFirstToken = firstTokenAt.map { $0.timeIntervalSince(startedAt) }

        if let timeToFirstToken, duration > timeToFirstToken {
            let decodeDuration = duration - timeToFirstToken
            self.decodeDuration = decodeDuration
            let decodedTokenCount = max(0, outputTokenCount - firstStreamUpdateTokenCount)
            self.outputTokensPerSecond = Double(decodedTokenCount) / decodeDuration
            self.outputCharactersPerSecond = Double(responseCharacterCount) / decodeDuration
        } else {
            self.decodeDuration = nil
            self.outputTokensPerSecond = nil
            self.outputCharactersPerSecond = nil
        }

        self.inputTokenCount = inputTokenCount
        self.outputTokenCount = outputTokenCount
        self.firstStreamUpdateTokenCount = firstStreamUpdateTokenCount
        self.tokenCountSource = tokenCountSource
        self.streamUpdateCount = streamUpdateDates.count
        self.maximumStreamUpdateGap = zip(streamUpdateDates, streamUpdateDates.dropFirst())
            .map { $1.timeIntervalSince($0) }
            .max()
        self.reasoningTokenCount = reasoningTokenCount
        self.contextSize = contextSize
        self.contextUtilization = contextSize.flatMap { size in
            size > 0 ? Double(inputTokenCount) / Double(size) : nil
        }
        self.startingResidentMemoryBytes = resourceSnapshots.first?.residentMemoryBytes
        self.peakObservedResidentMemoryBytes = resourceSnapshots.compactMap(\.residentMemoryBytes)
            .max()
        self.endingResidentMemoryBytes = resourceSnapshots.last?.residentMemoryBytes
        self.startingThermalState = resourceSnapshots.first?.thermalState ?? "unknown"
        self.endingThermalState = resourceSnapshots.last?.thermalState ?? "unknown"
        self.worstObservedThermalState = worstThermalState(resourceSnapshots.map(\.thermalState))
    }
}

public struct FMFBenchDistribution: Codable, Sendable {
    public let count: Int
    public let minimum: Double?
    public let median: Double?
    public let mean: Double?
    public let p90: Double?
    public let maximum: Double?
    public let standardDeviation: Double?

    public init(values: [Double]) {
        let sorted = values.sorted()
        count = sorted.count
        minimum = sorted.first
        median = Self.percentile(0.5, values: sorted)
        p90 = Self.percentile(0.9, values: sorted)
        maximum = sorted.last

        if sorted.isEmpty {
            mean = nil
            standardDeviation = nil
        } else {
            let mean = sorted.reduce(0, +) / Double(sorted.count)
            self.mean = mean
            let variance = sorted.reduce(0) { $0 + pow($1 - mean, 2) } / Double(sorted.count)
            self.standardDeviation = sqrt(variance)
        }
    }

    private static func percentile(_ percentile: Double, values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let rank = Int(ceil(percentile * Double(values.count))) - 1
        return values[max(0, min(rank, values.count - 1))]
    }
}
