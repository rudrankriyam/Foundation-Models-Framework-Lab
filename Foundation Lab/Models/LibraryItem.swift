//
//  LibraryItem.swift
//  Foundation Lab
//

import FoundationLabCore

enum LibraryItem: Hashable {
    case template(ExperimentTemplate.ID)
    case savedExperiment(FoundationLabExperimentConfiguration.ID)
}
