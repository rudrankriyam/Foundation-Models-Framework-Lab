import Foundation
import Testing

@Test("Quick-start tool names resolve from the default tool directory")
func quickStartToolNamesResolve() throws {
    let help = try runAFM("--help")
    let tokens = help.stdout.split(whereSeparator: \.isWhitespace).map(String.init)
    let toolNames = Set(tokens.indices.dropLast().compactMap { index in
        tokens[index] == "--tool" ? tokens[index + 1] : nil
    })

    #expect(help.status == 0)
    #expect(toolNames == ["demo-weather"])

    for toolName in toolNames.sorted() {
        let inspect = try runAFM("tool", "inspect", "--output", "json", "--tool", toolName)
        let validate = try runAFM("tool", "validate", "--output", "json", "--tool", toolName)
        let call = try runAFM(
            "tool", "call", "--output", "json",
            "--tool", toolName,
            "--args", "{}"
        )
        let session = try runAFM(
            "session", "respond", "--output", "json", "--dry-run",
            "--prompt", "Use the bundled weather sample.",
            "--tool", toolName
        )

        #expect(inspect.status == 0)
        #expect(validate.status == 0)
        #expect(call.status == 0)
        #expect(session.status == 0)

        let inspectJSON = try parseJSONObject(inspect.stdout)
        let validateJSON = try parseJSONObject(validate.stdout)
        let callJSON = try parseJSONObject(call.stdout)
        let sessionJSON = try parseJSONObject(session.stdout)
        let output = try #require(callJSON["output"] as? String)
        let outputJSON = try parseJSONObject(output)

        #expect(inspectJSON["name"] as? String == "demo_weather")
        #expect(inspectJSON["runner"] as? String == "static")
        #expect(validateJSON["status"] as? String == "valid")
        #expect(callJSON["name"] as? String == "demo_weather")
        #expect(outputJSON["status"] as? String == "sample")
        #expect(outputJSON["source"] as? String == "bundled-demo")
        #expect(sessionJSON["status"] as? String == "dry_run")
    }
}
