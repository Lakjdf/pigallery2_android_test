import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pigallery2_android/data/storage/pigallery2_cache_manager.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/shared/widgets/error_image.dart';
import 'package:provider/provider.dart';

class ThumbnailImage extends StatelessWidget {
  final Item item;
  final BoxFit fit;
  final ImageWidgetBuilder? imageBuilder;

  const ThumbnailImage(this.item, {super.key, this.fit = BoxFit.contain, this.imageBuilder});

  @override
  Widget build(BuildContext context) {
    MediaRepository repository = context.read<MediaRepository>();
    String? apiPath = repository.getThumbnailApiPath(item);
    if (apiPath == null) return const ErrorImage();
    return CachedNetworkImage(
      key: ValueKey(apiPath),
      imageUrl: apiPath,
      cacheManager: PiGallery2CacheManager.thumbs,
      httpHeaders: repository.headers,
      imageBuilder: imageBuilder,
      placeholder: (context, url) => SpinKitRipple(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      fadeOutDuration: const Duration(milliseconds: 300),
      fadeOutCurve: Curves.easeOutCubic,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeInCurve: Curves.easeInCubic,
      errorWidget: (context, url, error) {
        return const ErrorImage();
      },
      fit: fit,
      maxWidthDiskCache: 240,
      maxHeightDiskCache: 240,
    );
  }
}
