import 'package:pigallery2_android/domain/models/item.dart';

abstract interface class ItemRepository {
  Future<Directory?> search(Directory? baseDir, String searchText);

  Future<Directory?> getDirectories({String? path});

  Future<Directory?> getTopPicks(int daysLength);

  Future<Directory?> flattenDirectory(Directory? dir);
}
