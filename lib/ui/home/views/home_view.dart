import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/settings/views/settings_bottom_sheet.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/ui/top_picks/viewmodels/top_picks_model.dart';
import 'package:pigallery2_android/ui/gallery/gallery_view.dart';
import 'package:pigallery2_android/ui/app_bar/views/back_layer.dart';
import 'package:pigallery2_android/ui/app_bar/home_app_bar.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';

class HomeView extends StatelessWidget {
  final int stackPosition;

  HomeView(this.stackPosition) : super(key: ValueKey(stackPosition));

  void showServerSettings(BuildContext context) {
    showModalBottomSheet<int>(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      context: context,
      builder: (context) => SettingsBottomSheet(),
    ).whenComplete(() {
      if (!context.mounted) return;
      Provider.of<HomeModel>(context, listen: false).fetchItems();
      Provider.of<TopPicksModel>(context, listen: false).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    // BackdropScaffold does not enable predictive back gestures.
    // With it enabled, touch inputs are not registered for ~0.5s after the animation is finished.
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: ((bool didPop, _) {
        if (!didPop) return;
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        model.popStack();
      }),
      child: BackdropScaffold(
        primary: false,
        key: ValueKey(stackPosition),
        frontLayerBorderRadius: BorderRadius.zero,
        keepFrontLayerActive: true,
        stickyFrontLayer: true,
        frontLayer: GalleryView(stackPosition, () => showServerSettings(context)),
        backLayer: BackLayer(),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(toolbarHeight + SystemUi.getPadding().top),
          child: HomeAppBar(stackPosition, () => showServerSettings(context), key: ValueKey(stackPosition)),
        ),
      ),
    );
  }
}
