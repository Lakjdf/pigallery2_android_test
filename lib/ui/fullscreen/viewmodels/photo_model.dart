import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:motion_photos/motion_photos.dart';
import 'package:pigallery2_android/data/storage/pigallery2_cache_manager.dart';
import 'package:pigallery2_android/domain/models/item.dart' as models show Media;
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/paginated_fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model_state.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:quiver/collection.dart';

class PhotoModel extends SafeChangeNotifier implements PaginatedFullscreenModel {
  bool _longPressPending = false;
  final MediaRepository _mediaRepository;
  final LruMap<int, PhotoModelState> _state = LruMap(maximumSize: 3);

  PhotoModelState _createState(models.Media item) {
    PhotoModelState state = PhotoModelState(_mediaRepository.getMediaApiPath(item));
    _state[item.id] = state;
    _loadImage(state, item);
    return state;
  }

  PhotoModelState stateOf(models.Media item) {
    PhotoModelState state = _state[item.id] ??= _createState(item);
    return state;
  }

  PhotoModel(this._mediaRepository);

  void _initMotionVideoController(PhotoModelState state, models.Media item, Uint8List bytes) {
    // needs to be recreated since the controller is disposed when the video player is removed from the widget tree
    Player player = Player();
    // By default media_kit/mpv rotates the video.
    // Might be width/height issue of media_kit or related to mpv applying rotation based on (incorrect/missing) metadata.
    (player.platform as NativePlayer).setProperty("video-rotate", "no").then((_) {
      player.setPlaylistMode(PlaylistMode.loop);
      Media.memory(bytes).then((Playable playable) => player.open(playable));
      state.videoController = VideoController(
        player,
        configuration: const VideoControllerConfiguration(
          vo: "mediacodec_embed",
          hwdec: "mediacodec",
          enableHardwareAcceleration: true,
          androidAttachSurfaceAfterVideoParameters: false,
        ),
      )..waitUntilFirstFrameRendered.then((value) => notifyListeners());
    });
  }

  Future<Uint8List?> _loadMotionVideo(String localPath) async {
    MotionPhotos photo = MotionPhotos(localPath);
    return await Isolate.run(() async {
      var videoIndex = await photo.getMotionVideoIndex();
      if (videoIndex != null) {
        return await photo.getMotionVideo(index: videoIndex);
      }
      return null;
    }).catchError((error) {
      return null;
    });
  }

  void _loadImage(PhotoModelState state, models.Media item) {
    Stream<FileResponse> stream = PiGallery2CacheManager.fullRes.getFileStream(
      state.url,
      headers: _mediaRepository.headers,
      withProgress: false,
    );
    stream.listen((FileResponse event) {
      if (event is FileInfo) {
        _loadMotionVideo(event.file.path).then((bytes) {
          state.video = bytes;
          notifyListeners();
          if (_longPressPending) {
            // handle long press once the image has been downloaded to the cache
            handleLongPress(item);
          }
        });
      }
    });
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

  @override
  set currentItem(FullscreenItem item) {
    _longPressPending = false;
  }
}
