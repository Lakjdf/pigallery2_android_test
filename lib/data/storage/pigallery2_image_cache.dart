import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PiGallery2ImageCache implements ImageCache {
  final ImageCache _thumbCache = ImageCache();
  final ImageCache _fullResCache = ImageCache();

  bool _isThumb(Object key) {
    return key is CachedNetworkImageProvider && key.url.endsWith("thumbnail");
  }

  @override
  int get maximumSize => _thumbCache.maximumSize + _fullResCache.maximumSize;

  @override
  int get maximumSizeBytes => _thumbCache.maximumSizeBytes + _fullResCache.maximumSizeBytes;

  @override
  set maximumSize(int value) {
    _thumbCache.maximumSize = value;
    _fullResCache.maximumSize = value;
  }

  @override
  set maximumSizeBytes(int value) {
    _thumbCache.maximumSizeBytes = value;
    _fullResCache.maximumSizeBytes = value;
  }

  @override
  void clear() {
    _thumbCache.clear();
    _fullResCache.clear();
  }

  @override
  void clearLiveImages() {
    _thumbCache.clearLiveImages();
    _fullResCache.clearLiveImages();
  }

  @override
  bool containsKey(Object key) {
    if (_isThumb(key)) {
      return _thumbCache.containsKey(key);
    } else {
      return _fullResCache.containsKey(key);
    }
  }

  @override
  int get currentSize => _thumbCache.currentSize + _fullResCache.currentSize;

  @override
  int get currentSizeBytes => _thumbCache.currentSizeBytes + _fullResCache.currentSizeBytes;

  @override
  bool evict(Object key, {bool includeLive = true}) {
    if (_isThumb(key)) {
      return _thumbCache.evict(key, includeLive: includeLive);
    } else {
      return _fullResCache.evict(key, includeLive: includeLive);
    }
  }

  @override
  int get liveImageCount => _thumbCache.liveImageCount + _fullResCache.liveImageCount;

  @override
  int get pendingImageCount => _thumbCache.pendingImageCount + _fullResCache.liveImageCount;

  @override
  ImageStreamCompleter? putIfAbsent(Object key, ImageStreamCompleter Function() loader, {ImageErrorListener? onError}) {
    if (_isThumb(key)) {
      return _thumbCache.putIfAbsent(key, loader, onError: onError);
    } else {
      return _fullResCache.putIfAbsent(key, loader, onError: onError);
    }
  }

  @override
  ImageCacheStatus statusForKey(Object key) {
    if (_isThumb(key)) {
      return _thumbCache.statusForKey(key);
    } else {
      return _fullResCache.statusForKey(key);
    }
  }
}
