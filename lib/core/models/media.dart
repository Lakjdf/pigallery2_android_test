import 'package:collection/collection.dart';
import 'package:pigallery2_android/core/models/file.dart';
import 'package:pigallery2_android/core/models/media_metadata.dart';

List<Media> allMediaFromJson(List<Map<String, dynamic>> jsonData, List<String> parentPaths) {
  dynamic a = jsonData.mapIndexed((idx, x) => Media.fromJson(x, parentPaths[idx]));
  return a.toList();
}

class Media extends File {
  MediaMetadata metadata;

  Media.fromJson(super.json, super.parentPath)
      : metadata = MediaMetadata.fromJson(json['metadata'] ?? json['m']),
        super.fromJson();
}
