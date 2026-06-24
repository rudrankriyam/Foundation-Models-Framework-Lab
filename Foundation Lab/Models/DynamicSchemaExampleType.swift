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
            return "Basic Object"
        case .arraySchema:
            return "Arrays"
        case .enumSchema:
            return "Enumerations"
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
            return "Form Builder"
        case .errorHandling:
            return "Schema Errors"
        case .invoiceProcessing:
            return "Invoice Processing"
        }
    }

    var subtitle: String {
        switch self {
        case .basicObject:
            return "Create an object schema at runtime"
        case .arraySchema:
            return "Add minimum and maximum item counts to arrays"
        case .enumSchema:
            return "Limit string output to a defined set of choices"
        case .nestedObjects:
            return "Compose objects with nested properties"
        case .schemaReferences:
            return "Reuse shared definitions across schemas"
        case .generationGuides:
            return "Constrain generated values with guides"
        case .generablePattern:
            return "Compare @Generable models with runtime schemas"
        case .unionTypes:
            return "Allow several valid output shapes with anyOf"
        case .formBuilder:
            return "Build a schema and form from field definitions"
        case .errorHandling:
            return "Surface invalid schemas and generation failures"
        case .invoiceProcessing:
            return "Extract structured fields from invoice text"
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
