//
//  GeminiVideoPreview.swift
//  FoundationLab
//
//  Created by Codex on 6/15/26.
//

import AVFoundation
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct GeminiVideoPreview: View {
    let url: URL

    @State private var player = AVPlayer()
    @State private var isPlaying = false
    @State private var securityScopedURL: URL?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GeminiPlatformVideoPlayer(player: player)

            Button(
                isPlaying ? "Pause video" : "Play video",
                systemImage: isPlaying ? "pause.fill" : "play.fill"
            ) {
                togglePlayback()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.glassProminent)
            .padding(Spacing.small)
        }
        .clipShape(.rect(cornerRadius: CornerRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .strokeBorder(.quaternary)
        }
        .accessibilityLabel("Selected Gemini video input")
        .onAppear {
            load(url)
            play()
        }
        .onChange(of: url) { _, newURL in
            load(newURL)
            play()
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
            guard notification.object as? AVPlayerItem === player.currentItem else {
                return
            }
            player.seek(to: .zero)
            play()
        }
        .onDisappear {
            player.pause()
            isPlaying = false
            stopAccessingSecurityScopedURL()
        }
    }

    private func load(_ url: URL) {
        stopAccessingSecurityScopedURL()
        if url.startAccessingSecurityScopedResource() {
            securityScopedURL = url
        }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
    }

    private func stopAccessingSecurityScopedURL() {
        securityScopedURL?.stopAccessingSecurityScopedResource()
        securityScopedURL = nil
    }

    private func togglePlayback() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            play()
        }
    }

    private func play() {
        player.play()
        isPlaying = true
    }
}

#if os(macOS)
@available(macOS 27.0, *)
private struct GeminiPlatformVideoPlayer: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> GeminiPlayerView {
        GeminiPlayerView(player: player)
    }

    func updateNSView(_ view: GeminiPlayerView, context: Context) {
        view.player = player
    }
}

@available(macOS 27.0, *)
private final class GeminiPlayerView: NSView {
    private let playerLayer = AVPlayerLayer()

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    init(player: AVPlayer) {
        super.init(frame: .zero)
        wantsLayer = true
        layer = playerLayer
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}
#else
@available(iOS 27.0, visionOS 27.0, *)
private struct GeminiPlatformVideoPlayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> GeminiPlayerView {
        GeminiPlayerView(player: player)
    }

    func updateUIView(_ view: GeminiPlayerView, context: Context) {
        view.player = player
    }
}

@available(iOS 27.0, visionOS 27.0, *)
private final class GeminiPlayerView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    private var playerLayer: AVPlayerLayer {
        guard let layer = layer as? AVPlayerLayer else {
            fatalError("GeminiPlayerView requires AVPlayerLayer.")
        }
        return layer
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    init(player: AVPlayer) {
        super.init(frame: .zero)
        self.player = player
        playerLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        nil
    }
}
#endif
