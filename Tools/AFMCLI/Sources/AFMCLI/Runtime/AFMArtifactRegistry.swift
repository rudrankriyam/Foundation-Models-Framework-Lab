import ArgumentParser
import Foundation
import FoundationModels
import Yams

enum AFMArtifactRegistry {
    static func decodeSchemaDocument(from text: String, source: String = "--schema") throws -> AFMSchemaDocument {
        try decodeArtifact(AFMSchemaDocument.self, from: text, path: source)
    }

    static func loadSchemaDocument(from reference: ResolvedArtifactReference) throws -> AFMSchemaDocument {
        let text = try String(contentsOfFile: reference.filePath, encoding: .utf8)
        return try decodeArtifact(AFMSchemaDocument.self, from: text, path: reference.filePath)
    }

    static func loadToolManifest(from reference: ResolvedArtifactReference) throws -> AFMToolManifest {
        let text = try String(contentsOfFile: reference.filePath, encoding: .utf8)
        return try decodeArtifact(AFMToolManifest.self, from: text, path: reference.filePath)
    }

    static func loadTools(from references: [ResolvedArtifactReference]) throws -> [AFMManifestTool] {
        try references.map { reference in
            try AFMManifestTool(manifest: loadToolManifest(from: reference), sourcePath: reference.filePath)
        }
    }

    private static func decodeArtifact<T: Decodable>(_ type: T.Type, from text: String, path: String) throws -> T {
        let url = URL(fileURLWithPath: path)
        switch url.pathExtension.lowercased() {
        case "yaml", "yml":
            do {
                return try YAMLDecoder().decode(type, from: text)
            } catch {
                if let schemaError = AFMSchemaValidationError.find(in: error) {
                    throw ValidationError("Schema validation failed in \(path): \(schemaError.localizedDescription)")
                }
                throw ValidationError("Could not decode \(path) as YAML: \(error.localizedDescription)")
            }
        default:
            try AFMJSONDuplicateKeyPreflight.validate(text, source: path)
            do {
                let data = Data(text.utf8)
                return try JSONDecoder().decode(type, from: data)
            } catch {
                if let schemaError = AFMSchemaValidationError.find(in: error) {
                    throw ValidationError("Schema validation failed in \(path): \(schemaError.localizedDescription)")
                }
                throw ValidationError("Could not decode \(path) as JSON: \(error.localizedDescription)")
            }
        }
    }
}

extension AFMSchemaDocument {
    func generationSchema(fallbackName: String = "RootSchema") throws -> GenerationSchema {
        let definitionDocuments = definitions ?? [:]
        let definitionNames = Set(definitionDocuments.keys)
        guard !definitionNames.contains("") else {
            throw schemaValidationError("Definition names cannot be empty", at: "/$defs")
        }

        let dependencies = try definitionDocuments.keys.sorted().map { definitionName in
            guard let document = definitionDocuments[definitionName]?.value else {
                throw schemaValidationError(
                    "Missing schema for definition '\(definitionName)'",
                    at: afmJSONPointer(appending: definitionName, to: "/$defs")
                )
            }
            return try document.dynamicSchema(
                nameHint: definitionName,
                forcedName: definitionName,
                availableDefinitions: definitionNames,
                pointer: afmJSONPointer(appending: definitionName, to: "/$defs")
            )
        }
        let root = try dynamicSchema(
            nameHint: title ?? fallbackName,
            availableDefinitions: definitionNames,
            pointer: "",
            allowsDefinitions: true
        )
        try AFMSchemaProductivityValidator.validate(root: self, definitions: definitionDocuments)
        return try GenerationSchema(root: root, dependencies: dependencies)
    }
}

private extension AFMSchemaDocument {
    func dynamicSchema(
        nameHint: String,
        forcedName: String? = nil,
        availableDefinitions: Set<String>,
        pointer: String,
        allowsDefinitions: Bool = false
    ) throws -> DynamicGenerationSchema {
        if !allowsDefinitions, definitions != nil {
            throw schemaValidationError(
                "Nested $defs are not supported; move definitions to the document root",
                at: afmJSONPointer(appending: "$defs", to: pointer)
            )
        }

        if let reference {
            return try referenceSchema(
                reference,
                availableDefinitions: availableDefinitions,
                pointer: pointer
            )
        }

        if let anyOf {
            return try unionSchema(
                anyOf,
                nameHint: nameHint,
                forcedName: forcedName,
                availableDefinitions: availableDefinitions,
                pointer: pointer
            )
        }

        if let enumValues {
            return try enumSchema(enumValues, nameHint: nameHint, forcedName: forcedName, pointer: pointer)
        }

        return try typedSchema(
            resolvedSchemaType(),
            nameHint: nameHint,
            forcedName: forcedName,
            availableDefinitions: availableDefinitions,
            pointer: pointer
        )
    }

