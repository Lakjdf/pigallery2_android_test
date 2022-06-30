import 'package:pigallery2_android/core/models/file.dart';
import 'package:pigallery2_android/core/models/media.dart';

List<Directory> allDirectoriesFromJson(List<Map<String, dynamic>> jsonData) {
  dynamic res = List<Directory>.from(jsonData.map((x) => Directory.fromJson(x)));
  return res;
}

class Directory extends File {
  String path;
  int mediaCount;
  List<Directory> directories;
  dynamic preview; //todo
  List<Media> media;

  Directory({
    required id,
    required name,
    required this.path,
    required this.mediaCount,
    required this.directories,
    required this.preview,
    required this.media,
  }) : super(id: id, name: name);

  factory Directory.fromJson(Map<String, dynamic> json) {
    try {
      return Directory(
        id: json['id'],
        name: json['name'],
        path: json['path'],
        mediaCount: json['mediaCount'],
        directories: json['directories'] != null ? allDirectoriesFromJson(List.from(json['directories'])) : [],
        preview: json['preview'],
        media: json['media'] != null ? allMediaFromJson(List.from(json['media'])) : [],
      );
    } catch (e) {
      return Directory(id: 1, name: '', directories: [], media: [], path: '', mediaCount: 1, preview: null);
    }
  }
}
