import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/media_background_mode.dart';
import 'package:pigallery2_android/ui/server_settings/views/bottom_sheet_handle.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/custom_tabbar.dart';
import 'package:provider/provider.dart';

class MediaSettingsBottomSheet extends StatelessWidget {
  const MediaSettingsBottomSheet({super.key});

  List<TabData> getTabs(BuildContext context) {
    GlobalSettingsModel model = Provider.of<GlobalSettingsModel>(context, listen: false);
    return [
      TabData(
        title: const Tab(
          child: Text("Background"),
        ),
        content: Column(
          spacing: 6,
          children: [
            Selector<GlobalSettingsModel, MediaBackgroundMode>(
              selector: (context, model) => model.mediaBackgroundMode,
              builder: (BuildContext context, mode, Widget? child) {
                return ListTile(
                  title: const Text("Mode"),
                  subtitle: Row(
                    mainAxisSize: MainAxisSize.max,
                    spacing: 20,
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Container(width: double.infinity, alignment: Alignment.center, child: Text(MediaBackgroundMode.off.getDisplayName())),
                          selected: mode == MediaBackgroundMode.off,
                          onSelected: (selected) =>
                              selected ? Provider.of<GlobalSettingsModel>(context, listen: false).mediaBackgroundMode = MediaBackgroundMode.off : null,
                        ),
                      ),
                      Expanded(
                        child: ChoiceChip(
                          label: Container(width: double.infinity, alignment: Alignment.center, child: Text(MediaBackgroundMode.ambient.getDisplayName())),
                          selected: mode == MediaBackgroundMode.ambient,
                          onSelected: (selected) =>
                              selected ? Provider.of<GlobalSettingsModel>(context, listen: false).mediaBackgroundMode = MediaBackgroundMode.ambient : null,
                        ),
                      ),
                      Expanded(
                        child: ChoiceChip(
                          label: Container(width: double.infinity, alignment: Alignment.center, child: Text(MediaBackgroundMode.fill.getDisplayName())),
                          selected: mode == MediaBackgroundMode.fill,
                          onSelected: (selected) =>
                              selected ? Provider.of<GlobalSettingsModel>(context, listen: false).mediaBackgroundMode = MediaBackgroundMode.fill : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Selector<GlobalSettingsModel, int>(
              selector: (context, model) => model.mediaBackgroundBlur,
              builder: (BuildContext context, blur, Widget? child) => ListTile(
                title: Text("Intensity: $blur (Default 45)"),
                subtitle: Slider(
                  min: 0,
                  max: 100,
                  value: blur.toDouble(),
                  onChanged: (double value) => model.mediaBackgroundBlur = value.round(),
                ),
              ),
            ),
          ],
        ),
      ),
      TabData(
        title: const Tab(
          child: Text("Video"),
        ),
        content: Column(
          spacing: 6,
          children: [
            Selector<GlobalSettingsModel, bool>(
              selector: (context, model) => model.showVideoSeekPreview,
              builder: (BuildContext context, showVideoSeekPreview, Widget? child) {
                return ListTile(
                  title: const Text("Preview while seeking videos"),
                  subtitle: const Text("Requires PiGallery2 extension to be installed"),
                  onTap: () {
                    Provider.of<GlobalSettingsModel>(context, listen: false).showVideoSeekPreview = !showVideoSeekPreview;
                  },
                  trailing: IgnorePointer(
                    child: Switch(
                      value: showVideoSeekPreview,
                      onChanged: (_) {},
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 6, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomSheetHandle(),
          CustomTabBarWidget(
            identifier: "Media",
            tabData: getTabs(context),
            isScrollable: true,
          ),
        ],
      ),
    );
  }
}
