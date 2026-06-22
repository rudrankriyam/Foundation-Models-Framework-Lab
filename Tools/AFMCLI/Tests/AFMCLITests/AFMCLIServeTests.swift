import Darwin
import Foundation
import Testing

@Test("Serve command is discoverable and documents its security controls")
func serveHelp() throws {
    let root = try runAFM("--help")
    let serve = try runAFM("serve", "--help")

    #expect(root.status == 0)
    #expect(root.stdout.contains("SERVER COMMANDS"))
    #expect(root.stdout.contains("afm serve"))
    #expect(serve.status == 0)
    for flag in ["--host", "--port", "--socket", "--allow-network", "--token", "--allow-origin"] {
        #expect(serve.stdout.contains(flag))
    }
}

@Test("Serve dry-run resolves defaults without exposing bearer tokens")
func serveDryRun() throws {
    let result = try runAFM("serve", "--output", "json", "--dry-run", "--token", "do-not-print-me")

    #expect(result.status == 0)
    #expect(!result.stdout.contains("do-not-print-me"))
    let json = try parseJSONObject(result.stdout)
    #expect(json["status"] as? String == "dry_run")
    #expect(json["command"] as? String == "serve")
    #expect(json["endpoint"] as? String == "http://127.0.0.1:1976")
    #expect(json["authenticationEnabled"] as? Bool == true)
}

@Test("Serve rejects unsafe binding combinations before listening")
func serveConfigurationValidation() throws {
    let implicitNetwork = try runAFM(
        ["serve", "--dry-run", "--host", "0.0.0.0"],
        environment: ["AFM_SERVER_TOKEN": ""]
    )
    #expect(implicitNetwork.status == 64)
    #expect(implicitNetwork.stderr.contains("requires explicit network opt-in"))

    let unauthenticatedNetwork = try runAFM(
        ["serve", "--dry-run", "--host", "0.0.0.0", "--allow-network"],
        environment: ["AFM_SERVER_TOKEN": ""]
    )
    #expect(unauthenticatedNetwork.status == 64)
    #expect(unauthenticatedNetwork.stderr.contains("requires a bearer token"))

    let mixedTransports = try runAFM(
        "serve", "--dry-run", "--socket", "/tmp/afm.sock", "--host", "127.0.0.1"
    )
    #expect(mixedTransports.status == 64)
    #expect(mixedTransports.stderr.contains("--socket cannot be combined"))

    let wildcardOrigin = try runAFM("serve", "--dry-run", "--allow-origin", "*")
    #expect(wildcardOrigin.status == 64)
    #expect(wildcardOrigin.stderr.contains("exact, non-empty origins"))
}

@Test("SIGTERM gracefully removes a CLI Unix-domain socket")
func serveGracefulShutdown() throws {
    let path = "/tmp/afm-cli-\(UUID().uuidString.prefix(8)).sock"
    let process = Process()
    process.executableURL = try findAFMBinary()
    process.currentDirectoryURL = packageRoot()
    let secret = "never-print-this-token"
    process.arguments = ["serve", "--socket", path, "--output", "json", "--token", secret]

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe
    process.standardInput = FileHandle.nullDevice
    defer {
        if process.isRunning {
            Darwin.kill(process.processIdentifier, SIGKILL)
        }
        Darwin.unlink(path)
    }

    try process.run()
    waitForSocket(path: path, process: process)
    #expect(FileManager.default.fileExists(atPath: path))
    guard process.isRunning else {
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        Issue.record("afm serve exited before startup: \(stderr)")
        return
    }

    let startupOutput = readStartupOutput(from: stdoutPipe)

    #expect(Darwin.kill(process.processIdentifier, SIGTERM) == 0)
    waitForShutdown(process)

    var completeOutput = startupOutput
    completeOutput.append(stdoutPipe.fileHandleForReading.readDataToEndOfFile())
    let stdout = String(data: completeOutput, encoding: .utf8) ?? ""
    let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    #expect(process.terminationStatus == 0)
    let json = try parseJSONObject(stdout)
    #expect(json["status"] as? String == "started")
    #expect(json["command"] as? String == "serve")
    #expect(json["endpoint"] as? String == "unix://\(path)")
    #expect(json["transport"] as? String == "unix")
    #expect(json["authenticationEnabled"] as? Bool == true)
    #expect(!stdout.contains(secret))
    #expect(!stderr.contains(secret))
    #expect(!FileManager.default.fileExists(atPath: path))
}

private func waitForSocket(path: String, process: Process) {
    let deadline = Date().addingTimeInterval(5)
    while !FileManager.default.fileExists(atPath: path),
          process.isRunning,
          Date() < deadline {
        usleep(20_000)
    }
}

private func readStartupOutput(from pipe: Pipe) -> Data {
    var descriptor = pollfd(
        fd: pipe.fileHandleForReading.fileDescriptor,
        events: Int16(POLLIN),
        revents: 0
    )
    #expect(Darwin.poll(&descriptor, 1, 2_000) == 1)
    return pipe.fileHandleForReading.availableData
}

private func waitForShutdown(_ process: Process) {
    let deadline = Date().addingTimeInterval(5)
    while process.isRunning, Date() < deadline {
        usleep(20_000)
    }
    if process.isRunning {
        Issue.record("afm serve did not stop after SIGTERM")
        Darwin.kill(process.processIdentifier, SIGKILL)
    }
    process.waitUntilExit()
}
