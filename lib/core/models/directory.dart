import 'package:pigallery2_android/core/models/file.dart';
import 'package:pigallery2_android/core/models/media.dart';

List<Directory> allDirectoriesFromJson(List<Map<String, dynamic>> jsonData) {
  dynamic res = List<Directory>.from(jsonData.map((x) => Directory.fromJson(x)));
  return res;
}

class DirectoryPath extends File {
  String path;

  DirectoryPath({
    required id,
    required name,
    required this.path,
  }) : super(id: id, name: name);

  factory DirectoryPath.fromJson(Map<String, dynamic> json) {
    return DirectoryPath(
      id: json['id'],
      name: json['name'],
      path: json['path'],
    );
  }
}

class DirectoryPreview extends File {
  DirectoryPath directory;

  DirectoryPreview({
    required id,
    required name,
    required this.directory,
  }) : super(id: id, name: name);

  factory DirectoryPreview.fromJson(Map<String, dynamic> json) {
    return DirectoryPreview(
      id: json['id'],
      name: json['name'],
      directory: DirectoryPath.fromJson(json['directory']),
    );
  }
}

class Directory extends DirectoryPath {
  int mediaCount;
  int lastModified;
  List<Directory> directories;
  DirectoryPreview? preview;
  List<Media> media;

  Directory({
    required id,
    required name,
    required path,
    required this.mediaCount,
    required this.lastModified,
    required this.directories,
    required this.preview,
    required this.media,
  }) : super(id: id, name: name, path: path);

  factory Directory.fromJson(Map<String, dynamic> json) {
    return Directory(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      mediaCount: json['mediaCount'],
      lastModified: json['lastModified'],
      directories: json['directories'] != null ? allDirectoriesFromJson(List.from(json['directories'])) : [],
      preview: json['preview'] != null ? DirectoryPreview.fromJson(json['preview']) : null,
      media: json['media'] != null ? allMediaFromJson(List.from(json['media'])) : [],
    );
  }
}
