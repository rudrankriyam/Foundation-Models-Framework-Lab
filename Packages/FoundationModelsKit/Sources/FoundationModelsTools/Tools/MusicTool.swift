//
//  MusicTool.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import Foundation
import FoundationModels
import FoundationModelsKit
import MusicKit

/// A tool for controlling Apple Music playback using MusicKit.
///
/// Use `MusicTool` for search, playback control, and now playing information
/// for Apple Music content.
///
/// The following actions are supported:
/// - `search`: Search the Apple Music catalog
/// - `play`: Play a song by ID or search query
/// - `pause`: Pause current playback
/// - `stop`: Stop current playback
/// - `skip`/`next`: Skip to the next track
/// - `previous`: Go to the previous track
/// - `nowPlaying`: Get information about the currently playing track
///
/// ```swift
/// let session = LanguageModelSession(tools: [MusicTool()])
/// let response = try await session.respond(to: "Play Bohemian Rhapsody")
/// ```
///
/// - Important: Requires MusicKit capability, `NSAppleMusicUsageDescription` in Info.plist,
///   user permission at runtime, and an active Apple Music subscription for full playback.
public struct MusicTool: Tool {

  /// The name of the tool, used for identification.
  public let name = "controlMusic"
  /// A brief description of the tool's functionality.
  public let description = "Control Apple Music playback and search for songs, albums, and artists"

  /// Arguments for music operations.
  @Generable
  public struct Arguments: RuntimeCompatibleGenerable {
    /// The action to perform: "play", "pause", "stop", "skip", "previous", "search", "nowPlaying"
    @Guide(
      description:
        "The action to perform: 'play', 'pause', 'stop', 'skip', 'previous', 'search', 'nowPlaying'"
    )
    public var action: String

    /// Search query for finding music (for search action)
    @Guide(description: "Search query for finding music (for search action)")
    public var query: String?

    /// Type of search: "songs", "albums", "artists", "playlists" (default: "songs")
    @Guide(
      description: "Type of search: 'songs', 'albums', 'artists', 'playlists' (default: 'songs')")
    public var searchType: String?

    /// Limit for search results (default: 10, max: 25)
    @Guide(description: "Limit for search results (default: 10, max: 25)")
    public var limit: Int?

    /// Specific song/album/artist ID to play
    @Guide(description: "Specific song/album/artist ID to play")
    public var mediaId: String?

    public init(
      action: String = "",
      query: String? = nil,
      searchType: String? = nil,
      limit: Int? = nil,
      mediaId: String? = nil
    ) {
      self.action = action
      self.query = query
      self.searchType = searchType
      self.limit = limit
      self.mediaId = mediaId
    }
  }

  public init() {}

  public func call(arguments: Arguments) async throws -> some PromptRepresentable {
    // Check if MusicKit is authorized
    let authStatus = MusicAuthorization.currentStatus

    if authStatus != .authorized {
      if authStatus == .notDetermined {
        let status = await MusicAuthorization.request()
        if status != .authorized {
          return createErrorOutput(error: MusicError.authorizationDenied)
        }
      } else {
        return createErrorOutput(error: MusicError.authorizationDenied)
      }
    }

    switch arguments.action.lowercased() {
    case "search":
      return await searchMusic(
        query: arguments.query, type: arguments.searchType, limit: arguments.limit)
    case "play":
      return await playMusic(itemId: arguments.mediaId, query: arguments.query)
    case "pause", "stop":
      return pauseMusic()
    case "skip", "next":
      return await skipToNext()
    case "previous":
      return await skipToPrevious()
    case "nowplaying":
      return getCurrentSong()
    default:
      return createErrorOutput(error: MusicError.invalidAction)
    }
  }

