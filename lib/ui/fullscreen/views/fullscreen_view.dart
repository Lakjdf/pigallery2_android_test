import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/fullscreen/views/overlay/fullscreen_overlay.dart';
import 'package:pigallery2_android/ui/shared/widgets/horizontal_carousel_wrapper.dart';
import 'package:pigallery2_android/ui/fullscreen/views/photo_view_widget.dart';
import 'package:pigallery2_android/ui/fullscreen/views/vertical_dismiss_wrapper.dart';
import 'package:pigallery2_android/ui/fullscreen/views/video_view_widget.dart';
import 'package:provider/provider.dart';

class FullscreenView extends StatefulWidget {
  final Media item;

  const FullscreenView(this.item, {super.key});

  @override
  State<FullscreenView> createState() => _FullscreenViewState();
}

class _FullscreenViewState extends State<FullscreenView> {
  Widget buildItemWithHero(BuildContext context, Media item) {
    double screenWidth = MediaQuery.of(context).size.width;
    double heightDiff = screenWidth * (item.dimension.height / item.dimension.width) - screenWidth;
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
          context.read<FullscreenModel>().heroAnimationProgress = animation.value;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GlobalSettingsModel>().enableFullScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Media> media = Provider.of<HomeModel>(context, listen: false).currentState.media;
    FullscreenModel fullscreenModel = Provider.of<FullscreenModel>(context, listen: false);
    fullscreenModel.media = media;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      fullscreenModel.currentPage = media.indexOf(widget.item);
    });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: ((bool didPop, _) {
        if (didPop) return;
        GlobalSettingsModel model = context.read<GlobalSettingsModel>();
        if (!model.appInFullScreen) {
          model.disableFullScreen();
        }
        Navigator.pop(context);
      }),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FullscreenOverlay(
          child: HorizontalCarouselWrapper(
            onPageChanged: (idx) => fullscreenModel.currentPage = idx,
            initialIndex: media.indexOf(widget.item),
            itemCount: media.length,
            builder: ((context, index) {
              return PhotoViewGestureDetectorScope(
                axis: Axis.horizontal,
                child: VerticalDismissWrapper(
                  onOpacityChanged: (val) => context.read<FullscreenModel>().opacity = val,
                  child: buildItemWithHero(context, media[index]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
