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
        .onDisappear(perform: model.stop)
    }

    private var actionButton: some View {
        Button {
            if model.isResponding {
                model.stop()
            } else {
                model.run()
            }
        } label: {
            Label(
                model.isResponding ? LocalizedStringKey("Stop") : LocalizedStringKey("Run"),
                systemImage: model.isResponding ? "stop.circle" : "play.fill"
            )
        }
        .disabled(!model.isResponding && !model.hasPrompt)
    }
}
#endif
