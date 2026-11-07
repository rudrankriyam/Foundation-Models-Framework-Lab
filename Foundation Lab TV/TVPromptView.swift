//
//  TVPromptView.swift
//  Foundation Lab TV
//

#if canImport(FoundationModels, _version: 2.2)
import SwiftUI

@available(tvOS 27.3, *)
struct TVPromptView: View {
    @State private var model = TVPromptModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                TextField("Ask the on-device model", text: $model.prompt)
                    .onSubmit(model.run)

                VStack(alignment: .leading, spacing: 20) {
                    ForEach(TVPromptModel.presets, id: \.self) { preset in
                        Button(preset) {
                            model.prompt = preset
                            model.run()
                        }
                        .disabled(model.isResponding)
                    }
                }

                actionButton

                if let errorMessage = model.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }

                TVResponseText(text: model.response)
            }
            .padding(60)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if model.isResponding {
            Button("Stop", systemImage: "stop.circle", action: model.stop)
        } else {
            Button("Run", systemImage: "play.fill", action: model.run)
                .disabled(!model.canRun)
        }
    }
}
#endif
