import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/backend/models/directory.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'package:pigallery2_android/util/extensions.dart';

class ItemRepositoryImpl implements ItemRepository {
  final ApiService _api;

  ItemRepositoryImpl(this._api);

  @override
  Future<Directory?> search({String searchText = ""}) async {
    BackendDirectory? result = await _api.search(searchText: searchText);
    return result?.let((it) => Directory.fromBackend(result));
  }

  @override
  Future<Directory?> getDirectories({String? path}) async {
    BackendDirectory? result = await _api.getDirectories(path: path);
    return result?.let((it) => Directory.fromBackend(result));
  }

  @override
  Future<Directory?> getTopPicks(int daysLength) async {
    BackendDirectory? result = await _api.getTopPicks(daysLength);
    return result?.let((it) => Directory.fromBackend(result));
  }
}
