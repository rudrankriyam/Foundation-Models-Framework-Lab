import Foundation
import Testing
@testable import AFMCLI

@Test("Schema commands expose list and run flows")
func schemaCommands() throws {
    let list = try runAFM("schema", "list", "--output", "json")
    let typedPerson = try runAFM(
        "schema", "run", "typed-person", "--output", "json", "--dry-run",
        "--input", "Alex Rivera is a designer in Berlin."
    )
    let badPreset = try runAFM(
        "schema", "run", "enum-schema", "--dry-run", "--preset", "missing"
    )

    #expect(list.status == 0)
    #expect(typedPerson.status == 0)
    #expect(badPreset.status == 64)
    #expect(badPreset.stderr.contains("Unknown preset 'missing' for enum-schema"))

    let listJSON = try parseJSONObject(list.stdout)
    let typedJSON = try parseJSONObject(typedPerson.stdout)

    let schemas = listJSON["schemas"] as? [[String: Any]]
    #expect((schemas?.isEmpty == false))
    #expect(typedJSON["command"] as? String == "schema run typed-person")
    #expect(typedJSON["input"] as? String == "Alex Rivera is a designer in Berlin.")
}

@Test("Foundation Models flags surface in dry-run payloads")
func foundationModelsFlagsSurfaceInDryRunPayloads() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-fmf-\(UUID().uuidString)")
    let schemaDirectory = directory.appending(path: ".afm/schemas")
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: schemaDirectory, withIntermediateDirectories: true)

    let schema = """
    title: PersonCard
    type: object
    properties:
      name:
        type: string
    required:
      - name
    """
    try schema.write(to: schemaDirectory.appending(path: "person-card.yaml"), atomically: true, encoding: .utf8)

    let modelStatus = try runAFM(
        "model", "status", "--output", "json", "--dry-run",
        "--use-case", "content-tagging"
    )
    let customSchema = try runAFM(
        "schema", "run", "custom", "--output", "json", "--dry-run",
        "--schema", "person-card",
        "--schema-dir", schemaDirectory.path(),
        "--input", "Alex Rivera",
        "--use-case", "content-tagging",
        "--no-include-schema-in-prompt"
    )
    let feedback = try runAFM(
        "feedback", "export", "--output", "json", "--dry-run",
        "--prompt", "hello",
        "--file", "/tmp/afm-feedback.json",
        "--issue", "incorrect",
        "--issue-explanation", "Wrong answer"
    )
    let tag = try runAFM(
        "tag", "run", "--output", "json", "--dry-run",
        "--prompt", "A joyful dog playing in a sunny park."
    )

    #expect(modelStatus.status == 0)
    #expect(customSchema.status == 0)
    #expect(feedback.status == 0)
    #expect(tag.status == 0)

    let modelJSON = try parseJSONObject(modelStatus.stdout)
    let schemaJSON = try parseJSONObject(customSchema.stdout)
    let feedbackJSON = try parseJSONObject(feedback.stdout)
    let tagJSON = try parseJSONObject(tag.stdout)

    #expect(modelJSON["useCase"] as? String == "content-tagging")
    #expect(schemaJSON["useCase"] as? String == "content-tagging")
    #expect(schemaJSON["includeSchemaInPrompt"] as? Bool == false)
    #expect((feedbackJSON["feedbackIssues"] as? [String]) == ["incorrect"])
    #expect(tagJSON["command"] as? String == "tag run")
    #expect(tagJSON["useCase"] as? String == "content-tagging")
}

