import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/storage/pigallery2_image_cache.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/download_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_scroll_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/seeking/video_seek_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/seeking/video_seek_preview_model.dart';
import 'package:pigallery2_android/ui/home/views/error_screen.dart';
import 'package:pigallery2_android/ui/home/views/refresh_wrapper.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/fullscreen/views/fullscreen_view.dart';
import 'package:pigallery2_android/ui/gallery/directory_item.dart';
import 'package:pigallery2_android/ui/gallery/media_item.dart';
import 'package:pigallery2_android/ui/home/views/glass_nav_bar.dart';
import 'package:provider/provider.dart';

class GalleryViewGridView extends StatefulWidget {
  final int stackPosition;
  final List<Item> items;

  GalleryViewGridView(this.stackPosition, this.items) : super(key: ValueKey(items));

  @override
  State<GalleryViewGridView> createState() => _GalleryViewGridViewState();
}

class _GalleryViewGridViewState extends State<GalleryViewGridView> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late List<Item> items;
  int chunkSize = 100;

  @override
  void initState() {
    items = widget.items.take(chunkSize).toList();
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 0.0);
    _scrollController.addListener(() {
      // adding items dynamically based on scroll position
      // otherwise GridView.builder initializes all widgets upfront, which may take a long time
      if (_scrollController.position.extentAfter < 500) {
        if (items.length < widget.items.length) {
          setState(() {
            items.addAll(widget.items.skip(items.length).take(chunkSize));
          });
        }
      }
    });
  }

  double _getImageHeight(BuildContext context) {
    GlobalSettingsModel settingsModel = context.read<GlobalSettingsModel>();
    int crossAxisCount = settingsModel.getGridCrossAxisCount(MediaQuery.of(context).orientation);
    int spacing = settingsModel.gridSpacing;
    double aspectRatio = settingsModel.gridAspectRatio;

    // total width decreases by (crossAxisCount - 1) * spacing
    // (crossAxisCount - 1) * spacing / crossAxisCount
    double widthDecrease = spacing - spacing / crossAxisCount;

    double imageWidth = MediaQuery.of(context).size.width / crossAxisCount;
    // subtract widthDecrease to keep square
    double correctedHeight = (imageWidth - widthDecrease) / aspectRatio;
    return correctedHeight;
  }

  void _scrollToShowedItem(BuildContext context, int currentIndex) {
    if (_scrollController.hasClients) {
      if (!_scrollController.position.hasContentDimensions) return;
      if (_scrollController.position.maxScrollExtent == 0) return; // too few elements to scroll

      GlobalSettingsModel settingsModel = context.read<GlobalSettingsModel>();
      int crossAxisCount = settingsModel.getGridCrossAxisCount(MediaQuery.of(context).orientation);
      int spacing = settingsModel.gridSpacing;

      int row = currentIndex ~/ crossAxisCount;
      double imageHeight = _getImageHeight(context);
      double imageTop = row * (imageHeight + spacing);

      double error = imageHeight * 0.3; // how much space should be kept to top/bottom of screen

      if (max(imageTop - error, 0) < _scrollController.position.pixels) {
        // image is above visible
        double offset = imageTop - error;
        _scrollController.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.ease);
      } else if (imageTop + imageHeight + error >
          _scrollController.position.pixels + _scrollController.position.extentInside) {
        // image is below visible
        double offset = imageTop + imageHeight + error - _scrollController.position.extentInside;
        _scrollController.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.ease);
      }
    }
  }

  void openDirectory(BuildContext context, Directory directory) {
    context.read<GalleryModel>().addStack(directory);
    Navigator.of(context).pushNamed("", arguments: widget.stackPosition + 1);
  }

  void openFullscreen(BuildContext context, List<Item> items, int totalIndex) async {
    Media media = items[totalIndex] as Media;
    // skip directories since there's no fullscreen view for them
    int index = totalIndex - items.whereType<Directory>().length;

    FullscreenScrollModel scrollModel = FullscreenScrollModel();
    final subscription = scrollModel.getCurrentIndex().listen((index) {
      if (!context.mounted) return;
      _scrollToShowedItem(context, index);
    });
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (BuildContext context, _, _) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: ((context) {
                  return DownloadModel(Provider.of<MediaRepository>(context, listen: false), media);
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
                    index,
                    scrollModel,
                  );
                }),
              ),
              ChangeNotifierProvider(
                create: ((context) {
                  return VideoSeekPreviewModel(context.read(), context.read(), context.read());
                }),
              ),
              ChangeNotifierProvider(
                create: ((context) {
                  return VideoSeekModel(context.read(), context.read());
                }),
              ),
            ],
            child: FullscreenView(media),
          );
        },
      ),
    );
    subscription.cancel();
    PiGallery2ImageCache.fullResCache.clearLiveImages();
    PiGallery2ImageCache.fullResCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    GlobalSettingsModel model = Provider.of<GlobalSettingsModel>(context);
    return OrientationBuilder(
      builder: (context, orientation) => GalleryErrorScreen(
        child: RefreshWrapper(
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.paddingOf(context).left,
              MediaQuery.paddingOf(context).top,
              MediaQuery.paddingOf(context).right,
              MediaQuery.paddingOf(context).bottom +
                  GlassNavBarTheme.barHeight +
                  GlassNavBarTheme.bottomPadding +
                  16, // extra padding to clear the nav bar properly
            ),
            key: PageStorageKey(widget.stackPosition),
            controller: _scrollController,
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: model.getGridCrossAxisCount(orientation),
              crossAxisSpacing: model.gridSpacing.toDouble(),
              mainAxisSpacing: model.gridSpacing.toDouble(),
              childAspectRatio: model.gridAspectRatio,
            ),
            itemBuilder: (BuildContext context, int index) {
              Item item = items[index];
              return item is Directory
                  ? DirectoryItem(
                      dir: item,
                      borderRadius: model.gridRoundedCorners,
                      showDirectoryItemCount: model.showDirectoryItemCount,
                      onTap: () => openDirectory(context, item),
                    )
                  : MediaItem(
                      item: item as Media,
                      borderRadius: model.gridRoundedCorners,
                      onTap: () => openFullscreen(context, items, index),
                    );
            },
          ),
        ),
      ),
    );
  }
}
