import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/error_image.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';

class VideoViewWidget extends StatefulWidget {
  final Media item;

  const VideoViewWidget({super.key, required this.item});

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
        SpinKitRipple(color: Theme.of(context).colorScheme.onSurfaceVariant, size: 0.5 * MediaQuery.of(context).size.width),
      ],
    );
  }

  /// Mute if switching to next video.
  /// Inform [VideoModel] about controller change to update controls.
  void onVisibilityChanged(double visibleFraction) async {
    var fullScreenModel = Provider.of<VideoModel>(context, listen: false);
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
      aspectRatio: widget.item.dimension.width / widget.item.dimension.height,
      errorBuilder: (context, error) => const ErrorImage(),
      playerVisibilityChangedBehavior: onVisibilityChanged,
    );

    MediaRepository repository = Provider.of<MediaRepository>(context, listen: false);
    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      repository.getMediaApiPath(widget.item),
      headers: repository.headers,
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
