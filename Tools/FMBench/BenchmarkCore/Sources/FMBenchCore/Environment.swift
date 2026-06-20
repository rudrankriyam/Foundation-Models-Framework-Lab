import Foundation

public struct EnvironmentSnapshot: Codable, Sendable {
    public let deviceName: String
    public let systemName: String
    public let systemVersion: String
    public let systemBuild: String?
    public let localeIdentifier: String
    public let hardwareModel: String?
    public let cpuModel: String?
    public let cpuCores: Int?
    public let gpuModel: String?
    public let totalMemory: UInt64?
    public let thermalState: String
    public let lowPowerModeEnabled: Bool
    public let fmBenchCommit: String?
    public let timestamp: Date

    public init(
        deviceName: String,
        systemName: String,
        systemVersion: String,
        systemBuild: String?,
        localeIdentifier: String,
        hardwareModel: String?,
        cpuModel: String?,
        cpuCores: Int?,
        gpuModel: String?,
        totalMemory: UInt64?,
        thermalState: String,
        lowPowerModeEnabled: Bool,
        fmBenchCommit: String?,
        timestamp: Date = .now
    ) {
        self.deviceName = deviceName
        self.systemName = systemName
        self.systemVersion = systemVersion
        self.systemBuild = systemBuild
        self.localeIdentifier = localeIdentifier
        self.hardwareModel = hardwareModel
        self.cpuModel = cpuModel
        self.cpuCores = cpuCores
        self.gpuModel = gpuModel
        self.totalMemory = totalMemory
        self.thermalState = thermalState
        self.lowPowerModeEnabled = lowPowerModeEnabled
        self.fmBenchCommit = fmBenchCommit
        self.timestamp = timestamp
    }

    public static func capture() -> EnvironmentSnapshot {
        let processInfo = ProcessInfo.processInfo
        let version = processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        #if os(macOS)
        let systemName = "macOS"
        let hardwareModel = sysctlString("hw.model")
        let cpuModel = sysctlString("machdep.cpu.brand_string")
        let gpuModel = cpuModel
        #elseif os(iOS)
        let systemName = "iOS"
        let hardwareModel = processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? sysctlString("hw.machine")
        let cpuModel = "Apple A-series"
        let gpuModel = "Apple GPU"
        #elseif os(visionOS)
        let systemName = "visionOS"
        let hardwareModel = processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? sysctlString("hw.machine")
        let cpuModel = "Apple M/R-series"
        let gpuModel = "Apple GPU"
        #else
        let systemName = processInfo.operatingSystemVersionString
        let hardwareModel: String? = nil
        let cpuModel: String? = nil
        let gpuModel: String? = nil
        #endif

        return EnvironmentSnapshot(
            deviceName: processInfo.environment["FMBENCH_DEVICE_NAME"] ?? hardwareModel ?? systemName,
            systemName: systemName,
            systemVersion: versionString,
            systemBuild: operatingSystemBuild(),
            localeIdentifier: Locale.current.identifier,
            hardwareModel: hardwareModel,
            cpuModel: cpuModel,
            cpuCores: processInfo.processorCount,
            gpuModel: gpuModel,
            totalMemory: processInfo.physicalMemory,
            thermalState: thermalStateName(processInfo.thermalState),
            lowPowerModeEnabled: processInfo.isLowPowerModeEnabled,
            fmBenchCommit: processInfo.environment["FMBENCH_COMMIT"]
        )
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var value = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
        let bytes = value.prefix { $0 != 0 }.map(UInt8.init(bitPattern:))
        return String(bytes: bytes, encoding: .utf8)
    }

    private static func operatingSystemBuild() -> String? {
        #if os(macOS)
        return sysctlString("kern.osversion")
        #else
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }

    private static func thermalStateName(_ state: ProcessInfo.ThermalState) -> String {
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
}
