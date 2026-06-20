//
//  ExperimentPersistenceDocument.swift
//  Foundation Lab
//

import Foundation
import FoundationLabCore

nonisolated struct ExperimentPersistenceDocument: Codable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case savedExperiments
        case runs
    }

    var schemaVersion: Int
    var savedExperiments: [FoundationLabExperimentConfiguration]
    var runs: [FoundationLabExperimentRun]
    var discardedElementCount: Int

    init(
        schemaVersion: Int,
        savedExperiments: [FoundationLabExperimentConfiguration] = [],
        runs: [FoundationLabExperimentRun] = []
    ) {
        self.schemaVersion = schemaVersion
        self.savedExperiments = savedExperiments
        self.runs = runs
        discardedElementCount = 0
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 0

        let experiments = try container.decodeIfPresent(
            LossyArray<FoundationLabExperimentConfiguration>.self,
            forKey: .savedExperiments
        ) ?? LossyArray()
        let restoredRuns = try container.decodeIfPresent(
            LossyArray<FoundationLabExperimentRun>.self,
            forKey: .runs
        ) ?? LossyArray()

        savedExperiments = experiments.values
        runs = restoredRuns.values
        discardedElementCount = experiments.discardedElementCount
            + restoredRuns.discardedElementCount
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(savedExperiments, forKey: .savedExperiments)
        try container.encode(runs, forKey: .runs)
    }

    static func decodeCollection<Element: Decodable & Sendable>(
        _ type: Element.Type,
        from data: Data,
        decoder: JSONDecoder
    ) throws -> ExperimentDecodedCollection<Element> {
        let collection = try decoder.decode(LossyArray<Element>.self, from: data)
        return ExperimentDecodedCollection(
            values: collection.values,
            discardedElementCount: collection.discardedElementCount
        )
    }
}

nonisolated struct ExperimentDecodedCollection<Element: Sendable>: Sendable {
    let values: [Element]
    let discardedElementCount: Int
}

nonisolated private struct LossyArray<Element: Decodable>: Decodable {
    var values: [Element] = []
    var discardedElementCount = 0

    init() {}

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            let element = try container.decode(LossyElement<Element>.self)
            if let value = element.value {
                values.append(value)
            } else {
                discardedElementCount += 1
            }
        }
    }
}

nonisolated private struct LossyElement<Element: Decodable>: Decodable {
    let value: Element?

    init(from decoder: Decoder) throws {
        value = try? Element(from: decoder)
    }
}
