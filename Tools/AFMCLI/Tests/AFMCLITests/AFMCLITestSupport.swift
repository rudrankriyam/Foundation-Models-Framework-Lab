import Foundation
import Testing

struct CommandResult {
    let status: Int32
    let stdout: String
    let stderr: String
}

func runAFM(
    _ arguments: String...,
    environment: [String: String] = [:],
    stdin: String? = nil
) throws -> CommandResult {
    try runAFM(arguments, environment: environment, stdin: stdin)
}

func runAFM(
    _ arguments: [String],
    environment: [String: String] = [:],
    stdin: String? = nil
) throws -> CommandResult {
    let process = Process()
    process.executableURL = try findAFMBinary()
    process.currentDirectoryURL = packageRoot()
    process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    let stdinPipe = stdin.map { _ in Pipe() }
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe
    process.standardInput = stdinPipe ?? FileHandle.nullDevice
    process.arguments = arguments

    try process.run()
    let readGroup = DispatchGroup()
    let stdoutBuffer = CommandDataBuffer()
    let stderrBuffer = CommandDataBuffer()
    captureProcessOutput(from: stdoutPipe.fileHandleForReading, into: stdoutBuffer, group: readGroup)
    captureProcessOutput(from: stderrPipe.fileHandleForReading, into: stderrBuffer, group: readGroup)

    if let stdin, let stdinPipe {
        stdinPipe.fileHandleForWriting.write(Data(stdin.utf8))
        try? stdinPipe.fileHandleForWriting.close()
    }
    process.waitUntilExit()
    readGroup.wait()

    return CommandResult(
        status: process.terminationStatus,
        stdout: decodedOutput(stdoutBuffer.data),
        stderr: decodedOutput(stderrBuffer.data)
    )
}

func parseJSONObject(_ text: String) throws -> [String: Any] {
    let data = try #require(text.data(using: .utf8))
    let object = try JSONSerialization.jsonObject(with: data)
    return try #require(object as? [String: Any])
}

func parseJSONLines(_ text: String) throws -> [[String: Any]] {
    let lines = text
        .split(separator: "\n")
        .map(String.init)
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    return try lines.map(parseJSONObject)
}

private final class CommandDataBuffer: @unchecked Sendable {
    var data = Data()
}

private func captureProcessOutput(
    from handle: FileHandle,
    into buffer: CommandDataBuffer,
    group: DispatchGroup
) {
    group.enter()
    DispatchQueue.global(qos: .userInitiated).async {
        buffer.data = handle.readDataToEndOfFile()
        group.leave()
    }
}

private func decodedOutput(_ data: Data) -> String {
    (String(data: data, encoding: .utf8) ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

func findAFMBinary() throws -> URL {
    let root = packageRoot()
    let directCandidates = [
        root.appending(path: ".build/debug/afm"),
        root.appending(path: ".build/arm64-apple-macosx/debug/afm"),
        root.appending(path: ".build/x86_64-apple-macosx/debug/afm")
    ]

    for candidate in directCandidates where FileManager.default.isExecutableFile(atPath: candidate.path()) {
        return candidate
    }

    let buildRoot = root.appending(path: ".build")
    if let enumerator = FileManager.default.enumerator(at: buildRoot, includingPropertiesForKeys: nil) {
        for case let fileURL as URL in enumerator where fileURL.lastPathComponent == "afm" {
            if FileManager.default.isExecutableFile(atPath: fileURL.path()) {
                return fileURL
            }
        }
    }

    throw TestFailure("Could not find built afm executable under \(buildRoot.path())")
}

func packageRoot() -> URL {
    var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

    while directory.path != "/" {
        let manifest = directory.appending(path: "Package.swift")
        if FileManager.default.fileExists(atPath: manifest.path()) {
            return directory
        }
        directory.deleteLastPathComponent()
    }

    preconditionFailure("Could not find the package root above \(#filePath)")
}

private struct TestFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
