//
//  ModelRouterDashboardView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct ModelRouterDashboardView: View {
    @State private var requirement = ModelRequirement.offline

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Text(
                    String(
                        localized: """
                        Foundation Models provides model types, not an automatic router. Your app chooses a model after evaluating \
                        quality, capabilities, availability, privacy, and fallback behavior.
                        """
                    )
                )
                    .font(.body)
                    .foregroundStyle(.secondary)

                Picker("Primary requirement", selection: $requirement) {
                    ForEach(ModelRequirement.allCases) { requirement in
                        Text(requirement.title).tag(requirement)
                    }
                }
                .pickerStyle(.segmented)

                Xcode27Section(String(localized: "Example app policy")) {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Xcode27StatusRow(
                            title: String(localized: "Start with"),
                            value: requirement.recommendation,
                            systemImage: requirement.icon,
                            tint: requirement.tint
                        )

                        Text(requirement.reason)
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Text(
                            String(
                                localized: """
                                This is a design recommendation, not a runtime selection. Check availability and capabilities before \
                                creating the session.
                                """
                            )
                        )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Xcode27Section(String(localized: "Available Model Types")) {
                    VStack(spacing: 0) {
                        ForEach(ModelSurface.allCases) { surface in
                            ModelSurfaceRow(surface: surface)

                            if surface != ModelSurface.allCases.last {
                                Divider()
                            }
                        }
                    }
                }

                Xcode27Section(String(localized: "Selection order")) {
                    Xcode27KeyValueList(items: [
                        ("1", String(localized: "Evaluate feature quality")),
                        ("2", String(localized: "Match required capabilities")),
                        ("3", String(localized: "Check runtime availability")),
                        ("4", String(localized: "Apply a documented fallback"))
                    ])
                }

                CodeDisclosure(code: requirement.code)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("Choosing a Model")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Make routing an explicit app policy")
        #endif
    }
}

private struct ModelSurfaceRow: View {
    let surface: ModelSurface

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: surface.icon)
                .foregroundStyle(surface.tint)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(surface.title)
                    .font(.subheadline)
                    .bold()
                Text(surface.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Spacing.small)
        }
        .frame(maxWidth: .infinity, minHeight: FoundationLabLayout.minimumTouchTarget, alignment: .leading)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .combine)
    }
}

private enum ModelSurface: String, CaseIterable, Identifiable {
    case system
    case pcc
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "SystemLanguageModel"
        case .pcc: "PrivateCloudComputeLanguageModel"
        case .custom: String(localized: "LanguageModel conformance")
        }
    }

    var detail: String {
        switch self {
        case .system: String(localized: "Apple's on-device model. It works offline and has no daily usage quota.")
        case .pcc:
            String(localized: """
            Apple's server model for more reasoning and context. It requires availability, network access, entitlement eligibility, \
            and has usage limits.
            """)
        case .custom:
            String(
                localized: """
                A bridge your app or package implements for another model provider through LanguageModel and LanguageModelExecutor.
                """
            )
        }
    }

    var icon: String {
        switch self {
        case .system: "iphone"
        case .pcc: "icloud"
        case .custom: "server.rack"
        }
    }

    var tint: Color {
        switch self {
        case .system: .green
        case .pcc: .blue
        case .custom: .purple
        }
    }
}

private enum ModelRequirement: String, CaseIterable, Identifiable {
    case offline
    case reasoning
    case provider

    var id: String { rawValue }

    var title: String {
        switch self {
        case .offline: String(localized: "Offline")
        case .reasoning: String(localized: "Reasoning")
        case .provider: String(localized: "Custom")
        }
    }

    var recommendation: String {
        switch self {
        case .offline: String(localized: "System model")
        case .reasoning: String(localized: "Evaluate Private Cloud")
        case .provider: String(localized: "Custom model")
        }
    }

    var reason: String {
        switch self {
        case .offline:
            String(localized: "Choose the on-device system model when the feature must work without a network connection.")
        case .reasoning:
            String(
                localized: """
                Start on device, evaluate the feature, then choose Private Cloud Compute if measured quality requires more reasoning \
                or a larger context window.
                """
            )
        case .provider:
            String(localized: """
            Adopt LanguageModel when the product requires a model that Apple does not provide directly. Your executor owns provider \
            translation and streaming.
            """)
        }
    }

    var icon: String {
        switch self {
        case .offline: "iphone"
        case .reasoning: "brain.head.profile"
        case .provider: "shippingbox"
        }
    }

    var tint: Color {
        switch self {
        case .offline: .green
        case .reasoning: .blue
        case .provider: .purple
        }
    }

    var code: String {
        switch self {
        case .offline:
            """
            let model = SystemLanguageModel.default
            if model.isAvailable {
                let session = LanguageModelSession(model: model)
            } else {
                // Present the app's unavailable state.
            }
            """
        case .reasoning:
            """
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
                let model = PrivateCloudComputeLanguageModel()
                if model.isAvailable {
                    let session = LanguageModelSession(model: model)
                } else {
                    // Apply the fallback your feature documents.
                }
            }
            """
        case .provider:
            """
            @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
            func makeProviderSession<Model: LanguageModel>(
                model: Model
            ) -> LanguageModelSession {
                LanguageModelSession(model: model)
            }
            """
        }
    }
}

#Preview {
    NavigationStack {
        ModelRouterDashboardView()
    }
}
