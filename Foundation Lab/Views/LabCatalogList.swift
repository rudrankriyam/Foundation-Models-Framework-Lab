//
//  LabCatalogList.swift
//  Foundation Lab
//

import SwiftUI

struct LabCatalogList: View {
    let searchText: String

    var body: some View {
        if hasResults {
            List {
                LabExampleSection(
                    "Generation Options",
                    examples: filtered(ExampleType.generationExamples)
                )
                LabExampleSection(
                    "Models & Input",
                    examples: filtered(ExampleType.modelAndInputExamples)
                )
                LabExampleSection(
                    "Session",
                    examples: filtered(ExampleType.sessionExamples)
                )
                LabExampleSection(
                    "Agent Workflows",
                    examples: filtered(ExampleType.agentExamples)
                )
                LabExampleSection(
                    "Developer Tools",
                    examples: filtered(ExampleType.developerToolExamples)
                )

                if !filteredTools.isEmpty {
                    Section("Tools") {
                        ForEach(filteredTools, id: \.self) { tool in
                            NavigationLink(value: tool) {
                                LabNavigationRow(
                                    title: tool.displayName,
                                    subtitle: tool.shortDescription,
                                    systemImage: tool.icon
                                )
                            }
                        }
                    }
                }

                if !filteredSchemas.isEmpty {
                    Section("Dynamic Schemas") {
                        ForEach(filteredSchemas) { example in
                            NavigationLink(value: example) {
                                LabNavigationRow(
                                    title: example.title,
                                    subtitle: example.subtitle,
                                    systemImage: example.icon
                                )
                            }
                        }
                    }
                }

                if !filteredLanguages.isEmpty {
                    Section("Languages") {
                        ForEach(filteredLanguages) { language in
                            NavigationLink(value: language) {
                                LabNavigationRow(
                                    title: language.title,
                                    subtitle: language.subtitle,
                                    systemImage: language.icon
                                )
                            }
                        }
                    }
                }
            }
#if os(iOS)
            .listStyle(.insetGrouped)
#else
            .listStyle(.inset)
#endif
        } else {
            ContentUnavailableView.search(text: trimmedSearchText)
        }
    }

    private var filteredTools: [ToolExample] {
        ToolExample.allCases.filter { matches($0.displayName, $0.shortDescription) }
    }

    private var filteredSchemas: [DynamicSchemaExampleType] {
        DynamicSchemaExampleType.allCases.filter { matches($0.title, $0.subtitle) }
    }

    private var filteredLanguages: [LanguageExample] {
        LanguageExample.allCases.filter { matches($0.title, $0.subtitle) }
    }

    private var hasResults: Bool {
        !filtered(ExampleType.studioExamples).isEmpty
            || !filteredTools.isEmpty
            || !filteredSchemas.isEmpty
            || !filteredLanguages.isEmpty
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func filtered(_ examples: [ExampleType]) -> [ExampleType] {
        examples.filter { matches($0.title, $0.subtitle) }
    }

    private func matches(_ title: String, _ subtitle: String) -> Bool {
        let query = trimmedSearchText
        guard !query.isEmpty else { return true }

        return title.localizedStandardContains(query)
            || subtitle.localizedStandardContains(query)
    }
}

#Preview {
    NavigationStack {
        LabCatalogList(searchText: "")
    }
}