    func typedSchema(
        _ resolvedType: String,
        nameHint: String,
        forcedName: String?,
        availableDefinitions: Set<String>,
        pointer: String
    ) throws -> DynamicGenerationSchema {
        switch resolvedType {
        case "object":
            return try objectSchema(
                nameHint: nameHint,
                forcedName: forcedName,
                availableDefinitions: availableDefinitions,
                pointer: pointer
            )
        case "array":
            return try arraySchema(
                nameHint: nameHint,
                availableDefinitions: availableDefinitions,
                pointer: pointer
            )
        case "string":
            try validatePrimitiveShape(pointer: pointer)
            return DynamicGenerationSchema(type: String.self)
        case "integer":
            try validatePrimitiveShape(pointer: pointer)
            return DynamicGenerationSchema(type: Int.self)
        case "number":
            try validatePrimitiveShape(pointer: pointer)
            return DynamicGenerationSchema(type: Double.self)
        case "boolean":
            try validatePrimitiveShape(pointer: pointer)
            return DynamicGenerationSchema(type: Bool.self)
        default:
            throw schemaValidationError(
                "Unsupported schema type '\(resolvedType)' in '\(title ?? nameHint)'",
                at: afmJSONPointer(appending: "type", to: pointer)
            )
        }
    }

    func referenceSchema(
        _ reference: String,
        availableDefinitions: Set<String>,
        pointer: String
    ) throws -> DynamicGenerationSchema {
        try validateReferenceShape(pointer: pointer)
        let definitionName = try referencedDefinitionName(reference, pointer: pointer)
        guard availableDefinitions.contains(definitionName) else {
            throw schemaValidationError(
                "Undefined schema reference '\(reference)'",
                at: afmJSONPointer(appending: "$ref", to: pointer)
            )
        }
        return DynamicGenerationSchema(referenceTo: definitionName)
    }

    func unionSchema(
        _ anyOf: [AFMSchemaDocumentBox],
        nameHint: String,
        forcedName: String?,
        availableDefinitions: Set<String>,
        pointer: String
    ) throws -> DynamicGenerationSchema {
        try validateUnionShape(pointer: pointer)
        guard !anyOf.isEmpty else {
            throw schemaValidationError(
                "anyOf must contain at least one schema",
                at: afmJSONPointer(appending: "anyOf", to: pointer)
            )
        }
        let schemaName = try resolvedSchemaName(nameHint: nameHint, forcedName: forcedName, pointer: pointer)
        let choices = try anyOf.enumerated().map { index, choice in
            let choicePointer = afmJSONPointer(
                appending: String(index),
                to: afmJSONPointer(appending: "anyOf", to: pointer)
            )
            return try choice.value.dynamicSchema(
                nameHint: "\(schemaName)Choice\(index + 1)",
                availableDefinitions: availableDefinitions,
                pointer: choicePointer
            )
        }
        return DynamicGenerationSchema(name: schemaName, description: description, anyOf: choices)
    }

    func enumSchema(
        _ enumValues: [String],
        nameHint: String,
        forcedName: String?,
        pointer: String
    ) throws -> DynamicGenerationSchema {
        try validateEnumShape(pointer: pointer)
        guard !enumValues.isEmpty else {
            throw schemaValidationError(
                "enum must contain at least one string",
                at: afmJSONPointer(appending: "enum", to: pointer)
            )
        }
        return DynamicGenerationSchema(
            name: try resolvedSchemaName(nameHint: nameHint, forcedName: forcedName, pointer: pointer),
            description: description,
            anyOf: enumValues
        )
    }

    func objectSchema(
        nameHint: String,
        forcedName: String?,
        availableDefinitions: Set<String>,
        pointer: String
    ) throws -> DynamicGenerationSchema {
        try validateObjectShape(pointer: pointer)
        let properties = self.properties ?? [:]
        let orderedNames = try orderedPropertyNames(in: properties, pointer: pointer)
        let requiredNames = try requiredPropertyNames(in: properties, pointer: pointer)
        let dynamicProperties = try orderedNames.map { propertyName in
            try dynamicProperty(
                named: propertyName,
                properties: properties,
                requiredNames: requiredNames,
                availableDefinitions: availableDefinitions,
                pointer: pointer
            )
        }
        return DynamicGenerationSchema(
            name: try resolvedSchemaName(nameHint: nameHint, forcedName: forcedName, pointer: pointer),
            description: description,
            properties: dynamicProperties
        )
    }

