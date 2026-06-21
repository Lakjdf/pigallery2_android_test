import 'dart:async';

import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_cache.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_item.dart';

class VideoModelControllerState {
  late final VideoControllerCache<int, VideoControllerItem> _cache;
  final StreamController<VideoControllerItem?> _currentVideoControllerStream = StreamController();
  int? _currentItemId;

  /// Controllers detached by [detach], already paused and awaiting the deferred
  /// native disposal performed by [disposeDetached].
  final List<VideoControllerItem> _pendingDisposal = [];

  VideoModelControllerState() {
    _cache = VideoControllerCache(
      onRemove: _onEvicted,
      maximumSize: 4,
    );
  }

  /// Disposes a controller the cache evicted because [maximumSize] was exceeded.
  /// Close-time teardown does not go through here; see [detach]/[disposeDetached].
  void _onEvicted(VideoControllerItem item) {
    item.controller.player.dispose();
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

  /// Detaches every controller from the live cache so a re-opened view starts
  /// with fresh controllers. Their expensive native teardown
  /// is deferred to [disposeDetached] to keep it off the animation.
  void detach() {
    final detached = _cache.drain();
    for (final item in detached) {
      item.controller.player.pause().catchError((_) {});
    }
    _pendingDisposal.addAll(detached);
    setCurrentItemId(null);
  }

  /// Disposes the controllers detached by [detach].
  /// Since the disposal is partly running on the main thread, this is not to be invoked during an animation.
  Future<void> disposeDetached() async {
    if (_pendingDisposal.isEmpty) return;
    final items = List<VideoControllerItem>.of(_pendingDisposal);
    _pendingDisposal.clear();
    for (final item in items) {
      await item.controller.player.dispose();
    }
  }
}
