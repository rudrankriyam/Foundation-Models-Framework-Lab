//
//  ExampleType+Destination.swift
//  FoundationLab
//
//  Created by Codex on 4/26/26.
//

import SwiftUI

extension ExampleType {
    @MainActor
    @ViewBuilder
    var destination: some View {
        switch self {
        case .basicChat:
            BasicChatView()
        case .structuredData:
            StructuredDataView()
        case .generationGuides:
            GenerationGuidesView()
        case .streamingResponse:
            StreamingResponseView()
        case .journaling:
            JournalingView()
        case .creativeWriting:
            CreativeWritingView()
        case .modelAvailability:
            ModelAvailabilityView()
        case .generationOptions:
            GenerationOptionsView()
        case .modelRuntime:
            ModelRuntimeView()
        case .contextWindowInspector:
            ContextWindowInspectorView()
        case .privateCloudCompute:
            PrivateCloudComputeView()
        case .imageInputPlayground:
            ImageInputPlaygroundView()
        case .geminiVideoInput:
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
                GeminiVideoInputView()
            } else {
                ContentUnavailableView(
                    "Xcode 27 Required",
                    systemImage: "video.slash",
                    description: Text("Custom LanguageModel executors require iOS, macOS, or visionOS 27.")
                )
            }
        case .toolCallingModeLab:
            ToolCallingModeLabView()
        case .dynamicProfileBuilder:
            DynamicProfileBuilderView()
        case .reasoningLevelComparison:
            ReasoningLevelComparisonView()
        case .transcriptExplorer:
            TranscriptExplorerView()
        case .agentFlowInspector:
            AgentFlowInspectorView()
        case .historyTransformLab:
            HistoryTransformLabView()
        case .riskyToolConfirmation:
            RiskyToolConfirmationDemoView()
        case .modelRouterDashboard:
            ModelRouterDashboardView()
        case .contextBudgetVisualizer:
            ContextBudgetVisualizerView()
        case .toolCallTrajectoryViewer:
            ToolCallTrajectoryViewerView()
        case .foundationModelsSecurityPlayground:
            FoundationModelsSecurityPlaygroundView()
        case .usagePerformanceTrace:
            UsagePerformanceTraceView()
        case .spotlightRAGExplorer:
            SpotlightRAGExplorerView()
        case .providerBridgeWalkthrough:
            ProviderBridgeWalkthroughView()
        case .evaluationsLab:
#if os(macOS)
            EvaluationsLabView()
#else
            ContentUnavailableView(
                "Evaluations are available on Mac",
                systemImage: "macbook",
                description: Text(
                    "Run AppBench on the device, then use the macOS evaluation tools."
                )
            )
#endif
        case .fmCLIPythonPlayground:
            FMCLIPythonPlaygroundView()
        case .health:
            HealthExampleView()
        case .rag:
            RAGChatView()
        case .chat:
            ChatView(title: "Session", showsDoneButton: false, tearsDownOnDisappear: false)
        }
    }

    var preferredTab: TabSelection {
        switch self {
        case .structuredData, .generationGuides, .generationOptions, .modelRuntime,
             .contextWindowInspector, .privateCloudCompute, .imageInputPlayground,
             .geminiVideoInput, .toolCallingModeLab, .dynamicProfileBuilder, .reasoningLevelComparison,
             .transcriptExplorer, .agentFlowInspector, .historyTransformLab,
             .riskyToolConfirmation, .modelRouterDashboard, .contextBudgetVisualizer,
             .toolCallTrajectoryViewer, .foundationModelsSecurityPlayground,
             .usagePerformanceTrace, .spotlightRAGExplorer, .providerBridgeWalkthrough,
             .evaluationsLab, .fmCLIPythonPlayground:
            return .lab
        case .health, .rag:
            return .insights
        case .chat:
            return .session
        case .basicChat, .journaling, .creativeWriting, .streamingResponse, .modelAvailability:
            return .home
        }
    }

    static var homeExamples: [ExampleType] {
        [.modelAvailability, .streamingResponse, .journaling, .creativeWriting]
    }

    static var studioExamples: [ExampleType] {
        var examples = generationExamples + modelAndInputExamples + sessionExamples + agentExamples
#if os(macOS)
        examples.append(.evaluationsLab)
#endif
        examples.append(.fmCLIPythonPlayground)
        return examples
    }

    static var generationExamples: [ExampleType] {
        [.structuredData, .generationGuides, .generationOptions]
    }

    static var modelAndInputExamples: [ExampleType] {
        [.modelRuntime, .contextWindowInspector, .privateCloudCompute, .imageInputPlayground, .geminiVideoInput]
    }

    static var sessionExamples: [ExampleType] {
        [.toolCallingModeLab, .dynamicProfileBuilder, .reasoningLevelComparison, .transcriptExplorer]
    }

    static var agentExamples: [ExampleType] {
        [
            .agentFlowInspector,
            .historyTransformLab,
            .riskyToolConfirmation,
            .modelRouterDashboard,
            .contextBudgetVisualizer,
            .toolCallTrajectoryViewer,
            .foundationModelsSecurityPlayground,
            .usagePerformanceTrace,
            .spotlightRAGExplorer,
            .providerBridgeWalkthrough
        ]
    }

    static var developerToolExamples: [ExampleType] {
        var examples: [ExampleType] = []
#if os(macOS)
        examples.append(.evaluationsLab)
#endif
        examples.append(.fmCLIPythonPlayground)
        return examples
    }

    static var insightExamples: [ExampleType] {
        [.health, .rag]
    }
}
