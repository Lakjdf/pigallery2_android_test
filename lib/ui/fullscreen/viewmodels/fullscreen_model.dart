import 'package:collection/collection.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/paginated_fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_scroll_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:pigallery2_android/ui/fullscreen/views/fullscreen_view.dart';

class FullscreenItem {
  FullscreenItem(this.item);
  final Media item;
  FullscreenItem? next;
  FullscreenItem? previous;
}

class FullscreenModel extends SafeChangeNotifier {
  final List<PaginatedFullscreenModel> _fullscreenModels;
  final List<FullscreenItem> _items = [];
  final FullscreenScrollModel _scrollModel;

  FullscreenModel(this._fullscreenModels, this._currentPage, this._scrollModel);

  bool _hideDetailedOverlay = true;
  int _currentPage;
  double _opacity = 1;
  double _heroAnimationProgress = 0;

  bool get hideDetailedOverlay => _hideDetailedOverlay;

  set hideDetailedOverlay(bool value) {
    if (value != _hideDetailedOverlay) {
      _hideDetailedOverlay = value;
      notifyListeners();
    }
  }

  set media(List<Media> media) {
    _items.clear();
    media.forEachIndexed((idx, media) {
      final item = FullscreenItem(media);
      if (idx > 0) {
        _items.last.next = item;
        item.previous = _items.last;
      }
      _items.add(item);
    });
  }

  set currentPage(int idx) {
    _currentPage = idx;
    for (var model in _fullscreenModels) {
      model.currentItem = _items[idx];
    }
    _scrollModel.currentIndex = idx;
    notifyListeners();
  }

  @override
  void dispose() {
    for (var model in _fullscreenModels) {
      model.close();
    }
    super.dispose();
  }

  /// [Media] item displayed at the current page.
  int get currentPage => _currentPage;

  /// [Media] item displayed at the current page.
  Media get currentItem => _items[_currentPage].item;

  set opacity(double val) {
    _opacity = val;
    notifyListeners();
  }

  /// Opacity of elements related to the [FullscreenView].
  double get opacity => _opacity * _heroAnimationProgress;

  /// Progress of the hero animation when dismissing a [FullScreenView].
  double get heroAnimationProgress => _heroAnimationProgress;

  set heroAnimationProgress(double value) {
    _heroAnimationProgress = value;
    notifyListeners();
  }
}
