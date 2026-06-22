import Foundation
import Testing
@testable import AFMCLI

@Test("schema object matches fm nested and union artifacts semantically")
func schemaObjectMatchesFoundationModelsNestedAndUnionArtifacts() throws {
    let nested = try runAFM(
        "schema", "object",
        "--name", "ContactCard",
        "--string", "address.street",
        "--string", "address.zip", "--optional"
    )
    #expect(nested.status == 0)
    try expectSchema(nested.stdout, matchesFixture: "fm-schema-nested")

    let deep = try runAFM(
        "schema", "object", "--name", "Deep",
        "--string", "customer.billing.street",
        "--integer", "customer.billing.zip", "--optional",
        "--boolean", "customer.active"
    )
    #expect(deep.status == 0)
    try expectSchema(deep.stdout, matchesFixture: "fm-schema-deep")

    let email = try runAFM("schema", "object", "--name", "EmailContact", "--string", "email")
    let phone = try runAFM("schema", "object", "--name", "PhoneContact", "--string", "phone")
    let union = try runAFM(
        "schema", "object",
        "--name", "ContactMethod",
        "--anyOf",
        "--schema", email.stdout,
        "--schema", phone.stdout
    )

    #expect(email.status == 0)
    #expect(phone.status == 0)
    #expect(union.status == 0)
    try expectSchema(union.stdout, matchesFixture: "fm-schema-union")
}

@Test("schema object matches fm primitives, modifiers, and object arrays")
func schemaObjectMatchesFoundationModelsPropertyArtifacts() throws {
    let primitives = try runAFM(
        "schema", "object",
        "--name=Sample",
        "--string", "title", "--description", "Display title",
        "--int", "count", "--optional",
        "--double", "score",
        "--boolean", "active",
        "--string", "tags", "--array"
    )
    #expect(primitives.status == 0)
    try expectSchema(primitives.stdout, matchesFixture: "fm-schema-primitives")

    let item = try runAFM(
        "schema", "object", "--name", "Item",
        "--string", "id", "--double", "price"
    )
    let basket = try runAFM(
        "schema", "object", "--name", "Basket",
        "--object", "items", "--schema", item.stdout,
        "--array", "--description", "Line items"
    )
    #expect(item.status == 0)
    #expect(basket.status == 0)
    try expectSchema(basket.stdout, matchesFixture: "fm-schema-object-array")
}

@Test("schema object YAML composes and runs through schema custom")
func schemaObjectYAMLRoundTripsThroughCustomRunner() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-schema-object-yaml-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let item = try runAFM(
        "schema", "object", "--format", "yaml", "--name", "Item",
        "--string", "id", "--double", "price"
    )
    let itemURL = directory.appending(path: "item.yaml")
    try item.stdout.write(to: itemURL, atomically: true, encoding: .utf8)
    let basket = try runAFM(
        "schema", "object", "--name", "Basket",
        "--object", "items", "--schema", "@\(itemURL.path())",
        "--array", "--description", "Line items"
    )
    #expect(item.status == 0)
    #expect(basket.status == 0)
    try expectSchema(basket.stdout, matchesFixture: "fm-schema-object-array")

    let basketURL = directory.appending(path: "basket.json")
    try basket.stdout.write(to: basketURL, atomically: true, encoding: .utf8)
    let custom = try runSchemaCustomDryRun(basketURL)
    #expect(custom.status == 0)
    #expect((try parseJSONObject(custom.stdout))["command"] as? String == "schema run custom")
}

@Test("schema object rejects invalid declaration sequences")
func schemaObjectRejectsInvalidDeclarationSequences() throws {
    let cases = [
        InvalidSchemaObjectCase(arguments: ["--string", "name"], message: "Please provide --name"),
        InvalidSchemaObjectCase(arguments: ["--name", "Bad", "--optional"], message: "Property modifiers"),
        InvalidSchemaObjectCase(arguments: ["--name", "Bad", "--object", "child"], message: "must be followed"),
        InvalidSchemaObjectCase(arguments: ["--name", "Bad", "--anyOf"], message: "requires at least one"),
        InvalidSchemaObjectCase(
            arguments: ["--name", "Bad", "--string", "value", "--string", "value"],
            message: "multiple 'value'"
        ),
        InvalidSchemaObjectCase(
            arguments: [
                "--name", "Bad",
                "--string", "billing.address.street",
                "--integer", "shipping.address.zip"
            ],
            message: "Conflicting schema definitions named 'Address'"
        ),
        InvalidSchemaObjectCase(arguments: ["--name", "Bad", "--unknown"], message: "Unknown schema object option")
    ]

    for testCase in cases {
        let result = try runAFM(["schema", "object"] + testCase.arguments)
        #expect(result.status == 64)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains(testCase.message))
    }
}

