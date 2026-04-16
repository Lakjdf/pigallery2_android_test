import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/web_view_model.dart';
import 'package:pigallery2_android/ui/settings/views/settings_bottom_sheet.dart';
import 'package:pigallery2_android/ui/top_picks/viewmodels/top_picks_model.dart';
import 'package:provider/provider.dart';

void showServerSettings(BuildContext context) {
  ServerRepository serverRepository = context.read();
  String? previousServerUrl = serverRepository.serverUrl;
  
  showModalBottomSheet<int>(
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SettingsBottomSheet(),
    );
    },
    useRootNavigator: true,
  ).whenComplete(() {
    if (!context.mounted) return;
    if (previousServerUrl == serverRepository.serverUrl) return;
    context.read<TabNavigatorModel>().reset();
    context.read<WebViewModel>().updateUrl();
    context.read<TopPicksModel>().refresh();
  });
}
