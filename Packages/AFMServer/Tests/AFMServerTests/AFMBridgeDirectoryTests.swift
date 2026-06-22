import Darwin
import Foundation
import Testing
@testable import AFMServer

@Test("Bridge directory preparation creates and repairs exact current-user-only permissions")
func bridgeDirectoryPreparationAndValidation() throws {
    try withAFMBridgeTemporaryDirectory { parent in
        let directory = (parent as NSString).appendingPathComponent("bridge")
        try AFMBridgeDirectory.prepare(at: directory)

        var status = try afmBridgeStatus(at: directory)
        #expect((status.st_mode & S_IFMT) == S_IFDIR)
        #expect(status.st_uid == geteuid())
        #expect(afmBridgePermissions(status) == mode_t(0o700))
        try AFMBridgeDirectory.validate(at: directory)

        #expect(Darwin.chmod(directory, mode_t(0o755)) == 0)
        #expect(throws: AFMBridgeDescriptorError.permissionsMismatch(expected: 0o700, actual: 0o755)) {
            try AFMBridgeDirectory.validate(at: directory)
        }

        try AFMBridgeDirectory.prepare(at: directory)
        status = try afmBridgeStatus(at: directory)
        #expect(afmBridgePermissions(status) == mode_t(0o700))
    }
}

@Test("Bridge directory preparation refuses symlinks and non-directory objects")
func bridgeDirectoryRefusesUnsafeObjects() throws {
    try withAFMBridgeTemporaryDirectory { parent in
        let realDirectory = (parent as NSString).appendingPathComponent("real")
        let symlinkPath = (parent as NSString).appendingPathComponent("link")
        let filePath = (parent as NSString).appendingPathComponent("file")
        try AFMBridgeDirectory.prepare(at: realDirectory)
        #expect(Darwin.symlink(realDirectory, symlinkPath) == 0)
        #expect(FileManager.default.createFile(atPath: filePath, contents: Data("safe".utf8)))

        #expect(throws: AFMBridgeDescriptorError.self) {
            try AFMBridgeDirectory.prepare(at: symlinkPath)
        }
        #expect(throws: AFMBridgeDescriptorError.self) {
            try AFMBridgeDirectory.prepare(at: filePath)
        }
        #expect(try Data(contentsOf: URL(fileURLWithPath: filePath)) == Data("safe".utf8))
    }
}

@Test("Bridge directory paths must be absolute")
func bridgeDirectoryRejectsRelativePaths() {
    #expect(throws: AFMBridgeDescriptorError.invalidPath) {
        try AFMBridgeDirectory.prepare(at: "relative/bridge")
    }
}
