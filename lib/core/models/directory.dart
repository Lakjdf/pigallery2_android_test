import 'package:pigallery2_android/core/models/file.dart';
import 'package:pigallery2_android/core/models/media.dart';

List<Directory> allDirectoriesFromJson(List<Map<String, dynamic>> jsonData, String parentPath) {
  return List<Directory>.from(jsonData.map((x) => Directory.fromJson(x, parentPath)));
}

class DirectoryPath extends File {
  DirectoryPath({required super.id, required super.name, required String path}) : super(parentPath: path);

  static String _parsePath(Map<String, dynamic> json) {
    String path = json['path'];
    return path.replaceAll("./", "");
  }

  DirectoryPath.fromJson(Map<String, dynamic> json, String parentPath) : super.fromJson(json, _parsePath(json));
}

class DirectoryCover extends File {
  DirectoryCover.fromJson(Map<String, dynamic> json, String parentPath) : super.fromJson(json, DirectoryPath.fromJson(json['directory'], parentPath).apiPath);
}

class Directory extends DirectoryPath {
  final int mediaCount;
  final int lastModified;
  final List<Directory> directories;
  final DirectoryCover? cover;
  final List<Media> media;

  Directory({
    required super.id,
    required super.name,
    required super.path,
    required this.mediaCount,
    required this.lastModified,
    required this.directories,
    required this.cover,
    required this.media,
    required String parentPath,
  });

  static List<Directory> _parseDirectories(Map<String, dynamic> json, String parentPath) {
    dynamic directoriesJson = json['directories'];
    if (directoriesJson == null) return [];
    return allDirectoriesFromJson(List.from(directoriesJson), parentPath);
  }

  /// Parse [Media] items using the same [parentPath].
  static List<Media> _parseMedia(Map<String, dynamic> json, String parentPath) {
    dynamic dynamicJson = json['media'];
    if (dynamicJson == null) return [];
    List<Map<String, dynamic>> mediaJson = List.from(dynamicJson);
    return allMediaFromJson(mediaJson, List.filled(mediaJson.length, parentPath));
  }

  static DirectoryCover? _parseCover(Map<String, dynamic> json, String parentPath) {
    dynamic coverJson = json["cover"] ?? json["preview"];
    if (coverJson == null) return null;
    return DirectoryCover.fromJson(coverJson, parentPath);
  }

  Directory.fromJson(super.json, super.parentPath)
      : mediaCount = json['mediaCount'],
        lastModified = json['lastModified'],
        directories = _parseDirectories(json, parentPath),
        cover = _parseCover(json, parentPath),
        media = _parseMedia(json, parentPath),
        super.fromJson();
}
