import Darwin
import Foundation
import MachO

public struct FMBenchResourceSnapshot: Sendable {
    public let residentMemoryBytes: UInt64?
    public let thermalState: String

    public init(residentMemoryBytes: UInt64?, thermalState: String) {
        self.residentMemoryBytes = residentMemoryBytes
        self.thermalState = thermalState
    }

    static func capture() -> FMBenchResourceSnapshot {
        FMBenchResourceSnapshot(
            residentMemoryBytes: residentMemory(),
            thermalState: thermalStateName(ProcessInfo.processInfo.thermalState)
        )
    }

    private static func residentMemory() -> UInt64? {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size
        )
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return UInt64(info.resident_size)
    }
}

func thermalStateName(_ state: ProcessInfo.ThermalState) -> String {
    switch state {
    case .nominal:
        "nominal"
    case .fair:
        "fair"
    case .serious:
        "serious"
    case .critical:
        "critical"
    @unknown default:
        "unknown"
    }
}

func worstThermalState(_ states: [String]) -> String {
    let rank = ["unknown": -1, "nominal": 0, "fair": 1, "serious": 2, "critical": 3]
    return states.max { rank[$0, default: -1] < rank[$1, default: -1] } ?? "unknown"
}
