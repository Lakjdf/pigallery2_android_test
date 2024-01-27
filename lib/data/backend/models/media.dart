import 'package:collection/collection.dart';
import 'package:pigallery2_android/data/backend/models/models.dart';

List<BackendMedia> allMediaFromJson(List<Map<String, dynamic>> jsonData, List<String> parentPaths) {
  dynamic a = jsonData.mapIndexed((idx, x) => BackendMedia.fromJson(x, parentPaths[idx]));
  return a.toList();
}

class BackendMedia extends BackendFile {
  BackendMediaMetadata metadata;

  BackendMedia.fromJson(super.json, super.parentPath)
      : metadata = BackendMediaMetadata.fromJson(json['metadata'] ?? json['m']),
        super.fromJson();
}
