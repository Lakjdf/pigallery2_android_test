import 'package:pigallery2_android/util/extensions.dart';

enum SortOption { name, date, size, random }

extension ParseToString on SortOption {
  String getDisplayName() {
    return toString().split('.').last.toCapitalized();
  }
}