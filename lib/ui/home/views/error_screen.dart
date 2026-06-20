import 'package:flutter/material.dart';
import 'package:ionicons_plus/ionicons_plus.dart';
import 'package:pigallery2_android/ui/app_bar/actions/server_settings_action.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_models_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/util/strings.dart';
import 'package:provider/provider.dart';

class GalleryErrorScreen extends StatelessWidget {
  final Widget child;

  const GalleryErrorScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    String? error = context.select<TabModelsProvider, String?>((it) => it.model?.currentState.error);
    if (error != null) {
      return ErrorScreen(error: error);
    }
    return child;
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  Widget _buildAction(BuildContext context) {
    if (error.contains(Strings.errorNoServerConfigured)) {
      return Text("Tab to add", style: TextStyle(color: Theme.of(context).colorScheme.primary));
    }
    return Text("Tab to retry", style: TextStyle(color: Theme.of(context).colorScheme.primary));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Material(
        child: InkResponse(
          radius: 48,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          splashColor: Theme.of(context).colorScheme.primary,
          onTap: () {
            if (error.contains(Strings.errorNoServerConfigured)) {
              showServerSettings(context);
            } else {
              context.read<TabNavigatorModel>().refresh();
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ionicons.warning_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(error, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              _buildAction(context),
            ],
          ),
        ),
      ),
    );
  }
}
