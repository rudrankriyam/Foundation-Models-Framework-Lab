import Foundation
import Testing

@Suite("AFM token-count")
struct AFMCLITokenCountTests {
    @Test("JSON output carries provenance, context, and an additive breakdown")
    func jsonOutputCarriesProvenance() throws {
        let result = try runAFM(
            "token-count", "--output", "json",
            "Hello world",
            "--instructions", "Be concise.",
            "--text", "A second segment."
        )

        #expect(result.status == 0)
        let json = try parseJSONObject(result.stdout)
        let usage = try #require(json["usage"] as? [String: Any])
        let input = try #require(usage["input"] as? [String: Any])
        let components = try #require(json["components"] as? [[String: Any]])
        let total = try #require(usage["totalTokenCount"] as? Int)
        let componentTotal = components.reduce(0) {
            $0 + (($1["tokenCount"] as? Int) ?? 0)
        }

        #expect(json["command"] as? String == "token-count")
        #expect(["tokenized", "estimated"].contains(usage["measurement"] as? String))
        #expect(usage["scope"] as? String == "context")
        #expect(input["cachedTokenCount"] == nil)
        #expect(usage["output"] == nil)
        #expect(total > 0)
        #expect(componentTotal == total)
        #expect(json["componentTokenCount"] as? Int == total)
    }

    @Test("Quiet mode matches Apple's fm tokenizer when it is installed")
    func quietModeMatchesFM() throws {
        let prompt = try runAFM("token-count", "--quiet", "Hello world")
        let instructed = try runAFM(
            "token-count", "--quiet", "--instructions", "Be concise.", "Hello world"
        )

        #expect(prompt.status == 0)
        #expect(instructed.status == 0)
        #expect(Int(prompt.stdout) != nil)
        #expect(Int(instructed.stdout) != nil)

        guard FileManager.default.isExecutableFile(atPath: "/usr/bin/fm") else {
            return
        }
        let fmPrompt = try runExternal(
            executable: "/usr/bin/fm",
            arguments: ["token-count", "--quiet", "Hello world"]
        )
        let fmInstructed = try runExternal(
            executable: "/usr/bin/fm",
            arguments: [
                "token-count", "--quiet", "--instructions", "Be concise.", "Hello world"
            ]
        )

        // The binary can exist on hosted macOS runners where Apple Intelligence
        // and its tokenizer assets are unavailable. Keep this a live parity
        // assertion when both native invocations can actually produce counts.
        guard fmPrompt.status == 0, fmInstructed.status == 0 else {
            return
        }
        #expect(prompt.stdout == fmPrompt.stdout)
        #expect(instructed.stdout == fmInstructed.stdout)
    }

    @Test("Prompt, instructions, files, and stdin compose predictably")
    func fileAndStdinInputsCompose() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appending(path: "afm-token-inputs-\(UUID().uuidString)")
        let instructions = directory.appending(path: "instructions.txt")
        let extra = directory.appending(path: "extra.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try "Answer as a Swift expert.".write(to: instructions, atomically: true, encoding: .utf8)
        try "Include one code example.".write(to: extra, atomically: true, encoding: .utf8)

        let result = try runAFM(
            [
                "token-count", "--output", "json", "--stdin",
                "--instructions-file", instructions.path(),
                "--text", "@\(extra.path())"
            ],
            stdin: "Explain actors."
        )

        #expect(result.status == 0)
        let json = try parseJSONObject(result.stdout)
        let components = try #require(json["components"] as? [[String: Any]])
        #expect(components.compactMap { $0["kind"] as? String } == ["instructions", "prompt"])
        #expect(components.compactMap { $0["itemCount"] as? Int } == [1, 2])
    }

    @Test("Schema and tool manifests participate in token counting")
    func schemaAndToolsParticipate() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appending(path: "afm-token-artifacts-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let schema = """
        {
          "title": "Person",
          "type": "object",
          "properties": { "name": { "type": "string" } },
          "required": ["name"]
        }
        """
        let tool = """
        name: echo
        description: Echoes a value.
        parameters:
          title: EchoArguments
          type: object
          properties:
            value:
              type: string
          required: [value]
        runner:
          kind: static
          outputFormat: text
          text: ok
        """
        try schema.write(
            to: directory.appending(path: "person.json"),
            atomically: true,
            encoding: .utf8
        )
        try tool.write(
            to: directory.appending(path: "echo.yaml"),
            atomically: true,
            encoding: .utf8
        )

        let result = try runAFM(
            "token-count", "--output", "json",
            "--schema", "person", "--schema-dir", directory.path(),
            "--tool", "echo", "--tool-dir", directory.path()
        )

        #expect(result.status == 0)
        let json = try parseJSONObject(result.stdout)
        let components = try #require(json["components"] as? [[String: Any]])
        #expect(components.compactMap { $0["kind"] as? String } == ["schema", "tools"])
        #expect(components.allSatisfy { (($0["tokenCount"] as? Int) ?? 0) > 0 })
    }

    @Test("Human breakdown distinguishes tokenizer output from estimates")
    func humanBreakdown() throws {
        let result = try runAFM(
            "token-count", "--breakdown", "Hello world",
            environment: ["AFM_FORCE_TTY": "1"]
        )

        #expect(result.status == 0)
        #expect(result.stdout.contains("Token count:"))
        #expect(result.stdout.contains("Measurement:"))
        #expect(result.stdout.contains("Breakdown"))
        #expect(result.stdout.contains("Calibrated estimate:"))
    }
}

private func runExternal(executable: String, arguments: [String]) throws -> CommandResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    let standardOutput = Pipe()
    let standardError = Pipe()
    process.standardOutput = standardOutput
    process.standardError = standardError
    process.standardInput = FileHandle.nullDevice
    try process.run()
    let stdout = standardOutput.fileHandleForReading.readDataToEndOfFile()
    let stderr = standardError.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return CommandResult(
        status: process.terminationStatus,
        stdout: (String(bytes: stdout, encoding: .utf8) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines),
        stderr: (String(bytes: stderr, encoding: .utf8) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    )
}
