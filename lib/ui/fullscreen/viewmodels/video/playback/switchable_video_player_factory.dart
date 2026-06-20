import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_controller.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/video_player_factory.dart';

/// [VideoPlayerFactory] that delegates to one of two backends depending on the
/// [StorageKey.useVideoPlayerBackend] setting, read live on every controller
/// creation so the choice can be flipped from the UI at runtime.
///
/// The switch applies to newly opened videos; already-open controllers keep
/// whichever backend created them. This exists to A/B `media_kit` against
/// `video_player` on real devices.
class SwitchableVideoPlayerFactory implements VideoPlayerFactory {
  final SharedPrefsStorage _storage;
  final VideoPlayerFactory _mediaKit;
  final VideoPlayerFactory _videoPlayer;

  SwitchableVideoPlayerFactory(this._storage, this._mediaKit, this._videoPlayer);

  VideoPlayerFactory get _active => _storage.get(StorageKey.useVideoPlayerBackend) ? _videoPlayer : _mediaKit;

  @override
  void ensureInitialized() {
    _mediaKit.ensureInitialized();
    _videoPlayer.ensureInitialized();
  }

  @override
  AppVideoController createStreamingController() => _active.createStreamingController();

  @override
  AppVideoController createMotionPhotoController() => _active.createMotionPhotoController();
}
