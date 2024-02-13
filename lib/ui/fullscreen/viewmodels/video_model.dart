import 'package:better_player/better_player.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/paginated_fullscreen_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

class VideoModel extends SafeChangeNotifier implements PaginatedFullscreenModel {
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

  @override
  set currentItem(Media item) {
    /// Remove controller if new item is not a video.
    /// Else wait for addController() to be called. Avoids a lag when switching items.
    if (!item.isVideo) {
      _betterPlayerController = null;
    }
    awaitingNewController = true;
    _videoScale = 1.0;
    notifyListeners();
  }

  set videoScale(double val) {
    _videoScale = val;
    notifyListeners();
  }

  double get videoScale => _videoScale;
}
