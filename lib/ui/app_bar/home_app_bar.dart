import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/ui/app_bar/actions/delete_album_button.dart';
import 'package:pigallery2_android/ui/app_bar/actions/flatten_dir_button.dart';
import 'package:pigallery2_android/ui/app_bar/actions/save_album_button.dart';
import 'package:pigallery2_android/ui/app_bar/actions/sort_option_button.dart';
import 'package:pigallery2_android/ui/app_bar/viewmodels/app_bar_model.dart';
import 'package:pigallery2_android/ui/app_bar/viewmodels/app_bar_scroll_model.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/app_bar/actions/animated_backdrop_toggle_button.dart';
import 'package:pigallery2_android/ui/app_bar/search/search_app_bar_title.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_state.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_models_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';

enum AppBarAction { back, search, clearSearch, flatten, backdrop, saveAlbum, deleteAlbum, sort }

class AppBarState {
  final String title;
  final Set<AppBarAction> actions;

  AppBarState({required this.title, required this.actions});
}

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  Set<AppBarAction> buildActions(BuildContext context) {
    Set<AppBarAction> actions = {};

    bool canGoBack = context.select<AppBarModel, bool>((it) => it.canGoBack);
    bool isSearchOverlayShown = context.select<TabModelsProvider, bool>(
      (it) => it.searchModel?.showOverlay == true,
    );
    bool isSearchResultShown = context.select<TabModelsProvider, bool>(
      (it) => it.model?.currentState.type is SearchGalleryModelStateType,
    );
    bool isFlattenResultShown = context.select<TabModelsProvider, bool>(
      (it) => it.model?.currentState.type is FlattenGalleryModelStateType,
    );
    if (canGoBack || isSearchOverlayShown) {
      actions.add(AppBarAction.back);
    }

    if (isSearchOverlayShown) {
      actions.add(AppBarAction.clearSearch);
      return actions;
    }
    if (isSearchResultShown) {
      actions.add(AppBarAction.saveAlbum);
      actions.add(AppBarAction.sort);
      return actions;
    }

    final tab = context.select<TabStateModel, TabEntry>((it) => it.currentTab);
    if (tab != TabEntry.website) {
      actions.add(AppBarAction.sort);
      actions.add(AppBarAction.backdrop);
    }
    if (isFlattenResultShown) return actions;

    bool isSingleAlbumView = context.select<TabModelsProvider, bool>(
      (it) => it.model?.isAlbumView == true && it.model?.stackPosition == 1,
    );
    if (isSingleAlbumView) {
      actions.add(AppBarAction.deleteAlbum);
    }
    bool isAlbumView = context.select<TabModelsProvider, bool>((it) => it.model?.isAlbumView == true);
    if (isAlbumView) return actions;

    bool isServerConfigured = context.select<ServerRepository, bool>((it) => it.serverUrl != null);
    bool areDirectoriesDisplayed = context.select<AppBarModel, bool>((it) => it.areDirectoriesDisplayed);
    if (isServerConfigured && tab != TabEntry.website) {
      actions.add(AppBarAction.search);
      if (areDirectoriesDisplayed) {
        actions.add(AppBarAction.flatten);
      }
    }
    return actions;
  }

  /// not using AppBar since it doesn't properly keep top padding when status bar is hidden
  Widget buildAppBarContainer(BuildContext context, {required Widget child}) {
    final statusBarHeight = SystemUi.getPadding().top;
    return Container(
      padding: EdgeInsets.fromLTRB(6, statusBarHeight, 6, statusBarHeight == 0 ? 0 : 6),
      height: statusBarHeight + toolbarHeight,
      color: Colors.transparent,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    AppBarState state = AppBarState(
      title: context.select<AppBarModel, String>((it) => it.title),
      actions: buildActions(context),
    );
    return buildAppBarContainer(
      context,
      child: _HomeAppBarInner(
        state,
      ),
    );
  }
}

class _HomeAppBarInner extends StatelessWidget {
  final AppBarState state;
  const _HomeAppBarInner(this.state);

  List<Widget> _buildActions(BuildContext context) {
    List<Widget> actions = [];
    if (state.actions.contains(AppBarAction.clearSearch)) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            context.read<TabModelsProvider>().searchModel?.clearInput();
          },
        ),
      );
    }

    if (state.actions.contains(AppBarAction.search)) {
      actions.add(
        IconButton(
          onPressed: () async {
            final tab = context.read<TabStateModel>().currentTab;
            GalleryModel model = context.read<TabModelsProvider>().model!;
            context.read<TabModelsProvider>().searchModel!.startSearch(model.currentState.baseDirectory);
            final key = navigatorKeys[tab.pos]!;
            await key.currentState!.pushNamed("search", arguments: model.stackPosition);
          },
          icon: const Icon(Icons.search),
        ),
      );
    }
    if (state.actions.contains(AppBarAction.backdrop)) {
      actions.add(const AnimatedBackdropToggleButton());
    }
    if (state.actions.contains(AppBarAction.flatten)) {
      actions.add(const FlattenDirButton());
    }
    if (state.actions.contains(AppBarAction.saveAlbum)) {
      actions.add(const SaveAlbumButton());
    }
    if (state.actions.contains(AppBarAction.deleteAlbum)) {
      actions.add(const DeleteAlbumButton());
    }
    if (state.actions.contains(AppBarAction.sort)) {
      actions.add(const SortOptionWidget());
    }
    return actions;
  }

  Widget _buildNavigation(BuildContext context) {
    if (state.actions.contains(AppBarAction.back)) {
      return IconButton(
        onPressed: () {
          onBackInvoked(context);
        },
        icon: const Icon(Icons.arrow_back),
        padding: EdgeInsets.zero,
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildTitle(BuildContext context) {
    ThemeData theme = Theme.of(context);

    final isSearching = context.select<TabModelsProvider, bool>((it) => (it.searchModel?.isSearching == true));
    if (isSearching) {
      return SearchAppBarTitle();
    }

    return Expanded(
      child: Text(
        state.title == "." ? "" : state.title,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: theme.textTheme.titleLarge,
      ),
    );
  }

  List<Widget> _buildLeading(BuildContext context) {
    return [
      _buildNavigation(context),
      SizedBox(width: 6),
      _buildTitle(context),
    ];
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final showActions = context.select<AppBarScrollModel, bool>((m) => m.showActions);

    return IconButtonTheme(
      data: IconButtonThemeData(
        style: theme.iconButtonTheme.style?.copyWith(padding: WidgetStateProperty.all(EdgeInsets.zero)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ..._buildLeading(context),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            opacity: showActions ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !showActions,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _buildActions(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
