import 'dart:collection';
import 'dart:io';
import 'dart:ui';

import 'package:pigallery2_android/domain/models/sprite_thumbnail_data.dart';

/// Basic parser for WebVTT files containing sprite thumbnails.
///
/// ```
/// WEBVTT
///
/// 00:00:00.000 --> 00:00:01.000
/// bunny.mp4-sprite-01.jpg#xywh=0,0,300,200
/// ```
class WebVttParser {
  static SplayTreeMap<Duration, SpriteRegion> parse(File vttFile, String basePath) {
    final map = SplayTreeMap<Duration, SpriteRegion>();
    final lines = vttFile.readAsLinesSync();

    for (int i = 0; i < lines.length; i++) {
      if (!lines[i].contains('-->')) {
        continue;
      }

      final startTime = _parseDuration(lines[i].split('-->')[0].trim());

      final imageLine = lines[i + 1];
      final parts = imageLine.split('#xywh=');
      final imagePath = parts[0];
      final pos = parts[1].split(',').map(double.parse).toList();
      final cropRect = Rect.fromLTWH(pos[0], pos[1], pos[2], pos[3]);

      map[startTime] = SpriteRegion(
        imagePath: "$basePath/$imagePath",
        cropRect: cropRect,
      );
    }
    return map;
  }

  static Duration _parseDuration(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final secondsAndMillis = parts[2].split('.');
    final seconds = int.parse(secondsAndMillis[0]);
    final milliseconds = int.parse(secondsAndMillis[1]);
    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}
