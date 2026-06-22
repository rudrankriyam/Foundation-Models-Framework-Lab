import Darwin
import Foundation

public enum AFMBridgeDirectory {
    public static func prepare(at path: String) throws {
        try AFMBridgePOSIX.validateAbsolutePath(path)
        if Darwin.mkdir(path, AFMBridgePOSIX.directoryMode) != 0, errno != EEXIST {
            throw AFMBridgePOSIX.posixError(operation: "create the bridge directory")
        }
        let descriptor = try AFMBridgePOSIX.openDirectory(at: path, repairPermissions: true)
        Darwin.close(descriptor)
    }

    public static func validate(at path: String) throws {
        let descriptor = try AFMBridgePOSIX.openDirectory(at: path, repairPermissions: false)
        Darwin.close(descriptor)
    }
}
