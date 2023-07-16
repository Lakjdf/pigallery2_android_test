import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/api.dart';
import 'package:pigallery2_android/core/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/core/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/views/fullscreen/fullscreen_view.dart';
import 'package:pigallery2_android/ui/views/gallery/directory_item.dart';
import 'package:pigallery2_android/ui/views/gallery/media_item.dart';
import 'package:pigallery2_android/ui/views/home_view.dart';
import 'package:provider/provider.dart';

class GalleryViewGridView extends StatefulWidget {
  final int stackPosition;
  final List<File> files;

  GalleryViewGridView(this.stackPosition, this.files) : super(key: ValueKey(stackPosition));

  @override
  State<GalleryViewGridView> createState() => _GalleryViewGridViewState();
}

class _GalleryViewGridViewState extends State<GalleryViewGridView> with TickerProviderStateMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 0.0);
  }

  void _scrollToShowedItem(BuildContext context, int currentIndex) {
    if (_scrollController.hasClients) {
      int crossAxisCount = Provider.of<GlobalSettingsModel>(context, listen: false).getGridCrossAxisCount(MediaQuery.of(context).orientation);
      int imageHeight = MediaQuery.of(context).size.width ~/ crossAxisCount;
      int imageTop = (currentIndex ~/ crossAxisCount) * imageHeight;
      double error = imageHeight * 0.3;

      if (max(imageTop - error, 0) < _scrollController.position.pixels) {
        // image is above visible
        double offset = imageTop - error;
        _scrollController.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.ease);
      } else if (imageTop + imageHeight + error > _scrollController.position.pixels + _scrollController.position.extentInside) {
        // image is below visible
        double offset = imageTop + imageHeight + 2 * error - _scrollController.position.extentInside;
        _scrollController.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.ease);
      }
    }
  }

  void openDirectory(BuildContext context, Directory directory) {
    Provider.of<HomeModel>(context, listen: false).addStack(directory);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: ((context) => HomeView(widget.stackPosition + 1)),
      ),
    );
  }

  void openFullscreen(BuildContext context, Media item) async {
    Media lastItem = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (BuildContext context, _, __) {
          return ChangeNotifierProvider(
            create: ((context) => FullscreenModel(item)),
            child: const FullscreenView(),
          );
        },
      ),
    );
    if (mounted) {
      _scrollToShowedItem(
        context,
        Provider.of<HomeModel>(context, listen: false).stateOf(widget.stackPosition).files.indexOf(lastItem),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    GlobalSettingsModel model = Provider.of<GlobalSettingsModel>(context);
    return OrientationBuilder(
      builder: (context, orientation) => GridView.builder(
        key: PageStorageKey(widget.stackPosition),
        controller: _scrollController,
        itemCount: widget.files.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: model.getGridCrossAxisCount(orientation),
          crossAxisSpacing: model.gridSpacing.toDouble(),
          mainAxisSpacing: model.gridSpacing.toDouble(),
          childAspectRatio: model.gridAspectRatio,
        ),
        itemBuilder: (BuildContext context, int index) {
          ApiService api = Provider.of<ApiService>(context, listen: false);
          String? thumbnailUrl = api.getThumbnailApiPath(widget.files[index]);
          return widget.files[index] is Directory
              ? DirectoryItem(
                  dir: widget.files[index] as Directory,
                  thumbnailUrl: thumbnailUrl,
                  borderRadius: model.gridRoundedCorners,
                  showDirectoryItemCount: model.showDirectoryItemCount,
                  onTap: () => openDirectory(context, widget.files[index] as Directory),
                )
              : MediaItem(
                  item: widget.files[index] as Media,
                  thumbnailUrl: thumbnailUrl,
                  borderRadius: model.gridRoundedCorners,
                  onTap: () => openFullscreen(context, widget.files[index] as Media),
                );
        },
      ),
    );
  }
}