@Test("supported schema keywords still fail closed when malformed")
func supportedSchemaKeywordsFailClosedWhenMalformed() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-malformed-supported-schema-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let cases = [
        MalformedSchemaCase(
            name: "undefined-reference",
            document: ##"{"type":"object","properties":{"value":{"$ref":"#/$defs/Missing"}}}"##,
            message: "Undefined schema reference"
        ),
        MalformedSchemaCase(
            name: "external-reference",
            document: #"{"$ref":"https://example.com/schema.json"}"#,
            message: "Only local references"
        ),
        MalformedSchemaCase(
            name: "invalid-order",
            document: #"{"type":"object","properties":{"value":{"type":"string"}},"x-order":[]}"#,
            message: "x-order must list every object property"
        ),
        MalformedSchemaCase(
            name: "empty-union",
            document: #"{"title":"EmptyUnion","anyOf":[]}"#,
            message: "anyOf must contain at least one schema"
        ),
        MalformedSchemaCase(
            name: "nested-definitions",
            document: #"{"type":"object","properties":{"nested":{"type":"object","$defs":{"Value":{"type":"string"}}}}}"#,
            message: "Nested $defs are not supported"
        )
    ]

    for testCase in cases {
        let url = directory.appending(path: "\(testCase.name).json")
        try testCase.document.write(to: url, atomically: true, encoding: .utf8)
        let result = try runSchemaCustomDryRun(url)
        #expect(result.status == 64)
        #expect(result.stderr.contains(testCase.message))
    }
}

@Test("schema JSON rejects semantic duplicate keys at exact pointers")
func schemaJSONRejectsSemanticDuplicateKeys() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-duplicate-schema-keys-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let cases = [
        InvalidJSONSchemaCase(
            name: "escaped-root-key",
            document: ##"{"type":"object","\u0074ype":"string"}"##,
            pointer: "/type"
        ),
        InvalidJSONSchemaCase(
            name: "escaped-property-key",
            document: ##"{"type":"object","properties":{"a/b":{"type":"string"},"a\/b":{"type":"integer"}}}"##,
            pointer: "/properties/a~1b"
        ),
        InvalidJSONSchemaCase(
            name: "escaped-definition-key",
            document: ##"{"type":"object","$defs":{"Node":{"type":"object"},"\u004eode":{"type":"string"}}}"##,
            pointer: "/$defs/Node"
        ),
        InvalidJSONSchemaCase(
            name: "duplicate-inside-array",
            document: ##"{"title":"Choice","anyOf":[{"type":"object","\u0074ype":"string"}]}"##,
            pointer: "/anyOf/0/type"
        )
    ]

    for testCase in cases {
        let url = directory.appending(path: "\(testCase.name).json")
        try testCase.document.write(to: url, atomically: true, encoding: .utf8)
        let result = try runSchemaCustomDryRun(url)

        #expect(result.status == 64)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Duplicate object key"))
        #expect(result.stderr.contains("JSON pointer '\(testCase.pointer)'"))
    }

    let duplicateLeaf = ##"{"type":"object","\u0074ype":"string"}"##
    let deeplyNested = String(repeating: "[", count: 256)
        + duplicateLeaf
        + String(repeating: "]", count: 256)
    let deeplyNestedURL = directory.appending(path: "deeply-nested-duplicate.json")
    try deeplyNested.write(to: deeplyNestedURL, atomically: true, encoding: .utf8)
    let deeplyNestedResult = try runSchemaCustomDryRun(deeplyNestedURL)

    #expect(deeplyNestedResult.status == 64)
    #expect(deeplyNestedResult.stdout.isEmpty)
    #expect(deeplyNestedResult.stderr.contains("JSON nesting exceeds the supported depth"))
}

