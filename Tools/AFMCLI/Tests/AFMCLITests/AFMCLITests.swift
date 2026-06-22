import Foundation
import Testing

@Test("Root help shows grouped command discovery")
func rootHelpShowsGroupedCommands() throws {
    let result = try runAFM("--help")

    #expect(result.status == 0)
    #expect(result.stdout.contains("MODEL COMMANDS"))
    #expect(result.stdout.contains("TOKEN COMMANDS"))
    #expect(result.stdout.contains("SESSION COMMANDS"))
    #expect(result.stdout.contains("SCHEMA COMMANDS"))
    #expect(result.stdout.contains("TOOL COMMANDS"))
    #expect(result.stdout.contains("EXPORT COMMANDS"))
    #expect(result.stdout.contains("afm model status"))
}

@Test("Root dry-run emits a request shape instead of normal help output")
func rootDryRun() throws {
    let result = try runAFM("--output", "json", "--dry-run")

    #expect(result.status == 0)
    let json = try parseJSONObject(result.stdout)
    #expect(json["command"] as? String == "afm")
    #expect(json["status"] as? String == "dry_run")
}

@Test("Leaf command help covers every shipped public workflow")
func leafCommandHelpCoverage() throws {
    let commands: [[String]] = [
        ["model", "status", "--help"],
        ["model", "languages", "--help"],
        ["model", "use-cases", "--help"],
        ["model", "guardrails", "--help"],
        ["token-count", "--help"],
        ["tag", "run", "--help"],
        ["session", "respond", "--help"],
        ["session", "stream", "--help"],
        ["session", "chat", "--help"],
        ["schema", "list", "--help"],
        ["schema", "run", "custom", "--help"],
        ["schema", "run", "typed-person", "--help"],
        ["schema", "run", "basic-object", "--help"],
        ["schema", "run", "array-schema", "--help"],
        ["schema", "run", "enum-schema", "--help"],
        ["tool", "inspect", "--help"],
        ["tool", "validate", "--help"],
        ["tool", "call", "--help"],
        ["transcript", "export", "--help"],
        ["feedback", "export", "--help"],
        ["serve", "--help"]
    ]

    for command in commands {
        let result = try runAFM(command)
        #expect(result.status == 0)
        #expect(result.stdout.contains("USAGE:"))
        for flag in expectedHelpFlags(for: command) {
            #expect(result.stdout.contains(flag))
        }
    }
}

@Test("Model and schema discovery commands honor dry-run")
func discoveryCommandsHonorDryRun() throws {
    let status = try runAFM("model", "status", "--output", "json", "--dry-run")
    let languages = try runAFM("model", "languages", "--output", "json", "--dry-run")
    let useCases = try runAFM("model", "use-cases", "--output", "json", "--dry-run")
    let guardrails = try runAFM("model", "guardrails", "--output", "json", "--dry-run")
    let schemaList = try runAFM("schema", "list", "--output", "json", "--dry-run")

    #expect(status.status == 0)
    #expect(languages.status == 0)
    #expect(useCases.status == 0)
    #expect(guardrails.status == 0)
    #expect(schemaList.status == 0)

    #expect((try parseJSONObject(status.stdout))["command"] as? String == "model status")
    #expect((try parseJSONObject(languages.stdout))["command"] as? String == "model languages")
    #expect((try parseJSONObject(useCases.stdout))["command"] as? String == "model use-cases")
    #expect((try parseJSONObject(guardrails.stdout))["command"] as? String == "model guardrails")
    #expect((try parseJSONObject(schemaList.stdout))["command"] as? String == "schema list")
}

@Test("TTY-aware defaults choose text for terminals and json for pipes")
func ttyAwareOutputDefaults() throws {
    let textResult = try runAFM(
        "session", "respond", "--dry-run", "--prompt", "hi",
        environment: ["AFM_FORCE_TTY": "1"]
    )
    let jsonResult = try runAFM(
        "session", "respond", "--dry-run", "--prompt", "hi",
        environment: ["AFM_FORCE_NON_TTY": "1"]
    )

    #expect(textResult.status == 0)
    #expect(textResult.stdout.contains("[dry-run] afm session respond"))
    #expect(!textResult.stdout.contains("\"status\":\"dry_run\""))

    #expect(jsonResult.status == 0)
    #expect(jsonResult.stdout.contains("\"status\":\"dry_run\""))
    #expect(jsonResult.stdout.contains("\"command\":\"session respond\""))
}

