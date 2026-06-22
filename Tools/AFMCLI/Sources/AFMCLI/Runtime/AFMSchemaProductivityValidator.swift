import ArgumentParser
import Foundation

enum AFMSchemaProductivityValidator {
    static func validate(
        root: AFMSchemaDocument,
        definitions: [String: AFMSchemaDocumentBox]
    ) throws {
        let productiveDefinitions = productiveDefinitionNames(in: definitions)
        let unproductiveNames = Set(definitions.keys).subtracting(productiveDefinitions)

        if let cycle = unproductiveCycle(
            among: unproductiveNames,
            definitions: definitions,
            productiveDefinitions: productiveDefinitions
        ) {
            throw ValidationError(
                "Schema reference cycle cannot produce a finite value: "
                    + "\(cycle.names.joined(separator: " -> ")). "
                    + "JSON pointer '\(cycle.pointer)'."
            )
        }

        guard isProductive(root, productiveDefinitions: productiveDefinitions) else {
            throw ValidationError("Schema cannot produce a finite value.")
        }
    }
}

private extension AFMSchemaProductivityValidator {
    struct ReferenceEdge {
        let target: String
        let pointer: String
    }

    struct ReferenceCycle {
        let names: [String]
        let pointer: String
    }

    static func productiveDefinitionNames(
        in definitions: [String: AFMSchemaDocumentBox]
    ) -> Set<String> {
        var productive: Set<String> = []

        while true {
            let newlyProductive = definitions.keys.sorted().filter { name in
                guard !productive.contains(name), let document = definitions[name]?.value else {
                    return false
                }
                return isProductive(document, productiveDefinitions: productive)
            }
            guard !newlyProductive.isEmpty else {
                return productive
            }
            productive.formUnion(newlyProductive)
        }
    }

    static func isProductive(
        _ document: AFMSchemaDocument,
        productiveDefinitions: Set<String>
    ) -> Bool {
        if let reference = document.reference {
            guard let name = referencedDefinitionName(reference) else {
                return false
            }
            return productiveDefinitions.contains(name)
        }

        if let choices = document.anyOf {
            return choices.contains { choice in
                isProductive(choice.value, productiveDefinitions: productiveDefinitions)
            }
        }

        if let enumValues = document.enumValues {
            return !enumValues.isEmpty
        }

        return isTypedSchemaProductive(document, productiveDefinitions: productiveDefinitions)
    }

    static func isTypedSchemaProductive(
        _ document: AFMSchemaDocument,
        productiveDefinitions: Set<String>
    ) -> Bool {
        switch resolvedType(of: document) {
        case "object":
            let properties = document.properties ?? [:]
            let requiredNames = document.required ?? Array(properties.keys)
            return requiredNames.allSatisfy { propertyName in
                guard let property = properties[propertyName]?.value else {
                    return false
                }
                return isProductive(property, productiveDefinitions: productiveDefinitions)
            }
        case "array":
            if (document.minimumItems ?? 0) == 0 {
                return true
            }
            guard let items = document.items?.value else {
                return false
            }
            return isProductive(items, productiveDefinitions: productiveDefinitions)
        case "string", "integer", "number", "boolean":
            return true
        default:
            return false
        }
    }

    static func unproductiveCycle(
        among unproductiveNames: Set<String>,
        definitions: [String: AFMSchemaDocumentBox],
        productiveDefinitions: Set<String>
    ) -> ReferenceCycle? {
        let graph = Dictionary(uniqueKeysWithValues: unproductiveNames.sorted().map { name in
            let pointer = afmJSONPointer(appending: name, to: "/$defs")
            let edges = definitions[name].map { box in
                blockingReferences(
                    in: box.value,
                    pointer: pointer,
                    productiveDefinitions: productiveDefinitions
                )
            } ?? []
            return (name, edges.sorted(by: referenceEdgeOrder))
        })

        for start in unproductiveNames.sorted() {
            var positions: [String: Int] = [:]
            var path: [String] = []
            var current = start
            var incomingPointer = afmJSONPointer(appending: start, to: "/$defs")

            while positions[current] == nil {
                positions[current] = path.count
                path.append(current)
                guard let edge = graph[current]?.first else {
                    break
                }
                current = edge.target
                incomingPointer = edge.pointer
            }

            if let cycleStart = positions[current] {
                return ReferenceCycle(
                    names: Array(path[cycleStart...]) + [current],
                    pointer: incomingPointer
                )
            }
        }
        return nil
    }

