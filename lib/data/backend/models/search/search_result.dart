import 'package:pigallery2_android/data/backend/models/models.dart';
import 'package:path/path.dart' as p;

class SearchResult {
  final String name;
  final List<BackendMedia> media;
  final List<BackendDirectory> directories;

  BackendDirectory toDirectory() {
    return BackendDirectory(
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

  SearchResult.combine(Iterable<SearchResult> results)
      : name = results.first.name,
        media = results.expand((it) => it.media).toSet().toList(),
        directories = results.expand((it) => it.directories).toSet().toList();

  static String _findParentPath(Map<String, dynamic> json, int reference) {
    Map<String, dynamic> directory = List.from(json['map']['directories'])[reference];
    return p.join(directory['path'], directory['name']);
  }

  static List<BackendMedia> _parseMedia(Map<String, dynamic> json) {
    if (json['searchResult']['media'] == null) return [];
    List<Map<String, dynamic>> media = List.from(json['searchResult']['media']);
    List<String> parentPaths = media.map((e) => _findParentPath(json, e['d'])).toList();
    return allMediaFromJson(media, parentPaths);
  }

  static List<BackendDirectory> _parseDirectories(Map<String, dynamic> json) {
    dynamic directoriesJson = json['searchResult']['directories'];
    if (directoriesJson == null) return [];
    return allDirectoriesFromJson(List.from(directoriesJson), "");
  }

  SearchResult.fromJson(Map<String, dynamic> json, String title)
      : name = title,
        media = _parseMedia(json),
        directories = _parseDirectories(json);
}