@Test("Pretty JSON output emits formatted JSON when explicitly requested")
func prettyJSONOutput() throws {
    let result = try runAFM(
        "session", "respond", "--output", "json", "--pretty", "--dry-run", "--prompt", "hi"
    )

    #expect(result.status == 0)
    #expect(result.stdout.contains("\n  \"command\" : \"session respond\""))
    #expect(result.stdout.contains("\n  \"status\" : \"dry_run\""))
}

@Test("Verbose mode adds extra operator-facing detail")
func verboseModeAddsDetail() throws {
    let status = try runAFM("model", "status", "--verbose", environment: ["AFM_FORCE_TTY": "1"])
    let schemaList = try runAFM("schema", "list", "--verbose", environment: ["AFM_FORCE_TTY": "1"])

    #expect(status.status == 0)
    #expect(schemaList.status == 0)
    #expect(status.stdout.contains("Provider: Foundation Models"))
    #expect(schemaList.stdout.contains("Schema count:"))
}

@Test("Output and generation flags validate before runtime work starts")
func validationErrorsAreDeterministic() throws {
    let prettyResult = try runAFM("--output", "text", "--pretty", "model", "status")
    let temperatureResult = try runAFM("session", "respond", "--prompt", "hi", "--temperature", "2")
    let seedResult = try runAFM("session", "respond", "--prompt", "hi", "--seed", "1")

    #expect(prettyResult.status == 64)
    #expect(prettyResult.stderr.contains("--pretty is only valid with JSON output"))

    #expect(temperatureResult.status == 64)
    #expect(temperatureResult.stderr.contains("--temperature must be between 0 and 1"))

    #expect(seedResult.status == 64)
    #expect(seedResult.stderr.contains("--seed is only valid with non-greedy sampling"))
}

@Test("Session commands parse naturally in dry-run mode")
func sessionDryRunCommands() throws {
    let respond = try runAFM(
        "session", "respond", "--output", "json", "--dry-run", "--prompt", "Summarize this."
    )
    let stream = try runAFM(
        "session", "stream", "--output", "json", "--dry-run", "--prompt", "Stream this."
    )
    let chat = try runAFM(
        "session", "chat", "--output", "json", "--dry-run",
        "--message", "Hello",
        "--message", "Now answer in French."
    )

    #expect(respond.status == 0)
    #expect(stream.status == 0)
    #expect(chat.status == 0)

    let respondJSON = try parseJSONObject(respond.stdout)
    let streamJSON = try parseJSONObject(stream.stdout)
    let chatJSON = try parseJSONObject(chat.stdout)

    #expect(respondJSON["command"] as? String == "session respond")
    #expect(streamJSON["command"] as? String == "session stream")
    #expect(chatJSON["command"] as? String == "session chat")
    #expect((chatJSON["messages"] as? [String]) == ["Hello", "Now answer in French."])
}

@Test("Prompt and message sources resolve from files and stdin")
func promptAndMessageSourceResolution() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-inputs-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let promptFile = directory.appending(path: "prompt.txt")
    let messageFile = directory.appending(path: "message.txt")
    try "Prompt from file".write(to: promptFile, atomically: true, encoding: .utf8)
    try "Message from file".write(to: messageFile, atomically: true, encoding: .utf8)

    let promptFromFile = try runAFM(
        ["session", "respond", "--output", "json", "--dry-run", "--prompt", "@\(promptFile.path())"]
    )
    let promptFromStdin = try runAFM(
        ["session", "respond", "--output", "json", "--dry-run"],
        environment: ["AFM_FORCE_NON_TTY": "1"],
        stdin: "Prompt from stdin\n"
    )
    let chatFromFile = try runAFM(
        ["session", "chat", "--output", "json", "--dry-run", "--message-file", messageFile.path()]
    )

    #expect(promptFromFile.status == 0)
    #expect(promptFromStdin.status == 0)
    #expect(chatFromFile.status == 0)

    let fileJSON = try parseJSONObject(promptFromFile.stdout)
    let stdinJSON = try parseJSONObject(promptFromStdin.stdout)
    let chatJSON = try parseJSONObject(chatFromFile.stdout)

    #expect(fileJSON["prompt"] as? String == "Prompt from file")
    #expect(fileJSON["promptFile"] as? String == promptFile.path())
    #expect(stdinJSON["prompt"] as? String == "Prompt from stdin")
    #expect((chatJSON["messageFiles"] as? [String]) == [messageFile.path()])
    #expect((chatJSON["messages"] as? [String]) == ["Message from file"])
}

