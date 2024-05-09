import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:pigallery2_android/domain/models/item.dart' as models show Media;
import 'package:pigallery2_android/ui/fullscreen/viewmodels/paginated_fullscreen_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pigallery2_android/util/extensions.dart';

class VideoModel extends SafeChangeNotifier implements PaginatedFullscreenModel {
  double _videoScale = 1.0;
  int? _currentItemId;

  /// Maps [models.Media.id]s to how many Widgets referencing their video playback currently exist.
  /// Due to animations, these widgets will be drawn multiple times.
  final Map<int, int> _refs = {};

  /// Maps [models.Media.id]s to their [VideoController].
  /// Used to cache [VideoController] for multiple widgets.
  final Map<int, VideoController> _controllers = {};

  /// The [VideoController] of the Widget with > 50% visibility.
  /// null if the current item is not a video.
  VideoController? get videoController => _currentItemId?.let((it) => _controllers[it]);

  void _disposeController(int id) {
    VideoController? videoController = _controllers[id];
    if (videoController != null) {
      videoController.player.dispose();
      _controllers.remove(id);
    }
  }

  void _markAsCurrent(int id) {
    _controllers.forEach((key, value) {
      if (key == id) {
        value.player.setVolume(100);
        _currentItemId = id;
      } else {
        value.player.setVolume(0);
      }
    });
  }

  /// Unregister a Widget that displayed the [models.Media] video with the given [id].
  /// Disposes the controller if no other widget is using it.
  void unregisterVideoView(int id) {
    int? currentValue = _refs[id];
    if (currentValue != null) {
      if (currentValue <= 1) {
        _refs.remove(id);
        _disposeController(id);
      } else {
        _refs[id] = currentValue - 1;
      }
    }
  }

  /// Register a Widget that wants to display the [models.Media] video with the given [id].
  void registerVideoView(int id) {
    _refs.update(id, (value) => value += 1, ifAbsent: () => 1);
  }

  /// Creates a [VideoController] for the given [url] and [headers].
  /// Returns a [Stream] that emits once the controller is ready to display the first frame.
  Stream<VideoController> initializeVideoController(String url, Map<String, String> headers, int id) {
    VideoController? existingController = _controllers[id];
    if (existingController != null) {
      return existingController.waitUntilFirstFrameRendered.asStream().map((event) => existingController);
    }

    Player player = Player(configuration: const PlayerConfiguration(bufferSize: 32 * 32 * 1024 * 1024));
    player.setVolume(0);
    VideoController newController = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        vo: "mediacodec_embed",
        hwdec: "mediacodec",
        enableHardwareAcceleration: true,
        androidAttachSurfaceAfterVideoParameters: false,
      ),
    );

    Media playable = Media(url, httpHeaders: headers);
    player.setPlaylistMode(PlaylistMode.loop);
    player.open(playable);

    _controllers[id] = newController;
    if (_controllers.length == 1) {
      _markAsCurrent(id);
    }
    return newController.waitUntilFirstFrameRendered.asStream().map((event) => newController);
  }

  /// Invoked when the page changes (a new view has > 50% visibility)
  @override
  set currentItem(models.Media item) {
    /// Remove controller if new item is not a video.
    if (!item.isVideo) {
      _currentItemId = null;
    }
    _markAsCurrent(item.id);
    _videoScale = 1.0;
    notifyListeners();
  }

  set videoScale(double val) {
    _videoScale = val;
    notifyListeners();
  }

  double get videoScale => _videoScale;
}