    func dynamicProperty(
        named propertyName: String,
        properties: [String: AFMSchemaDocumentBox],
        requiredNames: Set<String>,
        availableDefinitions: Set<String>,
        pointer: String
    ) throws -> DynamicGenerationSchema.Property {
        let propertyPointer = afmJSONPointer(
            appending: propertyName,
            to: afmJSONPointer(appending: "properties", to: pointer)
        )
        guard let propertySchema = properties[propertyName]?.value else {
            throw schemaValidationError("Missing schema for property '\(propertyName)'", at: propertyPointer)
        }
        return DynamicGenerationSchema.Property(
            name: propertyName,
            description: propertySchema.description,
            schema: try propertySchema.dynamicSchema(
                nameHint: propertySchema.title ?? propertyName.camelizedSchemaName(),
                availableDefinitions: availableDefinitions,
                pointer: propertyPointer
            ),
            isOptional: !requiredNames.contains(propertyName)
        )
    }

    func arraySchema(
        nameHint: String,
        availableDefinitions: Set<String>,
        pointer: String
    ) throws -> DynamicGenerationSchema {
        try validateArrayShape(pointer: pointer)
        guard let items = items?.value else {
            throw schemaValidationError(
                "Array schema '\(title ?? nameHint)' is missing an items definition",
                at: afmJSONPointer(appending: "items", to: pointer)
            )
        }
        return DynamicGenerationSchema(
            arrayOf: try items.dynamicSchema(
                nameHint: items.title ?? "\(nameHint)Item",
                availableDefinitions: availableDefinitions,
                pointer: afmJSONPointer(appending: "items", to: pointer)
            ),
            minimumElements: minimumItems,
            maximumElements: maximumItems
        )
    }
}

private extension AFMSchemaDocument {
    private func resolvedSchemaType() -> String {
        if let type {
            return type
        }
        if properties != nil {
            return "object"
        }
        if items != nil {
            return "array"
        }
        if enumValues != nil {
            return "string"
        }
        return "object"
    }