@Test("schema references reject cycles without a finite value")
func schemaReferencesRejectUnproductiveCycles() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-schema-productivity-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let rejected = [
        InvalidJSONSchemaCase(
            name: "required-self-cycle",
            document: ##"""
            {"title":"Root","type":"object","properties":{"node":{"$ref":"#/$defs/Node"}},
            "required":["node"],"$defs":{"Node":{"type":"object",
            "properties":{"next":{"$ref":"#/$defs/Node"}},"required":["next"]}}}
            """##,
            pointer: "/$defs/Node/properties/next/$ref"
        ),
        InvalidJSONSchemaCase(
            name: "required-mutual-cycle",
            document: ##"""
            {"title":"Root","type":"object","properties":{"a":{"$ref":"#/$defs/A"}},
            "required":["a"],"$defs":{"A":{"type":"object",
            "properties":{"b":{"$ref":"#/$defs/B"}},"required":["b"]},
            "B":{"type":"object","properties":{"a":{"$ref":"#/$defs/A"}},"required":["a"]}}}
            """##,
            pointer: "/$defs/B/properties/a/$ref"
        ),
        InvalidJSONSchemaCase(
            name: "positive-array-cycle",
            document: ##"""
            {"title":"Root","type":"object","properties":{"node":{"$ref":"#/$defs/Node"}},
            "required":["node"],"$defs":{"Node":{"type":"object",
            "properties":{"children":{"type":"array","minItems":1,
            "items":{"$ref":"#/$defs/Node"}}},"required":["children"]}}}
            """##,
            pointer: "/$defs/Node/properties/children/items/$ref"
        )
    ]

    for testCase in rejected {
        let url = directory.appending(path: "\(testCase.name).json")
        try testCase.document.write(to: url, atomically: true, encoding: .utf8)
        let result = try runSchemaCustomDryRun(url)

        #expect(result.status == 64)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("cannot produce a finite value"))
        #expect(result.stderr.contains("JSON pointer '\(testCase.pointer)'"))
    }
}

@Test("schema references allow recursion with a finite base case")
func schemaReferencesAllowProductiveRecursion() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-schema-productive-recursion-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let accepted = [
        ValidJSONSchemaCase(
            name: "optional-recursion",
            document: ##"""
            {"title":"Root","type":"object","properties":{"node":{"$ref":"#/$defs/Node"}},
            "required":["node"],"$defs":{"Node":{"type":"object",
            "properties":{"next":{"$ref":"#/$defs/Node"}},"required":[]}}}
            """##
        ),
        ValidJSONSchemaCase(
            name: "zero-minimum-array-recursion",
            document: ##"""
            {"title":"Root","type":"object","properties":{"node":{"$ref":"#/$defs/Node"}},
            "required":["node"],"$defs":{"Node":{"type":"object",
            "properties":{"children":{"type":"array","minItems":0,
            "items":{"$ref":"#/$defs/Node"}}},"required":["children"]}}}
            """##
        ),
        ValidJSONSchemaCase(
            name: "recursive-union-with-base-case",
            document: ##"""
            {"title":"Root","type":"object","properties":{"node":{"$ref":"#/$defs/Node"}},
            "required":["node"],"$defs":{"Node":{"anyOf":[
            {"$ref":"#/$defs/Node"},{"type":"string"}]}}}
            """##
        )
    ]

    for testCase in accepted {
        let url = directory.appending(path: "\(testCase.name).json")
        try testCase.document.write(to: url, atomically: true, encoding: .utf8)
        let result = try runSchemaCustomDryRun(url)

        #expect(result.status == 0)
        #expect(result.stderr.isEmpty)
    }
}

private func expectSchema(_ text: String, matchesFixture fixture: String) throws {
    let fixtureURL = try #require(
        Bundle.module.url(forResource: fixture, withExtension: "json", subdirectory: "Fixtures")
    )
    let expectedData = try Data(contentsOf: fixtureURL)
    let actualData = try #require(text.data(using: .utf8))
    let expected = try #require(JSONSerialization.jsonObject(with: expectedData) as? NSDictionary)
    let actual = try #require(JSONSerialization.jsonObject(with: actualData) as? NSDictionary)
    #expect(actual.isEqual(expected))
}

private func runSchemaCustomDryRun(_ schemaURL: URL) throws -> CommandResult {
    try runAFM(
        "schema", "run", "custom",
        "--output", "json",
        "--dry-run",
        "--schema", schemaURL.path(),
        "--input", "Test input"
    )
}

private struct InvalidSchemaObjectCase {
    let arguments: [String]
    let message: String
}

private struct MalformedSchemaCase {
    let name: String
    let document: String
    let message: String
}

private struct InvalidJSONSchemaCase {
    let name: String
    let document: String
    let pointer: String
}

private struct ValidJSONSchemaCase {
    let name: String
    let document: String
}
