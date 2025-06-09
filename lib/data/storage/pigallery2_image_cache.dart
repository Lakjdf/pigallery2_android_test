import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/shared/widgets/cached_image_provider.dart';

import 'pigallery2_cache_manager.dart';

class PiGallery2ImageCache implements ImageCache {
  static final ImageCache thumbCache = ImageCache()
    ..maximumSize = 1000
    ..maximumSizeBytes = 100 * 1024 * 1024; // 100 MB
  static final ImageCache fullResCache = ImageCache()
    ..maximumSize = 10
    ..maximumSizeBytes = 200 * 1024 * 1024; // 200 MB

  bool _isThumb(Object key) {
    return key is CachedImageProvider && key.cacheManager == PiGallery2CacheManager.thumbs;
  }

  @override
  int get maximumSize => thumbCache.maximumSize + fullResCache.maximumSize;

  @override
  int get maximumSizeBytes => thumbCache.maximumSizeBytes + fullResCache.maximumSizeBytes;

  @override
  set maximumSize(int value) {
    thumbCache.maximumSize = value;
    fullResCache.maximumSize = value;
  }

  @override
  set maximumSizeBytes(int value) {
    thumbCache.maximumSizeBytes = value;
    fullResCache.maximumSizeBytes = value;
  }

  @override
  void clear() {
    thumbCache.clear();
    fullResCache.clear();
  }

  @override
  void clearLiveImages() {
    thumbCache.clearLiveImages();
    fullResCache.clearLiveImages();
  }

  @override
  bool containsKey(Object key) {
    if (_isThumb(key)) {
      return thumbCache.containsKey(key);
    } else {
      return fullResCache.containsKey(key);
    }
  }

  @override
  int get currentSize => thumbCache.currentSize + fullResCache.currentSize;

  @override
  int get currentSizeBytes => thumbCache.currentSizeBytes + fullResCache.currentSizeBytes;

  @override
  bool evict(Object key, {bool includeLive = true}) {
    if (_isThumb(key)) {
      return thumbCache.evict(key, includeLive: includeLive);
    } else {
      return fullResCache.evict(key, includeLive: includeLive);
    }
  }

  @override
  int get liveImageCount => thumbCache.liveImageCount + fullResCache.liveImageCount;

  @override
  int get pendingImageCount => thumbCache.pendingImageCount + fullResCache.liveImageCount;

  @override
  ImageStreamCompleter? putIfAbsent(Object key, ImageStreamCompleter Function() loader, {ImageErrorListener? onError}) {
    if (_isThumb(key)) {
      return thumbCache.putIfAbsent(key, loader, onError: onError);
    } else {
      return fullResCache.putIfAbsent(key, loader, onError: onError);
    }
  }

  @override
  ImageCacheStatus statusForKey(Object key) {
    if (_isThumb(key)) {
      return thumbCache.statusForKey(key);
    } else {
      return fullResCache.statusForKey(key);
    }
  }
}
