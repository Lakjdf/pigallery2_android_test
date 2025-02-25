import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:path_provider/path_provider.dart';
import 'package:pigallery2_android/data/storage/pigallery2_cache_manager.dart';
import 'package:pigallery2_android/data/storage/pigallery2_image_cache.dart';

/// Helper class to access files downloaded to the app cache.
class Downloads {
  static final String _downloadsFolder = PiGallery2CacheManager.fullRes.store.storeKey;

  // For some reason, share_plus copies every file to a different directory before sharing it.
  // share_plus deletes it once another file is shared.
  static const String _sharePlusFolder = "share_plus";

  static Future<Directory> _getTempDirectory(String name) async {
    String tempPath = (await getTemporaryDirectory()).path;
    String downloadsPath = p.join(tempPath, name);
    return Directory(downloadsPath);
  }

  static Future<String> getPath() async {
    Directory dir = await _getTempDirectory(_downloadsFolder);
    return (await dir.create()).path;
  }

  static Future<void> clear() async {
    Directory downloadsDir = await _getTempDirectory(_downloadsFolder);
    await PiGallery2CacheManager.fullRes.emptyCache();
    if (downloadsDir.existsSync()) {
      await downloadsDir.delete(recursive: true);
    }
    Directory spritesDir = await _getTempDirectory(PiGallery2CacheManager.spriteThumbnails.store.storeKey);
    await PiGallery2CacheManager.spriteThumbnails.emptyCache();
    if (spritesDir.existsSync()) {
      await spritesDir.delete(recursive: true);
    }
    Directory sharedDir = await _getTempDirectory(_sharePlusFolder);
    if (sharedDir.existsSync()) {
      await sharedDir.delete(recursive: true);
    }
    // Also clear in-memory media
    PiGallery2ImageCache.fullResCache.clear();
  }

  static Future<int> getSize() async {
    int downloadsSize = await PiGallery2CacheManager.fullRes.store.getCacheSize();
    int spritesSize = await PiGallery2CacheManager.spriteThumbnails.store.getCacheSize();
    Directory sharedDir = await _getTempDirectory(_sharePlusFolder);
    int sharedSize = (await sharedDir.stat()).size;
    if (sharedSize == -1) sharedSize = 0;
    return downloadsSize + spritesSize + sharedSize;
  }

  static Future<void> clearThumbnails() async {
    Directory thumbsDir = await _getTempDirectory(PiGallery2CacheManager.thumbs.store.storeKey);
    await PiGallery2CacheManager.thumbs.emptyCache();
    PiGallery2CacheManager.thumbs.store.emptyMemoryCache();
    if (thumbsDir.existsSync()) {
      await thumbsDir.delete(recursive: true);
    }
    // Also clear in-memory thumbnails
    PiGallery2ImageCache.thumbCache.clear();
    PiGallery2ImageCache.thumbCache.clearLiveImages();
  }

  static Future<int> getThumbnailSize() {
    return PiGallery2CacheManager.thumbs.store.getCacheSize();
  }
}
