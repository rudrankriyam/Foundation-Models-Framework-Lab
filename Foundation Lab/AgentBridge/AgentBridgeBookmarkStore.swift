#if os(macOS)
import Foundation

@MainActor
struct AgentBridgeBookmarkStore {
    enum Error: LocalizedError {
        case missingDirectory
        case inaccessibleDirectory
        case notDirectory

        var errorDescription: String? {
            switch self {
            case .missingDirectory:
                String(localized: "Choose a bridge folder before enabling the agent bridge.")
            case .inaccessibleDirectory:
                String(localized: "Foundation Lab could not keep access to the selected bridge folder.")
            case .notDirectory:
                String(localized: "The selected bridge location is not a folder.")
            }
        }
    }

    private static let bookmarkKey = "agentBridge.baseDirectoryBookmark.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasBookmark: Bool {
        defaults.data(forKey: Self.bookmarkKey) != nil
    }

    func save(_ directoryURL: URL) throws {
        let didStartAccess = directoryURL.startAccessingSecurityScopedResource()
        guard didStartAccess else {
            throw Error.inaccessibleDirectory
        }
        defer { directoryURL.stopAccessingSecurityScopedResource() }

        try requireDirectory(directoryURL)
        defaults.set(try bookmarkData(for: directoryURL), forKey: Self.bookmarkKey)
    }

    func resolvedURL() throws -> URL? {
        guard let data = defaults.data(forKey: Self.bookmarkKey) else { return nil }
        return try resolve(data).url
    }

    func beginAccess() throws -> URL {
        guard let data = defaults.data(forKey: Self.bookmarkKey) else {
            throw Error.missingDirectory
        }

        let resolution = try resolve(data)
        let directoryURL = resolution.url
        guard directoryURL.startAccessingSecurityScopedResource() else {
            throw Error.inaccessibleDirectory
        }

        do {
            try requireDirectory(directoryURL)
            if resolution.isStale {
                defaults.set(try bookmarkData(for: directoryURL), forKey: Self.bookmarkKey)
            }
            return directoryURL
        } catch {
            directoryURL.stopAccessingSecurityScopedResource()
            throw error
        }
    }

    private func bookmarkData(for directoryURL: URL) throws -> Data {
        try directoryURL.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: [.isDirectoryKey],
            relativeTo: nil
        )
    }

    private func resolve(_ data: Data) throws -> (url: URL, isStale: Bool) {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope, .withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return (url, isStale)
    }

    private func requireDirectory(_ url: URL) throws {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey])
        guard values.isDirectory == true else {
            throw Error.notDirectory
        }
    }
}
#endif
