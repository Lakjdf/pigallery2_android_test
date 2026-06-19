import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_controller.dart';

/// Creates [AppVideoController]s and performs one-time backend initialization.
///
/// This is the single seam for swapping the video playback package: provide a
/// different implementation in `main.dart` and the rest of the app is unchanged.
abstract interface class VideoPlayerFactory {
  /// Perform any one-time setup the backend requires. Called once at startup.
  void ensureInitialized();

  /// Creates a controller for streaming network video: looping playback tuned
  /// for low-latency streaming (no read-ahead caching).
  AppVideoController createStreamingController();

  /// Creates a controller for motion-photo playback: looping playback of a
  /// short in-memory clip, without the backend applying source rotation.
  AppVideoController createMotionPhotoController();
}
