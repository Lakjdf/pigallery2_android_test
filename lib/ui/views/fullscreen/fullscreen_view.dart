import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/views/fullscreen/fullscreen_overlay.dart';
import 'package:pigallery2_android/ui/views/fullscreen/horizontal_carousel_wrapper.dart';
import 'package:pigallery2_android/ui/views/fullscreen/photo_view_widget.dart';
import 'package:pigallery2_android/ui/views/fullscreen/vertical_dismiss_wrapper.dart';
import 'package:pigallery2_android/ui/views/fullscreen/video_view_widget.dart';
import 'package:provider/provider.dart';

class FullscreenView extends StatefulWidget {
  const FullscreenView({Key? key}) : super(key: key);

  @override
  State<FullscreenView> createState() => _FullscreenViewState();
}

class _FullscreenViewState extends State<FullscreenView> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Directory directory = Provider.of<HomeModel>(context).currentDir!;
    return WillPopScope(
      onWillPop: (() {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
            overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
        Navigator.pop(context,
            Provider.of<FullscreenModel>(context, listen: false).currentItem);
        return Future.value(false);
      }),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FullscreenOverlay(
          child: PhotoViewGestureDetectorScope(
            axis: Axis.horizontal,
            child: PhotoViewGestureDetectorScope(
              axis: Axis.vertical,
              child: HorizontalCarouselWrapper(
                onPageChanged: (idx) {
                  Provider.of<FullscreenModel>(context, listen: false)
                          .currentItem =
                      Provider.of<HomeModel>(context, listen: false).media[idx];
                },
                initialIndex: Provider.of<HomeModel>(context, listen: false)
                    .media
                    .indexOf(
                        Provider.of<FullscreenModel>(context, listen: false)
                            .currentItem),
                builder: ((context, index) {
                  Media item = Provider.of<HomeModel>(context, listen: false)
                      .media[index];
                  return VerticalDismissWrapper(
                    onOpacityChanged: (val) {
                      Provider.of<FullscreenModel>(context, listen: false)
                          .opacity = val;
                    },
                    child: lookupMimeType(item.name)!.contains("video")
                        ? VideoViewWidget(
                            key: ValueKey(item.id),
                            directory: directory,
                            item: item)
                        : PhotoViewWidget(
                            key: ValueKey(item.id), directory, item),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
