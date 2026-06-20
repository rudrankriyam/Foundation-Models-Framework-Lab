//
//  TabSelection.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import Foundation

enum TabSelection: String, CaseIterable, Hashable {
  case library
  case playground
  case runs

  var displayName: String {
    switch self {
    case .library:
      return String(localized: "Library")
    case .playground:
      return String(localized: "Playground")
    case .runs:
      return String(localized: "Runs")
    }
  }
}
