import 'package:pigallery2_android/core/models/file.dart';
import 'package:pigallery2_android/core/models/media.dart';

List<Directory> allDirectoriesFromJson(List<Map<String, dynamic>> jsonData, String parentPath) {
  return List<Directory>.from(jsonData.map((x) => Directory.fromJson(x, parentPath)));
}

class DirectoryPath extends File {
  DirectoryPath({required id, required name, required String path}) : super(id: id, name: name, parentPath: path);

  static String _parsePath(Map<String, dynamic> json) {
    String path = json['path'];
    return path.replaceAll("./", "");
  }

  DirectoryPath.fromJson(Map<String, dynamic> json, String parentPath) : super.fromJson(json, _parsePath(json));
}

class DirectoryPreview extends File {
  DirectoryPreview.fromJson(Map<String, dynamic> json, String parentPath) : super.fromJson(json, DirectoryPath.fromJson(json['directory'], parentPath).apiPath);
}

class Directory extends DirectoryPath {
  final int mediaCount;
  final int lastModified;
  final List<Directory> directories;
  final DirectoryPreview? preview;
  final List<Media> media;

  Directory({
    required id,
    required name,
    required path,
    required this.mediaCount,
    required this.lastModified,
    required this.directories,
    required this.preview,
    required this.media,
    required String parentPath,
  }) : super(id: id, name: name, path: path);

  /// Parse [Media] items using the same [parentPath].
  static List<Media> _parseMedia(Map<String, dynamic> json, String parentPath) {
    if (json['media'] == null) return [];
    List<Map<String, dynamic>> mediaJson = List.from(json['media']);
    return allMediaFromJson(mediaJson, List.filled(mediaJson.length, parentPath));
  }

  Directory.fromJson(Map<String, dynamic> json, String parentPath)
      : mediaCount = json['mediaCount'],
        lastModified = json['lastModified'],
        directories = json['directories'] != null ? allDirectoriesFromJson(List.from(json['directories']), parentPath) : [],
        preview = json['preview'] != null ? DirectoryPreview.fromJson(json['preview'], parentPath) : null,
        media = _parseMedia(json, parentPath),
        super.fromJson(json, parentPath);
}
