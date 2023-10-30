import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/util/strings.dart';
import 'package:pigallery2_android/core/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/views/gallery/gallery_grid_view.dart';
import 'package:pigallery2_android/ui/views/top_picks/top_picks_container.dart';
import 'package:pigallery2_android/ui/views/top_picks/top_picks_view.dart';
import 'package:pigallery2_android/ui/widgets/loading_indicator.dart';
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
        action: error == Strings.errorNoServerConfigured
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

  Widget buildTopPicksView() {
    return Selector<HomeModel, String?>(
      selector: (context, model) => model.serverUrl,
      builder: (context, serverUrl, child) => Selector<GlobalSettingsModel, bool>(
        selector: (context, model) => model.showTopPicks,
        builder: (context, showTopPicks, child) {
          if (showTopPicks && serverUrl != null) {
            return const TopPicksView();
          } else {
            return const TopPicksContainer(expand: false);
          }
        },
      ),
    );
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
              if (widget.stackPosition == 0) ...[buildTopPicksView()],
              Flexible(
                child: Selector<HomeModel, List<File>>(
                  selector: (context, model) => model.stateOf(widget.stackPosition).files,
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
