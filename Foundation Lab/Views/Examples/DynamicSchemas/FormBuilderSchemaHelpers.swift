//
//  FormBuilderSchemaHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

extension FormBuilderSchemaView {
    func addPersonalInfoFields(to properties: inout [DynamicGenerationSchema.Property], for lowercased: String) {
        if lowercased.contains("personal") || lowercased.contains("name") {
            properties.append(
                DynamicSchemaHelpers.typedProperty(
                    "name",
                    type: String.self,
                    description: "Full name"
                )
            )
        }

        if lowercased.contains("email") || lowercased.contains("contact") {
            properties.append(
                DynamicSchemaHelpers.guidedProperty(
                    "email",
                    type: String.self,
                    guides: [.pattern(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z] {2,}$/)],
                    description: "Email address"
                )
            )
        }

        if lowercased.contains("phone") || lowercased.contains("contact") {
            properties.append(
                DynamicSchemaHelpers.guidedProperty(
                    "phone",
                    type: String.self,
                    guides: [.pattern(/\(\d {3}\) \d {3}-\d {4}/)],
                    description: "Phone number (US format)",
                    isOptional: true
                )
            )
        }
    }

    func addExperienceFields(to properties: inout [DynamicGenerationSchema.Property], for lowercased: String) {
        if lowercased.contains("experience") || lowercased.contains("job") {
            properties.append(
                DynamicSchemaHelpers.guidedProperty(
                    "yearsOfExperience",
                    type: Int.self,
                    guides: [.range(0...50)],
                    description: "Years of professional experience",
                    isOptional: true
                )
            )

            properties.append(
                DynamicSchemaHelpers.typedProperty(
                    "currentPosition",
                    type: String.self,
                    description: "Current job title",
                    isOptional: true
                )
            )
        }
    }

    func addSkillsFields(to properties: inout [DynamicGenerationSchema.Property], for lowercased: String) {
        if lowercased.contains("skill") {
            properties.append(
                DynamicSchemaHelpers.arrayProperty(
                    "skills",
                    elementSchema: .init(type: String.self),
                    description: "List of skills"
                )
            )
        }
    }

    func addCommonFields(to properties: inout [DynamicGenerationSchema.Property]) {
        properties.append(
            DynamicSchemaHelpers.typedProperty(
                "availability",
                type: String.self,
                description: "When available to start",
                isOptional: true
            )
        )

        properties.append(
            DynamicSchemaHelpers.typedProperty(
                "salaryExpectation",
                type: String.self,
                description: "Salary expectation or range",
                isOptional: true
            )
        )

        properties.append(
            DynamicSchemaHelpers.typedProperty(
                "remoteWork",
                type: Bool.self,
                description: "Open to remote work",
                isOptional: true
            )
        )
    }

    func createPredefinedJobApplicationSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "JobApplication",
            description: "Job application form data",
            properties: [
                createPersonalInfoProperty(),
                createExperienceProperty(),
                createPreferencesProperty()
            ]
        )
    }

    func createPersonalInfoProperty() -> DynamicGenerationSchema.Property {
        DynamicSchemaHelpers.nestedProperty(
            "personalInfo",
            schema: createPersonalInfoSchema(),
            description: "Personal information"
        )
    }

    func createPersonalInfoSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "PersonalInfo",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "fullName",
                    type: String.self,
                    description: "Applicant's full name"
                ),
                DynamicSchemaHelpers.guidedProperty(
                    "email",
                    type: String.self,
                    guides: [.pattern(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z] {2,}$/)],
                    description: "Email address"
                ),
                DynamicSchemaHelpers.guidedProperty(
                    "phone",
                    type: String.self,
                    guides: [.pattern(/\(\d {3}\) \d {3}-\d {4}/)],
                    description: "Phone number",
                    isOptional: true
                )
            ]
        )
    }

    func createExperienceProperty() -> DynamicGenerationSchema.Property {
        DynamicSchemaHelpers.nestedProperty(
            "experience",
            schema: createExperienceSchema(),
            description: "Professional experience"
        )
    }

    func createExperienceSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Experience",
            properties: [
                DynamicSchemaHelpers.guidedProperty(
                    "years",
                    type: Int.self,
                    guides: [.range(0...50)],
                    description: "Years of experience"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "currentRole",
                    type: String.self,
                    description: "Current position"
                ),
                DynamicSchemaHelpers.arrayProperty(
                    "skills",
                    elementSchema: .init(type: String.self),
                    description: "Technical skills"
                )
            ]
        )
    }

    func createPreferencesProperty() -> DynamicGenerationSchema.Property {
        DynamicSchemaHelpers.nestedProperty(
            "preferences",
            schema: createPreferencesSchema(),
            description: "Job preferences"
        )
    }

    func createPreferencesSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Preferences",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "startDate",
                    type: String.self,
                    description: "Available to start"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "salaryRange",
                    type: String.self,
                    description: "Expected salary",
                    isOptional: true
                ),
                DynamicSchemaHelpers.typedProperty(
                    "remoteWork",
                    type: Bool.self,
                    description: "Open to remote"
                )
            ]
        )
    }

    func describeSchema(_ schema: DynamicGenerationSchema) -> String {
        var description = "Schema Definition:\n"
        description += "Fields:\n"

        // Note: In a real implementation, we would need access to schema internals
        // For now, we just show the basic info
        description += "  [Schema details would be displayed here]\n"

        return description
    }

    func getPattern(from schema: DynamicGenerationSchema) -> String? {
        // This is a simplified version - in real implementation would need to inspect schema internals
        return nil
    }

    func getRange(from schema: DynamicGenerationSchema) -> (Any?, Any?)? {
        // This is a simplified version - in real implementation would need to inspect schema internals
        return nil
    }

    func formatGeneratedContent(_ content: GeneratedContent) -> String {
        var result: [String: Any] = [:]

        switch content.kind {
        case .structure(let properties, let orderedKeys):
            for key in orderedKeys {
                if let value = properties[key] {
                    result[key] = convertToJSONValue(value)
                }
            }
        case .array(let elements):
            let arrayValues = elements.map { convertToJSONValue($0) }
            return formatJSONArray(arrayValues)
        case .string(let str):
            return "\"\(str)\""
        case .number(let num):
            return String(num)
        case .bool(let bool):
            return String(bool)
        case .null:
            return "null"
        @unknown default:
            return "unknown"
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? String(localized: "Unable to format")
        } catch let error {
            return String(localized: "Error formatting content: \(error.localizedDescription)")
        }
    }

    func convertToJSONValue(_ content: GeneratedContent) -> Any {
        switch content.kind {
        case .structure(let properties, let orderedKeys):
            var result: [String: Any] = [:]
            for key in orderedKeys {
                if let value = properties[key] {
                    result[key] = convertToJSONValue(value)
                }
            }
            return result
        case .array(let elements):
            return elements.map { convertToJSONValue($0) }
        case .string(let str):
            return str
        case .number(let num):
            return num
        case .bool(let bool):
            return bool
        case .null:
            return NSNull()
        @unknown default:
            return "unknown"
        }
    }

    func formatJSONArray(_ array: [Any]) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: array, options: [.prettyPrinted])
            return String(data: data, encoding: .utf8) ?? String(localized: "Unable to format array")
        } catch {
            return String(localized: "Error formatting array: \(error.localizedDescription)")
        }
    }
}
