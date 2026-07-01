//
//  DynamicSchemaExecutorExtension.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationLabCore
import FoundationModels
import FoundationModelsKit

extension ExampleExecutor {
    /// Convenience property to match the naming used in dynamic schema examples
    var results: String {
        get { result }
        set { result = newValue }
    }

    /// Convenience method to match the naming used in dynamic schema examples
    func reset() {
        clear()
    }

    /// Execute a custom async operation and capture the result
    func execute(_ operation: @escaping () async throws -> String) async {
        isRunning = true
        defer { isRunning = false }
        errorMessage = nil
        result = ""

        do {
            result = try await operation()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = FoundationModelsErrorHandler.handleError(error)
        }
    }

    /// Execute with a DynamicGenerationSchema
    func execute(
        withPrompt prompt: String,
        schema: DynamicGenerationSchema,
        formatResults: ((String) -> String)? = nil
    ) async {
        do {
            let generationSchema = try GenerationSchema(root: schema, dependencies: [])
            await executeDynamicSchema(
                prompt: prompt,
                schema: generationSchema
            ) { [formatResults] content in
                let formattedContent = self.formatGeneratedContent(content)
                if let formatResults {
                    return formatResults(formattedContent)
                }
                return formattedContent
            }
        } catch is CancellationError {
            return
        } catch {
            isRunning = false
            errorMessage = FoundationModelsErrorHandler.handleError(error)
        }
    }

    func executeDynamicSchema(
        prompt: String,
        schema: GenerationSchema,
        generationOptions: FoundationModelGenerationOptions? = nil,
        formatter: @escaping (GeneratedContent) -> String
    ) async {
        isRunning = true
        defer { isRunning = false }
        errorMessage = nil
        result = ""

        do {
            let response = try await FoundationModelDynamicSchemaGenerationUseCase().execute(
                FoundationModelDynamicSchemaGenerationRequest(
                    prompt: prompt,
                    schema: schema,
                    generationOptions: generationOptions,
                    context: FoundationModelInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )
            try Task.checkCancellation()
            result = formatter(response.output)
            storeLastTokenCount(response.metadata.tokenCount)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = FoundationModelsErrorHandler.handleError(error)
        }
    }

    /// Helper to format GeneratedContent as JSON string
    private func formatGeneratedContent(_ content: GeneratedContent) -> String {
        do {
            // Build a proper JSON object from the GeneratedContent
            let jsonObject = try buildJSONObject(from: content)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return String(describing: jsonObject)
        } catch {
            return String(localized: "Error formatting content: \(error.localizedDescription)")
        }
    }

    /// Recursively build a JSON-compatible object from GeneratedContent
    private func buildJSONObject(from content: GeneratedContent) throws -> Any {
        switch content.kind {
        case .string(let stringValue):
            return stringValue
        case .number(let numValue):
            return numValue
        case .bool(let boolValue):
            return boolValue
        case .null:
            return NSNull()
        case .array(let elements):
            return try elements.map { try buildJSONObject(from: $0) }
        case .structure(let properties, let orderedKeys):
            var jsonDict = [String: Any]()
            for key in orderedKeys {
                if let value = properties[key] {
                    jsonDict[key] = try buildJSONObject(from: value)
                }
            }
            return jsonDict
        @unknown default:
            return String(describing: content)
        }
    }
}