    private func resolvedSchemaName(
        nameHint: String,
        forcedName: String?,
        pointer: String
    ) throws -> String {
        let name = forcedName ?? title ?? nameHint
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw schemaValidationError("Schema names cannot be empty", at: pointer)
        }
        return name
    }

    private func orderedPropertyNames(
        in properties: [String: AFMSchemaDocumentBox],
        pointer: String
    ) throws -> [String] {
        guard let propertyOrder else {
            return properties.keys.sorted()
        }
        let orderPointer = afmJSONPointer(appending: "x-order", to: pointer)
        guard Set(propertyOrder).count == propertyOrder.count else {
            throw schemaValidationError("x-order contains duplicate property names", at: orderPointer)
        }
        guard Set(propertyOrder) == Set(properties.keys) else {
            throw schemaValidationError("x-order must list every object property exactly once", at: orderPointer)
        }
        return propertyOrder
    }

    private func requiredPropertyNames(
        in properties: [String: AFMSchemaDocumentBox],
        pointer: String
    ) throws -> Set<String> {
        let required = self.required ?? Array(properties.keys)
        let requiredPointer = afmJSONPointer(appending: "required", to: pointer)
        guard Set(required).count == required.count else {
            throw schemaValidationError("required contains duplicate property names", at: requiredPointer)
        }
        let unknownNames = Set(required).subtracting(properties.keys)
        guard unknownNames.isEmpty else {
            throw schemaValidationError(
                "required contains unknown properties: \(unknownNames.sorted().joined(separator: ", "))",
                at: requiredPointer
            )
        }
        return Set(required)
    }

    private func validateReferenceShape(pointer: String) throws {
        guard type == nil,
              properties == nil,
              required == nil,
              items == nil,
              minimumItems == nil,
              maximumItems == nil,
              enumValues == nil,
              anyOf == nil,
              propertyOrder == nil,
              additionalProperties == nil else {
            throw schemaValidationError(
                "$ref cannot be combined with structural schema keywords",
                at: afmJSONPointer(appending: "$ref", to: pointer)
            )
        }
    }

    private func validateUnionShape(pointer: String) throws {
        guard type == nil,
              properties == nil,
              required == nil,
              items == nil,
              minimumItems == nil,
              maximumItems == nil,
              enumValues == nil,
              reference == nil,
              propertyOrder == nil,
              additionalProperties == nil else {
            throw schemaValidationError(
                "anyOf cannot be combined with other structural schema keywords",
                at: afmJSONPointer(appending: "anyOf", to: pointer)
            )
        }
    }

    private func validateEnumShape(pointer: String) throws {
        guard type == nil || type == "string",
              properties == nil,
              required == nil,
              items == nil,
              minimumItems == nil,
              maximumItems == nil,
              reference == nil,
              anyOf == nil,
              propertyOrder == nil,
              additionalProperties == nil else {
            throw schemaValidationError(
                "enum only supports string schemas without other structural keywords",
                at: afmJSONPointer(appending: "enum", to: pointer)
            )
        }
        guard let enumValues, Set(enumValues).count == enumValues.count else {
            throw schemaValidationError(
                "enum contains duplicate values",
                at: afmJSONPointer(appending: "enum", to: pointer)
            )
        }
    }

    private func validateObjectShape(pointer: String) throws {
        guard items == nil,
              minimumItems == nil,
              maximumItems == nil,
              enumValues == nil,
              reference == nil,
              anyOf == nil else {
            throw schemaValidationError("Object schema contains incompatible keywords", at: pointer)
        }
    }

    private func validateArrayShape(pointer: String) throws {
        guard properties == nil,
              required == nil,
              enumValues == nil,
              reference == nil,
              anyOf == nil,
              propertyOrder == nil,
              additionalProperties == nil else {
            throw schemaValidationError("Array schema contains incompatible keywords", at: pointer)
        }
        if let minimumItems, minimumItems < 0 {
            throw schemaValidationError(
                "minItems cannot be negative",
                at: afmJSONPointer(appending: "minItems", to: pointer)
            )
        }
        if let maximumItems, maximumItems < 0 {
            throw schemaValidationError(
                "maxItems cannot be negative",
                at: afmJSONPointer(appending: "maxItems", to: pointer)
            )
        }
        if let minimumItems, let maximumItems, maximumItems < minimumItems {
            throw schemaValidationError(
                "maxItems cannot be less than minItems",
                at: afmJSONPointer(appending: "maxItems", to: pointer)
            )
        }
    }

    private func validatePrimitiveShape(pointer: String) throws {
        guard properties == nil,
              required == nil,
              items == nil,
              minimumItems == nil,
              maximumItems == nil,
              enumValues == nil,
              reference == nil,
              anyOf == nil,
              propertyOrder == nil,
              additionalProperties == nil else {
            throw schemaValidationError("Primitive schema contains incompatible keywords", at: pointer)
        }
    }

    private func referencedDefinitionName(_ reference: String, pointer: String) throws -> String {
        let prefix = "#/$defs/"
        let encodedName = String(reference.dropFirst(prefix.count))
        let decodedName = encodedName
            .replacingOccurrences(of: "~1", with: "/")
            .replacingOccurrences(of: "~0", with: "~")
        guard reference.hasPrefix(prefix),
              !encodedName.isEmpty,
              afmJSONPointerEscaped(decodedName) == encodedName else {
            throw schemaValidationError(
                "Only local references in the form '#/$defs/Name' are supported",
                at: afmJSONPointer(appending: "$ref", to: pointer)
            )
        }
        return decodedName
    }
}

struct AFMSchemaCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

func afmJSONPointer(appending component: String, to pointer: String) -> String {
    "\(pointer)/\(afmJSONPointerEscaped(component))"
}

func afmJSONPointerEscaped(_ component: String) -> String {
    component
        .replacingOccurrences(of: "~", with: "~0")
        .replacingOccurrences(of: "/", with: "~1")
}

private func schemaValidationError(_ message: String, at pointer: String) -> ValidationError {
    ValidationError("\(message) at JSON pointer '\(pointer.isEmpty ? "/" : pointer)'.")
}

struct AFMSchemaValidationError: LocalizedError {
    let keyword: String
    let jsonPointer: String
    let detail: String

    static func unsupportedKeyword(
        _ keyword: String,
        codingPath: [any CodingKey],
        detail: String = "This keyword is not supported."
    ) -> Self {
        let components = codingPath.map(\.stringValue) + [keyword]
        let pointer = "/" + components.map(afmJSONPointerEscaped).joined(separator: "/")
        return Self(keyword: keyword, jsonPointer: pointer, detail: detail)
    }

    var errorDescription: String? {
        "Unsupported schema keyword '\(keyword)' at JSON pointer '\(jsonPointer)'. \(detail)"
    }

    static func find(in error: any Error) -> Self? {
        if let schemaError = error as? Self {
            return schemaError
        }

        let underlyingError: (any Error)?
        switch error {
        case DecodingError.dataCorrupted(let context),
             DecodingError.keyNotFound(_, let context),
             DecodingError.typeMismatch(_, let context),
             DecodingError.valueNotFound(_, let context):
            underlyingError = context.underlyingError
        default:
            underlyingError = nil
        }

        guard let underlyingError else {
            return nil
        }
        return find(in: underlyingError)
    }

}
