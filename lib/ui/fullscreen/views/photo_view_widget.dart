import 'package:better_player/better_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
      httpHeaders: context.read<MediaRepository>().headers,
      fadeInDuration: const Duration(milliseconds: 1),
      fadeOutDuration: const Duration(milliseconds: 1),
      errorWidget: (context, url, error) => const ErrorImage(),
      placeholder: (context, url) => ThumbnailImage(
        key: ObjectKey(item),
        item,
      ),
    );
  }

  Widget _buildPhotoViewInner(BuildContext context) {
    bool isVideoInitialized = context.select<PhotoModel, bool>((it) => it.stateOf(item).isVideoInitialized);
    PhotoModelState state = context.read<PhotoModel>().stateOf(item);
    String url = state.url;
    BetterPlayerController? controller = state.betterPlayerController;
    if (controller == null || !isVideoInitialized) {
      return _buildImage(context, url);
    } else {
      return BetterPlayer(
        key: ValueKey(url),
        controller: controller,
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
