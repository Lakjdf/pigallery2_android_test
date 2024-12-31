import 'dart:async';
import 'dart:collection';

import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/models/sprite_thumbnail_data.dart';

/// Responsible for downloading [Media] items.
abstract interface class MediaRepository {
  /// Download the given [Media] item to a cache.
  /// Returned [StreamSubscription] contains download progress from 0 to 1.
  /// Supports cancellation.
  StreamSubscription<double> download(Media item);

  /// Returns the path to the cached [Media] item. [Null] if it does not exist.
  Future<String?> getFilePath(Media item);

  String getMediaApiPath(Media item);

  String? getThumbnailApiPath(Item item);

  Future<SplayTreeMap<Duration, SpriteRegion>?> getSpriteThumbnails(Media item);

  Map<String, String> get headers;
}
