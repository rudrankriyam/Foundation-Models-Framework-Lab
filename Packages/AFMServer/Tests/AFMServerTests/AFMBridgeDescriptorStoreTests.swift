import Darwin
import Foundation
import Testing
@testable import AFMServer

@Test("Descriptor publication is atomic, current-user-only, and readable")
func bridgeDescriptorPublishAndRead() throws {
    try withAFMBridgeTemporaryDirectory { parent in
        let directory = (parent as NSString).appendingPathComponent("bridge")
        let store = try AFMBridgeDescriptorStore(directoryPath: directory)
        let descriptor = try makeAFMBridgeTestDescriptor(modelIdentifiers: ["system", "pcc"])
        let lease = try store.publish(descriptor)

        #expect(lease.descriptorPath == store.descriptorPath)
        #expect(try store.read() == descriptor)
        let status = try afmBridgeStatus(at: store.descriptorPath)
        #expect((status.st_mode & S_IFMT) == S_IFREG)
        #expect(status.st_uid == geteuid())
        #expect(status.st_nlink == 1)
        #expect(afmBridgePermissions(status) == mode_t(0o600))
    }
}

@Test("Descriptor rotation makes old leases harmless and supports stale crash replacement")
func bridgeDescriptorRotationAndCrashReplacement() throws {
    try withAFMBridgeTemporaryDirectory { parent in
        let directory = (parent as NSString).appendingPathComponent("bridge")
        let store = try AFMBridgeDescriptorStore(directoryPath: directory)
        try AFMBridgeDirectory.prepare(at: directory)

        try Data("interrupted previous launch".utf8).write(to: URL(fileURLWithPath: store.descriptorPath))
        #expect(Darwin.chmod(store.descriptorPath, mode_t(0o600)) == 0)

        let first = try makeAFMBridgeTestDescriptor(launchIdentifier: UUID(), modelIdentifiers: ["system"])
        let firstLease = try store.publish(first)
        #expect(try store.read() == first)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory) == [store.fileName])

        let second = try makeAFMBridgeTestDescriptor(launchIdentifier: UUID(), modelIdentifiers: ["system", "pcc"])
        let secondLease = try store.publish(second)
        try firstLease.cleanup()
        #expect(try store.read() == second)

        try secondLease.cleanup()
        #expect(throws: AFMBridgeDescriptorError.descriptorMissing) {
            try store.read()
        }
    }
}

@Test("Descriptor leases never delete a replacement inode")
func bridgeDescriptorLeaseInodeSafety() throws {
    try withAFMBridgeTemporaryDirectory { parent in
        let directory = (parent as NSString).appendingPathComponent("bridge")
        let store = try AFMBridgeDescriptorStore(directoryPath: directory)
        let lease = try store.publish(makeAFMBridgeTestDescriptor())
        #expect(Darwin.unlink(store.descriptorPath) == 0)

        let replacement = Data("replacement".utf8)
        try replacement.write(to: URL(fileURLWithPath: store.descriptorPath))
        #expect(Darwin.chmod(store.descriptorPath, mode_t(0o600)) == 0)

        try lease.cleanup()
        #expect(try Data(contentsOf: URL(fileURLWithPath: store.descriptorPath)) == replacement)
    }
}

@Test("Descriptor publication refuses unsafe existing targets without changing them")
func bridgeDescriptorPublishRefusesUnsafeTargets() throws {
    try withAFMBridgeTemporaryDirectory { parent in
        let directory = (parent as NSString).appendingPathComponent("bridge")
        let store = try AFMBridgeDescriptorStore(directoryPath: directory)
        try AFMBridgeDirectory.prepare(at: directory)
        let descriptor = try makeAFMBridgeTestDescriptor()

        let target = (parent as NSString).appendingPathComponent("target")
        let targetData = Data("do not replace".utf8)
        #expect(FileManager.default.createFile(atPath: target, contents: targetData))
        #expect(Darwin.symlink(target, store.descriptorPath) == 0)
        #expect(throws: AFMBridgeDescriptorError.self) {
            try store.publish(descriptor)
        }
        #expect(try Data(contentsOf: URL(fileURLWithPath: target)) == targetData)
        #expect(try temporaryDescriptorNames(in: directory).isEmpty)

        #expect(Darwin.unlink(store.descriptorPath) == 0)
        let unsafeData = Data("unsafe mode".utf8)
        try unsafeData.write(to: URL(fileURLWithPath: store.descriptorPath))
        #expect(Darwin.chmod(store.descriptorPath, mode_t(0o644)) == 0)
        #expect(throws: AFMBridgeDescriptorError.permissionsMismatch(expected: 0o600, actual: 0o644)) {
            try store.publish(descriptor)
        }
        #expect(try Data(contentsOf: URL(fileURLWithPath: store.descriptorPath)) == unsafeData)
        #expect(try temporaryDescriptorNames(in: directory).isEmpty)

        #expect(Darwin.unlink(store.descriptorPath) == 0)
        #expect(Darwin.mkdir(store.descriptorPath, mode_t(0o700)) == 0)
        #expect(throws: AFMBridgeDescriptorError.self) {
            try store.publish(descriptor)
        }
        #expect(try temporaryDescriptorNames(in: directory).isEmpty)

        #expect(Darwin.rmdir(store.descriptorPath) == 0)
        #expect(Darwin.mkfifo(store.descriptorPath, mode_t(0o600)) == 0)
        #expect(throws: AFMBridgeDescriptorError.self) {
            try store.publish(descriptor)
        }
    }
}

