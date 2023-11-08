import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/core/viewmodels/top_picks_model.dart';
import 'package:pigallery2_android/ui/views/gallery_view.dart';
import 'package:pigallery2_android/ui/views/home/back_layer.dart';
import 'package:pigallery2_android/ui/views/home/bottom_sheet/bad_certificate_selection.dart';
import 'package:pigallery2_android/ui/views/home/bottom_sheet/bottom_sheet_handle.dart';
import 'package:pigallery2_android/ui/views/home/bottom_sheet/server_selection.dart';
import 'package:pigallery2_android/ui/views/home/home_app_bar.dart';
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
        return const Padding(
          padding: EdgeInsets.fromLTRB(24, 6, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSheetHandle(),
              BadCertificateSelection(),
              Divider(thickness: 3),
              ServerSelection(),
            ],
          ),
        );
      },
    ).whenComplete(() {
      Provider.of<HomeModel>(context, listen: false).fetchItems();
      int daysLength = Provider.of<GlobalSettingsModel>(context, listen: false).topPicksDaysLength;
      Provider.of<TopPicksModel>(context, listen: false).fetchTopPicks(daysLength);
    });
  }

  @override
  Widget build(BuildContext context) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
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
        frontLayer: GalleryView(stackPosition, () => showServerSettings(context)),
        backLayer: const BackLayer(),
        appBar: HomeAppBar(stackPosition, () => showServerSettings(context)),
      ),
    );
  }
}