  private func searchMusic(query: String?, type: String?, limit: Int?) async -> GeneratedContent {
    guard let query = query, !query.isEmpty else {
      return createErrorOutput(error: MusicError.missingQuery)
    }

    let searchLimit = limit ?? 10
    var request = MusicCatalogSearchRequest(
      term: query, types: [Song.self, Artist.self, Album.self])
    request.limit = searchLimit

    do {
      let response = try await request.response()
      var resultDescription = ""

      // Process songs
      if !response.songs.isEmpty {
        resultDescription += "🎵 Songs:\n"
        for (index, song) in response.songs.prefix(5).enumerated() {
          resultDescription += "\(index + 1). \"\(song.title)\" by \(song.artistName)\n"
          if let album = song.albumTitle {
            resultDescription += "   Album: \(album)\n"
          }
          resultDescription += "   ID: \(song.id)\n\n"
        }
      }

      // Process artists
      if !response.artists.isEmpty {
        resultDescription += "👤 Artists:\n"
        for (index, artist) in response.artists.prefix(3).enumerated() {
          resultDescription += "\(index + 1). \(artist.name)\n"
          resultDescription += "   ID: \(artist.id)\n\n"
        }
      }

      // Process albums
      if !response.albums.isEmpty {
        resultDescription += "💿 Albums:\n"
        for (index, album) in response.albums.prefix(3).enumerated() {
          resultDescription += "\(index + 1). \"\(album.title)\" by \(album.artistName)\n"
          if let releaseDate = album.releaseDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            resultDescription += "   Released: \(formatter.string(from: releaseDate))\n"
          }
          resultDescription += "   ID: \(album.id)\n\n"
        }
      }

      if resultDescription.isEmpty {
        resultDescription = "No results found for '\(query)'"
      }

      return GeneratedContent(properties: [
        "status": "success",
        "query": query,
        "resultCount": response.songs.count + response.artists.count + response.albums.count,
        "results": resultDescription.trimmingCharacters(in: .whitespacesAndNewlines),
        "message": "Found music matching '\(query)'"
      ])
    } catch {
      return createErrorOutput(error: error)
    }
  }

  private func playMusic(itemId: String?, query: String?) async -> GeneratedContent {
    do {
      let player = ApplicationMusicPlayer.shared

      if let itemId = itemId {
        // Play specific item by ID
        let request = MusicCatalogResourceRequest<Song>(
          matching: \.id, equalTo: MusicItemID(itemId))
        let response = try await request.response()

        if let song = response.items.first {
          player.queue = [song]
          try await player.play()

          return GeneratedContent(properties: [
            "status": "success",
            "action": "play",
            "nowPlaying": "\(song.title) by \(song.artistName)",
            "message": "Now playing: \(song.title)"
          ])
        } else {
          return createErrorOutput(error: MusicError.itemNotFound)
        }
      } else if let query = query {
        // Search and play first result
        var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
        request.limit = 1
        let response = try await request.response()

        if let song = response.songs.first {
          player.queue = [song]
          try await player.play()

          return GeneratedContent(properties: [
            "status": "success",
            "action": "play",
            "nowPlaying": "\(song.title) by \(song.artistName)",
            "message": "Now playing: \(song.title)"
          ])
        } else {
          return createErrorOutput(error: MusicError.noResults)
        }
      } else {
        // Resume playback
        try await player.play()
        return GeneratedContent(properties: [
          "status": "success",
          "action": "resume",
          "message": "Playback resumed"
        ])
      }
    } catch {
      return createErrorOutput(error: error)
    }
  }

  private func pauseMusic() -> GeneratedContent {
    let player = ApplicationMusicPlayer.shared
    player.pause()

    return GeneratedContent(properties: [
      "status": "success",
      "action": "pause",
      "message": "Playback paused"
    ])
  }

  private func skipToNext() async -> GeneratedContent {
    let player = ApplicationMusicPlayer.shared

    do {
      try await player.skipToNextEntry()
      return GeneratedContent(properties: [
        "status": "success",
        "action": "next",
        "message": "Skipped to next song"
      ])
    } catch {
      return createErrorOutput(error: error)
    }
  }

  private func skipToPrevious() async -> GeneratedContent {
    let player = ApplicationMusicPlayer.shared

    do {
      try await player.skipToPreviousEntry()
      return GeneratedContent(properties: [
        "status": "success",
        "action": "previous",
        "message": "Skipped to previous song"
      ])
    } catch {
      return createErrorOutput(error: error)
    }
  }

  private func getCurrentSong() -> GeneratedContent {
    let player = ApplicationMusicPlayer.shared

    guard let nowPlaying = player.queue.currentEntry else {
      return GeneratedContent(properties: [
        "status": "success",
        "message": "No song currently playing"
      ])
    }

    // Check if the entry has an item (non-transient)
    if case .song(let song) = nowPlaying.item {
      if let album = song.albumTitle {
        return GeneratedContent(properties: [
          "status": "success",
          "id": song.id.rawValue,
          "playbackState": String(describing: player.state.playbackStatus),
          "title": song.title,
          "artist": song.artistName,
          "album": album,
          "message": "Currently playing: \(song.title) by \(song.artistName)"
        ])
      } else {
        return GeneratedContent(properties: [
          "status": "success",
          "id": song.id.rawValue,
          "playbackState": String(describing: player.state.playbackStatus),
          "title": song.title,
          "artist": song.artistName,
          "message": "Currently playing: \(song.title) by \(song.artistName)"
        ])
      }
    } else if let item = nowPlaying.item {
      return GeneratedContent(properties: [
        "status": "success",
        "id": item.id.rawValue,
        "playbackState": String(describing: player.state.playbackStatus),
        "message": "Currently playing: \(item.id)"
      ])
    } else if let transientItem = nowPlaying.transientItem {
      // Handle transient items
      return GeneratedContent(properties: [
        "status": "success",
        "message": "Loading: \(transientItem.id)",
        "isTransient": true
      ])
    } else {
      return GeneratedContent(properties: [
        "status": "success",
        "message": "Unknown playback state"
      ])
    }
  }

  private func createErrorOutput(error: Error) -> GeneratedContent {
    return GeneratedContent(properties: [
      "status": "error",
      "error": error.localizedDescription,
      "message": "Failed to perform music operation"
    ])
  }
}

enum MusicError: Error, LocalizedError {
  case invalidAction
  case authorizationDenied
  case missingQuery
  case itemNotFound
  case noResults

  var errorDescription: String? {
    switch self {
    case .invalidAction:
      return
        "Invalid action. Use 'search', 'play', 'pause', 'stop', 'skip', 'next', 'previous', or 'nowPlaying'."
    case .authorizationDenied:
      return "Apple Music access denied. Please grant permission in Settings."
    case .missingQuery:
      return "Search query is required."
    case .itemNotFound:
      return "The requested music item was not found."
    case .noResults:
      return "No results found for your search."
    }
  }
}
