import 'package:pigallery2_android/data/backend/models/models.dart';

List<BackendDirectory> allDirectoriesFromJson(List<Map<String, dynamic>> jsonData, String parentPath) {
  return List<BackendDirectory>.from(jsonData.map((x) => BackendDirectory.fromJson(x, parentPath)));
}

class BackendDirectoryPath extends BackendFile {
  BackendDirectoryPath({required super.id, required super.name, required String path}) : super(parentPath: path);

  static String _parsePath(Map<String, dynamic> json) {
    String path = json['path'];
    return path.replaceAll("./", "");
  }

  BackendDirectoryPath.fromJson(Map<String, dynamic> json, String parentPath) : super.fromJson(json, _parsePath(json));
}

class BackendDirectoryCover extends BackendFile {
  BackendDirectoryCover.fromJson(Map<String, dynamic> json, String parentPath) : super.fromJson(json, BackendDirectoryPath.fromJson(json['directory'], parentPath).apiPath);
}

class BackendDirectory extends BackendDirectoryPath {
  final int mediaCount;
  final int lastModified;
  final List<BackendDirectory> directories;
  final BackendDirectoryCover? cover;
  final List<BackendMedia> media;

  BackendDirectory({
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

  static List<BackendDirectory> _parseDirectories(Map<String, dynamic> json, String parentPath) {
    dynamic directoriesJson = json['directories'];
    if (directoriesJson == null) return [];
    return allDirectoriesFromJson(List.from(directoriesJson), parentPath);
  }

  /// Parse [BackendMedia] items using the same [parentPath].
  static List<BackendMedia> _parseMedia(Map<String, dynamic> json, String parentPath) {
    dynamic dynamicJson = json['media'];
    if (dynamicJson == null) return [];
    List<Map<String, dynamic>> mediaJson = List.from(dynamicJson);
    return allMediaFromJson(mediaJson, List.filled(mediaJson.length, parentPath));
  }

  static BackendDirectoryCover? _parseCover(Map<String, dynamic> json, String parentPath) {
    dynamic coverJson = json["cover"] ?? json["preview"];
    if (coverJson == null) return null;
    return BackendDirectoryCover.fromJson(coverJson, parentPath);
  }

  BackendDirectory.fromJson(super.json, super.parentPath)
      : mediaCount = json['mediaCount'],
        lastModified = json['lastModified'],
        directories = _parseDirectories(json, parentPath),
        cover = _parseCover(json, parentPath),
        media = _parseMedia(json, parentPath),
        super.fromJson();
}
