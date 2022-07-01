import 'package:better_player/better_player.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:pigallery2_android/core/models/models.dart';

class FullscreenModel extends ChangeNotifier {
  Media _currentItem;
  double _opacity = 1.0;
  double _videoScale = 1.0;
  BetterPlayerController? _betterPlayerController;
  bool awaitingNewController = true;

  BetterPlayerController? get betterPlayerController => _betterPlayerController;

  void addController(BetterPlayerController controller) {
    if (awaitingNewController) {
      _betterPlayerController = controller;
      awaitingNewController = false;
      notifyListeners();
    }
  }

  FullscreenModel(this._currentItem);

  set currentItem(Media item) {
    _currentItem = item;

    /// Remove controller if new item is not a video.
    /// Else wait for addController() to be called. Avoids a lag when switching items.
    if (!lookupMimeType(item.name)!.contains("video")) {
      _betterPlayerController = null;
    }
    awaitingNewController = true;
    _videoScale = 1.0;
    notifyListeners();
  }

  Media get currentItem => _currentItem;

  set videoScale(double val) {
    _videoScale = val;
    notifyListeners();
  }

  double get videoScale => _videoScale;

  set opacity(double val) {
    _opacity = val;
    notifyListeners();
  }

  double get opacity => _opacity;
}
