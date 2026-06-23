import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pigallery2_android/data/storage/pigallery2_cache_manager.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model_state.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_controller.dart';
import 'package:pigallery2_android/ui/fullscreen/views/media_item_background.dart';
import 'package:pigallery2_android/ui/shared/widgets/cached_image_provider.dart';
import 'package:pigallery2_android/ui/shared/widgets/error_image.dart';
import 'package:pigallery2_android/ui/shared/widgets/selector_guard.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';
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
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
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
        Selector<PhotoModel, bool>(
          selector: (context, model) => model.backgroundActive,
          builder: (context, active, child) => AmbientBackground(item: widget.item, active: active),
        ),
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

  Widget buildMotionPhoto(String url, AppVideoController controller) {
    // need to rotate the player due to some issue with mpv rotating portrait videos.
    bool rotateVideoPlayer = widget.item.aspectRatio < 1;
    return RotatedBox(
      quarterTurns: rotateVideoPlayer ? 1 : 0,
      child: controller.buildView(key: ValueKey(url)),
    );
  }

  Widget buildPhotoViewInner(BuildContext context) {
    PhotoModelState state = context.read<PhotoModel>().stateOf(widget.item);
    return SelectorGuard<PhotoModel, AppVideoController>(
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
