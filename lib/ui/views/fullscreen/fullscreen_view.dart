import 'package:flutter/material.dart';
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
  Widget buildItemWithHero(BuildContext context, Media item) {
    FullscreenModel model = Provider.of<FullscreenModel>(context, listen: false);
    double screenWidth = MediaQuery.of(context).size.width;
    double heightDiff = screenWidth * (item.metadata.size.height / item.metadata.size.width) - screenWidth;
    return Hero(
      // always use thumbnail for hero animation
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        animation.addListener(() {
          model.heroAnimationProgress = animation.value;
        });
        final Hero hero = toHeroContext.widget as Hero;
        if (flightDirection == HeroFlightDirection.pop) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, value) {
              // make sure that thumbnail does not expand
              return FittedBox(
                fit: BoxFit.fitWidth,
                child: SizedBox(
                  width: screenWidth,
                  height: screenWidth + ((animation.value) * heightDiff),
                  child: hero.child,
                ),
              );
            },
          );
        }
        return hero.child;
      },
      tag: item.id.toString(),
      child: lookupMimeType(item.name)!.contains("video")
          ? VideoViewWidget(
              key: ValueKey(item.id),
              item: item,
            )
          : PhotoViewWidget(
              key: ValueKey(item.id),
              item,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    model.enableFullScreen();
    List<Media> media = model.currentState.media;
    FullscreenModel fullscreenModel = Provider.of<FullscreenModel>(context, listen: false);
    return WillPopScope(
      onWillPop: (() {
        if (!model.appInFullScreen) {
          model.disableFullScreen();
        }
        Navigator.pop(context, fullscreenModel.currentItem);
        return Future.value(false);
      }),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FullscreenOverlay(
          child: HorizontalCarouselWrapper(
            onPageChanged: (idx) => fullscreenModel.currentItem = media[idx],
            initialIndex: media.indexOf(fullscreenModel.currentItem),
            builder: ((context, index) => PhotoViewGestureDetectorScope(
                  axis: Axis.horizontal,
                  child: VerticalDismissWrapper(
                    onOpacityChanged: (val) => fullscreenModel.opacity = val,
                    child: buildItemWithHero(context, media[index]),
                  ),
                )),
          ),
        ),
      ),
    );
  }
}
