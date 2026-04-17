import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/app_bar/viewmodels/app_bar_scroll_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:provider/provider.dart';

/// Keeps [AppBarScrollModel] in sync with a gallery-like view's scroll
/// controller and visibility.
///
/// Mix in on a `State<T>` that:
///  - exposes its [ScrollController] via [appBarScrollController]
///  - calls [syncAppBarOffset] from the controller's listener
///  - calls [watchTabForAppBarSync] from `build` (for tab-switch detection)
///
/// Handles the `RouteAware` subscription + lifecycle wiring internally so
/// the bar re-shows when a child route is popped or the tab becomes active.
mixin AppBarScrollSync<T extends StatefulWidget> on State<T> implements RouteAware {
  ScrollController get appBarScrollController;

  ModalRoute? _subscribedRoute;
  // Cached so async callbacks don't call context.read on a deactivated element.
  AppBarScrollModel? _appBarScrollModel;
  RouteObserver<PageRoute>? _routeObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appBarScrollModel = context.read<AppBarScrollModel>();
    _routeObserver ??= galleryRouteObservers[context.read<TabEntry>().pos];
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _subscribedRoute) {
      _routeObserver?.unsubscribe(this);
      _subscribedRoute = route;
      _routeObserver?.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    if (_subscribedRoute != null) _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {}

  @override
  void didPopNext() => attachAppBar();

  /// Call from the scroll controller's listener.
  void syncAppBarOffset() {
    if (!mounted || !appBarScrollController.hasClients) return;
    _appBarScrollModel?.update(
      offset: appBarScrollController.position.pixels,
      direction: appBarScrollController.position.userScrollDirection,
    );
  }

  /// Resets the bar to a visible state adopting the current scroll offset.
  /// Call when this view becomes active (mount, route pop, tab switch).
  void attachAppBar() {
    if (!mounted) return;
    final offset = appBarScrollController.hasClients ? appBarScrollController.position.pixels : 0.0;
    _appBarScrollModel?.attach(offset);
  }

  /// Call from `build` so tab switches trigger a re-attach when this view
  /// becomes the topmost route in the newly active tab.
  void watchTabForAppBarSync(BuildContext context) {
    final currentTab = context.select<TabStateModel, TabEntry>((m) => m.currentTab);
    final myTab = context.read<TabEntry>();
    if (currentTab == myTab && ModalRoute.of(context)?.isCurrent == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => attachAppBar());
    }
  }
}