@Test("Descriptor reads reject symlinks, wrong modes, hard links, malformed data, and oversized data")
func bridgeDescriptorReadValidation() throws {
    try withAFMBridgeTemporaryDirectory { parent in
        let directory = (parent as NSString).appendingPathComponent("bridge")
        let store = try AFMBridgeDescriptorStore(directoryPath: directory)
        try AFMBridgeDirectory.prepare(at: directory)

        let target = (parent as NSString).appendingPathComponent("target")
        #expect(FileManager.default.createFile(atPath: target, contents: Data("{}".utf8)))
        #expect(Darwin.symlink(target, store.descriptorPath) == 0)
        #expect(throws: AFMBridgeDescriptorError.self) { try store.read() }

        #expect(Darwin.unlink(store.descriptorPath) == 0)
        try Data("{}".utf8).write(to: URL(fileURLWithPath: store.descriptorPath))
        #expect(Darwin.chmod(store.descriptorPath, mode_t(0o644)) == 0)
        #expect(throws: AFMBridgeDescriptorError.permissionsMismatch(expected: 0o600, actual: 0o644)) {
            try store.read()
        }

        #expect(Darwin.unlink(store.descriptorPath) == 0)
        try Data("not json".utf8).write(to: URL(fileURLWithPath: store.descriptorPath))
        #expect(Darwin.chmod(store.descriptorPath, mode_t(0o600)) == 0)
        #expect(throws: AFMBridgeDescriptorError.decodingFailed) { try store.read() }

        #expect(Darwin.unlink(store.descriptorPath) == 0)
        let unsupported = try makeAFMBridgeTestDescriptor()
        let unsupportedVersion = AFMBridgeConnectionDescriptor(
            version: 2,
            endpoint: unsupported.endpoint,
            bearerToken: unsupported.bearerToken,
            processIdentifier: unsupported.processIdentifier,
            launchIdentifier: unsupported.launchIdentifier,
            modelIdentifiers: unsupported.modelIdentifiers,
            startedAt: unsupported.startedAt
        )
        try JSONEncoder().encode(unsupportedVersion).write(to: URL(fileURLWithPath: store.descriptorPath))
        #expect(Darwin.chmod(store.descriptorPath, mode_t(0o600)) == 0)
        #expect(throws: AFMBridgeDescriptorError.unsupportedVersion(2)) { try store.read() }

        #expect(Darwin.unlink(store.descriptorPath) == 0)
        try Data(repeating: 65, count: AFMBridgeDescriptorStore.maximumDescriptorByteCount + 1)
            .write(to: URL(fileURLWithPath: store.descriptorPath))
        #expect(Darwin.chmod(store.descriptorPath, mode_t(0o600)) == 0)
        #expect(throws: AFMBridgeDescriptorError.descriptorTooLarge) { try store.read() }

        #expect(Darwin.unlink(store.descriptorPath) == 0)
        let hardLinkSource = (parent as NSString).appendingPathComponent("hard-link-source")
        try Data("{}".utf8).write(to: URL(fileURLWithPath: hardLinkSource))
        #expect(Darwin.chmod(hardLinkSource, mode_t(0o600)) == 0)
        #expect(Darwin.link(hardLinkSource, store.descriptorPath) == 0)
        #expect(throws: AFMBridgeDescriptorError.tooManyLinks) { try store.read() }

        #expect(Darwin.unlink(store.descriptorPath) == 0)
        #expect(Darwin.mkfifo(store.descriptorPath, mode_t(0o600)) == 0)
        #expect(throws: AFMBridgeDescriptorError.self) { try store.read() }
    }
}

@Test("Descriptor store rejects unsafe file names")
func bridgeDescriptorStoreFileNameValidation() {
    for fileName in ["", ".", "..", "nested/connection.json", "connection\0.json"] {
        #expect(throws: AFMBridgeDescriptorError.invalidFileName) {
            try AFMBridgeDescriptorStore(directoryPath: "/tmp/bridge", fileName: fileName)
        }
    }
}

private func temporaryDescriptorNames(in directory: String) throws -> [String] {
    try FileManager.default.contentsOfDirectory(atPath: directory).filter { name in
        name.hasPrefix(".connection.json.")
    }
}
