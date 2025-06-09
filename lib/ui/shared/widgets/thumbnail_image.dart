import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pigallery2_android/data/storage/pigallery2_cache_manager.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/shared/widgets/cached_image_provider.dart';
import 'package:pigallery2_android/ui/shared/widgets/error_image.dart';
import 'package:provider/provider.dart';

class ThumbnailImage extends StatelessWidget {
  final Item item;
  final BoxFit fit;
  final Widget Function(BuildContext, Widget)? imageBuilder;
  final double? width;
  final double? height;

  const ThumbnailImage(this.item, {super.key, this.fit = BoxFit.contain, this.imageBuilder, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    MediaRepository repository = context.read<MediaRepository>();
    String? apiPath = repository.getThumbnailApiPath(item);
    if (apiPath == null) return const ErrorImage();
    return Image(
      key: ValueKey(apiPath),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return imageBuilder?.call(context, child) ?? child;
        return SpinKitRipple(color: Theme.of(context).colorScheme.onSurfaceVariant);
      },
      errorBuilder: (context, error, _) => const ErrorImage(),
      image: CachedImageProvider(url: apiPath, cacheManager: PiGallery2CacheManager.thumbs, headers: context.read<MediaRepository>().headers),
      fit: fit,
      height: height,
      width: width,
    );
  }
}
