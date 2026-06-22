//
//  SettingsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
#if os(macOS)
            AgentBridgeSettingsView()
#endif

            Section("About") {
                LabeledContent("Version", value: version)

                Text("Learn with ready-made experiments, then compose and inspect your own Foundation Models sessions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Support") {
                Link(destination: issueURL) {
                    Label("Report a Bug or Request a Feature", systemImage: "exclamationmark.bubble")
                }

                Link(destination: authorURL) {
                    Label("Made by Rudrank Riyam", systemImage: "person.crop.circle")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: dismiss.callAsFunction)
            }
        }
#endif
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? String(localized: "Unknown")
    }

    private var issueURL: URL {
        guard let url = URL(string: "https://github.com/rudrankriyam/Foundation-Models-Framework-Lab/issues") else {
            preconditionFailure("The Foundation Lab issue URL must be valid.")
        }
        return url
    }

    private var authorURL: URL {
        guard let url = URL(string: "https://x.com/rudrankriyam") else {
            preconditionFailure("The Foundation Lab author URL must be valid.")
        }
        return url
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
#if os(macOS)
    .environment(AgentBridgeController())
#endif
}
