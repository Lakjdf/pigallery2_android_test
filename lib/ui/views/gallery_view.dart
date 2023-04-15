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
  final String baseDirectory;
  final List<File> files;

  GalleryViewGridView(this.baseDirectory, this.files) : super(key: ValueKey(baseDirectory));

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

      if (imageTop - error < _scrollController.position.pixels) {
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
    return GestureDetector(
      onTap: () {
        String target = "${widget.baseDirectory.isEmpty ? '' : '${widget.baseDirectory}/'}${dir.name}";
        Provider.of<HomeModel>(context, listen: false).addStack();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: ((context) => HomeView(target)),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              foregroundDecoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.6, 1.0],
                ),
              ),
              child: dir.preview == null
                  ? const ErrorImage()
                  : ThumbnailImage(
                      key: ObjectKey(dir),
                      dir,
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
          Provider.of<HomeModel>(context, listen: false).files.indexOf(lastItem),
        );
      },
      child: Hero(
        tag: item.id.toString(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: ThumbnailImage(
            key: ObjectKey(item),
            item,
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
                          color: Colors.white.withAlpha(175),
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
      key: PageStorageKey(widget.baseDirectory),
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
  final String baseDirectory;

  GalleryView(this.baseDirectory) : super(key: ValueKey(baseDirectory));

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> with TickerProviderStateMixin {
  late Future<void>? fetchRequestTrigger;

  @override
  void initState() {
    fetchRequestTrigger = Provider.of<HomeModel>(context, listen: false).fetchItems(baseDirectory: widget.baseDirectory);
    super.initState();
  }

  void checkForError(BuildContext context, HomeModel model) {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (model.error != null) {
      SnackBar snackBar = SnackBar(
        action: SnackBarAction(
          label: "Reload",
          onPressed: () => model.reset(),
        ),
        content: Text(
          model.error!,
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
    return FutureBuilder(
      future: fetchRequestTrigger,
      builder: (context, snapshot) {
        HomeModel model = Provider.of<HomeModel>(context, listen: true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          checkForError(context, model);
        });
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: SpinKitSpinningLines(
              color: Theme.of(context).colorScheme.secondary,
            ),
          );
        }
        return GalleryViewGridView(
          widget.baseDirectory,
          model.files,
        );
      },
    );
  }
}