@Test("Adapter paths validate early and appear in dry-run payloads")
func adapterDryRunAndValidation() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-adapters-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let adapterPath = directory.appending(path: "Demo.fmadapter")
    let invalidPath = directory.appending(path: "Demo.txt")
    try FileManager.default.createDirectory(at: adapterPath, withIntermediateDirectories: true)
    try Data().write(to: invalidPath)

    let valid = try runAFM(
        ["session", "respond", "--output", "json", "--dry-run", "--adapter", adapterPath.path(), "--prompt", "hello"]
    )
    let invalid = try runAFM(
        ["session", "respond", "--dry-run", "--adapter", invalidPath.path(), "--prompt", "hello"]
    )
    let unsupportedGuardrails = try runAFM(
        [
            "session", "respond", "--dry-run",
            "--adapter", adapterPath.path(),
            "--guardrails", "permissive-content-transformations",
            "--prompt", "hello"
        ]
    )

    #expect(valid.status == 0)
    #expect(invalid.status == 64)
    #expect(unsupportedGuardrails.status == 64)

    let validJSON = try parseJSONObject(valid.stdout)
    #expect(validJSON["adapter"] as? String == adapterPath.path())
    #expect(invalid.stderr.contains("--adapter must point to a .fmadapter package"))
    #expect(
        unsupportedGuardrails.stderr.contains(
            "--adapter only supports the framework's default guardrails"
        )
    )
}

@Test("Tool manifests validate, inspect, and call through the CLI")
func toolManifestCommands() throws {
    let fixture = try ToolManifestFixture()
    defer { fixture.remove() }

    let inspect = try runAFM(
        "tool", "inspect", "--output", "json",
        "--tool", "echo-json",
        "--tool-dir", fixture.toolDirectory.path()
    )
    let validate = try runAFM(
        "tool", "validate", "--output", "json",
        "--tool", "echo-json",
        "--tool", "echo-json-two",
        "--tool-dir", fixture.toolDirectory.path()
    )
    let call = try runAFM(
        "tool", "call", "--output", "json",
        "--tool", "echo-json",
        "--tool-dir", fixture.toolDirectory.path(),
        "--args-file", fixture.argumentsFile.path()
    )

    #expect(inspect.status == 0)
    #expect(validate.status == 0)
    #expect(call.status == 0)

    let inspectJSON = try parseJSONObject(inspect.stdout)
    let validateJSON = try parseJSONObject(validate.stdout)
    let callJSON = try parseJSONObject(call.stdout)
    let validatedTools = try #require(validateJSON["tools"] as? [[String: Any]])
    let echoedOutput = try #require(callJSON["output"] as? String)
    let echoedJSON = try parseJSONObject(echoedOutput)

    #expect(inspectJSON["name"] as? String == "echo_json")
    #expect(validateJSON["status"] as? String == "valid")
    #expect(validatedTools.count == 2)
    #expect(validatedTools.compactMap { $0["name"] as? String } == ["echo_json", "echo_json_two"])
    #expect(
        validatedTools.compactMap { $0["file"] as? String } == [
            fixture.toolDirectory.appending(path: "echo-json.yaml").path(),
            fixture.toolDirectory.appending(path: "echo-json-two.yaml").path()
        ]
    )
    #expect(callJSON["name"] as? String == "echo_json")
    #expect(echoedJSON["city"] as? String == "Berlin")
}

@Test("Shell tools drain large stdout and stderr concurrently")
func shellToolDrainsLargeOutput() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-large-output-\(UUID().uuidString)")
    let toolDirectory = directory.appending(path: ".afm/tools")
    let argsFile = directory.appending(path: "args.json")

    try FileManager.default.createDirectory(at: toolDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let toolManifest = """
    name: large_output
    description: Emits more data than a process pipe can buffer.
    parameters:
      title: EmptyPayload
      type: object
      properties: {}
    runner:
      kind: shell
      outputFormat: text
      command: /bin/sh
      args:
        - -lc
        - >-
          /usr/bin/yes output | /usr/bin/head -c 131072;
          /usr/bin/yes error | /usr/bin/head -c 131072 >&2
    """
    try toolManifest.write(
        to: toolDirectory.appending(path: "large-output.yaml"),
        atomically: true,
        encoding: .utf8
    )
    try "{}".write(to: argsFile, atomically: true, encoding: .utf8)

    let result = try runAFM(
        "tool", "call", "--output", "json",
        "--tool", "large-output",
        "--tool-dir", toolDirectory.path(),
        "--args-file", argsFile.path()
    )

    #expect(result.status == 0)
    let json = try parseJSONObject(result.stdout)
    let output = try #require(json["output"] as? String)
    #expect(output.count >= 131_072)
}

