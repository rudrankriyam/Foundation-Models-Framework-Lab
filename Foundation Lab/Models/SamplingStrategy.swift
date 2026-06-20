//
//  SamplingStrategy.swift
//  FoundationLab
//
//  Sampling strategy options for language model generation.
//

import Foundation

enum SamplingStrategy: Int, CaseIterable {
    case `default`
    case greedy
    case sampling
    case probabilityThreshold
}
