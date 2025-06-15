import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_helper.dart';
import 'package:pigallery2_android/ui/app_bar/actions/flatten_dir_button.dart';
import 'package:pigallery2_android/ui/app_bar/actions/sort_option_button.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/app_bar/search/gallery_search_delegate.dart';
import 'package:pigallery2_android/ui/app_bar/views/website_view.dart';
import 'package:pigallery2_android/ui/app_bar/actions/animated_backdrop_toggle_button.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';

class HomeAppBar extends StatelessWidget {
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

          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    List<Widget> actions = [];
    bool isServerConfigured = context.select<HomeModel, bool>((it) => it.isServerConfigured);
    bool isSearching = context.select<HomeModel, bool>((it) => it.stateOf(stackPosition).isSearching);
    bool areDirectoriesDisplayed = context.select<HomeModel, bool>(
      (it) => it.stateOf(stackPosition).directories.isNotEmpty,
    );
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
      actions.add(IconButton(onPressed: showServerSettings, icon: const Icon(Icons.settings)));
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
    actions.addAll([const SortOptionWidget()]);
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    String? directoryName = context.select<HomeModel, String?>((it) => it.stateOf(stackPosition).title);
    final statusBarHeight = SystemUi.getPadding().top;

    // not using AppBar since it doesn't properly keep top padding when status bar is hidden
    return Container(
      padding: EdgeInsets.fromLTRB(6, statusBarHeight, 6, statusBarHeight == 0 ? 0 : 6),
      color: theme.appBarTheme.backgroundColor,
      child: IconButtonTheme(
        data: IconButtonThemeData(
          style: theme.iconButtonTheme.style?.copyWith(padding: WidgetStateProperty.all(EdgeInsets.zero)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (stackPosition > 0)
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
              ),
            SizedBox(width: 6),
            Text(
              directoryName == "." ? "" : directoryName ?? "",
              overflow: TextOverflow.fade,
              maxLines: 1,
              softWrap: false,
              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: _buildActions(context)),
          ],
        ),
      ),
    );
  }
}
