#if os(macOS)
import SwiftUI
import UniformTypeIdentifiers

struct AgentBridgeSettingsView: View {
    @Environment(AgentBridgeController.self) private var controller
    @State private var isSelectingDirectory = false

    var body: some View {
        @Bindable var controller = controller

        Section("Agent Bridge") {
            Toggle("Enable local agent bridge", isOn: $controller.isEnabled)
                .disabled(!controller.canToggleEnabled)

            LabeledContent("Status") {
                Label(controller.statusTitle, systemImage: statusSymbol)
                    .foregroundStyle(statusStyle)
            }

            if let baseDirectoryPath = controller.baseDirectoryPath {
                LabeledContent("Base Folder") {
                    Text(baseDirectoryPath)
                        .font(.callout.monospaced())
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
            }

            if let descriptorPath = controller.descriptorPath {
                LabeledContent("Connection File") {
                    Text(descriptorPath)
                        .font(.callout.monospaced())
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
            }

            Button("Choose Bridge Folder…", systemImage: "folder", action: chooseDirectory)
                .disabled(controller.isEnabled || controller.isTransitioning)

            Text(
                "Foundation Lab stores a private connection file and exposes an authenticated loopback server. "
                    + "It stays off until you enable it; after that, "
                    + "Foundation Lab can restore the bridge when launched."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let errorMessage = controller.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
        }
        .fileImporter(
            isPresented: $isSelectingDirectory,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false,
            onCompletion: handleSelection
        )
    }

    private var statusSymbol: String {
        switch controller.status {
        case .notConfigured:
            "folder.badge.questionmark"
        case .off:
            "stop.circle"
        case .starting, .stopping:
            "hourglass"
        case .running:
            "checkmark.circle.fill"
        case .failed:
            "exclamationmark.triangle.fill"
        }
    }

    private var statusStyle: Color {
        switch controller.status {
        case .running:
            .green
        case .failed:
            .red
        default:
            .secondary
        }
    }

    private func chooseDirectory() {
        isSelectingDirectory = true
    }

    private func handleSelection(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            guard let directoryURL = urls.first else {
                controller.handleEmptyDirectorySelection()
                return
            }
            controller.selectBaseDirectory(directoryURL)
        case .failure(let error):
            controller.handleDirectorySelectionFailure(error)
        }
    }
}
#endif
