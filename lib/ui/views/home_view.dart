import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/core/viewmodels/theming_model.dart';
import 'package:pigallery2_android/ui/views/bottom_sheet/bad_certificate_selection.dart';
import 'package:pigallery2_android/ui/views/bottom_sheet/bottom_sheet_handle.dart';
import 'package:pigallery2_android/ui/views/bottom_sheet/server_selection.dart';
import 'package:pigallery2_android/ui/views/gallery_view.dart';
import 'package:pigallery2_android/ui/views/website_view.dart';
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
      child: Scaffold(
        key: ValueKey(stackPosition),
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
            stackPosition == 0
                ? IconButton(
              onPressed: Provider.of<ThemingModel>(context).toggleTheme,
              icon: const Icon(Icons.palette),
            )
                : Container(),
            Selector<HomeModel, bool>(
              selector: (context, model) => model.appInFullScreen,
              builder: (context, inFullScreen, child) => IconButton(
                onPressed: model.toggleAppInFullScreen,
                icon: Icon(inFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
              ),
            ),
            buildSortOptions(context, model),
          ],
        ),
        body: GalleryView(stackPosition),
      ),
    );
  }
}
