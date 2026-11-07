//
//  DataContentLabViewModel.swift
//  FoundationLab
//

import Foundation
import FoundationModels
import Observation
import UniformTypeIdentifiers

@available(iOS 27.2, macOS 27.2, visionOS 27.2, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
@Observable
final class DataContentLabViewModel {
    struct RoundTrip {
        let encodedByteCount: Int
        let payloadsPreserved: Bool
        let decodedPalette: ColorPalette?
    }

    let swatch = ColorSwatch(name: "Sunset", colors: [0xFF5E3A, 0xFFC857, 0x2E86AB])
    private(set) var observedPalettes: [ColorPalette] = []
    private(set) var observationSource: String?
    private(set) var responseText: String?
    private(set) var entryKinds: [String] = []
    private(set) var roundTrip: RoundTrip?
    private(set) var errorMessage: String?
    private(set) var isRunning = false

    func run() async {
        isRunning = true
        defer { isRunning = false }
        observedPalettes = []
        observationSource = nil
        responseText = nil
        entryKinds = []
        roundTrip = nil
        errorMessage = nil

        let session = LanguageModelSession(profile: PaletteDemoProfile { [weak self] entry in
            try self?.observe(entry)
        })

        do {
            let response = try await session.respond {
                "Suggest a complementary palette."
                Attachment(swatch).label("brand-swatch")
            }
            responseText = response.content
            if observationSource == nil {
                for case let .data(entry) in session.transcript {
                    observedPalettes.append(try ColorPalette(entry))
                }
                observationSource = "session.transcript"
            }
            entryKinds = session.transcript.map(Self.describe)

            let encoded = try JSONEncoder().encode(session.transcript)
            let decoded = try JSONDecoder().decode(Transcript.self, from: encoded)
            var decodedPalette: ColorPalette?
            for case let .data(entry) in decoded {
                decodedPalette = try ColorPalette(entry)
            }
            roundTrip = RoundTrip(
                encodedByteCount: encoded.count,
                payloadsPreserved: Self.dataPayloads(in: decoded) == Self.dataPayloads(in: session.transcript),
                decodedPalette: decodedPalette
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func observe(_ entry: Transcript.DataEntry) throws {
        observedPalettes.append(try ColorPalette(entry))
        observationSource = "onDataEntry"
    }

    private static func dataPayloads(in transcript: Transcript) -> [String] {
        transcript.flatMap { entry -> [String] in
            switch entry {
            case let .data(data):
                return [payload(data.contentType, data.content, data.metadata)]
            case let .prompt(prompt):
                return prompt.segments.compactMap { segment in
                    guard case let .attachment(attachment) = segment,
                          case let .data(data) = attachment.content else { return nil }
                    return payload(data.contentType, data.content, data.metadata)
                }
            default:
                return []
            }
        }
    }

    private static func payload(_ type: UTType, _ content: Data, _ metadata: GeneratedContent) -> String {
        "\(type.identifier) \(content.base64EncodedString()) \(metadata.jsonString)"
    }

    private static func describe(_ entry: Transcript.Entry) -> String {
        switch entry {
        case .instructions:
            return "instructions"
        case let .prompt(prompt):
            let attachments = prompt.segments.compactMap { segment -> String? in
                guard case let .attachment(attachment) = segment,
                      case let .data(data) = attachment.content else { return nil }
                return "\(data.contentType.identifier), \(data.content.count) bytes"
            }
            return attachments.isEmpty ? "prompt" : "prompt + data attachment (\(attachments.joined(separator: "; ")))"
        case let .data(data):
            return "data (\(data.contentType.identifier), \(data.content.count) bytes)"
        case .response:
            return "response"
        default:
            return "other"
        }
    }
}
