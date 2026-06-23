import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:pigallery2_android/domain/models/item.dart' as models show Media;
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_controller.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/fullscreen/views/media_item_background.dart';
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

  Widget buildLoading() {
    return Stack(
      key: ValueKey(widget.item.id),
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        AmbientBackground(item: widget.item),
        ThumbnailImage(key: ObjectKey(widget.item), widget.item),
      ],
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
    Size screenSize = MediaQuery.of(context).size;
    // prefer aspectRatio of the player over metadata
    double aspectRatio = videoController.player.aspectRatio ?? widget.item.aspectRatio;
    return Selector<VideoModel, double>(
      selector: (context, model) => model.videoScale,
      builder: (context, scale, child) => Transform.scale(
        transformHitTests: true,
        scale: scale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AmbientBackground(
              item: widget.item,
              liveContentBuilder: (width, height) => videoController.buildView(
                key: ValueKey("${widget.item.id}: ${screenSize.hashCode} background"),
                fit: BoxFit.cover,
                aspectRatio: aspectRatio,
                width: width,
                height: height,
                alignment: Alignment.center,
              ),
            ),
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
      return buildLoading();
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
          return buildLoading();
        }
      }),
    );
  }
}
