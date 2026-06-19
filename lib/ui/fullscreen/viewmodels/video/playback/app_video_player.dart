import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_source.dart';

/// Package-agnostic playback engine.
///
/// Abstracts the subset of a video player the app relies on so the underlying
/// package (currently `media_kit`) can be swapped out. All streams are
/// broadcast streams since the UI attaches multiple listeners to them.
abstract interface class AppVideoPlayer {
  /// Load [source] and start playing if [play] is true.
  Future<void> open(AppVideoSource source, {bool play = true});

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  /// Set the playback volume in the range 0–100.
  Future<void> setVolume(double volume);

  /// Release all resources. The player must not be used afterwards.
  Future<void> dispose();

  // --- Synchronous state snapshot ---

  Duration get position;

  Duration get duration;

  /// How far the player has buffered.
  Duration get buffer;

  bool get isPlaying;

  bool get isBuffering;

  /// Aspect ratio reported by the decoded video, or null if not yet known.
  /// Preferred over source metadata when available.
  double? get aspectRatio;

  // --- Reactive state ---

  Stream<Duration> get positionStream;

  Stream<Duration> get durationStream;

  Stream<Duration> get bufferStream;

  Stream<bool> get bufferingStream;

  /// Emits a message for every playback error.
  Stream<String> get errorStream;
}
