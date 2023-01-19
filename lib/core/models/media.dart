import 'package:pigallery2_android/core/models/file.dart';

import 'package:pigallery2_android/core/models/media_metadata.dart';

List<Media> allMediaFromJson(List<Map<String, dynamic>> jsonData) {
  dynamic res = List<Media>.from(jsonData.map((x) => Media.fromJson(x)));
  return res;
}

class Media extends File {
  MediaMetadata metadata;

  Media({
    required id,
    required name,
    required this.metadata,
  }) : super(id: id, name: name);

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'], // don't use 't' as it's not unique
      name: json['name'] ?? json['n'],
      metadata: MediaMetadata.fromJson(json['metadata'] ?? json['m']),
    );
  }
}
