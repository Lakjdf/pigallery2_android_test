import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/widgets/error_image.dart';
import 'package:pigallery2_android/ui/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';

class VideoViewWidget extends StatefulWidget {
  final Directory directory;
  final Media item;

  const VideoViewWidget({Key? key, required this.directory, required this.item})
      : super(key: key);

  @override
  State<VideoViewWidget> createState() => _VideoViewWidgetState();
}

class _VideoViewWidgetState extends State<VideoViewWidget> {
  late BetterPlayerController _betterPlayerController;
  late BetterPlayerConfiguration _config;
  bool isInitialized = false;

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }

  Widget buildPlaceholder() {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        ThumbnailImage(
            key: ObjectKey(widget.item),
            "${widget.directory.path}${widget.directory.name}/${widget.item.name}"),
        SpinKitRipple(
          color: Colors.white,
          size: 0.5 * MediaQuery.of(context).size.width,
        ),
      ],
    );
  }

  /// Mute if switching to next video.
  /// Inform [FullscreenModel] about controller change to update controls.
  void onVisibilityChanged(double visibleFraction) async {
    if (visibleFraction < 0.5) {
      _betterPlayerController.setVolume(0);
    } else {
      _betterPlayerController.setVolume(1);
      Provider.of<FullscreenModel>(context, listen: false)
          .addController(_betterPlayerController);
    }
  }

  @override
  void initState() {
    super.initState();
    _config = BetterPlayerConfiguration(
      controlsConfiguration: const BetterPlayerControlsConfiguration(
        showControls: false,
      ),
      autoPlay: true,
      looping: true,
      fit: BoxFit.contain,
      aspectRatio:
          widget.item.metadata.size.width / widget.item.metadata.size.height,
      errorBuilder: (context, error) {
        return const ErrorImage();
      },
      playerVisibilityChangedBehavior: onVisibilityChanged,
    );

    String src =
        "${Provider.of<HomeModel>(context, listen: false).serverUrl}/api/gallery/content/${widget.directory.path}${widget.directory.name}/${widget.item.name}";
    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      src,
      headers: Provider.of<HomeModel>(context, listen: false).getHeaders(),
    );

    _betterPlayerController = BetterPlayerController(
      _config,
      betterPlayerDataSource: betterPlayerDataSource,
    );
    _betterPlayerController.setControlsEnabled(false);
    _betterPlayerController.addEventsListener((p0) {
      if (p0.betterPlayerEventType == BetterPlayerEventType.initialized ||
          p0.betterPlayerEventType == BetterPlayerEventType.exception) {
        _betterPlayerController.setVolume(0);
        setState(() {
          isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double heightDiff = MediaQuery.of(context).size.width *
            (widget.item.metadata.size.height /
                widget.item.metadata.size.width) -
        MediaQuery.of(context).size.width;
    return Hero(
      // always use thumbnail for hero animation
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        final Hero hero = toHeroContext.widget as Hero;
        if (flightDirection == HeroFlightDirection.pop) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, value) {
              // make sure that thumbnail does not expand
              return FittedBox(
                fit: BoxFit.fitWidth,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width +
                      ((animation.value) * heightDiff),
                  child: hero.child,
                ),
              );
            },
          );
        }
        return hero.child;
      },
      tag: widget.item.id.toString(),
      child: isInitialized
          ? BetterPlayer(
              key: ValueKey(widget.item.id),
              controller: _betterPlayerController,
            )
          : buildPlaceholder(),
    );
  }
}
