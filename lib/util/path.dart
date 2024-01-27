import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:path_provider/path_provider.dart';

/// Helper class to access files downloaded to the app cache.
class Downloads {
  static const String _downloadsFolder = "downloaded";

  // For some reason, share_plus copies every file to a different directory before sharing it.
  // share_plus deletes it once another file is shared.
  static const String _sharePlusFolder = "share_plus";

  static Future<Directory> _getTempDirectory(String name) async {
    String tempPath = (await getTemporaryDirectory()).path;
    String downloadsPath = p.join(tempPath, name);
    return Directory(downloadsPath);
  }

  static Future<String> getPath() async {
    Directory dir = await _getTempDirectory(_downloadsFolder);
    return (await dir.create()).path;
  }

  static Future<void> clear() async {
    Directory downloadsDir = await _getTempDirectory(_downloadsFolder);
    if (downloadsDir.existsSync()) {
      await downloadsDir.delete(recursive: true);
    }
    Directory sharedDir = await _getTempDirectory(_sharePlusFolder);
    if (sharedDir.existsSync()) {
      await sharedDir.delete(recursive: true);
    }
  }
}
