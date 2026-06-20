//
//  AppIntentDestinations.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 1/24/26.
//

import AppIntents
import FoundationLabCore

enum ExampleDestination: String, AppEnum, CaseIterable {
    case basicChat
    case journaling
    case creativeWriting
    case structuredData
    case streamingResponse
    case modelAvailability
    case generationGuides
    case generationOptions
    case health
    case rag

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Example")

    static let caseDisplayRepresentations: [ExampleDestination: DisplayRepresentation] = [
        .basicChat: DisplayRepresentation(title: "One-shot"),
        .journaling: DisplayRepresentation(title: "Journaling"),
        .creativeWriting: DisplayRepresentation(title: "Creative Writing"),
        .structuredData: DisplayRepresentation(title: "Structured Data"),
        .streamingResponse: DisplayRepresentation(title: "Streaming Response"),
        .modelAvailability: DisplayRepresentation(title: "Model Availability"),
        .generationGuides: DisplayRepresentation(title: "Generation Guides"),
        .generationOptions: DisplayRepresentation(title: "Generation Options"),
        .health: DisplayRepresentation(title: "Health Dashboard"),
        .rag: DisplayRepresentation(title: "RAG Chat")
    ]

    var exampleType: ExampleType {
        switch self {
        case .basicChat:
            return .basicChat
        case .journaling:
            return .journaling
        case .creativeWriting:
            return .creativeWriting
        case .structuredData:
            return .structuredData
        case .streamingResponse:
            return .streamingResponse
        case .modelAvailability:
            return .modelAvailability
        case .generationGuides:
            return .generationGuides
        case .generationOptions:
            return .generationOptions
        case .health:
            return .health
        case .rag:
            return .rag
        }
    }
}

enum ToolDestination: String, AppEnum, CaseIterable {
    case weather
    case web
    case contacts
    case calendar
    case reminders
    case location
    case health
    case music
    case webMetadata

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tool")

    static let caseDisplayRepresentations: [ToolDestination: DisplayRepresentation] = [
        .weather: DisplayRepresentation(title: "Weather"),
        .web: DisplayRepresentation(title: "Web Search"),
        .contacts: DisplayRepresentation(title: "Contacts"),
        .calendar: DisplayRepresentation(title: "Calendar"),
        .reminders: DisplayRepresentation(title: "Reminders"),
        .location: DisplayRepresentation(title: "Location"),
        .health: DisplayRepresentation(title: "Health"),
        .music: DisplayRepresentation(title: "Music"),
        .webMetadata: DisplayRepresentation(title: "Web Metadata")
    ]

    var tool: FoundationLabBuiltInTool {
        switch self {
        case .weather:
            return .weather
        case .web:
            return .web
        case .contacts:
            return .contacts
        case .calendar:
            return .calendar
        case .reminders:
            return .reminders
        case .location:
            return .location
        case .health:
            return .health
        case .music:
            return .music
        case .webMetadata:
            return .webMetadata
        }
    }
}

enum SchemaDestination: String, AppEnum, CaseIterable {
    case basicObject
    case arraySchema
    case enumSchema
    case nestedObjects
    case schemaReferences
    case generationGuides
    case generablePattern
    case unionTypes
    case formBuilder
    case errorHandling
    case invoiceProcessing

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Schema Example")

    static let caseDisplayRepresentations: [SchemaDestination: DisplayRepresentation] = [
        .basicObject: DisplayRepresentation(title: "Basic Object Schema"),
        .arraySchema: DisplayRepresentation(title: "Array Schemas"),
        .enumSchema: DisplayRepresentation(title: "Enum Schemas"),
        .nestedObjects: DisplayRepresentation(title: "Nested Objects"),
        .schemaReferences: DisplayRepresentation(title: "Schema References"),
        .generationGuides: DisplayRepresentation(title: "Generation Guides"),
        .generablePattern: DisplayRepresentation(title: "@Generable Pattern"),
        .unionTypes: DisplayRepresentation(title: "Union Types"),
        .formBuilder: DisplayRepresentation(title: "Dynamic Form Builder"),
        .errorHandling: DisplayRepresentation(title: "Error Handling"),
        .invoiceProcessing: DisplayRepresentation(title: "Invoice Processing")
    ]

    var schemaExample: DynamicSchemaExampleType {
        switch self {
        case .basicObject:
            return .basicObject
        case .arraySchema:
            return .arraySchema
        case .enumSchema:
            return .enumSchema
        case .nestedObjects:
            return .nestedObjects
        case .schemaReferences:
            return .schemaReferences
        case .generationGuides:
            return .generationGuides
        case .generablePattern:
            return .generablePattern
        case .unionTypes:
            return .unionTypes
        case .formBuilder:
            return .formBuilder
        case .errorHandling:
            return .errorHandling
        case .invoiceProcessing:
            return .invoiceProcessing
        }
    }
}

enum LanguageDestination: String, AppEnum, CaseIterable {
    case languageDetection
    case multilingualResponses
    case sessionManagement
    case productionExample

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Language Example")

    static let caseDisplayRepresentations: [LanguageDestination: DisplayRepresentation] = [
        .languageDetection: DisplayRepresentation(title: "Language Detection"),
        .multilingualResponses: DisplayRepresentation(title: "Multilingual Play"),
        .sessionManagement: DisplayRepresentation(title: "Multiple Sessions"),
        .productionExample: DisplayRepresentation(title: "Insights Example")
    ]

    var languageExample: LanguageExample {
        switch self {
        case .languageDetection:
            return .languageDetection
        case .multilingualResponses:
            return .multilingualResponses
        case .sessionManagement:
            return .sessionManagement
        case .productionExample:
            return .productionExample
        }
    }
}
