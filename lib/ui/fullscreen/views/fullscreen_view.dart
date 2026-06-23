import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/fullscreen/views/media_item_background.dart';
import 'package:pigallery2_android/ui/fullscreen/views/overlay/fullscreen_overlay.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_models_provider.dart';
import 'package:pigallery2_android/ui/shared/widgets/horizontal_carousel_wrapper.dart';
import 'package:pigallery2_android/ui/fullscreen/views/photo_view_widget.dart';
import 'package:pigallery2_android/ui/fullscreen/views/vertical_dismiss_wrapper.dart';
import 'package:pigallery2_android/ui/fullscreen/views/video_view_widget.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';

class FullscreenView extends StatefulWidget {
  final Media item;

  const FullscreenView(this.item, {super.key});

  @override
  State<FullscreenView> createState() => _FullscreenViewState();
}

class _FullscreenViewState extends State<FullscreenView> {
  late final VideoModel _videoModel;

  Widget buildItemWithHero(BuildContext context, Media item) {
    double screenWidth = PlatformDispatcher.instance.views.first.physicalSize.width;
    double heightDiff = screenWidth * (item.dimension.height / item.dimension.width) - screenWidth;
    return Hero(
      flightShuttleBuilder:
          (
            BuildContext flightContext,
            Animation<double> animation,
            HeroFlightDirection flightDirection,
            BuildContext fromHeroContext,
            BuildContext toHeroContext,
          ) {
            animation.addListener(() {
              context.read<FullscreenModel>().heroAnimationProgress = animation.value;
            });
            final Hero hero = toHeroContext.widget as Hero;
            if (flightDirection == HeroFlightDirection.pop) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
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
      transitionOnUserGestures: true,
      tag: item.id.toString(),
      child: item.isVideo
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
  void initState() {
    super.initState();
    _videoModel = context.read<VideoModel>();
    final media = context.read<TabModelsProvider>().model?.currentState.media ?? [];
    _videoModel.pageScrollPosition.value = media.indexOf(widget.item).toDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemUi.setFullscreenSystemBarColors(context);
    });
  }

  @override
  void dispose() {
    _videoModel.disposeDetached();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Media> media = context.read<TabModelsProvider>().model?.currentState.media ?? [];
    FullscreenModel fullscreenModel = Provider.of<FullscreenModel>(context, listen: false);
    VideoModel videoModel = Provider.of<VideoModel>(context, listen: false);
    fullscreenModel.media = media;
    int initialIndex = media.indexOf(widget.item);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      fullscreenModel.currentPage = initialIndex;
    });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: ((bool didPop, _) {
        if (didPop) return;
        fullscreenModel.close();
        SystemUi.setDefaultSystemBarColors(context);
        SystemUi.showSystemBars();
        Navigator.pop(context);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const FullscreenSharedBackground(),
            FullscreenOverlay(
              key: ValueKey(widget.item.id),
              viewPadding: SystemUi.getPadding(),
              child: HorizontalCarouselWrapper(
                onPageChanged: (idx) => fullscreenModel.currentPage = idx,
                onPageScroll: (pos) => videoModel.pageScrollPosition.value = pos,
                initialIndex: initialIndex,
                itemCount: media.length,
                builder: ((context, index) {
                  return PhotoViewGestureDetectorScope(
                    axis: Axis.horizontal,
                    child: ClipRect(
                      child: VerticalDismissWrapper(
                        onOpacityChanged: (val) => context.read<FullscreenModel>().opacity = val,
                        background: MediaItemBackground(item: media[index]),
                        child: buildItemWithHero(context, media[index]),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
