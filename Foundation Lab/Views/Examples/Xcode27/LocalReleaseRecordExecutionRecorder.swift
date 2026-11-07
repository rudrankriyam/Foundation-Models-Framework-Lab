//
//  LocalReleaseRecordExecutionRecorder.swift
//  FoundationLab
//

actor LocalReleaseRecordExecutionRecorder {
    private var outputs: [String] = []

    func record(_ output: String) {
        outputs.append(output)
    }

    func snapshot() -> [String] {
        outputs
    }
}
