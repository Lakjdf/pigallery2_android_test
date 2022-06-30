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
    HomeModel homeModel = Provider.of<HomeModel>(context, listen: false);
    FullscreenModel fullscreenModel = Provider.of<FullscreenModel>(context, listen: false);
    return WillPopScope(
      onWillPop: (() {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
        Navigator.pop(context, fullscreenModel.currentItem);
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
                onPageChanged: (idx) => fullscreenModel.currentItem = homeModel.media[idx],
                initialIndex: homeModel.media.indexOf(fullscreenModel.currentItem),
                builder: ((context, index) {
                  Media item = homeModel.media[index];
                  Directory directory = homeModel.currentDir!;
                  return VerticalDismissWrapper(
                    onOpacityChanged: (val) {
                      fullscreenModel.opacity = val;
                    },
                    child: lookupMimeType(item.name)!.contains("video")
                        ? VideoViewWidget(
                            key: ValueKey(item.id),
                            directory: directory,
                            item: item,
                          )
                        : PhotoViewWidget(
                            key: ValueKey(item.id),
                            directory,
                            item,
                          ),
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
