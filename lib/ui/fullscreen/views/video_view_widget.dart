import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:pigallery2_android/domain/models/item.dart' as models show Media;
import 'package:pigallery2_android/domain/models/media_background_mode.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_controller.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/error_image.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';

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

  Widget buildVideo(BuildContext context, AppVideoController videoController) {
    Size screenSize = MediaQuery.of(context).size;
    Size childSize;
    // prefer aspectRatio of the player over metadata
    double aspectRatio = videoController.player.aspectRatio ?? widget.item.aspectRatio;
    if (screenSize.aspectRatio > aspectRatio) {
      childSize = Size(screenSize.height * aspectRatio, screenSize.height);
    } else {
      childSize = Size(screenSize.width, screenSize.width / aspectRatio);
    }
    // required for the video widget to update its dimensions; defaults to source metadata
    videoController.setSize(width: childSize.width.toInt(), height: childSize.height.toInt()).catchError((_) => {});
    return Center(
      child: videoController.buildView(
        // has to include the screenSize; won't update on orientation changes otherwise
        key: ValueKey("${widget.item.id}: ${screenSize.hashCode}"),
        fit: BoxFit.contain,
        aspectRatio: aspectRatio,
        width: childSize.width,
        height: childSize.height,
        alignment: Alignment.center,
      ),
    );
  }

  Widget buildVideoView(BuildContext context, AppVideoController videoController) {
    return Selector<VideoModel, double>(
      selector: (context, model) => model.videoScale,
      builder: (context, scale, child) => Transform.scale(
        transformHitTests: true,
        scale: scale,
        child: Stack(
          children: [
            VideoViewWidgetBackground(item: widget.item, videoController: videoController),
            buildVideo(context, videoController),
          ],
        ),
      ),
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

    return ListenableBuilder(
      listenable: controllerItem,
      builder: ((context, _) {
        if (controllerItem.firstFrameRendered) {
          return buildVideoView(context, controllerItem.controller);
        } else {
          return buildPlaceholder();
        }
      }),
    );
  }
}

class VideoViewWidgetBackground extends StatelessWidget {
  final models.Media item;
  final AppVideoController videoController;

  const VideoViewWidgetBackground({super.key, required this.item, required this.videoController});

  Widget buildVideo(BuildContext context, AppVideoController videoController) {
    Size screenSize = MediaQuery.of(context).size;
    Size childSize;
    // prefer aspectRatio of the player over metadata
    double aspectRatio = videoController.player.aspectRatio ?? item.aspectRatio;
    if (screenSize.aspectRatio > aspectRatio) {
      childSize = Size(screenSize.height * aspectRatio, screenSize.height);
    } else {
      childSize = Size(screenSize.width, screenSize.width / aspectRatio);
    }
    return Center(
      child: videoController.buildView(
        key: ValueKey("${item.id}: ${screenSize.hashCode} background"),
        fit: BoxFit.contain,
        aspectRatio: aspectRatio,
        width: childSize.width,
        height: childSize.height,
        alignment: Alignment.center,
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
