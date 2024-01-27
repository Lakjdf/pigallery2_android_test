import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_helper.dart';
import 'package:pigallery2_android/ui/app_bar/actions/sort_options_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    String? directoryName = context.read<HomeModel>().stateOf(stackPosition).baseDirectory?.name;
    return AppBar(
      iconTheme: theme.iconTheme,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      title: Text(stackPosition == 0 && directoryName == "." ? "" : directoryName ?? ""), // don't show name of root dir '.'
      actions: [
        Consumer<HomeModel>(
          builder: (context, model, child) => stackPosition == 0 && model.isServerConfigured
              ? IconButton(
                  onPressed: () async {
                    HomeModel model = Provider.of<HomeModel>(context, listen: false);
                    model.startSearch();
                    await showSearch(context: context, delegate: GallerySearchDelegate());
                    model.stopSearch();
                  },
                  icon: const Icon(Icons.search),
                )
              : Container(),
        ),
        stackPosition == 0
            ? IconButton(
                onPressed: showServerSettings,
                icon: const Icon(Icons.settings),
              )
            : Container(),
        Consumer<HomeModel>(
          builder: (context, model, child) => stackPosition == 0 && model.isServerConfigured
              ? IconButton(
                  onPressed: () {
                    String? url = StorageHelper(context.read<SharedPrefsStorage>()).getSelectedServerUrl();
                    url?.let((it) => showAdminPanel(context, it));
                  },
                  icon: const Icon(Icons.manage_accounts),
                )
              : Container(),
        ),
        if (stackPosition == 0) const AnimatedBackdropToggleButton(),
        const FullscreenToggleAction(),
        const SortOptionsWidget(),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
