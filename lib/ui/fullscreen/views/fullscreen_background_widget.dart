import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/models/media_background_mode.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';

/// Custom background for fullscreen view. Does not move with the item when dismissing/scaling it.
class FullscreenBackgroundWidget extends StatelessWidget {
  final Media item;
  const FullscreenBackgroundWidget({super.key, required this.item});

  Widget buildDefaultBackground() {
    return Container(color: Colors.black);
  }

  Widget buildVideoBackground(BuildContext context, Media item) {
    Size screenSize = MediaQuery.of(context).size;
    return Selector<VideoModel, VideoController?>(
      selector: (context, model) => model.getVideoControllerItem(item.id)?.controller,
      builder: (context, videoController, child) {
        if (videoController == null) return buildDefaultBackground();
        return Selector<GlobalSettingsModel, int>(
          selector: (context, model) => model.mediaBackgroundBlur,
          builder: (context, blur, child) => ClipRect(
            child: ImageFiltered(
              enabled: true,
              imageFilter: ImageFilter.blur(
                sigmaX: blur.toDouble(),
                sigmaY: blur.toDouble(),
                tileMode: TileMode.clamp,
              ),
              child: Center(
                child: Video(
                  key: ValueKey("${item.id}: $screenSize background"),
                  controller: videoController,
                  fit: BoxFit.cover,
                  aspectRatio: item.aspectRatio,
                  controls: NoVideoControls,
                  width: screenSize.width,
                  height: screenSize.height,
                  alignment: Alignment.center,
                  pauseUponEnteringBackgroundMode: true,
                  resumeUponEnteringForegroundMode: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildPhotoBackground(BuildContext context, Media item) {
    return Selector<GlobalSettingsModel, int>(
      selector: (context, model) => model.mediaBackgroundBlur,
      builder: (context, blur, child) => Selector<FullscreenModel, double>(
        selector: (context, model) => model.opacity,
        builder: (context, opacity, child) => Opacity(
          opacity: opacity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blur.toDouble(),
              sigmaY: blur.toDouble(),
              tileMode: TileMode.clamp,
            ),
            enabled: true,
            child: ThumbnailImage(
              key: ValueKey("${item.id} background"),
              fit: BoxFit.cover,
              item,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<GlobalSettingsModel, MediaBackgroundMode>(
      selector: (context, model) => model.mediaBackgroundMode,
      builder: (context, mode, child) {
        if (item.isVideo && mode == MediaBackgroundMode.fill) {
          return buildVideoBackground(context, item);
        }
        if (item.isImage && mode == MediaBackgroundMode.fill) {
          return buildPhotoBackground(context, item);
        }
        return buildDefaultBackground();
      },
    );
  }

}