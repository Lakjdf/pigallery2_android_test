import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/core/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/views/bottom_sheet/bad_certificate_selection.dart';
import 'package:pigallery2_android/ui/views/bottom_sheet/bottom_sheet_handle.dart';
import 'package:pigallery2_android/ui/views/bottom_sheet/server_selection.dart';
import 'package:pigallery2_android/ui/views/gallery_view.dart';
import 'package:pigallery2_android/ui/views/website_view.dart';
import 'package:pigallery2_android/ui/widgets/animated_backdrop_toggle_button.dart';
import 'package:provider/provider.dart';

class HomeView extends StatelessWidget {
  final int stackPosition;

  HomeView(this.stackPosition) : super(key: ValueKey(stackPosition));

  void showServerSettings(BuildContext context) {
    showModalBottomSheet<int>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              BottomSheetHandle(),
              BadCertificateSelection(),
              Divider(thickness: 3),
              ServerSelection(),
            ],
          ),
        );
      },
    ).whenComplete(() => Provider.of<HomeModel>(context, listen: false).fetchItems());
  }

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
        title: Text(name),
        trailing: IgnorePointer(
          child: Radio(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        if (option.runtimeType == SortOption) {
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

  Widget buildBackLayer(ThemeData theme) {
    return ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          title: const Text("Directory Item Count"),
          leading: Icon(Icons.onetwothree, color: theme.colorScheme.onSurfaceVariant),
          trailing: Selector<GlobalSettingsModel, bool>(
            selector: (context, model) => model.showDirectoryItemCount,
            builder: (BuildContext context, showDirectoryItemCount, Widget? child) {
              return Switch(
                value: showDirectoryItemCount,
                onChanged: (value) {
                  Provider.of<GlobalSettingsModel>(context, listen: false).showDirectoryItemCount = value;
                },
              );
            },
          ),
        ),
        ListTile(
          title: const Text("Rounded Corners"),
          leading: Icon(Icons.rounded_corner, color: theme.colorScheme.onSurfaceVariant),
          trailing: Selector<GlobalSettingsModel, bool>(
            selector: (context, model) => model.galleryRoundedCorners,
            builder: (BuildContext context, showDirectoryItemCount, Widget? child) {
              return Switch(
                value: showDirectoryItemCount,
                onChanged: (value) {
                  Provider.of<GlobalSettingsModel>(context, listen: false).galleryRoundedCorners = value;
                },
              );
            },
          ),
        ),
        ListTile(
          title: const Text("Dynamic Theme"),
          leading: Icon(Icons.palette, color: theme.colorScheme.onSurfaceVariant),
          trailing: Selector<GlobalSettingsModel, bool>(
            selector: (context, model) => model.useMaterial3,
            builder: (BuildContext context, useMaterial3, Widget? child) {
              return Switch(
                value: useMaterial3,
                onChanged: (value) {
                  Provider.of<GlobalSettingsModel>(context, listen: false).useMaterial3 = value;
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    ThemeData theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        model.popStack();
        return true;
      },
      child: BackdropScaffold(
        key: ValueKey(stackPosition),
        frontLayerBorderRadius: BorderRadius.zero,
        keepFrontLayerActive: true,
        stickyFrontLayer: true,
        frontLayer: GalleryView(stackPosition),
        backLayer: buildBackLayer(theme),
        appBar: AppBar(
          iconTheme: theme.iconTheme,
          titleTextStyle: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          title: Text(model.stateOf(stackPosition).baseDirectoryName),
          actions: [
            stackPosition == 0
                ? IconButton(
                    onPressed: () {
                      showServerSettings(context);
                    },
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
            Selector<GlobalSettingsModel, bool>(
              selector: (context, model) => model.appInFullScreen,
              builder: (context, inFullScreen, child) => IconButton(
                onPressed: Provider.of<GlobalSettingsModel>(context, listen: false).toggleAppInFullScreen,
                icon: Icon(inFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
              ),
            ),
            buildSortOptions(context, model),
            if (stackPosition == 0) const AnimatedBackdropToggleButton(),
          ],
        ),
      ),
    );
  }
}
