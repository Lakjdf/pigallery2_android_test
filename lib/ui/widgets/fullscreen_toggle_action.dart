import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/viewmodels/global_settings_model.dart';
import 'package:provider/provider.dart';

class FullscreenToggleAction extends StatelessWidget {
  const FullscreenToggleAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<GlobalSettingsModel, bool>(
      selector: (context, model) => model.appInFullScreen,
      builder: (context, inFullScreen, child) => IconButton(
        onPressed: Provider.of<GlobalSettingsModel>(context, listen: false).toggleAppInFullScreen,
        icon: Icon(inFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
      ),
    );
  }
}
