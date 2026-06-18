//
//  LabView.swift
//  FoundationLab
//
//  Created by Codex on 5/23/26.
//

import SwiftUI

struct LabView: View {
    @State private var searchText = ""

    var body: some View {
        LabCatalogList(searchText: searchText)
            .navigationTitle("Lab")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
            .searchable(text: $searchText, prompt: "Search Lab")
            .navigationDestination(for: ExampleType.self) { exampleType in
                exampleType.destination
            }
            .navigationDestination(for: ToolExample.self) { tool in
                tool.destination
            }
            .navigationDestination(for: DynamicSchemaExampleType.self) { example in
                example.destination
            }
            .navigationDestination(for: LanguageExample.self) { languageExample in
                languageExample.destination
            }
    }
}

#Preview {
    NavigationStack {
        LabView()
    }
}
