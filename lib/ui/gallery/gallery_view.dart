import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/util/strings.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/gallery/gallery_grid_view.dart';
import 'package:pigallery2_android/ui/top_picks/views/top_picks_view.dart';
import 'package:pigallery2_android/ui/shared/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';

class GalleryView extends StatefulWidget {
  final int stackPosition;
  final VoidCallback showServerSettings;

  GalleryView(this.stackPosition, this.showServerSettings) : super(key: ValueKey(stackPosition));

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> with TickerProviderStateMixin {
  late Future<void>? fetchRequestTrigger;

  void checkForError(BuildContext context, String? error) {
    ScaffoldMessenger.of(context).clearSnackBars();
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    if (error != null) {
      SnackBar snackBar = SnackBar(
        action: error.contains(Strings.errorNoServerConfigured)
            ? SnackBarAction(
                label: "Add",
                onPressed: widget.showServerSettings,
              )
            : model.isSearching
                ? null
                : SnackBarAction(
                    label: "Reload",
                    onPressed: model.fetchItems,
                  ),
        content: Text(error),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 2,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        duration: const Duration(days: 365),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<HomeModel, bool>(
      selector: (context, model) => model.stateOf(widget.stackPosition).isLoading,
      builder: (context, isLoading, child) {
        if (isLoading) return const LoadingIndicator();
        return Selector<HomeModel, String?>(
          shouldRebuild: (String? previous, String? next) => true,
          selector: (context, model) => model.stateOf(widget.stackPosition).error,
          builder: (BuildContext context, error, Widget? child) {
            if (ModalRoute.of(context)?.isCurrent == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                checkForError(context, error);
              });
            }
            return child!;
          },
          child: Column(
            children: [
              if (widget.stackPosition == 0) const TopPicksView(),
              Flexible(
                child: Selector<HomeModel, List<Item>>(
                  selector: (context, model) => model.stateOf(widget.stackPosition).items,
                  builder: (context, files, child) {
                    return GalleryViewGridView(
                      widget.stackPosition,
                      files,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
