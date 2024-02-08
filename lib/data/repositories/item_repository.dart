import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/backend/models/directory.dart';
import 'package:pigallery2_android/data/backend/models/search/search_query.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'package:pigallery2_android/util/extensions.dart';

class ItemRepositoryImpl implements ItemRepository {
  final ApiService _api;

  ItemRepositoryImpl(this._api);

  @override
  Future<Directory?> search(Directory? baseDir, String searchText) async {
    SearchQuery query = AndSearchQuery([
      DirectorySearchQuery(text: baseDir?.relativeApiPath ?? "."),
      AnyTextSearchQuery(text: searchText),
    ]);
    BackendDirectory? result = await _api.search(query);
    return result?.let((it) => Directory.fromBackend(result));
  }

  @override
  Future<Directory?> getDirectories({String? path}) async {
    BackendDirectory? result = await _api.getDirectories(path: path);
    return result?.let((it) => Directory.fromBackend(result));
  }

  @override
  Future<Directory?> getTopPicks(int daysLength) async {
    BackendDirectory? result = await _api.search(TopPicksQuery(daysLength: daysLength));
    return result?.let((it) => Directory.fromBackend(result));
  }

  @override
  Future<Directory?> flattenDirectory(Directory? dir) async {
    String path = dir?.relativeApiPath ?? ".";
    BackendDirectory? result = await _api.search(DirectorySearchQuery(text: path));
    // remove current directory from response
    result?.directories.removeWhere((element) => element.apiPath == path);
    return result?.let((it) => Directory.fromBackend(result));
  }
}
