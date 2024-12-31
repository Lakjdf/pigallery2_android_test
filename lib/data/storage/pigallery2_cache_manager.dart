import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PiGallery2CacheManager {
  static CacheManager thumbs = CustomImageCacheManager(
    Config(
      "thumbs",
      fileService: HttpFileService(),
    ),
  );

  static CacheManager fullRes = CustomImageCacheManager(
    Config(
      "fullRes",
      maxNrOfCacheObjects: 20,
      fileService: HttpFileService(),
    ),
  );

  static CacheManager spriteThumbnails = CustomImageCacheManager(
    Config(
      "spriteThumbnails",
      maxNrOfCacheObjects: 20,
      fileService: HttpFileService(),
    ),
  );
}

class CustomImageCacheManager extends CacheManager with ImageCacheManager {
  CustomImageCacheManager(super.config);
}
