import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/gallery/gallery_grid_view.dart';
import 'package:pigallery2_android/ui/top_picks/views/top_picks_view.dart';
import 'package:pigallery2_android/ui/shared/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';

class GalleryView extends StatelessWidget {
  // Static so the TopPicksView element is reparented (state preserved) when
  // GalleryViewGridView is rebuilt with a new ValueKey on items change.
  // Only one GalleryView at a time renders TopPicks (home tab, stackPosition 0),
  // so a single shared key is safe.
  static final GlobalKey _topPicksKey = GlobalKey();

  final int stackPosition;

  GalleryView(this.stackPosition) : super(key: ValueKey(stackPosition));

  Widget buildBody(BuildContext context) {
    final showTopPicks = stackPosition == 0 && context.read<TabEntry>() == TabEntry.home;
    return Selector<GalleryModel, List<Item>>(
      selector: (context, model) => model.stateOf(stackPosition).items,
      builder: (context, files, child) {
        return GalleryViewGridView(
          stackPosition,
          files,
          leading: showTopPicks ? TopPicksView(key: _topPicksKey) : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Selector<GalleryModel, bool>(
        selector: (context, model) => model.stateOf(stackPosition).isLoading,
        builder: (context, isLoading, child) {
          if (isLoading) return const LoadingIndicator();
          return buildBody(context);
        },
      ),
    );
  }
}
