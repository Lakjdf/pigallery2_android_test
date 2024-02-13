import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/download_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/fullscreen/views/fullscreen_view.dart';
import 'package:pigallery2_android/ui/gallery/directory_item.dart';
import 'package:pigallery2_android/ui/gallery/media_item.dart';
import 'package:pigallery2_android/ui/home/views/home_view.dart';
import 'package:provider/provider.dart';

class GalleryViewGridView extends StatefulWidget {
  final int stackPosition;
  final List<Item> items;

  GalleryViewGridView(this.stackPosition, this.items) : super(key: ValueKey(stackPosition));

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
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: ((context) => VideoModel()),
              ),
              ChangeNotifierProvider(
                create: ((context) {
                  return DownloadModel(
                    Provider.of<MediaRepository>(context, listen: false),
                    item,
                  );
                }),
              ),
              ChangeNotifierProvider(
                create: ((context) {
                  return FullscreenModel(
                    [
                      Provider.of<VideoModel>(context, listen: false),
                      Provider.of<PhotoModel>(context, listen: false),
                      Provider.of<DownloadModel>(context, listen: false),
                    ],
                    item,
                  );
                }),
              )
            ],
            child: FullscreenView(item),
          );
        },
      ),
    );
    if (mounted) {
      _scrollToShowedItem(
        context,
        context.read<HomeModel>().stateOf(widget.stackPosition).items.indexOf(lastItem),
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
        itemCount: widget.items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: model.getGridCrossAxisCount(orientation),
          crossAxisSpacing: model.gridSpacing.toDouble(),
          mainAxisSpacing: model.gridSpacing.toDouble(),
          childAspectRatio: model.gridAspectRatio,
        ),
        itemBuilder: (BuildContext context, int index) {
          return widget.items[index] is Directory
              ? DirectoryItem(
                  dir: widget.items[index] as Directory,
                  borderRadius: model.gridRoundedCorners,
                  showDirectoryItemCount: model.showDirectoryItemCount,
                  onTap: () => openDirectory(context, widget.items[index] as Directory),
                )
              : MediaItem(
                  item: widget.items[index] as Media,
                  borderRadius: model.gridRoundedCorners,
                  onTap: () => openFullscreen(context, widget.items[index] as Media),
                );
        },
      ),
    );
  }
}
