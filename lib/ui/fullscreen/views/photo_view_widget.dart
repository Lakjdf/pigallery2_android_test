import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pigallery2_android/data/storage/pigallery2_cache_manager.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/models/media_background_mode.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model_state.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/cached_image_provider.dart';
import 'package:pigallery2_android/ui/shared/widgets/error_image.dart';
import 'package:pigallery2_android/ui/shared/widgets/selector_guard.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PhotoViewWidget extends StatefulWidget {
  final Media item;

  const PhotoViewWidget(this.item, {super.key});

  @override
  State<PhotoViewWidget> createState() => _PhotoViewWidgetState();
}

class _PhotoViewWidgetState extends State<PhotoViewWidget> {
  final PhotoViewController _controller = PhotoViewController();

  _PhotoViewWidgetState();

  @override
  void initState() {
    super.initState();
    PhotoModel model = context.read();
    _controller.outputStateStream.listen((val) {
      double? scale = val.scale;
      if (scale != null && (scale - 1).abs() < 1e-6) {
        model.backgroundActive = true;
      }
      else {
        model.backgroundActive = false;
      }
    });
  }

  Widget buildImage(BuildContext context, String url) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PhotoViewWidgetBackground(item: widget.item),
        Image(
          key: ValueKey(widget.item.id),
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return ThumbnailImage(
              key: ObjectKey(widget.item),
              widget.item,
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            );
          },
          errorBuilder: (context, error, _) => const ErrorImage(),
          image: CachedImageProvider(url: url, cacheManager: PiGallery2CacheManager.fullRes, headers: context.read<MediaRepository>().headers),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          fit: BoxFit.cover,
        ),
      ],
    );
  }

  Widget buildMotionPhoto(String url, VideoController controller) {
    // need to rotate the player due to some issue with mpv rotating portrait videos.
    bool rotateVideoPlayer = widget.item.aspectRatio < 1;
    return RotatedBox(
      quarterTurns: rotateVideoPlayer ? 1 : 0,
      child: Video(key: ValueKey(url), controller: controller),
    );
  }

  Widget buildPhotoViewInner(BuildContext context) {
    PhotoModelState state = context.read<PhotoModel>().stateOf(widget.item);
    return SelectorGuard<PhotoModel, VideoController>(
      selector: (model) => model.stateOf(widget.item).videoController,
      condition: (videoController) => videoController.isInitialized,
      then: (context, videoController) => buildMotionPhoto(state.url, videoController),
      otherwise: (context, _) => buildImage(context, state.url),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    Size childSize;
    if (screenSize.aspectRatio > widget.item.aspectRatio) {
      childSize = Size(screenSize.height * widget.item.aspectRatio, screenSize.height);
    } else {
      childSize = Size(screenSize.width, screenSize.width / widget.item.aspectRatio);
    }
    return ClipRect(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: VisibilityDetector(
        key: ValueKey(widget.item.id),
        onVisibilityChanged: (info) {
          if (info.visibleFraction == 1) {
            context.read<PhotoModel>().notifyFullyVisible();
          }
        },
        child: GestureDetector(
          onLongPress: () => context.read<PhotoModel>().handleLongPress(widget.item),
          onLongPressEnd: (_) => context.read<PhotoModel>().handleLongPressEnd(widget.item),
          child: PhotoView.customChild(
            controller: _controller,
            key: ValueKey(widget.item.id),
            backgroundDecoration: const BoxDecoration(color: Colors.transparent),
            minScale: PhotoViewComputedScale.contained,
            childSize: childSize,
            child: buildPhotoViewInner(context),
          ),
        ),
      ),
    );
  }
}

class PhotoViewWidgetBackground extends StatelessWidget {
  final Media item;

  const PhotoViewWidgetBackground({super.key, required this.item});

  Widget buildAmbientBackground(BuildContext context) {
    double imageHeight = MediaQuery.of(context).size.width * (item.dimension.height / item.dimension.width);
    double imageWidth = MediaQuery.of(context).size.height * (item.dimension.width / item.dimension.height);
    return Selector<GlobalSettingsModel, int>(
      selector: (context, model) => model.mediaBackgroundBlur,
      builder: (context, blur, child) => ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur.toDouble(), sigmaY: blur.toDouble(), tileMode: TileMode.decal),
        // imageFilter: ImageFilter.compose(
        //   outer: ImageFilter.blur(sigmaX: blur.toDouble(), sigmaY: blur.toDouble(), tileMode: TileMode.decal),
        //   inner: ColorFilter.matrix([
        //     1, 0, 0, 0, 30, // Red
        //     0, 1, 0, 0, 30, // Green
        //     0, 0, 1, 0, 30, // Blue
        //     0, 0, 0, 1, 0, // Alpha
        //   ]),
        // ),
        child: ThumbnailImage(key: ObjectKey(item), fit: BoxFit.cover, height: imageHeight, width: imageWidth, item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAmbientMode = context.select<GlobalSettingsModel, bool>((it) => it.mediaBackgroundMode == MediaBackgroundMode.ambient);
    bool isBackgroundActive = context.select<PhotoModel, bool>((it) => it.backgroundActive);
    if (isAmbientMode && isBackgroundActive) {
      return buildAmbientBackground(context);
    }
    return SizedBox.shrink();
  }
}
