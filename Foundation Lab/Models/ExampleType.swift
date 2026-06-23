//
//  ExampleType.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import Foundation
import FoundationModels

enum ExampleType: String, CaseIterable, Identifiable {
    case basicChat = "basic_chat"
    case journaling = "journaling"
    case creativeWriting = "creative_writing"
    case structuredData = "structured_data"
    case streamingResponse = "streaming_response"
    case modelAvailability = "model_availability"
    case generationGuides = "generation_guides"
    case generationOptions = "generation_options"
    case modelRuntime = "model_runtime"
    case contextWindowInspector = "context_window_inspector"
    case privateCloudCompute = "private_cloud_compute"
    case imageInputPlayground = "image_input_playground"
    case geminiVideoInput = "gemini_video_input"
    case toolCallingModeLab = "tool_calling_mode_lab"
    case dynamicProfileBuilder = "dynamic_profile_builder"
    case reasoningLevelComparison = "reasoning_level_comparison"
    case transcriptExplorer = "transcript_explorer"
    case agentFlowInspector = "agent_flow_inspector"
    case historyTransformLab = "history_transform_lab"
    case riskyToolConfirmation = "risky_tool_confirmation"
    case modelRouterDashboard = "model_router_dashboard"
    case contextBudgetVisualizer = "context_budget_visualizer"
    case toolCallTrajectoryViewer = "tool_call_trajectory_viewer"
    case foundationModelsSecurityPlayground = "foundation_models_security_playground"
    case usagePerformanceTrace = "usage_performance_trace"
    case spotlightRAGExplorer = "spotlight_rag_explorer"
    case providerBridgeWalkthrough = "provider_bridge_walkthrough"
    case evaluationsLab = "evaluations_lab"
    case fmCLIPythonPlayground = "fm_cli_python_playground"
    case health = "health"
    case rag = "rag"
}

extension ExampleType {
    var id: String { rawValue }

    static let xcode27Examples: [ExampleType] = [
        .modelRuntime,
        .contextWindowInspector,
        .privateCloudCompute,
        .imageInputPlayground,
        .usagePerformanceTrace,
        .toolCallingModeLab,
        .riskyToolConfirmation,
        .foundationModelsSecurityPlayground,
        .toolCallTrajectoryViewer,
        .dynamicProfileBuilder,
        .reasoningLevelComparison,
        .transcriptExplorer,
        .agentFlowInspector,
        .historyTransformLab,
        .modelRouterDashboard,
        .contextBudgetVisualizer,
        .geminiVideoInput,
        .spotlightRAGExplorer,
        .providerBridgeWalkthrough,
        .evaluationsLab,
        .fmCLIPythonPlayground
    ]

    var title: String {
        switch self {
        case .basicChat:
            return "One-shot"
        case .journaling:
            return "Journaling"
        case .creativeWriting:
            return "Creative Writing"
        case .structuredData:
            return "Structured Data"
        case .streamingResponse:
            return "Streaming Response"
        case .modelAvailability:
            return "Model Availability"
        case .generationGuides:
            return "Generation Guides"
        case .generationOptions:
            return "Generation Options"
        case .modelRuntime:
            return "Model Runtime"
        case .contextWindowInspector:
            return "Context Window"
        case .privateCloudCompute:
            return "Private Cloud"
        case .imageInputPlayground:
            return "Image Input"
        case .geminiVideoInput:
            return "Gemini Video"
        case .toolCallingModeLab:
            return "Tool Modes"
        case .dynamicProfileBuilder:
            return "Dynamic Profile"
        case .reasoningLevelComparison:
            return "Reasoning Levels"
        case .transcriptExplorer:
            return "Transcript Explorer"
        case .agentFlowInspector:
            return "Agent Flow"
        case .historyTransformLab:
            return "History Lab"
        case .riskyToolConfirmation:
            return "Tool Authorization"
        case .modelRouterDashboard:
            return "Model Router"
        case .contextBudgetVisualizer:
            return "Budget Visualizer"
        case .toolCallTrajectoryViewer:
            return "Trajectory"
        case .foundationModelsSecurityPlayground:
            return "Agent Security"
        case .usagePerformanceTrace:
            return "Response Usage"
        case .spotlightRAGExplorer:
            return "Spotlight RAG"
        case .providerBridgeWalkthrough:
            return "Provider Bridge"
        case .evaluationsLab:
            return "Evaluations"
        case .fmCLIPythonPlayground:
            return "fm Scripts"
        case .health:
            return "Health Dashboard"
        case .rag:
            return "Doc Q&A"
        }
    }

