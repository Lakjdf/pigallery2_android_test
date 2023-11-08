import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/views/home/search/gallery_search_delegate.dart';
import 'package:pigallery2_android/ui/views/website_view.dart';
import 'package:pigallery2_android/ui/widgets/animated_backdrop_toggle_button.dart';
import 'package:pigallery2_android/ui/widgets/fullscreen_toggle_action.dart';
import 'package:pigallery2_android/ui/widgets/sort_options_widget.dart';
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
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    ThemeData theme = Theme.of(context);
    String? directoryName = model.stateOf(stackPosition).baseDirectory?.name;
    return AppBar(
      iconTheme: theme.iconTheme,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      title: Text(stackPosition == 0 && directoryName == "." ? "" : directoryName ?? ""), // don't show name of root dir '.'
      actions: [
        Consumer<HomeModel>(
          builder: (context, model, child) => stackPosition == 0 && model.serverUrl != null
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
          builder: (context, model, child) => stackPosition == 0 && model.serverUrl != null
              ? IconButton(
                  onPressed: () {
                    showAdminPanel(context, model.serverUrl!);
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
