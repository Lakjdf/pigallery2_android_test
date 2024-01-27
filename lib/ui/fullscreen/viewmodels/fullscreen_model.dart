import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/paginated_fullscreen_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:pigallery2_android/ui/fullscreen/views/fullscreen_view.dart';

class FullscreenModel extends SafeChangeNotifier {
  final List<PaginatedFullscreenModel> _fullscreenModels;

  FullscreenModel(this._fullscreenModels, this._currentItem);

  Media _currentItem;
  double _opacity = 1;
  double _heroAnimationProgress = 0;

  set currentItem(Media item) {
    _currentItem = item;
    for (var model in _fullscreenModels) {
      model.currentItem = item;
    }
    notifyListeners();
  }

  /// [Media] item displayed at the current page.
  Media get currentItem => _currentItem;

  set opacity(double val) {
    _opacity = val;
    notifyListeners();
  }

  /// Opacity of elements related to the [FullscreenView].
  double get opacity => _opacity;

  /// Progress of the hero animation when dismissing a [FullScreenView].
  double get heroAnimationProgress => _heroAnimationProgress;

  set heroAnimationProgress(double value) {
    _heroAnimationProgress = value;
    notifyListeners();
  }
}
