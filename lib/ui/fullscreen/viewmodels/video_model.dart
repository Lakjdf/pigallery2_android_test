import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:mutex/mutex.dart';
import 'package:pigallery2_android/domain/models/item.dart' as models show Media;
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/paginated_fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_model_controller_state.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_model_refs.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoModel extends SafeChangeNotifier implements PaginatedFullscreenModel {
  late final VideoModelControllerState _state;

  late final VideoModelRefs _refs;

  late final MediaRepository _mediaRepository;

  double _videoScale = 1.0;

  VideoControllerItem? _currentVideoControllerItem;

  VideoModel(MediaRepository mediaRepository) {
    _state = VideoModelControllerState();
    _refs = VideoModelRefs(_state);
    _mediaRepository = mediaRepository;

    _state.getCurrentController().listen((videoController) {
      if (videoController != _currentVideoControllerItem) {
        _currentVideoControllerItem = videoController;
        notifyListeners();
      }
    });
  }

  set videoScale(double val) {
    _videoScale = val;
    notifyListeners();
  }

  double get videoScale => _videoScale;

  /// The [VideoControllerItem] of the Widget with > 50% visibility.
  /// null if the current item is not a video.
  VideoControllerItem? get videoControllerItem => _currentVideoControllerItem;

  VideoControllerItem? getVideoControllerItem(int id) {
    return _state.getController(id);
  }

  /// Unregister a Widget that displayed the [models.Media] video with the given [id].
  /// Required to stop the playback after the video is no longer visible.
  void unregisterMountedWidget(int id) {
    _refs.unregisterMountedWidget(id);
  }

  /// Register a Widget that wants to display the [models.Media] video with the given [id].
  void registerMountedWidget(int id) {
    _refs.registerMountedWidget(id);
  }

  Media _mediaFromModel(models.Media media) {
    return Media(_mediaRepository.getMediaApiPath(media), httpHeaders: _mediaRepository.headers);
  }

  VideoControllerItem _initVideoController(models.Media media, bool autoPlay) {
    VideoControllerItem? existingItem = _state.getController(media.id);
    if (existingItem != null) {
      return existingItem;
    }

    Player player = Player(configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024, logLevel: MPVLogLevel.trace))..setVolume(0);
    // https://github.com/media-kit/media-kit/issues/776#issuecomment-2072158673
    (player.platform as dynamic).setProperty('cache', 'no'); // --cache=<yes|no|auto>
    (player.platform as dynamic).setProperty('cache-secs', '0'); // --cache-secs=<seconds> with cache but why not.
    (player.platform as dynamic).setProperty('demuxer-seekable-cache', 'no'); // --demuxer-seekable-cache=<yes|no|auto> Redundant with cache but why not.
    (player.platform as dynamic).setProperty('demuxer-max-back-bytes', '0'); // --demuxer-max-back-bytes=<bytesize>
    (player.platform as dynamic).setProperty('demuxer-donate-buffer', 'no'); // --demuxer-donate-buffer==<yes|no>
    VideoController newController = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        vo: "mediacodec_embed",
        hwdec: "mediacodec",
        enableHardwareAcceleration: true,
        androidAttachSurfaceAfterVideoParameters: false,
      ),
    );
    VideoControllerItem item = VideoControllerItem(newController);

    Media playable = _mediaFromModel(media);
    player.setPlaylistMode(PlaylistMode.loop);
    player.open(playable, play: autoPlay);

    _state.addController(media.id, item);
    notifyListeners();
    return item;
  }

  final Mutex _initVideoControllerLock = Mutex();

  Future<VideoControllerItem> _initVideoControllerSafe(models.Media media, bool autoPlay) async {
    await _initVideoControllerLock.acquire();
    VideoControllerItem controller;
    try {
      controller = _initVideoController(media, autoPlay);
    } finally {
      _initVideoControllerLock.release();
    }
    return controller;
  }

  /// Creates a [VideoController] for the given [models.Media].
  /// Returns a [Stream] that emits once the controller is ready to display the first frame.
  Stream<VideoControllerItem> _initializeVideoController(models.Media media, {bool autoPlay = true}) {
    return Stream.fromFuture(_initVideoControllerSafe(media, autoPlay).then((item) {
      return item.controller.waitUntilFirstFrameRendered.then((value) => item);
    }));
  }

  void _preload(models.Media? media) {
    if (media != null && media.isVideo == true) {
      _initializeVideoController(media, autoPlay: false);
    }
  }

  /// Invoked when the page changes (a new view has > 50% visibility)
  @override
  set currentItem(FullscreenItem item) {
    _videoScale = 1.0;

    /// Remove controller if new item is not a video.
    if (!item.item.isVideo) {
      _state.setCurrentItemId(null);

      _preload(item.previous?.item);
      _preload(item.next?.item);
    } else {
      _state.setCurrentItemId(item.item.id);

      // preload after first frame is rendered
      _initializeVideoController(item.item).listen((_) {
        _preload(item.previous?.item);
        _preload(item.next?.item);
      });
    }
    notifyListeners();
  }

  @override
  void close() {
    _state.free();
  }
}
