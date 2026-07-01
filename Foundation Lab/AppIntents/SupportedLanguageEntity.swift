import AppIntents
import CoreSpotlight
import Foundation
import FoundationLabCore
import FoundationModelsKit
import UniformTypeIdentifiers

struct SupportedLanguageEntityQuery: EntityStringQuery, EnumerableEntityQuery {
    func entities(for identifiers: [SupportedLanguageEntity.ID]) async throws -> [SupportedLanguageEntity] {
        let entities = try await allEntities()
        let lookup = Dictionary(uniqueKeysWithValues: entities.map { ($0.id, $0) })
        return identifiers.compactMap { lookup[$0] }
    }

    func entities(matching string: String) async throws -> [SupportedLanguageEntity] {
        let trimmedQuery = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return try await allEntities()
        }

        let query = trimmedQuery.localizedLowercase
        return try await allEntities().filter { entity in
            entity.displayName.localizedLowercase.contains(query) ||
            entity.languageIdentifier.localizedLowercase.contains(query) ||
            entity.languageCode.localizedLowercase.contains(query)
        }
    }

    func allEntities() async throws -> [SupportedLanguageEntity] {
        FoundationModelSupportedLanguagesUseCase()
            .execute(locale: .current)
            .languages
            .map { SupportedLanguageEntity(descriptor: $0) }
    }
}

struct SupportedLanguageEntity: IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Supported Language")
    static let defaultQuery = SupportedLanguageEntityQuery()

    let id: String
    let languageCode: String
    let regionCode: String?
    let displayName: String

    init(descriptor: FoundationModelSupportedLanguage) {
        let locale = Locale.current
        self.id = descriptor.identifier
        self.languageCode = descriptor.languageCode
        self.regionCode = descriptor.regionCode
        self.displayName = Self.localizedDisplayName(for: descriptor, locale: locale)
    }

    var languageIdentifier: String {
        if let regionCode, !regionCode.isEmpty {
            return "\(languageCode)-\(regionCode)"
        }
        return languageCode
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayName)",
            subtitle: "\(languageIdentifier)"
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = displayName
        attributeSet.displayName = displayName
        attributeSet.contentDescription = "A Foundation Lab supported language identified as \(languageIdentifier)."
        attributeSet.keywords = [languageCode, languageIdentifier, "Foundation Lab", "language"]
        return attributeSet
    }
}

private extension SupportedLanguageEntity {
    static func localizedDisplayName(
        for descriptor: FoundationModelSupportedLanguage,
        locale: Locale
    ) -> String {
        let languageName = locale.localizedString(forLanguageCode: descriptor.languageCode) ?? descriptor.languageCode

        guard let regionCode = descriptor.regionCode, !regionCode.isEmpty else {
            return languageName
        }

        let regionName = locale.localizedString(forRegionCode: regionCode) ?? regionCode
        return "\(languageName) (\(regionName))"
    }
}
