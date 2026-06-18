//
//  LabExampleSection.swift
//  Foundation Lab
//

import SwiftUI

struct LabExampleSection: View {
    private let title: LocalizedStringKey
    private let examples: [ExampleType]

    init(_ title: LocalizedStringKey, examples: [ExampleType]) {
        self.title = title
        self.examples = examples
    }

    var body: some View {
        if !examples.isEmpty {
            Section {
                ForEach(examples) { example in
                    NavigationLink(value: example) {
                        LabNavigationRow(
                            title: example.title,
                            subtitle: example.subtitle,
                            systemImage: example.icon
                        )
                    }
                }
            } header: {
                Text(title)
            }
        }
    }
}

#Preview {
    NavigationStack {
        List {
            LabExampleSection(
                "Generation Options",
                examples: ExampleType.generationExamples
            )
        }
    }
}
