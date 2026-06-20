import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_controller.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/video_player_factory.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/videoplayer/vp_video_controller.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/videoplayer/vp_video_player.dart';

/// [VideoPlayerFactory] backed by the official `video_player` plugin
/// (ExoPlayer/media3 on Android).
///
/// This is the only place outside `videoplayer/` that knows about that package.
///
/// Caveats vs. the `media_kit` backend:
/// - No low-latency cache tuning knob; ExoPlayer's default buffering is used.
/// - Source rotation cannot be disabled, so the motion-photo controller relies
///   on ExoPlayer's automatic rotation (the UI's manual compensation may need
///   revisiting if motion photos become a priority).
class VpVideoPlayerFactory implements VideoPlayerFactory {
  @override
  void ensureInitialized() {
    // video_player needs no global initialization.
  }

  @override
  AppVideoController createStreamingController() {
    // Muted on start; VideoModel cross-fades the volume while swiping.
    return VpVideoController(VpVideoPlayer(loop: true));
  }

  @override
  AppVideoController createMotionPhotoController() {
    return VpVideoController(VpVideoPlayer(loop: true, initialVolume: 100));
  }
}
