//
//  ExperimentLibraryCatalogView.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct ExperimentLibraryCatalogView: View {
    let catalog: ExperimentLibraryCatalog

    var body: some View {
        List {
            switch catalog {
            case .schemas:
                schemaSections
            case .languages:
                languageSections
            }
        }
        .navigationTitle(catalog.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .listStyle(.insetGrouped)
        #else
        .navigationSubtitle(catalog.subtitle)
        .listStyle(.inset)
        #endif
    }

    @ViewBuilder
    private var schemaSections: some View {
        schemaSection(
            "Beginner",
            systemImage: FoundationLabExperimentLevel.beginner.systemImage,
            examples: [.basicObject, .arraySchema, .enumSchema]
        )
        schemaSection(
            "Intermediate",
            systemImage: FoundationLabExperimentLevel.intermediate.systemImage,
            examples: [.nestedObjects, .generationGuides, .generablePattern]
        )
        schemaSection(
            "Advanced",
            systemImage: FoundationLabExperimentLevel.advanced.systemImage,
            examples: [.schemaReferences, .unionTypes, .errorHandling]
        )
        schemaSection(
            "Expert Projects",
            systemImage: FoundationLabExperimentLevel.expert.systemImage,
            examples: [.formBuilder, .invoiceProcessing]
        )
    }

    @ViewBuilder
    private var languageSections: some View {
        Section {
            languageRow(.languageDetection)
            languageRow(.multilingualResponses)
        } header: {
            Label("Explore", systemImage: "text.bubble")
        }

        Section {
            languageRow(.sessionManagement)
            languageRow(.productionExample)
        } header: {
            Label("Production Patterns", systemImage: "shippingbox")
        }
    }

    private func schemaSection(
        _ title: String,
        systemImage: String,
        examples: [DynamicSchemaExampleType]
    ) -> some View {
        Section {
            ForEach(examples) { example in
                NavigationLink(value: example) {
                    destinationRow(
                        title: example.title,
                        subtitle: example.subtitle,
                        systemImage: example.icon
                    )
                }
            }
        } header: {
            Label(title, systemImage: systemImage)
        }
    }

    private func languageRow(_ language: LanguageExample) -> some View {
        NavigationLink(value: language) {
            destinationRow(
                title: language.title,
                subtitle: language.subtitle,
                systemImage: language.icon
            )
        }
    }

    private func destinationRow(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
        }
        .padding(.vertical, Spacing.xSmall)
        .contentShape(.rect)
    }
}

private extension ExperimentLibraryCatalog {
    var subtitle: String {
        switch self {
        case .schemas:
            String(localized: "Build reliable structured output")
        case .languages:
            String(localized: "Explore multilingual model behavior")
        }
    }
}

#Preview("Schemas") {
    NavigationStack {
        ExperimentLibraryCatalogView(catalog: .schemas)
    }
}

#Preview("Languages") {
    NavigationStack {
        ExperimentLibraryCatalogView(catalog: .languages)
    }
}
