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
  final Media item;

  const VideoViewWidget({Key? key, required this.item}) : super(key: key);

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
        ThumbnailImage(key: ObjectKey(widget.item), widget.item),
        SpinKitRipple(color: Colors.white, size: 0.5 * MediaQuery.of(context).size.width),
      ],
    );
  }

  /// Mute if switching to next video.
  /// Inform [FullscreenModel] about controller change to update controls.
  void onVisibilityChanged(double visibleFraction) async {
    var fullScreenModel = Provider.of<FullscreenModel>(context, listen: false);
    double scaledThreshold = 1 / (2 * fullScreenModel.videoScale);
    // VisibilityDetector does not handle scaling properly; Add scaling to visibleFraction manually
    double fixedVisibleFraction = visibleFraction * fullScreenModel.videoScale;
    if (fixedVisibleFraction < scaledThreshold) {
      _betterPlayerController.setVolume(0);
    } else {
      _betterPlayerController.setVolume(1);
      fullScreenModel.addController(_betterPlayerController);
    }
  }

  @override
  void initState() {
    super.initState();
    _config = BetterPlayerConfiguration(
      controlsConfiguration: const BetterPlayerControlsConfiguration(
        showControls: false,
        backgroundColor: Colors.transparent,
      ),
      autoPlay: true,
      looping: true,
      fit: BoxFit.contain,
      aspectRatio: widget.item.metadata.size.width / widget.item.metadata.size.height,
      errorBuilder: (context, error) => const ErrorImage(),
      playerVisibilityChangedBehavior: onVisibilityChanged,
    );

    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      model.getItemPath(widget.item),
      headers: model.getHeaders(),
    );

    _betterPlayerController = BetterPlayerController(
      _config,
      betterPlayerDataSource: betterPlayerDataSource,
    );
    _betterPlayerController.setControlsEnabled(false);
    _betterPlayerController.addEventsListener((p0) {
      if (p0.betterPlayerEventType == BetterPlayerEventType.initialized || p0.betterPlayerEventType == BetterPlayerEventType.exception) {
        _betterPlayerController.setVolume(0);
        setState(() {
          isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return isInitialized
        ? BetterPlayer(
            key: ValueKey(widget.item.id),
            controller: _betterPlayerController,
          )
        : buildPlaceholder();
  }
}