    var subtitle: String {
        switch self {
        case .basicChat:
            return "Single prompt-response interaction"
        case .journaling:
            return "Prompts, starters, and reflective summaries"
        case .creativeWriting:
            return "Stories, poems, and creative content"
        case .structuredData:
            return "Parse and generate structured information"
        case .streamingResponse:
            return "Real-time response streaming"
        case .modelAvailability:
            return "Check Apple Intelligence status"
        case .generationGuides:
            return "Guided generation with constraints"
        case .generationOptions:
            return "Experiment with model parameters"
        case .modelRuntime:
            return "Inspect this device's system model and tokenizer"
        case .contextWindowInspector:
            return "Inspect context size and token budget"
        case .privateCloudCompute:
            return "Probe PCC availability, quota, and context size"
        case .imageInputPlayground:
            return "Run a live on-device image attachment request"
        case .geminiVideoInput:
            return "Analyze video with a custom LanguageModelSession"
        case .toolCallingModeLab:
            return "Compare allowed, required, and disallowed tools"
        case .dynamicProfileBuilder:
            return "Compose Xcode 27 session profiles"
        case .reasoningLevelComparison:
            return "Compare light, moderate, and deep reasoning"
        case .transcriptExplorer:
            return "Run a session and inspect its observed transcript"
        case .agentFlowInspector:
            return "Inspect an agent turn from profile to usage"
        case .historyTransformLab:
            return "Compare trimming, redaction, and spotlighting"
        case .riskyToolConfirmation:
            return "Review app-owned authorization before side effects"
        case .modelRouterDashboard:
            return "Make routing an explicit app policy"
        case .contextBudgetVisualizer:
            return "Show kept, summarized, and dropped context"
        case .toolCallTrajectoryViewer:
            return "Capture and verify an actual tool path"
        case .foundationModelsSecurityPlayground:
            return "Inspect framework guarantees and app-owned boundaries"
        case .usagePerformanceTrace:
            return "Measure streaming time and inspect reported token usage"
        case .spotlightRAGExplorer:
            return "Explore Core Spotlight grounded answers"
        case .providerBridgeWalkthrough:
            return "Map custom models into LanguageModelSession"
        case .evaluationsLab:
            return "Evaluate judges, samples, and tool trajectories"
        case .fmCLIPythonPlayground:
            return "Prototype workflows with fm CLI and Python"
        case .health:
            return "AI-powered health insights and tracking"
        case .rag:
            return "Ask questions with source citations"
        }
    }

    var icon: String {
        switch self {
        case .basicChat:
            return "ellipsis.message"
        case .journaling:
            return "square.and.pencil"
        case .creativeWriting:
            return "pencil.and.outline"
        case .structuredData:
            return "list.bullet.rectangle"
        case .streamingResponse:
            return "wave.3.right"
        case .modelAvailability:
            return "checkmark.shield"
        case .generationGuides:
            return "slider.horizontal.3"
        case .generationOptions:
            return "tuningfork"
        case .modelRuntime:
            return "cpu"
        case .contextWindowInspector:
            return "text.page.badge.magnifyingglass"
        case .privateCloudCompute:
            return "icloud.and.arrow.up"
        case .imageInputPlayground:
            return "photo.on.rectangle.angled"
        case .geminiVideoInput:
            return "video.badge.waveform"
        case .toolCallingModeLab:
            return "hammer"
        case .dynamicProfileBuilder:
            return "slider.horizontal.below.rectangle"
        case .reasoningLevelComparison:
            return "brain.head.profile"
        case .transcriptExplorer:
            return "list.bullet.rectangle.portrait"
        case .agentFlowInspector:
            return "point.topleft.down.curvedto.point.bottomright.up"
        case .historyTransformLab:
            return "clock.arrow.circlepath"
        case .riskyToolConfirmation:
            return "hand.raised"
        case .modelRouterDashboard:
            return "arrow.triangle.branch"
        case .contextBudgetVisualizer:
            return "chart.pie"
        case .toolCallTrajectoryViewer:
            return "checklist.checked"
        case .foundationModelsSecurityPlayground:
            return "exclamationmark.shield"
        case .usagePerformanceTrace:
            return "speedometer"
        case .spotlightRAGExplorer:
            return "magnifyingglass.circle"
        case .providerBridgeWalkthrough:
            return "link"
        case .evaluationsLab:
            return "checkmark.seal"
        case .fmCLIPythonPlayground:
            return "terminal"
        case .health:
            return "heart.fill"
        case .rag:
            return "doc.text.magnifyingglass"
        }
    }

}

// MARK: - Language Example Enum

enum LanguageExample: String, CaseIterable, Identifiable {
    case languageDetection = "language_detection"
    case multilingualResponses = "multilingual_responses"
    case sessionManagement = "session_management"
    case productionExample = "production_example"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .languageDetection:
            return "Language Detection"
        case .multilingualResponses:
            return "Multilingual Play"
        case .sessionManagement:
            return "Multiple Sessions"
        case .productionExample:
            return "Insights Example"
        }
    }

    var subtitle: String {
        switch self {
        case .languageDetection:
            return "Query and display supported languages"
        case .multilingualResponses:
            return "Generate responses in different languages"
        case .sessionManagement:
            return "Persistent session patterns across languages"
        case .productionExample:
            return "Real-world multilingual implementation"
        }
    }

    var icon: String {
        switch self {
        case .languageDetection:
            return "globe.badge.chevron.backward"
        case .multilingualResponses:
            return "text.bubble"
        case .sessionManagement:
            return "arrow.triangle.2.circlepath"
        case .productionExample:
            return "app.badge"
        }
    }
}
