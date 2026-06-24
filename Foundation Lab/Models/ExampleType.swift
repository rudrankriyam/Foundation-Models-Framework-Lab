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
            return "One-Shot Prompt"
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
            return "Tool Calling Modes"
        case .dynamicProfileBuilder:
            return "Session Profile Builder"
        case .reasoningLevelComparison:
            return "Reasoning Levels"
        case .transcriptExplorer:
            return "Transcript Explorer"
        case .agentFlowInspector:
            return "Agent Turn Map"
        case .historyTransformLab:
            return "Transcript Transforms"
        case .riskyToolConfirmation:
            return "Tool Authorization"
        case .modelRouterDashboard:
            return "Model Router"
        case .contextBudgetVisualizer:
            return "Context Budget"
        case .toolCallTrajectoryViewer:
            return "Tool Call Trajectory"
        case .foundationModelsSecurityPlayground:
            return "Security Boundaries"
        case .usagePerformanceTrace:
            return "Usage & Performance"
        case .spotlightRAGExplorer:
            return "Spotlight RAG"
        case .providerBridgeWalkthrough:
            return "Custom Model Provider"
        case .evaluationsLab:
            return "Evaluations"
        case .fmCLIPythonPlayground:
            return "fm CLI & Python"
        case .health:
            return "Health"
        case .rag:
            return "Document Q&A"
        }
    }

    var subtitle: String {
        switch self {
        case .basicChat:
            return "Send one prompt and inspect one complete response"
        case .journaling:
            return "Turn reflections into summaries and follow-up questions"
        case .creativeWriting:
            return "Compare how voice and constraints shape creative output"
        case .structuredData:
            return "Generate typed Swift values instead of parsing prose"
        case .streamingResponse:
            return "Watch a response arrive as the model generates it"
        case .modelAvailability:
            return "Check whether the on-device model is ready"
        case .generationGuides:
            return "Constrain generated values with @Guide"
        case .generationOptions:
            return "Compare sampling, temperature, and token limits"
        case .modelRuntime:
            return "Inspect the system model, capabilities, and tokenizer"
        case .contextWindowInspector:
            return "See what consumes a session's context budget"
        case .privateCloudCompute:
            return "Inspect Private Cloud Compute availability, quota, and context size"
        case .imageInputPlayground:
            return "Send an image and prompt to the on-device model"
        case .geminiVideoInput:
            return "Connect a video-capable model to LanguageModelSession"
        case .toolCallingModeLab:
            return "Compare allowed, required, and disallowed tool calling"
        case .dynamicProfileBuilder:
            return "Build a LanguageModelSession profile from runtime controls"
        case .reasoningLevelComparison:
            return "Compare one prompt across three reasoning levels"
        case .transcriptExplorer:
            return "Run a session and inspect its actual transcript entries"
        case .agentFlowInspector:
            return "Trace one agent turn from profile selection to usage"
        case .historyTransformLab:
            return "Compare trimming, redaction, and relevance transforms"
        case .riskyToolConfirmation:
            return "Keep side-effect approval in app-owned code"
        case .modelRouterDashboard:
            return "Route requests with an explicit app-owned policy"
        case .contextBudgetVisualizer:
            return "Decide what to keep, summarize, or drop"
        case .toolCallTrajectoryViewer:
            return "Compare actual tool calls with an expected path"
        case .foundationModelsSecurityPlayground:
            return "Separate framework guarantees from app responsibilities"
        case .usagePerformanceTrace:
            return "Measure response timing and reported token usage"
        case .spotlightRAGExplorer:
            return "Ground responses in content indexed by your app"
        case .providerBridgeWalkthrough:
            return "Connect a custom model to LanguageModelSession"
        case .evaluationsLab:
            return "Design datasets, graders, and tool trajectory checks"
        case .fmCLIPythonPlayground:
            return "Run Foundation Models workflows from the fm CLI and Python"
        case .health:
            return "Review authorized HealthKit data and ask grounded questions"
        case .rag:
            return "Index documents, ask questions, and inspect citations"
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
            return "Multilingual Responses"
        case .sessionManagement:
            return "Language Sessions"
        case .productionExample:
            return "Localized App Pattern"
        }
    }

    var subtitle: String {
        switch self {
        case .languageDetection:
            return "Check language support before creating a session"
        case .multilingualResponses:
            return "Generate the same response in several languages"
        case .sessionManagement:
            return "Keep separate conversation state for each language"
        case .productionExample:
            return "Build localized, language-aware app responses"
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
