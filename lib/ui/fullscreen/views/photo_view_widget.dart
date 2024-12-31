import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pigallery2_android/data/storage/pigallery2_cache_manager.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model_state.dart';
import 'package:pigallery2_android/ui/shared/widgets/error_image.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';

class PhotoViewWidget extends StatelessWidget {
  final Media item;

  const PhotoViewWidget(this.item, {super.key});

  Widget _buildImage(BuildContext context, String url) {
    return CachedNetworkImage(
      key: ValueKey(url),
      cacheManager: PiGallery2CacheManager.fullRes,
      imageUrl: url,
      fit: BoxFit.contain,
      httpHeaders: context.read<MediaRepository>().headers,
      fadeInDuration: const Duration(milliseconds: 1),
      fadeOutDuration: const Duration(milliseconds: 1),
      errorWidget: (context, url, error) => const ErrorImage(), // not working most of the time https://github.com/Baseflow/flutter_cached_network_image/issues/932
      placeholder: (context, url) => ThumbnailImage(
        key: ObjectKey(item),
        item,
      ),
    );
  }

  Widget _buildPhotoViewInner(BuildContext context) {
    bool isVideoInitialized = context.select<PhotoModel, bool>((it) => it.stateOf(item).isVideoInitialized);
    PhotoModelState state = context.read<PhotoModel>().stateOf(item);
    // need to rotate the player due to some issue with mpv rotating portrait videos.
    bool rotateVideoPlayer = item.aspectRatio < 1 && state.isVideoInitialized;
    String url = state.url;
    VideoController? controller = state.videoController;
    if (controller == null || !isVideoInitialized) {
      return _buildImage(context, url);
    } else {
      return RotatedBox(
        quarterTurns: rotateVideoPlayer ? 1 : 0,
        child: Video(
          key: ValueKey(url),
          controller: controller,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        context.read<PhotoModel>().handleLongPress(item);
      },
      onLongPressEnd: (_) {
        context.read<PhotoModel>().handleLongPressEnd(item);
      },
      child: PhotoView.customChild(
        key: ValueKey(item.id),
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        minScale: PhotoViewComputedScale.contained * 1.0,
        childSize: Size(item.dimension.width.toDouble(), item.dimension.height.toDouble()),
        child: _buildPhotoViewInner(context),
      ),
    );
  }
}
