import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mime/mime.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/views/fullscreen/fullscreen_view.dart';
import 'package:pigallery2_android/ui/views/home_view.dart';
import 'package:pigallery2_android/ui/widgets/error_image.dart';
import 'package:pigallery2_android/ui/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';

const double borderRadius = 0; //15
const double gridSpacing = 0; //9

class GalleryViewGridView extends StatefulWidget {
  final int stackPosition;
  final List<File> files;

  GalleryViewGridView(this.stackPosition, this.files) : super(key: ValueKey(stackPosition));

  @override
  State<GalleryViewGridView> createState() => _GalleryViewGridViewState();
}

class _GalleryViewGridViewState extends State<GalleryViewGridView> with TickerProviderStateMixin {
  late ScrollController _scrollController;

  bool isVideo(Media item) {
    return lookupMimeType(item.name)!.contains("video");
  }

  int getCrossAxisCount(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape ? 5 : 3;
  }

  void _scrollToShowedItem(BuildContext context, int currentIndex) {
    if (_scrollController.hasClients) {
      int crossAxisCount = getCrossAxisCount(context);
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

  Widget directoryItem(context, Directory dir) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    return GestureDetector(
      onTap: () {
        model.addStack(dir.name);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: ((context) => HomeView(widget.stackPosition + 1)),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Theme.of(context).colorScheme.surface],
                  stops: const [0.6, 1.0],
                ),
              ),
              child: dir.preview == null
                  ? const ErrorImage()
                  : ThumbnailImage(
                      key: ObjectKey(dir),
                      model.getThumbnailApiPath(model.stateOf(widget.stackPosition), dir),
                      fit: BoxFit.cover,
                    ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 0.0),
                  child: Text(
                    dir.name,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6.0, 3.0, 6.0, 6.0),
                  child: Text(
                    dir.mediaCount.toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget mediaItem(context, Media item) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    return GestureDetector(
      onTap: () async {
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
              }),
        );
        _scrollToShowedItem(
          context,
          model.stateOf(widget.stackPosition).files.indexOf(lastItem),
        );
      },
      child: Hero(
        tag: item.id.toString(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: ThumbnailImage(
            key: ObjectKey(item),
            model.getThumbnailApiPath(model.stateOf(widget.stackPosition), item),
            imageBuilder: (context, imageProvider) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                  isVideo(item)
                      ? Icon(
                          Icons.play_arrow,
                          size: 70,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(175),
                        )
                      : Container(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: PageStorageKey(widget.stackPosition),
      controller: _scrollController,
      itemCount: widget.files.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: getCrossAxisCount(context),
        crossAxisSpacing: gridSpacing,
        mainAxisSpacing: gridSpacing,
      ),
      itemBuilder: (BuildContext context, int index) {
        return widget.files[index].runtimeType == Directory
            ? directoryItem(
                context,
                widget.files[index] as Directory,
              )
            : mediaItem(
                context,
                widget.files[index] as Media,
              );
      },
    );
  }
}

class GalleryView extends StatefulWidget {
  final int stackPosition;

  GalleryView(this.stackPosition) : super(key: ValueKey(stackPosition));

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> with TickerProviderStateMixin {
  late Future<void>? fetchRequestTrigger;

  @override
  void initState() {
    super.initState();
  }

  void checkForError(BuildContext context, String? error) {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (error != null) {
      SnackBar snackBar = SnackBar(
        action: SnackBarAction(
          label: "Reload",
          onPressed: () => Provider.of<HomeModel>(context, listen: false).fetchItems(),
        ),
        content: Text(
          error,
        ),
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
        if (isLoading) {
          return Center(
            child: SpinKitSpinningLines(
              color: Theme.of(context).colorScheme.secondary,
            ),
          );
        } else {
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
            child: Selector<HomeModel, List<File>>(
              selector: (context, model) => model.stateOf(widget.stackPosition).files,
              builder: (context, files, child) {
                return GalleryViewGridView(
                  widget.stackPosition,
                  files,
                );
              },
            ),
          );
        }
      },
    );
  }
}
