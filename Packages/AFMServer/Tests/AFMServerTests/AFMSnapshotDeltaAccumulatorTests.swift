import Testing
@testable import AFMServer

@Test("Snapshot accumulation emits only new cumulative content")
func snapshotAccumulatorDeltas() throws {
    var accumulator = AFMSnapshotDeltaAccumulator()

    #expect(try accumulator.append(snapshot: "Hel") == "Hel")
    #expect(try accumulator.append(snapshot: "Hello") == "lo")
    #expect(try accumulator.append(snapshot: "Hello") == "")
    #expect(accumulator.content == "Hello")
}

@Test("Snapshot accumulation preserves extended grapheme clusters")
func snapshotAccumulatorUnicode() throws {
    var accumulator = AFMSnapshotDeltaAccumulator()

    #expect(try accumulator.append(snapshot: "Hello 👨‍👩‍👧‍👦") == "Hello 👨‍👩‍👧‍👦")
    #expect(try accumulator.append(snapshot: "Hello 👨‍👩‍👧‍👦!") == "!")
}

@Test("Snapshot accumulation rejects rewritten content")
func snapshotAccumulatorRejectsNonMonotonicContent() throws {
    var accumulator = AFMSnapshotDeltaAccumulator()
    _ = try accumulator.append(snapshot: "Hello")

    #expect(throws: AFMSnapshotDeltaAccumulator.AccumulationError.nonMonotonicSnapshot) {
        try accumulator.append(snapshot: "Hallo")
    }
}
