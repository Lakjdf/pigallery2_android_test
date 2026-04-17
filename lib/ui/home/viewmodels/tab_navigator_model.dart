import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pigallery2_android/ui/app_bar/viewmodels/app_bar_model.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_models_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/search/search_viewmodel.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:pigallery2_android/ui/top_picks/viewmodels/top_picks_model.dart';
import 'package:provider/provider.dart';

final Map<int, GlobalKey<NavigatorState>> navigatorKeys = {
  for (var it in TabEntry.values) it.pos: GlobalKey<NavigatorState>(),
};

/// One observer per tab Navigator ([NavigatorObserver] can't be attached to
/// more than one Navigator). Lets gallery views subscribe via [RouteAware] so
/// they can re-sync the app bar scroll state when a child route is popped and
/// they become visible again.
final Map<int, RouteObserver<PageRoute>> galleryRouteObservers = {
  for (var it in TabEntry.values) it.pos: RouteObserver<PageRoute>(),
};

class TabNavigatorModel extends SafeChangeNotifier {
  final TabStateModel _tabStateModel;
  final AppBarModel _appBarModel;
  final TabModelsProvider _galleryModelProvider;
  final TopPicksModel _topPicksModel;
  int _currentTab = 0;
  VoidCallback? _webViewBackHandler;
  late Function(double) _navigateToFunction;

  TabNavigatorModel(this._tabStateModel, this._appBarModel, this._galleryModelProvider, this._topPicksModel) {
    _tabStateModel.addListener(_tabChangedListener);
  }

  @override
  void dispose() {
    _tabStateModel.removeListener(_tabChangedListener);
    super.dispose();
  }

  void _tabChangedListener() {
    _currentTab = _tabStateModel.currentTab.pos;
  }

  void registerWebViewBackHandler(VoidCallback handler) {
    _webViewBackHandler = handler;
  }

  void unregisterWebViewBackHandler() {
    _webViewBackHandler = null;
  }

  void registerNavigateToFunction(Function(double) handler) {
    _navigateToFunction = handler;
  }

  void navigateTo(double page) {
    _navigateToFunction(page);
  }

  /// invoked before removing the stack from [model].
  void goBack() {
    if (_currentTab == TabEntry.website.pos) {
      final webviewBackHandler = _webViewBackHandler;
      if (webviewBackHandler == null) {
        SystemNavigator.pop();
      } else {
        webviewBackHandler.call();
      }
    } else {
      if (navigatorKeys[_currentTab]?.currentState?.canPop() != true) {
        SystemNavigator.pop();
      } else {
        navigatorKeys[_currentTab]?.currentState?.pop();
      }
    }
    _appBarModel.handleBack();
  }

  Future<void> reset() async {
    for (var key in navigatorKeys.values) {
      while (key.currentState?.canPop() == true) {
        key.currentState!.pop();
      }
    }
    await _galleryModelProvider.reset();
  }

  Future<void> refresh() async {
    GalleryModel? model = _galleryModelProvider.model;
    if (model == null) return;
    if (_galleryModelProvider.getModelByTab(0) == model) {
      await _topPicksModel.refresh();
    }
    await model.fetch(isRefresh: true);
  }
}

/// back navigation triggered; either via a widget or system gesture
void onBackInvoked(BuildContext context) {
  context.read<TabNavigatorModel>().goBack();
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  SearchViewModel? searchModel = context.read<TabModelsProvider>().searchModel;
  GalleryModel? model = context.read<TabModelsProvider>().model;
  bool isSearchResultShown = model?.currentState.isSearching == true;
  if (isSearchResultShown || searchModel?.isSearching != true) {
    model?.popStack();
  }
  searchModel?.stopSearch();
}
