import ArgumentParser
import Foundation

enum AFMSchemaObjectBuilder {
    static func build(_ request: AFMSchemaObjectRequest) throws -> AFMSchemaDocument {
        let document: AFMSchemaDocument
        switch request.mode {
        case .object(let properties):
            document = try buildObject(name: request.name, properties: properties)
        case .union(let schemas):
            document = try buildUnion(name: request.name, schemas: schemas)
        }
        _ = try document.generationSchema(fallbackName: request.name)
        return document
    }

    private static func buildObject(
        name: String,
        properties: [AFMSchemaObjectProperty]
    ) throws -> AFMSchemaDocument {
        let root = AFMSchemaObjectNode(name: name)
        for property in properties {
            try root.insert(property)
        }

        var definitions: [String: AFMSchemaDocumentBox] = [:]
        var components = try objectComponents(for: root, definitions: &definitions)
        components.definitions = definitions.isEmpty ? nil : definitions
        return AFMSchemaDocument(components)
    }

    private static func buildUnion(
        name: String,
        schemas: [AFMSchemaDocument]
    ) throws -> AFMSchemaDocument {
        var definitions: [String: AFMSchemaDocumentBox] = [:]
        var choices: [AFMSchemaDocumentBox] = []

        for schema in schemas {
            _ = try schema.generationSchema(fallbackName: "\(name)Choice")
            try mergeDefinitions(from: schema, into: &definitions)
            let choice = schemaWithoutDefinitions(schema)
            if let title = choice.title, !title.isEmpty {
                try mergeDefinition(named: title, document: choice, into: &definitions)
                choices.append(AFMSchemaDocumentBox(referenceDocument(to: title)))
            } else {
                choices.append(AFMSchemaDocumentBox(choice))
            }
        }

        var components = AFMSchemaDocument.Components()
        components.title = name
        components.anyOf = choices
        components.definitions = definitions.isEmpty ? nil : definitions
        return AFMSchemaDocument(components)
    }

    private static func objectComponents(
        for node: AFMSchemaObjectNode,
        definitions: inout [String: AFMSchemaDocumentBox]
    ) throws -> AFMSchemaDocument.Components {
        var properties: [String: AFMSchemaDocumentBox] = [:]
        var required: [String] = []
        let orderedNames = node.orderedPropertyNames

        for propertyName in orderedNames {
            guard let value = node.properties[propertyName] else {
                throw ValidationError("Missing schema object property '\(propertyName)'.")
            }
            switch value {
            case .nested(let child):
                let childComponents = try objectComponents(for: child, definitions: &definitions)
                let childDocument = AFMSchemaDocument(childComponents)
                try mergeDefinition(named: child.name, document: childDocument, into: &definitions)
                properties[propertyName] = AFMSchemaDocumentBox(referenceDocument(to: child.name))
                required.append(propertyName)
            case .leaf(let property):
                properties[propertyName] = AFMSchemaDocumentBox(
                    try propertyDocument(property, definitions: &definitions)
                )
                if !property.isOptional {
                    required.append(propertyName)
                }
            }
        }

        var components = AFMSchemaDocument.Components()
        components.title = node.name
        components.type = "object"
        components.properties = properties
        components.required = required
        components.additionalProperties = false
        components.propertyOrder = orderedNames
        return components
    }

    private static func propertyDocument(
        _ property: AFMSchemaObjectProperty,
        definitions: inout [String: AFMSchemaDocumentBox]
    ) throws -> AFMSchemaDocument {
        let base: AFMSchemaDocument
        switch property.kind {
        case .primitive(let type):
            var components = AFMSchemaDocument.Components()
            components.type = type
            base = AFMSchemaDocument(components)
        case .object(let schema):
            guard let schema else {
                throw ValidationError("--object '\(property.path.joined(separator: "."))' is missing --schema.")
            }
            guard schemaRepresentsObject(schema) else {
                throw ValidationError("--object schemas must describe an object.")
            }
            _ = try schema.generationSchema(fallbackName: property.path.last?.camelizedSchemaName() ?? "Object")
            try mergeDefinitions(from: schema, into: &definitions)
            let objectDocument = schemaWithoutDefinitions(schema)
            if let title = objectDocument.title, !title.isEmpty {
                try mergeDefinition(named: title, document: objectDocument, into: &definitions)
                base = referenceDocument(to: title)
            } else {
                base = objectDocument
            }
        }

        let decorated = document(base, replacingDescriptionWith: property.description)
        guard property.isArray else {
            return decorated
        }
        var arrayComponents = AFMSchemaDocument.Components()
        arrayComponents.description = property.description
        arrayComponents.type = "array"
        arrayComponents.items = AFMSchemaDocumentBox(document(base, replacingDescriptionWith: nil))
        return AFMSchemaDocument(arrayComponents)
    }