@Test("Transcript and feedback export validate file paths up front")
func exportCommandsValidateFilePaths() throws {
    let transcript = try runAFM(
        "transcript", "export", "--message", "hi", "--file", "", "--dry-run"
    )
    let feedback = try runAFM(
        "feedback", "export", "--prompt", "hi", "--file", "", "--dry-run"
    )

    #expect(transcript.status == 64)
    #expect(transcript.stderr.contains("Please provide a non-empty --file."))

    #expect(feedback.status == 64)
    #expect(feedback.stderr.contains("Please provide a non-empty --file."))
}

@Test("Export commands dry-run with explicit file paths")
func exportCommandsDryRun() throws {
    let transcript = try runAFM(
        "transcript", "export", "--output", "json", "--dry-run",
        "--message", "hello", "--file", "/tmp/afm-test-transcript.json"
    )
    let feedback = try runAFM(
        "feedback", "export", "--output", "json", "--dry-run",
        "--prompt", "hello", "--file", "/tmp/afm-test-feedback.json"
    )

    #expect(transcript.status == 0)
    #expect(feedback.status == 0)

    let transcriptJSON = try parseJSONObject(transcript.stdout)
    let feedbackJSON = try parseJSONObject(feedback.stdout)

    #expect(transcriptJSON["command"] as? String == "transcript export")
    #expect(transcriptJSON["file"] as? String == "/tmp/afm-test-transcript.json")
    #expect(feedbackJSON["command"] as? String == "feedback export")
    #expect(feedbackJSON["file"] as? String == "/tmp/afm-test-feedback.json")
}

@Test("Feedback export creates nested parent directories")
func feedbackExportCreatesNestedDirectories() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-feedback-\(UUID().uuidString)")
    let file = directory.appending(path: "nested/output/feedback.json")

    defer {
        try? FileManager.default.removeItem(at: directory)
    }

    let result = try runAFM(
        "feedback", "export",
        "--output", "json",
        "--prompt", "What is the capital of France?",
        "--file", file.path()
    )

    #expect(result.status == 0)
    #expect(FileManager.default.fileExists(atPath: file.path()))

    let json = try parseJSONObject(result.stdout)
    #expect(json["command"] as? String == "feedback export")
    #expect(json["file"] as? String == file.path())
}

@Test("Streaming JSON mode emits event lines instead of buffering silently")
func streamingJSONEmitsEvents() throws {
    let stream = try runAFM(
        "session", "stream",
        "--output", "json",
        "--prompt", "Reply with exactly: streamed ok."
    )
    let chat = try runAFM(
        "session", "chat",
        "--stream",
        "--output", "json",
        "--message", "Hello",
        "--message", "Answer with exactly: done."
    )

    #expect(stream.status == 0)
    #expect(chat.status == 0)

    let streamEvents = try parseJSONLines(stream.stdout)
    let chatEvents = try parseJSONLines(chat.stdout)

    #expect((streamEvents.first?["event"] as? String) == "started")
    #expect(streamEvents.contains { ($0["event"] as? String) == "delta" })
    #expect((streamEvents.last?["event"] as? String) == "completed")
    let streamUsage = try #require(streamEvents.last?["tokenUsage"] as? [String: Any])
    expectValidRuntimeTokenUsage(streamUsage)
    #expect((streamUsage["totalTokenCount"] as? Int) ?? 0 > 0)

    #expect(chatEvents.contains { ($0["event"] as? String) == "message_started" })
    #expect(chatEvents.contains { ($0["event"] as? String) == "message_delta" })
    #expect(chatEvents.contains { ($0["event"] as? String) == "message_completed" })
    #expect((chatEvents.last?["event"] as? String) == "session_completed")
    let chatUsage = try #require(chatEvents.last?["tokenUsage"] as? [String: Any])
    expectValidRuntimeTokenUsage(chatUsage)
}

