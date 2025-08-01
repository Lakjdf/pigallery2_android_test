import 'dart:math' as math;
import 'package:path/path.dart' as p;
import 'package:pigallery2_android/util/extensions.dart';

class BackendFile {
  final String name;
  final int id;

  final String _parentPath;

  /// Relative API path. Does not include server url.
  String get apiPath => p.join(_parentPath, name.encodeUri()).replaceAll("./", "");

  BackendFile({required this.name, required this.id, required String parentPath}) : _parentPath = parentPath;

  /// Creates a local [id] if none is given.
  BackendFile.fromJson(Map<String, dynamic> json, this._parentPath)
      : name = json['name'] ?? json['n'],
        id = json['id'] ?? math.Random().nextInt(4294967296);
}
