/// Which video playback engine to use for newly opened videos.
///
/// Selected live by [SwitchableVideoPlayerFactory]; the cache/demux tuning that
/// applies to the `media_kit` variants is a separate toggle
/// ([StorageKey.mediaKitLowLatencyCache]).
enum VideoPlayerBackend {
  /// `media_kit` / libmpv with the Android `mediacodec_embed` video output
  /// (hardware surface embedding). The app default.
  mediaKit,

  /// `media_kit` / libmpv with its default render configuration (texture
  /// rendering), i.e. the same internal view path as `video_player`.
  mediaKitDefault,

  /// The official Flutter `video_player` plugin (ExoPlayer/media3 on Android).
  videoPlayer,
}

extension VideoPlayerBackendInfo on VideoPlayerBackend {
  String get displayName => switch (this) {
    VideoPlayerBackend.mediaKit => "media_kit (hardware)",
    VideoPlayerBackend.mediaKitDefault => "media_kit (default config) [Default]",
    VideoPlayerBackend.videoPlayer => "video_player",
  };

  String get description => switch (this) {
    VideoPlayerBackend.mediaKit =>
      "libmpv with hardware-only decoding, rendered on dedicated surface. Some formats may not play.",
    VideoPlayerBackend.mediaKitDefault =>
      "libmpv with software fallback, rendered as a texture. Plays the most formats, but tends to stutter.",
    VideoPlayerBackend.videoPlayer => "ExoPlayer, texture rendering. Common formats; causes crashes on some devices.",
  };

  /// Whether this backend is one of the `media_kit` variants (and therefore
  /// honours the low-latency cache toggle).
  bool get isMediaKit => this != VideoPlayerBackend.videoPlayer;
}
