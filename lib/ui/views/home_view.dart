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

  Widget buildBackLayer(BuildContext context) {
    ThemeData theme = Theme.of(context);
    GlobalSettingsModel model = Provider.of<GlobalSettingsModel>(context, listen: false);
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ListTile(
          title: const Text("Dynamic Theme"),
          leading: Icon(Icons.palette, color: theme.colorScheme.onSurfaceVariant),
          trailing: Selector<GlobalSettingsModel, bool>(
            selector: (context, model) => model.useMaterial3,
            builder: (BuildContext context, useMaterial3, Widget? child) => Switch(
              value: useMaterial3,
              onChanged: (value) {
                model.useMaterial3 = value;
              },
            ),
          ),
        ),
        ListTile(
          title: const Text("Directory Item Count"),
          leading: Icon(Icons.onetwothree, color: theme.colorScheme.onSurfaceVariant),
          trailing: Selector<GlobalSettingsModel, bool>(
            selector: (context, model) => model.showDirectoryItemCount,
            builder: (BuildContext context, showDirectoryItemCount, Widget? child) {
              return Switch(
                value: showDirectoryItemCount,
                onChanged: (value) {
                  model.showDirectoryItemCount = value;
                },
              );
            },
          ),
        ),
        ListTile(
          title: const Text("Items Per Row"),
          leading: Icon(Icons.grid_on, color: theme.colorScheme.onSurfaceVariant),
          trailing: Selector<GlobalSettingsModel, int>(
              selector: (context, model) => model.getGridCrossAxisCount(MediaQuery.of(context).orientation),
              builder: (BuildContext context, gridCrossAxisCount, Widget? child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      color: theme.colorScheme.onSurfaceVariant,
                      onPressed: (gridCrossAxisCount > 1) ? () => model.storeGridCrossAxisCount(MediaQuery.of(context).orientation, gridCrossAxisCount - 1) : null,
                      icon: const Icon(Icons.remove),
                      disabledColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                    Text(gridCrossAxisCount.toString()),
                    IconButton(
                      color: theme.colorScheme.onSurfaceVariant,
                      onPressed: (gridCrossAxisCount < 10) ? () => model.storeGridCrossAxisCount(MediaQuery.of(context).orientation, gridCrossAxisCount + 1) : null,
                      icon: const Icon(Icons.add),
                      disabledColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                  ],
                );
              }),
        ),
        ListTile(
          leading: Icon(Icons.rounded_corner, color: theme.colorScheme.onSurfaceVariant),
          title: Row(
            children: [
              const Expanded(child: Text("Corner Radius")),
              Expanded(
                child: Selector<GlobalSettingsModel, int>(
                  selector: (context, model) => model.gridRoundedCorners,
                  builder: (context, gridRoundedCorners, child) => Slider(
                    divisions: 25,
                    min: 0,
                    max: 25,
                    value: gridRoundedCorners.toDouble(),
                    label: gridRoundedCorners.toString(),
                    onChanged: (double value) => model.gridRoundedCorners = value.round(),
                    onChangeEnd: (value) => model.storeGridRoundedCorners(),
                  ),
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.grid_view, color: theme.colorScheme.onSurfaceVariant),
          title: Row(
            children: [
              const Expanded(child: Text("Spacing")),
              Expanded(
                child: Selector<GlobalSettingsModel, int>(
                  selector: (context, model) => model.gridSpacing,
                  builder: (context, gridSpacing, child) => Slider(
                    divisions: 25,
                    min: 0,
                    max: 25,
                    value: gridSpacing.toDouble(),
                    label: gridSpacing.toString(),
                    onChanged: (double value) => model.gridSpacing = value.round(),
                    onChangeEnd: (value) => model.storeGridSpacing(),
                  ),
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.aspect_ratio, color: theme.colorScheme.onSurfaceVariant),
          title: Row(
            children: [
              const Expanded(child: Text("Aspect Ratio")),
              Expanded(
                child: Selector<GlobalSettingsModel, double>(
                  selector: (context, model) => model.gridAspectRatio,
                  builder: (context, gridAspectRatio, child) => Slider(
                    divisions: 10,
                    min: 0,
                    max: 1,
                    value: gridAspectRatio > 1 ? gridAspectRatio / 2 : gridAspectRatio - .5,
                    label: gridAspectRatio.toStringAsFixed(1),
                    onChanged: (double value) => model.gridAspectRatio = value > .5 ? 2 * value : .5 + value,
                    onChangeEnd: (_) => model.storeGridAspectRatio(),
                  ),
                ),
              ),
            ],
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
        backLayer: buildBackLayer(context),
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
        ),
      ),
    );
  }
}