    static func blockingReferences(
        in document: AFMSchemaDocument,
        pointer: String,
        productiveDefinitions: Set<String>
    ) -> [ReferenceEdge] {
        if let reference = document.reference,
           let target = referencedDefinitionName(reference),
           !productiveDefinitions.contains(target) {
            return [
                ReferenceEdge(
                    target: target,
                    pointer: afmJSONPointer(appending: "$ref", to: pointer)
                )
            ]
        }

        if let choices = document.anyOf {
            return blockingUnionReferences(
                choices,
                pointer: pointer,
                productiveDefinitions: productiveDefinitions
            )
        }

        if document.enumValues != nil {
            return []
        }

        switch resolvedType(of: document) {
        case "object":
            return blockingObjectReferences(
                in: document,
                pointer: pointer,
                productiveDefinitions: productiveDefinitions
            )
        case "array":
            guard (document.minimumItems ?? 0) > 0,
                  let items = document.items?.value,
                  !isProductive(items, productiveDefinitions: productiveDefinitions) else {
                return []
            }
            return blockingReferences(
                in: items,
                pointer: afmJSONPointer(appending: "items", to: pointer),
                productiveDefinitions: productiveDefinitions
            )
        default:
            return []
        }
    }

    static func blockingUnionReferences(
        _ choices: [AFMSchemaDocumentBox],
        pointer: String,
        productiveDefinitions: Set<String>
    ) -> [ReferenceEdge] {
        choices.enumerated().flatMap { index, choice -> [ReferenceEdge] in
            guard !isProductive(choice.value, productiveDefinitions: productiveDefinitions) else {
                return []
            }
            let choicePointer = afmJSONPointer(
                appending: String(index),
                to: afmJSONPointer(appending: "anyOf", to: pointer)
            )
            return blockingReferences(
                in: choice.value,
                pointer: choicePointer,
                productiveDefinitions: productiveDefinitions
            )
        }
    }

    static func blockingObjectReferences(
        in document: AFMSchemaDocument,
        pointer: String,
        productiveDefinitions: Set<String>
    ) -> [ReferenceEdge] {
        let properties = document.properties ?? [:]
        let requiredNames = document.required ?? Array(properties.keys)
        return requiredNames.sorted().flatMap { propertyName -> [ReferenceEdge] in
            guard let property = properties[propertyName]?.value,
                  !isProductive(property, productiveDefinitions: productiveDefinitions) else {
                return []
            }
            let propertyPointer = afmJSONPointer(
                appending: propertyName,
                to: afmJSONPointer(appending: "properties", to: pointer)
            )
            return blockingReferences(
                in: property,
                pointer: propertyPointer,
                productiveDefinitions: productiveDefinitions
            )
        }
    }

    static func resolvedType(of document: AFMSchemaDocument) -> String {
        if let type = document.type {
            return type
        }
        if document.properties != nil {
            return "object"
        }
        if document.items != nil {
            return "array"
        }
        if document.enumValues != nil {
            return "string"
        }
        return "object"
    }

    static func referencedDefinitionName(_ reference: String) -> String? {
        let prefix = "#/$defs/"
        guard reference.hasPrefix(prefix) else {
            return nil
        }
        let encodedName = String(reference.dropFirst(prefix.count))
        let decodedName = encodedName
            .replacingOccurrences(of: "~1", with: "/")
            .replacingOccurrences(of: "~0", with: "~")
        guard !encodedName.isEmpty, afmJSONPointerEscaped(decodedName) == encodedName else {
            return nil
        }
        return decodedName
    }

    static func referenceEdgeOrder(_ lhs: ReferenceEdge, _ rhs: ReferenceEdge) -> Bool {
        if lhs.target == rhs.target {
            return lhs.pointer < rhs.pointer
        }
        return lhs.target < rhs.target
    }
}