private func expectValidRuntimeTokenUsage(_ usage: [String: Any]) {
    let measurement = usage["measurement"] as? String
    #expect(["observed", "tokenized", "estimated"].contains { $0 == measurement })
    if measurement == "observed" {
        #expect(usage["scope"] as? String == "session")
    } else {
        #expect(usage["scope"] as? String == "context")
    }
}

@Test("Unknown commands suggest the closest valid command")
func unknownCommandSuggestions() throws {
    let root = try runAFM("modle")
    let nested = try runAFM("session", "repond")

    #expect(root.status == 64)
    #expect(root.stderr.contains("Did you mean 'model'?"))

    #expect(nested.status == 64)
    #expect(nested.stderr.contains("Did you mean 'session respond'?"))
}

@Test("Model commands run against the live framework surface")
func modelCommandsReturnStructuredJSON() throws {
    let status = try runAFM("model", "status", "--output", "json")
    let languages = try runAFM("model", "languages", "--output", "json")
    let useCases = try runAFM("model", "use-cases", "--output", "json")
    let guardrails = try runAFM("model", "guardrails", "--output", "json")

    #expect(status.status == 0)
    #expect(languages.status == 0)
    #expect(useCases.status == 0)
    #expect(guardrails.status == 0)

    let statusJSON = try parseJSONObject(status.stdout)
    let languagesJSON = try parseJSONObject(languages.stdout)
    let useCasesJSON = try parseJSONObject(useCases.stdout)
    let guardrailsJSON = try parseJSONObject(guardrails.stdout)

    #expect(statusJSON["status"] is String)
    #expect(statusJSON["reason"] is String)
    #expect(statusJSON["useCase"] is String)

    let supportedLanguages = languagesJSON["languages"] as? [[String: Any]]
    #expect((supportedLanguages?.isEmpty == false))
    #expect(languagesJSON["currentLanguage"] is String)
    #expect(languagesJSON["useCase"] is String)
    #expect((useCasesJSON["useCases"] as? [[String: Any]])?.isEmpty == false)
    #expect((guardrailsJSON["guardrails"] as? [[String: Any]])?.isEmpty == false)
}

private func expectedHelpFlags(for command: [String]) -> [String] {
    let commandGroup = command.first
    let isSchemaRun = Array(command.prefix(2)) == ["schema", "run"]
    var flags = ["--help"]

    if commandGroup == "session"
        || commandGroup == "feedback"
        || commandGroup == "transcript"
        || command == ["tag", "run", "--help"]
        || isSchemaRun {
        flags.append(contentsOf: ["--guardrails <guardrails>", "--adapter <adapter>"])
    }
    if commandGroup == "session"
        || commandGroup == "feedback"
        || commandGroup == "transcript"
        || command == ["model", "status", "--help"]
        || command == ["model", "languages", "--help"] {
        flags.append("--use-case <use-case>")
    }
    if isSchemaRun {
        flags.append("--include-schema-in-prompt")
    }
    return flags
}

private struct ToolManifestFixture {
    let root: URL
    let toolDirectory: URL
    let argumentsFile: URL

    init() throws {
        root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appending(path: "afm-tools-\(UUID().uuidString)")
        toolDirectory = root.appending(path: ".afm/tools")
        argumentsFile = root.appending(path: "args.json")
        try FileManager.default.createDirectory(at: toolDirectory, withIntermediateDirectories: true)

        let manifest = """
        name: echo_json
        description: Echoes JSON arguments back to the caller.
        parameters:
          title: EchoPayload
          type: object
          properties:
            city:
              type: string
          required:
            - city
        runner:
          kind: shell
          outputFormat: json
          command: /bin/sh
          args:
            - -lc
            - cat
        """
        let secondManifest = manifest.replacingOccurrences(
            of: "name: echo_json",
            with: "name: echo_json_two"
        )
        try manifest.write(
            to: toolDirectory.appending(path: "echo-json.yaml"),
            atomically: true,
            encoding: .utf8
        )
        try secondManifest.write(
            to: toolDirectory.appending(path: "echo-json-two.yaml"),
            atomically: true,
            encoding: .utf8
        )
        try #"{"city":"Berlin"}"#.write(to: argumentsFile, atomically: true, encoding: .utf8)
    }

    func remove() {
        try? FileManager.default.removeItem(at: root)
    }
}
