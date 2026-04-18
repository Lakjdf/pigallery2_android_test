import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/search/search_viewmodel.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

/// Provides viewmodels of the current tab to widgets above the tab view.
class TabModelsProvider extends SafeChangeNotifier {
  final List<GalleryModel> _models;
  final List<SearchViewModel> _searchModels;
  final TabStateModel _tabStateModel;
  int _currentTab;

  TabModelsProvider(
    this._tabStateModel,
    GalleryModel home,
    GalleryModel albums,
    GalleryModel timeline,
  ) : _models = [home, albums, timeline],
      _searchModels = [SearchViewModel()],
      _currentTab = _tabStateModel.currentTab.pos {
    model?.addListener(_galleryModelNotify);
    searchModel?.addListener(_searchModelNotify);
    _tabStateModel.addListener(_tabChangedListener);
    model?.ensureInitialFetch();
  }

  GalleryModel? get model => _models.elementAtOrNull(_currentTab);

  SearchViewModel? get searchModel => _searchModels.elementAtOrNull(_currentTab);

  @override
  void dispose() {
    model?.removeListener(_galleryModelNotify);
    searchModel?.removeListener(_searchModelNotify);
    _tabStateModel.removeListener(_tabChangedListener);
    super.dispose();
  }

  GalleryModel getModelByTab(int tab) {
    return _models[tab];
  }

  SearchViewModel getSearchModelByTab(int tab) {
    return _searchModels[tab];
  }

  void _tabChangedListener() {
    if (_currentTab != _tabStateModel.currentTab.pos) {
      model?.removeListener(_galleryModelNotify);
      searchModel?.removeListener(_searchModelNotify);
      _currentTab = _tabStateModel.currentTab.pos;
      model?.addListener(_galleryModelNotify);
      searchModel?.addListener(_searchModelNotify);
      model?.ensureInitialFetch();
      notifyListeners();
    }
  }

  void _galleryModelNotify() {
    notifyListeners();
  }

  void _searchModelNotify() {
    notifyListeners();
  }

  Future<void> reset() async {
    for (var model in _models) {
      while (model.stackPosition > 0) {
        model.popStack();
      }
      await model.fetch();
    }
    for (var model in _searchModels) {
      model.stopSearch();
    }
  }
}
