import ArgumentParser
import Foundation
import Yams

struct SchemaObjectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "object",
        abstract: "Generate a runnable JSON or YAML schema for an object or union.",
        discussion: """
        PROPERTY DECLARATIONS
          --string <name>       Declare a string property.
          --integer <name>      Declare an integer property. --int is an alias.
          --double <name>       Declare a floating-point property.
          --boolean <name>      Declare a Boolean property.
          --object <name>       Declare an object property followed by --schema.
          --schema <json>       Supply an object or anyOf choice schema. Use @path for a file.
          --anyOf               Build a root union from subsequent --schema values.

        PROPERTY MODIFIERS
          --array               Make the preceding property an array.
          --description <text>  Describe the preceding property.
          --optional            Make the preceding property optional.

        OUTPUT
          --format <json|yaml>  Artifact format. Defaults to json.

        Dot-separated property names create referenced nested objects.

        EXAMPLES
          afm schema object --name Person --string name --integer age --optional
          afm schema object --name Restaurant --string name --string address.street
          afm schema object --name SearchResult --anyOf --schema @found.json --schema @missing.json
        """
    )

    @Argument(parsing: .allUnrecognized)
    var arguments: [String] = []

    mutating func run() async throws {
        let request = try AFMSchemaObjectParser.parse(arguments)
        let document = try AFMSchemaObjectBuilder.build(request)
        print(try Self.render(document, format: request.format))
    }

    static func render(
        _ document: AFMSchemaDocument,
        format: AFMSchemaObjectSerializationFormat
    ) throws -> String {
        switch format {
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let data = try encoder.encode(document)
            guard let output = String(data: data, encoding: .utf8) else {
                throw AFMRuntimeError.providerFailure("Could not encode schema JSON.")
            }
            return output
        case .yaml:
            return try YAMLEncoder().encode(document)
        }
    }
}