    private static func referenceDocument(to definitionName: String) -> AFMSchemaDocument {
        var components = AFMSchemaDocument.Components()
        components.reference = "#/$defs/\(afmJSONPointerEscaped(definitionName))"
        return AFMSchemaDocument(components)
    }

    private static func document(
        _ document: AFMSchemaDocument,
        replacingDescriptionWith description: String?
    ) -> AFMSchemaDocument {
        var components = components(from: document)
        components.description = description ?? document.description
        return AFMSchemaDocument(components)
    }

    private static func schemaWithoutDefinitions(_ schema: AFMSchemaDocument) -> AFMSchemaDocument {
        var components = components(from: schema)
        components.definitions = nil
        return AFMSchemaDocument(components)
    }

    private static func components(from schema: AFMSchemaDocument) -> AFMSchemaDocument.Components {
        var components = AFMSchemaDocument.Components()
        components.title = schema.title
        components.description = schema.description
        components.type = schema.type
        components.properties = schema.properties
        components.required = schema.required
        components.items = schema.items
        components.minimumItems = schema.minimumItems
        components.maximumItems = schema.maximumItems
        components.enumValues = schema.enumValues
        components.additionalProperties = schema.additionalProperties
        components.definitions = schema.definitions
        components.reference = schema.reference
        components.anyOf = schema.anyOf
        components.propertyOrder = schema.propertyOrder
        return components
    }

    private static func schemaRepresentsObject(_ schema: AFMSchemaDocument) -> Bool {
        guard schema.reference == nil, schema.anyOf == nil, schema.enumValues == nil else {
            return false
        }
        return schema.type == "object" || (schema.type == nil && schema.properties != nil)
    }

    private static func mergeDefinitions(
        from schema: AFMSchemaDocument,
        into definitions: inout [String: AFMSchemaDocumentBox]
    ) throws {
        for name in (schema.definitions ?? [:]).keys.sorted() {
            guard let document = schema.definitions?[name]?.value else {
                continue
            }
            try mergeDefinition(named: name, document: document, into: &definitions)
        }
    }

    private static func mergeDefinition(
        named name: String,
        document: AFMSchemaDocument,
        into definitions: inout [String: AFMSchemaDocumentBox]
    ) throws {
        guard let existing = definitions[name]?.value else {
            definitions[name] = AFMSchemaDocumentBox(document)
            return
        }
        guard try encodedSchema(existing) == encodedSchema(document) else {
            throw ValidationError("Conflicting schema definitions named '\(name)'.")
        }
    }

    private static func encodedSchema(_ schema: AFMSchemaDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(schema)
    }
}

private final class AFMSchemaObjectNode {
    enum Value {
        case nested(AFMSchemaObjectNode)
        case leaf(AFMSchemaObjectProperty)
    }

    let name: String
    private(set) var properties: [String: Value] = [:]
    private var insertionOrder: [String] = []

    init(name: String) {
        self.name = name
    }

    var orderedPropertyNames: [String] {
        let leafNames = insertionOrder.filter {
            if case .leaf = properties[$0] { return true }
            return false
        }
        let nestedNames = insertionOrder.filter {
            if case .nested = properties[$0] { return true }
            return false
        }
        return leafNames + nestedNames
    }

    func insert(_ property: AFMSchemaObjectProperty) throws {
        var current = self
        for component in property.path.dropLast() {
            if let existing = current.properties[component] {
                guard case .nested(let child) = existing else {
                    throw ValidationError("Property path '\(property.path.joined(separator: "."))' conflicts with '\(component)'.")
                }
                current = child
            } else {
                let child = AFMSchemaObjectNode(name: component.camelizedSchemaName())
                current.properties[component] = .nested(child)
                current.insertionOrder.append(component)
                current = child
            }
        }

        guard let propertyName = property.path.last else {
            throw ValidationError("Property paths cannot be empty.")
        }
        guard current.properties[propertyName] == nil else {
            throw ValidationError("Schema contains multiple '\(property.path.joined(separator: "."))' properties.")
        }
        current.properties[propertyName] = .leaf(property)
        current.insertionOrder.append(propertyName)
    }
}
