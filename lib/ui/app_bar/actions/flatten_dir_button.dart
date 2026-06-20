import 'package:flutter/material.dart';
import 'package:ionicons_plus/ionicons_plus.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_models_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:provider/provider.dart';

class FlattenDirButton extends StatelessWidget {
  const FlattenDirButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        GalleryModel model = context.read<TabModelsProvider>().model!;
        model.flattenDir();
        TabStateModel tabStateModel = context.read<TabStateModel>();
        navigatorKeys[tabStateModel.currentTab.pos]!.currentState!.pushNamed("", arguments: model.stackPosition);
      },
      icon: Icon(
        Ionicons.git_branch_outline,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
