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
        case .basicChat, .journaling, .creativeWriting, .streamingResponse, .generationOptions:
            RecipeDestinationView(example: self)
        case .structuredData:
            StructuredDataView()
        case .generationGuides:
            GenerationGuidesView()
        case .modelAvailability:
            ModelAvailabilityView()
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
                    "OS 27 Required",
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
                    "Run FMBench on the device, then use the macOS evaluation tools."
                )
            )
#endif
        case .fmCLIPythonPlayground:
            FMCLIPythonPlaygroundView()
        case .health:
            HealthExampleView()
        case .rag:
            RAGChatView()
        }
    }

}
