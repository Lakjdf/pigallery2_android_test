import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/domain/models/video_player_backend.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_controller.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/mediakit/media_kit_video_player_factory.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/video_player_factory.dart';

/// [VideoPlayerFactory] that delegates to one of the available backends
/// depending on the [StorageKey.videoPlayerBackend] setting, read live on every
/// controller creation so the choice can be flipped from the UI at runtime.
///
/// The two `media_kit` variants additionally honour
/// [StorageKey.mediaKitLowLatencyCache] (read live as well).
///
/// The switch applies to newly opened videos; already-open controllers keep
/// whichever backend created them. This exists to A/B the playback engines on
/// real devices.
class SwitchableVideoPlayerFactory implements VideoPlayerFactory {
  final SharedPrefsStorage _storage;
  final VideoPlayerFactory _videoPlayer;

  SwitchableVideoPlayerFactory(this._storage, this._videoPlayer);

  VideoPlayerFactory get _active {
    final lowLatency = _storage.get(StorageKey.mediaKitLowLatencyCache);
    return switch (_storage.get(StorageKey.videoPlayerBackend)) {
      VideoPlayerBackend.videoPlayer => _videoPlayer,
      VideoPlayerBackend.mediaKit => MediaKitVideoPlayerFactory(useEmbeddedCodec: true, lowLatencyCache: lowLatency),
      VideoPlayerBackend.mediaKitDefault => MediaKitVideoPlayerFactory(useEmbeddedCodec: false, lowLatencyCache: lowLatency),
    };
  }

  @override
  void ensureInitialized() {
    MediaKitVideoPlayerFactory().ensureInitialized();
    _videoPlayer.ensureInitialized();
  }

  @override
  AppVideoController createStreamingController() => _active.createStreamingController();

  @override
  AppVideoController createMotionPhotoController() => _active.createMotionPhotoController();
}
