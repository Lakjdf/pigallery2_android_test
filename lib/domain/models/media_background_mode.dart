import 'package:pigallery2_android/util/extensions.dart';

enum MediaBackgroundMode { off, ambient, fill }

extension ParseToString on MediaBackgroundMode {
  String getDisplayName() {
    return toString().split('.').last.toCapitalized();
  }
}