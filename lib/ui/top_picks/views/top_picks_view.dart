import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/top_picks/viewmodels/top_picks_model.dart';
import 'package:pigallery2_android/ui/top_picks/views/top_picks_container.dart';
import 'package:pigallery2_android/ui/top_picks/views/top_picks_inner_view.dart';
import 'package:provider/provider.dart';

/// Wrapper Widget to show/hide the top picks.
class TopPicksView extends StatelessWidget {
  const TopPicksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<GlobalSettingsModel, bool>(
      selector: (context, model) => model.showTopPicks,
      builder: (context, showTopPicks, child) => Selector<TopPicksModel, bool>(
        selector: (context, model) => model.isUpToDateAndEmpty,
        builder: (context, contentIsEmpty, child) {
          if (showTopPicks && !contentIsEmpty) {
            return TopPicksContainer(expand: true, child: TopPicksInnerView());
          } else {
            return const TopPicksContainer(expand: false);
          }
        },
      ),
    );
  }
}
