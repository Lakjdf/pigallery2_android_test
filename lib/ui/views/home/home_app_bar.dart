import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/views/website_view.dart';
import 'package:pigallery2_android/ui/widgets/animated_backdrop_toggle_button.dart';
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

  PopupMenuItem<dynamic> buildPopupItem(dynamic thisValue, dynamic selectedValue, String name) {
    return PopupMenuItem(
      value: thisValue,
      padding: const EdgeInsets.all(0),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: -3),
        horizontalTitleGap: 0,
        title: Text(name),
        trailing: IgnorePointer(
          child: Radio(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4),
            value: thisValue,
            groupValue: selectedValue,
            onChanged: null,
          ),
        ),
      ),
    );
  }

  PopupMenuButton buildSortOptions(BuildContext context, HomeModel model) {
    return PopupMenuButton<dynamic>(
      icon: Icon(
        Icons.sort,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onSelected: (dynamic option) {
        if (option is SortOption) {
          model.sortOption = option;
        } else {
          model.sortOrder = option;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<dynamic>>[
        ...SortOption.values.map((e) => buildPopupItem(e, model.sortOption, e.getName())).toList(),
        const PopupMenuDivider(),
        buildPopupItem(true, model.sortAscending, "Ascending"),
        buildPopupItem(false, model.sortAscending, "Descending"),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    ThemeData theme = Theme.of(context);
    return AppBar(
      iconTheme: theme.iconTheme,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      title: Text(model.stateOf(stackPosition).baseDirectoryName),
      actions: [
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
        Selector<GlobalSettingsModel, bool>(
          selector: (context, model) => model.appInFullScreen,
          builder: (context, inFullScreen, child) => IconButton(
            onPressed: Provider.of<GlobalSettingsModel>(context, listen: false).toggleAppInFullScreen,
            icon: Icon(inFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
          ),
        ),
        buildSortOptions(context, model),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
