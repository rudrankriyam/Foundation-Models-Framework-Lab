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
            case .xcode27:
                xcode27Sections
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

    @ViewBuilder
    private var xcode27Sections: some View {
        exampleSection(
            ExperimentTrack.contextAndRuntime.title,
            systemImage: ExperimentTrack.contextAndRuntime.systemImage,
            examples: [
                .modelRuntime,
                .contextWindowInspector,
                .privateCloudCompute,
                .imageInputPlayground,
                .usagePerformanceTrace
            ]
        )
        exampleSection(
            ExperimentTrack.buildWithTools.title,
            systemImage: ExperimentTrack.buildWithTools.systemImage,
            examples: [
                .toolCallingModeLab,
                .riskyToolConfirmation,
                .foundationModelsSecurityPlayground,
                .toolCallTrajectoryViewer
            ]
        )
        exampleSection(
            ExperimentTrack.advancedWorkflows.title,
            systemImage: ExperimentTrack.advancedWorkflows.systemImage,
            examples: [
                .dynamicProfileBuilder,
                .reasoningLevelComparison,
                .transcriptExplorer,
                .agentFlowInspector,
                .historyTransformLab,
                .modelRouterDashboard,
                .contextBudgetVisualizer
            ]
        )
        exampleSection(
            ExperimentTrack.appliedProjects.title,
            systemImage: ExperimentTrack.appliedProjects.systemImage,
            examples: [
                .geminiVideoInput,
                .spotlightRAGExplorer,
                .providerBridgeWalkthrough
            ]
        )
        exampleSection(
            ExperimentLaunch.workspace(ExpertWorkspace.fmfBench).displayName,
            systemImage: ExperimentLaunch.workspace(ExpertWorkspace.fmfBench).systemImage,
            examples: [.evaluationsLab, .fmCLIPythonPlayground]
        )
    }

    private func exampleSection(
        _ title: String,
        systemImage: String,
        examples: [ExampleType]
    ) -> some View {
        Section {
            ForEach(examples) { example in
                NavigationLink(value: example) {
                    xcode27DestinationRow(example)
                }
            }
        } header: {
            Label(title, systemImage: systemImage)
        }
    }

    private func schemaSection(
        _ title: LocalizedStringKey,
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

    private func xcode27DestinationRow(_ example: ExampleType) -> some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(LocalizedStringKey(example.title))
                    .font(.headline)
                if let subtitle = example.xcode27CatalogSubtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: example.icon)
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
        }
        .padding(.vertical, Spacing.xSmall)
        .contentShape(.rect)
    }

    private func destinationRow(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(LocalizedStringKey(title))
                    .font(.headline)
                Text(LocalizedStringKey(subtitle))
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

private extension ExampleType {
    var xcode27CatalogSubtitle: String? {
        switch self {
        case .modelRuntime:
            String(localized: "Inspect this device's model and tokenize the prompt")
        case .contextWindowInspector:
            String(localized: "Inspect the pieces that consume a session budget")
        case .privateCloudCompute:
            String(localized: "Probe PCC availability, quota, and context size")
        case .imageInputPlayground:
            String(localized: "Import an image, ask the on-device model, and inspect live usage evidence")
        case .usagePerformanceTrace:
            String(localized: "Run a real streamed response and inspect its reported usage")
        case .toolCallingModeLab:
            String(localized: "Inspect allowed, required, and disallowed tool behavior")
        case .riskyToolConfirmation:
            String(localized: "Keep side-effect authorization inside app-owned tool code")
        case .foundationModelsSecurityPlayground:
            String(localized: "Inspect the boundary between Foundation Models and your app")
        case .toolCallTrajectoryViewer:
            String(localized: "Compare explicit fixtures, not imaginary runs")
        case .dynamicProfileBuilder:
            String(localized: "Compose a LanguageModelSession.Profile recipe")
        case .reasoningLevelComparison:
            String(localized: "Inspect light, moderate, and deep ContextOptions")
        case .transcriptExplorer:
            String(localized: "Inspect reasoning, attachment, and custom transcript cases")
        case .agentFlowInspector:
            String(localized: "Know which layer owns each decision")
        case .historyTransformLab:
            String(localized: "Compare transcript transforms before a model call")
        case .modelRouterDashboard:
            String(localized: "Make routing an explicit app policy")
        case .contextBudgetVisualizer:
            String(localized: "Decide what your app keeps before a session runs out of context")
        case .geminiVideoInput:
            String(localized: "Bridge a custom video-capable model into LanguageModelSession.")
        case .spotlightRAGExplorer:
            String(localized: "Ground a session in your app's indexed content")
        case .providerBridgeWalkthrough:
            String(localized: "How a custom LanguageModel executes session requests")
        case .evaluationsLab:
            String(localized: "Design a test suite before trusting a score")
        case .fmCLIPythonPlayground:
            String(localized: "Use Apple's fm CLI and Foundation Models SDK for Python")
        default:
            nil
        }
    }
}

private extension ExperimentLibraryCatalog {
    var subtitle: String {
        switch self {
        case .schemas:
            String(localized: "Build reliable structured output")
        case .languages:
            String(localized: "Explore multilingual model behavior")
        case .xcode27:
            String(localized: "Compose and measure production-grade experiments.")
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

#Preview("Xcode 27") {
    NavigationStack {
        ExperimentLibraryCatalogView(catalog: .xcode27)
    }
}
