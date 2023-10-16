import 'package:pigallery2_android/core/models/directory.dart';
import 'package:pigallery2_android/core/models/media.dart';
import 'package:path/path.dart' as p;

class SearchResult {
  final List<Media> media;

  Directory toDirectory() {
    return Directory(
      id: -1,
      name: "",
      path: "",
      mediaCount: 0,
      lastModified: 0,
      directories: [],
      cover: null,
      media: media,
      parentPath: "",
    );
  }

  static String _findParentPath(Map<String, dynamic> json, int reference) {
    Map<String, dynamic> directory = List.from(json['map']['directories'])[reference];
    return p.join(directory['path'], directory['name']);
  }

  static List<Media> _parseMedia(Map<String, dynamic> json) {
    if (json['searchResult']['media'] == null) return [];
    List<Map<String, dynamic>> media = List.from(json['searchResult']['media']);
    List<String> parentPaths = media.map((e) => _findParentPath(json, e['d'])).toList();
    return allMediaFromJson(media, parentPaths);
  }

  SearchResult.fromJson(Map<String, dynamic> json) : media = _parseMedia(json);
}
