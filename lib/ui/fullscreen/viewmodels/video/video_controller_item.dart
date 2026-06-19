import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_controller.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_player.dart';

/// Holds an [AppVideoController] alongside its error events.
/// Required since error events are not buffered.
class VideoControllerItem extends ChangeNotifier {
  final AppVideoController controller;
  final List<String> _errorEvents = [];
  bool _firstFrameRendered = false;

  VideoControllerItem(this.controller) {
    controller.player.errorStream.listen((value) {
      _errorEvents.add(value);
    });
    controller.waitUntilFirstFrameRendered.then((_) {
      _firstFrameRendered = true;
      notifyListeners();
    });
  }

  Stream<String> errorStream() async* {
    for (String event in _errorEvents) {
      yield event;
    }
    yield* controller.player.errorStream;
  }

  AppVideoPlayer get player => controller.player;

  bool get hasError => _errorEvents.isNotEmpty;

  bool get firstFrameRendered => _firstFrameRendered;
}
