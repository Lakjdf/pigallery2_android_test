import 'dart:typed_data';

import 'package:better_player/better_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pigallery2_android/data/storage/pigallery2_cache_manager.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/paginated_fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model_state.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:quiver/collection.dart';

class PhotoModel extends SafeChangeNotifier implements PaginatedFullscreenModel {
  bool _longPressPending = false;
  final MediaRepository _mediaRepository;
  final LruMap<int, PhotoModelState> _state = LruMap(maximumSize: 3);

  PhotoModelState _createState(Media item) {
    PhotoModelState state = PhotoModelState(_mediaRepository.getMediaApiPath(item));
    _state[item.id] = state;
    _loadImage(state, item);
    return state;
  }

  PhotoModelState stateOf(Media item) {
    PhotoModelState state = _state[item.id] ??= _createState(item);
    return state;
  }

  PhotoModel(this._mediaRepository);

  void _initMotionVideoController(PhotoModelState state, Media item, Uint8List bytes) {
    // needs to be recreated since the controller is disposed when BetterPlayer is removed from the widget tree
    state.betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: true,
        // fit: BoxFit.contain,
        aspectRatio: item.aspectRatio,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
        ),
      ),
      betterPlayerDataSource: BetterPlayerDataSource.memory(bytes),
    )..addEventsListener((p0) {
        if (p0.betterPlayerEventType == BetterPlayerEventType.initialized) {
          notifyListeners();
        }
      });
  }

  void _loadImage(PhotoModelState state, Media item) {
    Stream<FileResponse> stream = PiGallery2CacheManager.fullRes.getFileStream(
      state.url,
      headers: _mediaRepository.headers,
      withProgress: false,
    );
    stream.listen((FileResponse event) {
      if (event is FileInfo) {
        state.onDownloadFinished(event.file.path).then((_) {
          notifyListeners();
          if (_longPressPending) {
            // handle long press once the image has been downloaded to the cache
            handleLongPress(item);
          }
        });
      }
    });
  }

  void handleLongPress(Media item) async {
    PhotoModelState state = stateOf(item);
    Uint8List? bytes = await state.getMotionVideo();
    if (bytes != null) {
      _longPressPending = false;
      _initMotionVideoController(state, item, bytes);
    } else {
      _longPressPending = true;
    }
  }

  void handleLongPressEnd(Media item) {
    _longPressPending = false;
    var controller = stateOf(item).betterPlayerController;
    stateOf(item).betterPlayerController = null;
    controller?.dispose();
    notifyListeners();
  }

  @override
  set currentItem(Media item) {
    _longPressPending = false;
  }
}
