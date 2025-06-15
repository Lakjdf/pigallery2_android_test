import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pigallery2_android/domain/models/item.dart' as models show Media;
import 'package:pigallery2_android/domain/models/media_background_mode.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/error_image.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoViewWidget extends StatefulWidget {
  final models.Media item;

  const VideoViewWidget({super.key, required this.item});

  @override
  State<VideoViewWidget> createState() => _VideoViewWidgetState();
}

class _VideoViewWidgetState extends State<VideoViewWidget> {
  bool error = false;
  StreamSubscription<String>? errorStream;
  late VideoModel videoModel;
  final Logger _logger = Logger("VideoViewWidget");

  @override
  void initState() {
    super.initState();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    videoModel = Provider.of<VideoModel>(context, listen: false);
    videoModel.registerMountedWidget(widget.item.id);
  }

  @override
  void dispose() {
    videoModel.unregisterMountedWidget(widget.item.id);
    errorStream?.cancel();
    super.dispose();
  }

  void listenForError(VideoControllerItem item) {
    errorStream ??= item.errorStream().listen((data) {
      _logger.warning("Received error from VideoController: $data");
      setState(() {
        error = true;
      });
    });
  }

  Widget buildPlaceholder() {
    return Stack(
      key: ValueKey(widget.item.id),
      fit: StackFit.passthrough,
      children: [ThumbnailImage(key: ObjectKey(widget.item), widget.item)],
    );
  }

  /// smoothly transition audio when swiping between videos.
  void onVisibilityChanged(double visibleFraction, VideoController videoController) {
    int target = 70; // volume of both videos when they are 50% visible
    double threshold = 0.2; // threshold at which the volume will be changed (0.2 -> at 50-+20% visibility)

    double lowerThreshold = 0.5 - threshold;
    double upperThreshold = 0.5 + threshold;
    if (visibleFraction >= lowerThreshold && visibleFraction <= 0.5) {
      // 0 at lowerThreshold and target at 0.5
      videoController.player.setVolume((visibleFraction - lowerThreshold) * target / threshold);
    } else if (visibleFraction > 0.5 && visibleFraction <= upperThreshold) {
      // target at 0.5 & 100 at upperThreshold
      videoController.player.setVolume((visibleFraction - 0.5) * (100 - target) / threshold + target);
    } else if (visibleFraction > upperThreshold) {
      videoController.player.setVolume(100);
    } else if (visibleFraction < lowerThreshold) {
      videoController.player.setVolume(0);
    }
  }

  Widget buildVideo(BuildContext context, VideoController videoController) {
    Size screenSize = MediaQuery.of(context).size;
    Size childSize;
    if (screenSize.aspectRatio > widget.item.aspectRatio) {
      childSize = Size(screenSize.height * widget.item.aspectRatio, screenSize.height);
    } else {
      childSize = Size(screenSize.width, screenSize.width / widget.item.aspectRatio);
    }
    return Center(
      child: VisibilityDetector(
        key: ValueKey("${widget.item.id}: $screenSize"),
        onVisibilityChanged: (info) => onVisibilityChanged(info.visibleFraction, videoController),
        child: Video(
          key: ValueKey("${widget.item.id}: $screenSize"),
          // has to include the screenSize; won't update on orientation changes otherwise
          controller: videoController,
          fit: BoxFit.contain,
          aspectRatio: widget.item.aspectRatio,
          controls: NoVideoControls,
          width: childSize.width,
          height: childSize.height,
          alignment: Alignment.center,
          pauseUponEnteringBackgroundMode: true,
          resumeUponEnteringForegroundMode: true,
        ),
      ),
    );
  }

  Widget buildVideoView(BuildContext context, VideoController videoController) {
    return Stack(
      children: [
        VideoViewWidgetBackground(item: widget.item, videoController: videoController),
        Selector<VideoModel, double>(
          selector: (context, model) => model.videoScale,
          builder: (context, scale, child) =>
              Transform.scale(transformHitTests: true, scale: scale, child: buildVideo(context, videoController)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controllerItem = context.select<VideoModel, VideoControllerItem?>(
      (model) => model.getVideoControllerItem(widget.item.id),
    );
    if (controllerItem == null) {
      return buildPlaceholder();
    }
    listenForError(controllerItem);
    if (error) {
      return const ErrorImage();
    }
    return FutureBuilder(
      future: controllerItem.controller.waitUntilFirstFrameRendered,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return buildPlaceholder();
        } else {
          return buildVideoView(context, controllerItem.controller);
        }
      },
    );
  }
}

class VideoViewWidgetBackground extends StatelessWidget {
  final models.Media item;
  final VideoController videoController;

  const VideoViewWidgetBackground({super.key, required this.item, required this.videoController});

  Widget buildVideo(BuildContext context, VideoController videoController) {
    Size screenSize = MediaQuery.of(context).size;
    Size childSize;
    if (screenSize.aspectRatio > item.aspectRatio) {
      childSize = Size(screenSize.height * item.aspectRatio, screenSize.height);
    } else {
      childSize = Size(screenSize.width, screenSize.width / item.aspectRatio);
    }
    return Center(
      child: Video(
        key: ValueKey("${item.id}: $screenSize background"),
        controller: videoController,
        fit: BoxFit.contain,
        aspectRatio: item.aspectRatio,
        controls: NoVideoControls,
        width: childSize.width,
        height: childSize.height,
        alignment: Alignment.center,
        pauseUponEnteringBackgroundMode: true,
        resumeUponEnteringForegroundMode: true,
      ),
    );
  }

  Widget buildAmbientBackground(BuildContext context) {
    return Selector<GlobalSettingsModel, int>(
      selector: (context, model) => model.mediaBackgroundBlur,
      builder: (context, blur, child) => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur.toDouble(), sigmaY: blur.toDouble(), tileMode: TileMode.decal),
        child: buildVideo(context, videoController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAmbientMode = context.select<GlobalSettingsModel, bool>(
      (it) => it.mediaBackgroundMode == MediaBackgroundMode.ambient,
    );
    if (isAmbientMode) {
      return buildAmbientBackground(context);
    }
    return SizedBox.shrink();
  }
}
