import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/storage/pigallery2_image_cache.dart';
import 'package:pigallery2_android/ui/settings/viewmodels/server_model.dart';
import 'package:pigallery2_android/ui/settings/views/server_selection/bad_certificate_selection.dart';
import 'package:pigallery2_android/ui/settings/views/server_selection/bottom_sheet_handle.dart';
import 'package:pigallery2_android/ui/settings/views/server_selection/server_selection.dart';
import 'package:pigallery2_android/ui/settings/views/clear_cache_list_tile.dart';
import 'package:pigallery2_android/ui/settings/views/edit_text_list_tile.dart';
import 'package:pigallery2_android/ui/shared/widgets/custom_tabbar.dart';
import 'package:pigallery2_android/util/path.dart';
import 'package:provider/provider.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  List<TabData> getTabs(BuildContext context) {
    ServerModel serverModel = context.read<ServerModel>();
    return [
      TabData(
        title: const Tab(
          child: Text("Server"),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            spacing: 6,
            children: [
              BadCertificateSelection(),
              // Divider(thickness: 3, height: 3),
              ServerSelection(),
            ],
          ),
        ),
      ),
      TabData(
        title: const Tab(
          child: Text("Compatibility"),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            spacing: 6,
            children: [
              Selector<ServerModel, String>(
                selector: (_, model) => model.apiThumbnailPath,
                builder: (BuildContext context, String value, Widget? child) => EditTextListTile(
                  title: "API Thumbnail path",
                  description: "Default: /320\nOlder versions: /thumbnail/240\nLeave empty for full resolution",
                  initialValue: serverModel.apiThumbnailPath,
                  onSave: (value) => serverModel.apiThumbnailPath = value,
                ),
              ),
              Selector<ServerModel, String>(
                selector: (_, model) => model.apiVideoPath,
                builder: (BuildContext context, String value, Widget? child) => EditTextListTile(
                  title: "API Video path",
                  description: "Empty for full resolution.\nUse /bestfit if Videos don't play",
                  initialValue: serverModel.apiVideoPath,
                  onSave: (value) => serverModel.apiVideoPath = value,
                ),
              ),
            ],
          ),
        ),
      ),
      TabData(
        title: const Tab(
          height: 46,
          child: Text("Misc"),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            spacing: 6,
            children: [
              ListTile(
                onTap: () {
                  Provider.of<ApiService>(context, listen: false).startIndexingJob();
                },
                title: Text("Start Indexing Job"),
                trailing: Icon(Icons.play_arrow),
              ),
              ClearCacheListTile(
                title: "Clear Media Cache",
                cacheSize: Downloads.getSize,
                memorySize: () => PiGallery2ImageCache.fullResCache.currentSizeBytes,
                onClear: Downloads.clear,
              ),
              ClearCacheListTile(
                title: "Clear Thumbnail Cache",
                cacheSize: Downloads.getThumbnailSize,
                memorySize: () => PiGallery2ImageCache.thumbCache.currentSizeBytes,
                onClear: Downloads.clearThumbnails,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 6, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetHandle(),
            CustomTabBarWidget(
              identifier: "Global",
              tabData: getTabs(context),
              isScrollable: true,
            ),
          ],
        ),
      ),
    );
  }
}
