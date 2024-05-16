import 'dart:async';

import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_cache.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_item.dart';

class VideoModelControllerState {
  late final VideoControllerCache<int, VideoControllerItem> _cache;
  final StreamController<VideoControllerItem?> _currentVideoControllerStream = StreamController();
  int? _currentItemId;

  VideoModelControllerState() {
    _cache = VideoControllerCache(
      onRemove: _onRemove,
      maximumSize: 4,
    );
  }

  void _onRemove(VideoControllerItem item) {
    item.controller.player.dispose();
    if (_cache.length == 0) {
      _currentItemId = null;
      _currentVideoControllerStream.add(null);
    }
  }

  void addController(int id, VideoControllerItem controller) {
    _cache[id] = controller;
    // update state if controller is added after item is marked as current
    if (_currentItemId == id) {
      _currentVideoControllerStream.add(controller);
      _cache.promoteEntry(id);
    }
  }

  VideoControllerItem? getController(int id) {
    return _cache[id];
  }

  Stream<VideoControllerItem?> getCurrentController() {
    return _currentVideoControllerStream.stream;
  }

  void setCurrentItemId(int? id) {
    _currentItemId = id;
    _currentVideoControllerStream.add(_cache[id]);
    if (id != null) {
      _cache.promoteEntry(id);
    }
  }

  void free() {
    while (_cache.length > 0) {
      _cache.removeLru();
    }
  }
}