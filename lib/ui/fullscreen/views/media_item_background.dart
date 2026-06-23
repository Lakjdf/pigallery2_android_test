import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/models/media_background_mode.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';

/// Black base layer behind the whole carousel.
class FullscreenSharedBackground extends StatelessWidget {
  const FullscreenSharedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<FullscreenModel, double>(
      selector: (context, model) => model.opacity,
      builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
      child: const ColoredBox(color: Colors.black),
    );
  }
}

/// Per-page background; paints the blurred `fill` cover, nothing in other modes.
class MediaItemBackground extends StatelessWidget {
  final Media item;

  const MediaItemBackground({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    bool isFill = context.select<GlobalSettingsModel, bool>((model) => model.mediaBackgroundMode == MediaBackgroundMode.fill);
    if (!isFill) return const SizedBox.shrink();
    return _FillBackground(item: item);
  }
}

/// Blurred thumbnail covering the screen
class _FillBackground extends StatelessWidget {
  final Media item;

  const _FillBackground({required this.item});

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Selector<GlobalSettingsModel, int>(
      selector: (context, model) => model.mediaBackgroundBlur,
      builder: (context, blur, child) => ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur.toDouble(), sigmaY: blur.toDouble(), tileMode: TileMode.clamp),
          child: child,
        ),
      ),
      child: item.isVideo
          ? _FillVideoView(item: item, screenSize: screenSize)
          : ThumbnailImage(key: ValueKey("${item.id} background"), item, fit: BoxFit.cover),
    );
  }
}

/// Blurred video covering the screen
class _FillVideoView extends StatelessWidget {
  final Media item;
  final Size screenSize;

  const _FillVideoView({required this.item, required this.screenSize});

  @override
  Widget build(BuildContext context) {
    Widget thumbnail = ThumbnailImage(key: ValueKey("${item.id} background"), item, fit: BoxFit.cover);
    VideoControllerItem? controllerItem = context.select<VideoModel, VideoControllerItem?>(
      (model) => model.getVideoControllerItem(item.id),
    );
    if (controllerItem == null) return thumbnail;
    return ListenableBuilder(
      listenable: controllerItem,
      builder: (context, child) {
        if (!controllerItem.firstFrameRendered) return thumbnail;
        return Center(
          child: controllerItem.controller.buildView(
            key: ValueKey("${item.id}: ${screenSize.hashCode} background"),
            fit: BoxFit.cover,
            aspectRatio: item.aspectRatio,
            width: screenSize.width,
            height: screenSize.height,
            alignment: Alignment.center,
          ),
        );
      },
    );
  }
}

/// Builds [AmbientBackground]'s live content, sized to the given box.
typedef AmbientLiveContentBuilder = Widget Function(double width, double height);

/// Blurred glow behind the contained media.
class AmbientBackground extends StatelessWidget {
  final Media item;

  final bool active;

  final AmbientLiveContentBuilder? liveContentBuilder;

  const AmbientBackground({super.key, required this.item, this.active = true, this.liveContentBuilder});

  @override
  Widget build(BuildContext context) {
    bool isAmbient = context.select<GlobalSettingsModel, bool>((model) => model.mediaBackgroundMode == MediaBackgroundMode.ambient);
    if (!isAmbient || !active) return const SizedBox.shrink();

    Size screenSize = MediaQuery.of(context).size;
    double imageHeight = screenSize.width * (item.dimension.height / item.dimension.width);
    double imageWidth = screenSize.height * (item.dimension.width / item.dimension.height);
    Widget content = liveContentBuilder?.call(imageWidth, imageHeight) ??
        ThumbnailImage(key: ObjectKey(item), item, fit: BoxFit.cover, height: imageHeight, width: imageWidth);

    return Center(
      child: Selector<GlobalSettingsModel, int>(
        selector: (context, model) => model.mediaBackgroundBlur,
        builder: (context, blur, child) => ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur.toDouble(), sigmaY: blur.toDouble(), tileMode: TileMode.decal),
          child: child,
        ),
        child: content,
      ),
    );
  }
}
