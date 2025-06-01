import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:pigallery2_android/ui/shared/widgets/error_image.dart';
import 'package:pigallery2_android/ui/shared/widgets/selector_guard.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:provider/provider.dart';

class PhotoViewWidget extends StatelessWidget {
  final Media item;

  const PhotoViewWidget(this.item, {super.key});

  Widget buildImage(BuildContext context, String url) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PhotoViewWidgetBackground(item: item),
        CachedNetworkImage(
          key: ValueKey(url),
          cacheManager: PiGallery2CacheManager.fullRes,
          imageUrl: url,
          fit: BoxFit.contain,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          httpHeaders: context.read<MediaRepository>().headers,
          fadeInDuration: const Duration(milliseconds: 1),
          fadeOutDuration: const Duration(milliseconds: 1),
          // not working most of the time https://github.com/Baseflow/flutter_cached_network_image/issues/932
          errorWidget: (context, url, error) => const ErrorImage(),
          placeholder: (context, url) => ThumbnailImage(
            key: ObjectKey(item),
            item,
          ),
        ),
      ],
    );
  }

  Widget buildMotionPhoto(String url, VideoController controller) {
    // need to rotate the player due to some issue with mpv rotating portrait videos.
    bool rotateVideoPlayer = item.aspectRatio < 1;
    return RotatedBox(
      quarterTurns: rotateVideoPlayer ? 1 : 0,
      child: Video(
        key: ValueKey(url),
        controller: controller,
      ),
    );
  }

  Widget buildPhotoViewInner(BuildContext context) {
    PhotoModelState state = context.read<PhotoModel>().stateOf(item);
    return SelectorGuard<PhotoModel, VideoController>(
      selector: (model) => model.stateOf(item).videoController,
      condition: (videoController) => videoController.isInitialized,
      then: (context, videoController) => buildMotionPhoto(state.url, videoController),
      otherwise: (context, _) => buildImage(context, state.url),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    Size childSize;
    if (screenSize.aspectRatio > item.aspectRatio) {
      childSize = Size(screenSize.height * item.aspectRatio, screenSize.height);
    } else {
      childSize = Size(screenSize.width, screenSize.width / item.aspectRatio);
    }
    return ClipRect(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: GestureDetector(
        onLongPress: () => context.read<PhotoModel>().handleLongPress(item),
        onLongPressEnd: (_) => context.read<PhotoModel>().handleLongPressEnd(item),
        child: PhotoView.customChild(
          scaleStateChangedCallback: (PhotoViewScaleState state) {
            context.read<PhotoModel>().backgroundActive = state == PhotoViewScaleState.initial;
          },
          key: ValueKey(item.id),
          backgroundDecoration: const BoxDecoration(color: Colors.transparent),
          minScale: PhotoViewComputedScale.contained,
          childSize: childSize,
          child: buildPhotoViewInner(context),
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
        imageFilter: ImageFilter.blur(
          sigmaX: blur.toDouble(),
          sigmaY: blur.toDouble(),
          tileMode: TileMode.decal,
        ),
        // imageFilter: ImageFilter.compose(
        //   outer: ImageFilter.blur(sigmaX: blur.toDouble(), sigmaY: blur.toDouble(), tileMode: TileMode.decal),
        //   inner: ColorFilter.matrix([
        //     1, 0, 0, 0, 30, // Red
        //     0, 1, 0, 0, 30, // Green
        //     0, 0, 1, 0, 30, // Blue
        //     0, 0, 0, 1, 0, // Alpha
        //   ]),
        // ),
        child: ThumbnailImage(
          key: ObjectKey(item),
          fit: BoxFit.cover,
          height: imageHeight,
          width: imageWidth,
          item,
        ),
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
