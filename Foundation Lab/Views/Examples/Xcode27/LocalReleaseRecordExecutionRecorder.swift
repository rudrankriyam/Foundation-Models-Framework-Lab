//
//  LocalReleaseRecordExecutionRecorder.swift
//  FoundationLab
//

#if compiler(>=6.4)
actor LocalReleaseRecordExecutionRecorder {
    private var outputs: [String] = []

    func record(_ output: String) {
        outputs.append(output)
    }

    func snapshot() -> [String] {
        outputs
    }
}
#endif