@Test("Custom schema files resolve from schema-dir and dry-run cleanly")
func customSchemaFilesResolve() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-schemas-\(UUID().uuidString)")
    let schemaDirectory = directory.appending(path: ".afm/schemas")
    let inputFile = directory.appending(path: "input.txt")

    try FileManager.default.createDirectory(at: schemaDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let schema = """
    title: PersonCard
    type: object
    properties:
      name:
        type: string
      age:
        type: integer
      occupation:
        type: string
    required:
      - name
      - age
      - occupation
    """
    try schema.write(to: schemaDirectory.appending(path: "person-card.yaml"), atomically: true, encoding: .utf8)
    try "Alex Rivera is a 34-year-old designer in Berlin.".write(to: inputFile, atomically: true, encoding: .utf8)

    let result = try runAFM(
        "schema", "run", "custom",
        "--output", "json",
        "--dry-run",
        "--schema", "person-card",
        "--schema-dir", schemaDirectory.path(),
        "--input", "@\(inputFile.path())"
    )

    #expect(result.status == 0)
    let json = try parseJSONObject(result.stdout)
    #expect(json["command"] as? String == "schema run custom")
    #expect(json["schema"] as? String == "person-card")
    #expect(json["schemaFile"] as? String == schemaDirectory.appending(path: "person-card.yaml").path())
    #expect(json["input"] as? String == "Alex Rivera is a 34-year-old designer in Berlin.")
    #expect(json["inputFile"] as? String == inputFile.path())
}

@Test("All dynamic schema workflows dry-run cleanly")
func dynamicSchemaDryRuns() throws {
    let basic = try runAFM(
        "schema", "run", "basic-object", "--output", "json", "--dry-run", "--preset", "product"
    )
    let array = try runAFM(
        "schema", "run", "array-schema", "--output", "json", "--dry-run", "--preset", "todo",
        "--min-items", "2", "--max-items", "4"
    )
    let enumeration = try runAFM(
        "schema", "run", "enum-schema", "--output", "json", "--dry-run",
        "--choice", "high", "--choice", "medium", "--choice", "low"
    )

    #expect(basic.status == 0)
    #expect(array.status == 0)
    #expect(enumeration.status == 0)

    let basicJSON = try parseJSONObject(basic.stdout)
    let arrayJSON = try parseJSONObject(array.stdout)
    let enumJSON = try parseJSONObject(enumeration.stdout)

    #expect(basicJSON["command"] as? String == "schema run basic-object")
    #expect(arrayJSON["command"] as? String == "schema run array-schema")
    #expect(enumJSON["command"] as? String == "schema run enum-schema")
}

@Test("Piped schema input overrides preset defaults")
func pipedSchemaInputOverridesPresetDefaults() throws {
    let pipedInput = "Taylor is a 29-year-old architect in Seattle."
    let result = try runAFM(
        [
            "schema", "run", "typed-person",
            "--output", "json",
            "--dry-run"
        ],
        stdin: "\(pipedInput)\n"
    )

    #expect(result.status == 0)
    let json = try parseJSONObject(result.stdout)
    #expect(json["input"] as? String == pipedInput)
}

@Test("Schemas emitted by fm convert into runnable generation schemas")
func foundationModelsCLISchemaFixturesConvert() throws {
    let fixtures = ["fm-schema-nested", "fm-schema-union"]

    for fixture in fixtures {
        let schemaURL = try #require(
            Bundle.module.url(
                forResource: fixture,
                withExtension: "json",
                subdirectory: "Fixtures"
            )
        )
        let result = try runCustomSchemaDryRun(schemaURL)

        #expect(result.status == 0)
        #expect(result.stderr.isEmpty)
        let payload = try parseJSONObject(result.stdout)
        #expect(payload["command"] as? String == "schema run custom")
    }
}

