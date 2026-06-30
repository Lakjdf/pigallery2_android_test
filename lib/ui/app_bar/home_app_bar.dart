import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/ui/app_bar/actions/delete_album_button.dart';
import 'package:pigallery2_android/ui/app_bar/actions/flatten_dir_button.dart';
import 'package:pigallery2_android/ui/app_bar/actions/save_album_button.dart';
import 'package:pigallery2_android/ui/app_bar/actions/sort_option_button.dart';
import 'package:pigallery2_android/ui/app_bar/viewmodels/app_bar_model.dart';
import 'package:pigallery2_android/ui/app_bar/viewmodels/app_bar_scroll_model.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/app_bar/search/search_app_bar_title.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_state.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_models_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

enum AppBarAction { back, search, clearSearch, flatten, saveAlbum, deleteAlbum, sort, share, clearSelection }

class AppBarState {
  final String title;
  final String? subtitle;
  final double subtitleProgress;
  final Set<AppBarAction> actions;

  AppBarState({
    required this.title,
    required this.subtitle,
    required this.subtitleProgress,
    required this.actions,
  });
}

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  Set<AppBarAction> buildActions(BuildContext context) {
    Set<AppBarAction> actions = {};

    bool isSelectionActive = context.select<TabModelsProvider, bool>((it) => it.model?.isSelectionActive == true);
    if (isSelectionActive) {
      actions.add(AppBarAction.share);
      actions.add(AppBarAction.clearSelection);
      return actions;
    }

    bool canGoBack = context.select<AppBarModel, bool>((it) => it.canGoBack);
    bool isSearchOverlayShown = context.select<TabModelsProvider, bool>(
      (it) => it.searchModel?.showOverlay == true,
    );
    bool isSearchResultShown = context.select<TabModelsProvider, bool>(
      (it) => it.model?.currentState.type is SearchGalleryModelStateType,
    );
    bool isFlattenResultShown = context.select<TabModelsProvider, bool>(
      (it) =>
          it.model?.currentState.type is FlattenGalleryModelStateType ||
          it.model?.currentState.type is TimelineGalleryModelStateType,
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
    if (tab != TabEntry.website && tab != TabEntry.timeline) {
      actions.add(AppBarAction.sort);
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
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    AppBarState state = AppBarState(
      title: context.select<AppBarModel, String>((it) => it.title),
      subtitle: context.select<AppBarModel, String?>((it) => it.subtitle),
      subtitleProgress: context.select<AppBarModel, double>((it) => it.subtitleProgress),
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

  Future<void> _shareSelectedMedia(BuildContext context) async {
    final galleryModel = context.read<TabModelsProvider>().model;
    final selectedMedia = galleryModel?.selectedMedia ?? const <Media>[];
    if (selectedMedia.isEmpty) return;

    final repository = context.read<MediaRepository>();
    final files = <XFile>[];
    for (final media in selectedMedia) {
      String? filePath = await repository.getFilePath(media);
      if (filePath != null) {
        files.add(XFile(filePath));
        continue;
      }

      final completer = Completer<void>();
      final subscription = repository.download(media);
      subscription.onData((_) {});
      subscription.onDone(() async {
        final downloadedPath = await repository.getFilePath(media);
        if (downloadedPath != null) {
          files.add(XFile(downloadedPath));
        }
        completer.complete();
      });
      subscription.onError((_) => completer.complete());
      await completer.future;
    }

    if (files.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(files: files));
      galleryModel?.clearSelection();
    }
  }

  Widget _buildNavigation(BuildContext context) {
    if (state.actions.contains(AppBarAction.clearSelection)) {
      return IconButton(
        onPressed: () {
          context.read<TabModelsProvider>().model?.clearSelection();
        },
        icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
        padding: EdgeInsets.zero,
      );
    }

    if (state.actions.contains(AppBarAction.back)) {
      return IconButton(
        onPressed: () {
          onBackInvoked(context);
        },
        icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
        padding: EdgeInsets.zero,
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildAlwaysVisibleActions(BuildContext context) {
    List<Widget> actions = [];
    
    if (state.actions.contains(AppBarAction.share)) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () async => _shareSelectedMedia(context),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }

  Widget _buildTitle(BuildContext context) {
    ThemeData theme = Theme.of(context);

    final isSearching = context.select<TabModelsProvider, bool>((it) => (it.searchModel?.isSearching == true));
    if (isSearching) {
      return SearchAppBarTitle();
    }

    final displayedTitle = state.title == "." ? "" : state.title;
    final subtitle = state.subtitle;
    if (subtitle == null) {
      return Expanded(
        child: Text(
          displayedTitle,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: theme.textTheme.titleLarge,
        ),
      );
    }
    // When a date subtitle is available, the directory title and date swap
    // prominence as the user scrolls into the month grid. The swap is driven
    // by subtitleProgress (0 = title dominant, 1 = date dominant) so the
    // transition tracks the gesture directly. The title renders at a fixed
    // titleLarge size and shrinks via Transform.scale — not fontSize lerp,
    // which re-measures the text every frame and makes Align jitter by a
    // pixel on slow scroll.
    final progress = state.subtitleProgress;
    final titleBaseStyle = theme.textTheme.titleLarge;
    final titleBaseSize = titleBaseStyle?.fontSize ?? 22.0;
    final titleTargetSize = theme.textTheme.labelSmall?.fontSize ?? 11.0;
    final titleScale = 1.0 + (titleTargetSize / titleBaseSize - 1.0) * progress;
    final titleBaseColor = titleBaseStyle?.color ?? theme.colorScheme.onSurface;
    final titleStyle = titleBaseStyle?.copyWith(
      color: Color.lerp(titleBaseColor, theme.colorScheme.onSurfaceVariant, progress),
    );
    final subtitleStyle = titleBaseStyle?.copyWith(fontWeight: FontWeight.w600);
    return Expanded(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Opacity(
              opacity: progress,
              child: Transform.scale(
                alignment: Alignment.bottomLeft,
                scale: 0.92 + 0.08 * progress,
                child: Text(
                  subtitle,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: subtitleStyle,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.lerp(Alignment.centerLeft, Alignment.topLeft, progress)!,
            child: Transform.scale(
              alignment: Alignment.topLeft,
              scale: titleScale,
              child: Text(
                displayedTitle,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: titleStyle,
              ),
            ),
          ),
        ],
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
          _buildAlwaysVisibleActions(context),
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
