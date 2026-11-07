//
//  RunFeedbackSheet.swift
//  Foundation Lab
//

import FoundationLabCore
import FoundationModels
import SwiftUI
import UniformTypeIdentifiers

struct RunFeedbackSheet: View {
    let run: FoundationLabExperimentRun

    @Environment(\.dismiss) private var dismiss
    @State private var sentiment: LanguageModelFeedback.Sentiment = .neutral
    @State private var selectedCategories: Set<LanguageModelFeedback.Issue.Category> = []
    @State private var explanation = ""
    @State private var includesDesiredOutput = false
    @State private var desiredOutput: String
    @State private var attachment: RunFeedbackAttachment?
    @State private var isExporting = false
    @State private var errorMessage: String?

    init(run: FoundationLabExperimentRun) {
        self.run = run
        _desiredOutput = State(initialValue: run.response)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Sentiment", selection: $sentiment) {
                        Text("Positive").tag(LanguageModelFeedback.Sentiment.positive)
                        Text("Neutral").tag(LanguageModelFeedback.Sentiment.neutral)
                        Text("Negative").tag(LanguageModelFeedback.Sentiment.negative)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Sentiment")
                } footer: {
                    Text("Foundation Lab rebuilds a session from this run's recorded transcript. The original live session is not used.")
                }

                Section("Issues") {
                    ForEach(LanguageModelFeedback.Issue.Category.allCases, id: \.self) { category in
                        Toggle(label(for: category), isOn: binding(for: category))
                    }

                    if !selectedCategories.isEmpty {
                        TextField("Explanation", text: $explanation, axis: .vertical)
                    }
                }

                Section {
                    Toggle("Include Desired Output", isOn: $includesDesiredOutput)

                    if includesDesiredOutput {
                        TextField("Desired Output", text: $desiredOutput, axis: .vertical)
                            .lineLimit(3...12)
                    }
                }

                attachmentSection
            }
            .formStyle(.grouped)
            .navigationTitle("Send Feedback")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: sentiment) { attachment = nil }
            .onChange(of: selectedCategories) { attachment = nil }
            .onChange(of: explanation) { attachment = nil }
            .onChange(of: includesDesiredOutput) { attachment = nil }
            .onChange(of: desiredOutput) { attachment = nil }
            .fileExporter(
                isPresented: $isExporting,
                item: attachment,
                contentTypes: [.json],
                defaultFilename: attachment?.fileName
            ) { result in
                if case .failure(let error) = result {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private var attachmentSection: some View {
        Section {
            if let attachment {
                Button("Save Attachment", systemImage: "square.and.arrow.down") {
                    isExporting = true
                }
                ShareLink(
                    item: attachment,
                    preview: SharePreview(attachment.fileName)
                ) {
                    Label("Share Attachment", systemImage: "square.and.arrow.up")
                }
            } else {
                Button("Create Attachment", systemImage: "doc.badge.plus", action: createAttachment)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
        } footer: {
            Text("Attach the file to a report in Feedback Assistant to send it to Apple.")
        }
    }

    private func binding(for category: LanguageModelFeedback.Issue.Category) -> Binding<Bool> {
        Binding {
            selectedCategories.contains(category)
        } set: { isSelected in
            if isSelected {
                selectedCategories.insert(category)
            } else {
                selectedCategories.remove(category)
            }
        }
    }

    private func createAttachment() {
        let trimmedExplanation = explanation.trimmingCharacters(in: .whitespacesAndNewlines)
        let issues = LanguageModelFeedback.Issue.Category.allCases
            .filter(selectedCategories.contains)
            .map {
                LanguageModelFeedback.Issue(
                    category: $0,
                    explanation: trimmedExplanation.isEmpty ? nil : trimmedExplanation
                )
            }
        let session = run.makeFeedbackSession()
        let data = includesDesiredOutput
            ? session.logFeedbackAttachment(sentiment: sentiment, issues: issues, desiredResponseText: desiredOutput)
            : session.logFeedbackAttachment(sentiment: sentiment, issues: issues)

        guard !data.isEmpty else {
            errorMessage = String(localized: "Foundation Models returned an empty feedback attachment.")
            return
        }
        errorMessage = nil
        attachment = RunFeedbackAttachment(
            data: data,
            fileName: "FoundationLab-Feedback-\(run.id.uuidString.prefix(8)).json"
        )
    }

    private func label(for category: LanguageModelFeedback.Issue.Category) -> String {
        switch category {
        case .unhelpful:
            String(localized: "Unhelpful")
        case .tooVerbose:
            String(localized: "Too verbose")
        case .didNotFollowInstructions:
            String(localized: "Did not follow instructions")
        case .incorrect:
            String(localized: "Incorrect")
        case .stereotypeOrBias:
            String(localized: "Stereotype or bias")
        case .suggestiveOrSexual:
            String(localized: "Suggestive or sexual")
        case .vulgarOrOffensive:
            String(localized: "Vulgar or offensive")
        case .triggeredGuardrailUnexpectedly:
            String(localized: "Triggered guardrail unexpectedly")
        @unknown default:
            String(localized: "Other issue")
        }
    }
}
