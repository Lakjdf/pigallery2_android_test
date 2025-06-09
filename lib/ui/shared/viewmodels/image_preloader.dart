import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:pigallery2_android/data/storage/pigallery2_cache_manager.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/shared/widgets/cached_image_provider.dart';

class ImagePreloader {
  final Logger _logger = Logger("ImagePreloader");
  final MediaRepository _mediaRepository;
  final BuildContext _context;

  ImagePreloader(this._mediaRepository, this._context);

  Future<bool> _isCached(ImageProvider provider) async {
    final key = await provider.obtainKey(ImageConfiguration.empty);
    return PaintingBinding.instance.imageCache.containsKey(key);
  }

  /// Preload the full resolution image from the given url s.t. it can be displayed instantly when using [CachedImageProvider].
  /// Swallows exceptions as they will be forwarded to the Image widget.
  Future<void> preloadImage(String url) async {
    BuildContext context = _context;
    final provider = CachedImageProvider(url: url, headers: _mediaRepository.headers, cacheManager: PiGallery2CacheManager.fullRes);
    bool cached = await _isCached(provider);
    if (cached || !context.mounted) return;
    await precacheImage(
      provider,
      context,
      onError: (error, _) {
        _logger.warning("Failed to fetch $url", error);
      },
    );
  }
}
