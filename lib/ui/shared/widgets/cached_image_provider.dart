import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CachedImageProvider extends ImageProvider<CachedImageProvider> {
  const CachedImageProvider({required this.url, required this.cacheManager, this.headers});

  final String url;
  final CacheManager cacheManager;
  final Map<String, String>? headers;

  @override
  Future<CachedImageProvider> obtainKey(ImageConfiguration _) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(CachedImageProvider key, ImageDecoderCallback decode) {
    var completer = MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1,
      informationCollector: () sync* {
        yield ErrorDescription('CustomNetworkImageProvider for $url');
      },
    );
    return completer;
  }

  Future<ui.Codec> _loadAsync(CachedImageProvider key, ImageDecoderCallback decode) async {
    Stream<FileResponse> stream = cacheManager.getFileStream(url, headers: headers);
    late FileInfo fileInfo;
    await for (final resp in stream) {
      if (resp is FileInfo) {
        fileInfo = resp;
        break;
      }
    }
    final bytes = await fileInfo.file.readAsBytes();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) => other is CachedImageProvider && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
