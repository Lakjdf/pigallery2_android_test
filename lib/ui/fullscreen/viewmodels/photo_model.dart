import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:motion_photos/motion_photos.dart';
import 'package:pigallery2_android/data/storage/pigallery2_cache_manager.dart';
import 'package:pigallery2_android/domain/models/item.dart' as models show Media;
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/paginated_fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model_state.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_config_factory.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/image_preloader.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:quiver/collection.dart';

class PhotoModel extends SafeChangeNotifier implements PaginatedFullscreenModel {
  final Logger _logger = Logger("PhotoModel");
  bool _longPressPending = false;
  bool _backgroundActive = true;
  final MediaRepository _mediaRepository;
  final ImagePreloader _imagePreloader;
  final LruMap<int, PhotoModelState> _state = LruMap(maximumSize: 3);
  void Function()? _pendingPreload;

  bool get backgroundActive => _backgroundActive;

  set backgroundActive(bool value) {
    if (value != _backgroundActive) {
      _backgroundActive = value;
      notifyListeners();
    }
  }

  PhotoModelState _createState(models.Media item) {
    PhotoModelState state = PhotoModelState(_mediaRepository.getMediaApiPath(item));
    _state[item.id] = state;
    _loadImage(state, item);
    return state;
  }

  PhotoModelState stateOf(models.Media item) {
    assert(item.isImage);
    PhotoModelState state = _state[item.id] ??= _createState(item);
    return state;
  }

  PhotoModel(this._mediaRepository, this._imagePreloader);

  void _initMotionVideoController(PhotoModelState state, models.Media item, Uint8List bytes) {
    // needs to be recreated since the controller is disposed when the video player is removed from the widget tree
    Player player = Player();
    // By default media_kit/mpv rotates the video.
    // Might be width/height issue of media_kit or related to mpv applying rotation based on (incorrect/missing) metadata.
    (player.platform as NativePlayer).setProperty("video-rotate", "no").then((_) {
      player.setPlaylistMode(PlaylistMode.loop);
      Media.memory(bytes).then((Playable playable) => player.open(playable));
      state.videoController = VideoController(player, configuration: VideoControllerConfigFactory.createConfiguration())
        ..waitUntilFirstFrameRendered.then((value) => notifyListeners());
    });
  }

  Future<Uint8List?> _loadMotionVideo(Uint8List bytes) async {
    return await Isolate.run(() async {
      return MotionPhotos(bytes).getMotionVideo();
    }).catchError((error) {
      return null;
    });
  }

  Future<void> _loadImage(PhotoModelState state, models.Media item) async {
    await _imagePreloader.preloadImage(state.url);
    notifyListeners();
    FileInfo? fileInfo = await PiGallery2CacheManager.fullRes.getFileFromMemory(state.url);
    if (fileInfo == null) {
      _logger.warning("Image was not cached in memory: ${state.url}");
      return;
    }
    var bytes = fileInfo.file.readAsBytesSync();
    state.video = await _loadMotionVideo(bytes);
    notifyListeners();
    if (_longPressPending) {
      // handle long press once the image has been downloaded to the cache
      handleLongPress(item);
    }
  }

  void _preload(models.Media? media) async {
    if (media != null && media.isImage) {
      stateOf(media);
    }
  }

  void handleLongPress(models.Media item) async {
    PhotoModelState state = stateOf(item);
    Uint8List? bytes = state.video;
    if (bytes != null) {
      _longPressPending = false;
      _initMotionVideoController(state, item, bytes);
    } else {
      _longPressPending = true;
    }
  }

  void handleLongPressEnd(models.Media item) {
    _longPressPending = false;
    var controller = stateOf(item).videoController;
    stateOf(item).videoController = null;
    controller?.player.dispose();
    notifyListeners();
  }

  void notifyFullyVisible() {
    _pendingPreload?.call();
    _pendingPreload = null;
  }

  @override
  set currentItem(FullscreenItem item) {
    _longPressPending = false;
    _backgroundActive = true;
    _pendingPreload = () {
      _preload(item.next?.item);
      _preload(item.previous?.item);
    };
  }

  @override
  void close() {
    _state.clear();
  }
}
