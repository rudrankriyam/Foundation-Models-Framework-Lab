//
//  SettingsToolbarButton.swift
//  Foundation Lab
//

import SwiftUI

struct SettingsToolbarButton: View {
    @Binding var isPresented: Bool

    var body: some View {
        Button("Settings", systemImage: "gear", action: showSettings)
    }

    private func showSettings() {
        isPresented = true
    }
}
