import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_helper.dart';
import 'package:pigallery2_android/ui/app_bar/actions/flatten_dir_button.dart';
import 'package:pigallery2_android/ui/app_bar/actions/sort_option_button.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/app_bar/search/gallery_search_delegate.dart';
import 'package:pigallery2_android/ui/app_bar/views/website_view.dart';
import 'package:pigallery2_android/ui/app_bar/actions/animated_backdrop_toggle_button.dart';
import 'package:pigallery2_android/ui/app_bar/actions/fullscreen_toggle_button.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:provider/provider.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int stackPosition;
  final VoidCallback showServerSettings;

  const HomeAppBar(this.stackPosition, this.showServerSettings, {super.key});

  void showAdminPanel(BuildContext context, String serverUrl) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => WebsiteView(serverUrl),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // animation that slides the page in from the right
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    List<Widget> actions = [];
    bool isServerConfigured = context.select<HomeModel, bool>((it) => it.isServerConfigured);
    bool isSearching = context.select<HomeModel, bool>((it) => it.stateOf(stackPosition).isSearching);
    bool areDirectoriesDisplayed = context.select<HomeModel, bool>((it) => it.stateOf(stackPosition).directories.isNotEmpty);
    if (isServerConfigured && !isSearching) {
      actions.add(
        IconButton(
          onPressed: () async {
            HomeModel model = Provider.of<HomeModel>(context, listen: false);
            model.startSearch();
            await showSearch(context: context, delegate: GallerySearchDelegate(stackPosition));
            model.stopSearch();
          },
          icon: const Icon(Icons.search),
        ),
      );
    }
    if (stackPosition == 0) {
      actions.add(
        IconButton(
          onPressed: showServerSettings,
          icon: const Icon(Icons.settings),
        ),
      );
    }
    if (stackPosition == 0 && isServerConfigured) {
      actions.add(
        IconButton(
          onPressed: () {
            String? url = StorageHelper(context.read<SharedPrefsStorage>()).getSelectedServerUrl();
            url?.let((it) => showAdminPanel(context, it));
          },
          icon: const Icon(Icons.manage_accounts),
        ),
      );
    }
    if (stackPosition == 0) {
      actions.add(const AnimatedBackdropToggleButton());
    }
    if (isServerConfigured && !isSearching && areDirectoriesDisplayed) {
      actions.add(const FlattenDirButton());
    }
    actions.addAll([const FullscreenToggleAction(), const SortOptionWidget()]);
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    String? directoryName = context.select<HomeModel, String?>((it) => it.stateOf(stackPosition).title);
    return AppBar(
      iconTheme: theme.iconTheme,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      title: Text(directoryName == "." ? "" : directoryName ?? ""), // don't show name of root dir '.'
      actions: _buildActions(context),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
