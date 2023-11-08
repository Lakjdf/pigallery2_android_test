import 'package:pigallery2_android/core/models/directory.dart';
import 'package:pigallery2_android/core/models/media.dart';
import 'package:path/path.dart' as p;
import 'package:pigallery2_android/core/services/models/search_query.dart';

class SearchResult {
  final String name;
  final List<Media> media;
  final List<Directory> directories;

  Directory toDirectory() {
    return Directory(
      id: -1,
      name: name,
      path: "",
      mediaCount: 0,
      lastModified: 0,
      directories: directories,
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

  static List<Directory> _parseDirectories(Map<String, dynamic> json) {
    dynamic directoriesJson = json['searchResult']['directories'];
    if (directoriesJson == null) return [];
    return allDirectoriesFromJson(List.from(directoriesJson), "");
  }

  SearchResult.fromJson(Map<String, dynamic> json)
      : name = TextSearchQuery.fromJson(json["searchResult"]["searchQuery"]).text,
        media = _parseMedia(json),
        directories = _parseDirectories(json);
}
