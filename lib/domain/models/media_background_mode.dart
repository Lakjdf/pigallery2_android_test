import 'package:pigallery2_android/util/extensions.dart';

enum MediaBackgroundMode { off, ambient, fill }

extension ParseToString on MediaBackgroundMode {
  String getDisplayName() {
    return toString().split('.').last.toCapitalized();
  }
}

extension MediaBackgroundModeBackground on MediaBackgroundMode {
  /// Whether the background depends on the specific item being shown.
  bool get isItemSpecific => this == MediaBackgroundMode.fill;
}
