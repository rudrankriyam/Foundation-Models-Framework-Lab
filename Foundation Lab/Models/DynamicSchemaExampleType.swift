//
//  DynamicSchemaExampleType.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation

enum DynamicSchemaExampleType: String, CaseIterable, Identifiable {
    case basicObject = "basic_object"
    case arraySchema = "array_schema"
    case enumSchema = "enum_schema"
    case nestedObjects = "nested_objects"
    case schemaReferences = "schema_references"
    case generationGuides = "generation_guides"
    case generablePattern = "generable_pattern"
    case unionTypes = "union_types"
    case formBuilder = "form_builder"
    case errorHandling = "error_handling"
    case invoiceProcessing = "invoice_processing"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basicObject:
            return "Basic Object Schema"
        case .arraySchema:
            return "Array Schemas"
        case .enumSchema:
            return "Enum Schemas"
        case .nestedObjects:
            return "Nested Objects"
        case .schemaReferences:
            return "Schema References"
        case .generationGuides:
            return "Generation Guides"
        case .generablePattern:
            return "@Generable Pattern"
        case .unionTypes:
            return "Union Types (anyOf)"
        case .formBuilder:
            return "Dynamic Form Builder"
        case .errorHandling:
            return "Error Handling"
        case .invoiceProcessing:
            return "Invoice Processing"
        }
    }

    var subtitle: String {
        switch self {
        case .basicObject:
            return "Create simple object schemas at runtime"
        case .arraySchema:
            return "Arrays with min/max constraints"
        case .enumSchema:
            return "String enumerations and choices"
        case .nestedObjects:
            return "Complex nested object structures"
        case .schemaReferences:
            return "Schemas referencing other schemas"
        case .generationGuides:
            return "Apply constraints to generated values"
        case .generablePattern:
            return "Type-safe generation with @Generable"
        case .unionTypes:
            return "Multiple type alternatives"
        case .formBuilder:
            return "Build forms dynamically from user input"
        case .errorHandling:
            return "Handle schema errors gracefully"
        case .invoiceProcessing:
            return "Real-world invoice data extraction"
        }
    }

    var icon: String {
        switch self {
        case .basicObject:
            return "doc.text"
        case .arraySchema:
            return "list.number"
        case .enumSchema:
            return "list.bullet"
        case .nestedObjects:
            return "folder.fill"
        case .schemaReferences:
            return "link"
        case .generationGuides:
            return "ruler"
        case .generablePattern:
            return "swift"
        case .unionTypes:
            return "arrow.triangle.branch"
        case .formBuilder:
            return "rectangle.grid.1x2"
        case .errorHandling:
            return "exclamationmark.triangle"
        case .invoiceProcessing:
            return "doc.richtext"
        }
    }

}