@Test("Unsupported schema keywords report their exact JSON pointers")
func unsupportedSchemaKeywordsReportExactPointers() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-unsupported-schemas-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let cases = [
        UnsupportedSchemaCase(
            name: "one-of",
            document: #"{"oneOf":[{"type":"string"},{"type":"integer"}]}"#,
            keyword: "oneOf",
            pointer: "/oneOf"
        ),
        UnsupportedSchemaCase(
            name: "all-of",
            document: #"{"type":"object","properties":{"profile":{"allOf":[{"type":"object"}]}}}"#,
            keyword: "allOf",
            pointer: "/properties/profile/allOf"
        ),
        UnsupportedSchemaCase(
            name: "escaped-unsupported-path",
            document: #"{"type":"object","properties":{"home/office~primary":{"format":"email"}}}"#,
            keyword: "format",
            pointer: "/properties/home~1office~0primary/format"
        ),
        UnsupportedSchemaCase(
            name: "open-additional-properties",
            document: #"{"type":"object","properties":{"profile":{"type":"object","additionalProperties":true}}}"#,
            keyword: "additionalProperties",
            pointer: "/properties/profile/additionalProperties"
        ),
        UnsupportedSchemaCase(
            name: "schema-additional-properties",
            document: #"{"type":"object","additionalProperties":{"type":"string"}}"#,
            keyword: "additionalProperties",
            pointer: "/additionalProperties"
        )
    ]

    for testCase in cases {
        let schemaURL = directory.appending(path: "\(testCase.name).json")
        try testCase.document.write(to: schemaURL, atomically: true, encoding: .utf8)
        let result = try runCustomSchemaDryRun(schemaURL)

        #expect(result.status == 64)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Unsupported schema keyword '\(testCase.keyword)'"))
        #expect(result.stderr.contains("JSON pointer '\(testCase.pointer)'"))
    }

}

@Test("Unsupported YAML schema keywords report exact JSON pointers")
func unsupportedYAMLSchemaKeywordReportsExactPointer() throws {
    let schemaURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-unsupported-schema-\(UUID().uuidString).yaml")
    defer { try? FileManager.default.removeItem(at: schemaURL) }
    let schema = """
    type: object
    properties:
      address:
        oneOf:
        - type: string
        - type: integer
    """
    try schema.write(to: schemaURL, atomically: true, encoding: .utf8)

    let result = try runCustomSchemaDryRun(schemaURL)

    #expect(result.status == 64)
    #expect(result.stderr.contains("Unsupported schema keyword 'oneOf'"))
    #expect(result.stderr.contains("JSON pointer '/properties/address/oneOf'"))
}

@Test("Closed additional properties preserve supported schema conversion")
func closedAdditionalPropertiesRemainSupported() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-supported-schema-\(UUID().uuidString)")
    let schemaURL = directory.appending(path: "supported.json")
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let schema = """
    {
      "title": "ReleaseSummary",
      "description": "A supported schema using every currently converted shape.",
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": "string"
        },
        "priority": {
          "type": "string",
          "enum": ["low", "medium", "high"]
        },
        "scores": {
          "type": "array",
          "minItems": 1,
          "maxItems": 3,
          "items": {
            "type": "number"
          }
        },
        "metadata": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "revision": {
              "type": "integer"
            }
          },
          "required": ["revision"]
        },
        "approved": {
          "type": "boolean"
        }
      },
      "required": ["name", "priority", "scores", "metadata"]
    }
    """
    let document = try JSONDecoder().decode(AFMSchemaDocument.self, from: Data(schema.utf8))
    _ = try document.generationSchema(fallbackName: "ReleaseSummary")
    try schema.write(to: schemaURL, atomically: true, encoding: .utf8)

    let result = try runCustomSchemaDryRun(schemaURL)

    #expect(result.status == 0)
    #expect(result.stderr.isEmpty)
    let json = try parseJSONObject(result.stdout)
    #expect(json["command"] as? String == "schema run custom")
    #expect(json["schemaFile"] as? String == schemaURL.path())
}

private func runCustomSchemaDryRun(_ schemaURL: URL) throws -> CommandResult {
    try runAFM(
        "schema", "run", "custom",
        "--output", "json",
        "--dry-run",
        "--schema", schemaURL.path(),
        "--input", "Test input"
    )
}

private struct UnsupportedSchemaCase {
    let name: String
    let document: String
    let keyword: String
    let pointer: String
}
