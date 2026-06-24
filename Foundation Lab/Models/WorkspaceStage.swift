//
//  WorkspaceStage.swift
//  Foundation Lab
//

import Foundation

enum WorkspaceStage: String, CaseIterable, Identifiable {
    case settings
    case runs
    case evaluation
    case preview
    case output

    var id: Self { self }
}
