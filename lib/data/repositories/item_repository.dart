import 'package:collection/collection.dart';
import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/backend/models/directory.dart';
import 'package:pigallery2_android/data/backend/models/search/search_query.dart';
import 'package:pigallery2_android/data/backend/models/search/search_result.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'package:pigallery2_android/util/extensions.dart';

class ItemRepositoryImpl implements ItemRepository {
  final ApiService _api;

  ItemRepositoryImpl(this._api);

  @override
  Future<Directory?> search(Directory? baseDir, String searchText) async {
    String path = baseDir?.relativeApiPath ?? ".";
    SearchQuery query = AndSearchQuery([
      DirectorySearchQuery(text: path),
      AnyTextSearchQuery(text: searchText),
    ]);
    BackendDirectory? result = (await _api.search(query))?.toDirectory();
    // remove current directory from response
    result?.directories.removeWhere((element) => element.apiPath == path);
    return result?.let((it) => Directory.fromBackend(result));
  }

  @override
  Future<Directory?> getDirectories({String? path}) async {
    BackendDirectory? result = await _api.getDirectories(path: path);
    return result?.let((it) => Directory.fromBackend(result));
  }

  @override
  /// Combines [TopPicksQuery] with [RecentlyAddedQuery] to also show images from the current year.
  Future<Directory?> getTopPicks(int daysLength) async {
    SearchResult? topPicksResult = await _api.search(TopPicksQuery(daysLength: daysLength));
    SearchResult? recentlyAddedResult = await _api.search(RecentlyAddedQuery(daysLength: daysLength));
    SearchResult? searchResult;
    if (topPicksResult == null && recentlyAddedResult == null) {
      searchResult = null;
    } else {
      final results = [topPicksResult, recentlyAddedResult].whereNot((it) => it == null).cast<SearchResult>();
      searchResult = SearchResult.combine(results);
    }
    BackendDirectory? result = searchResult?.toDirectory();
    return result?.let((it) => Directory.fromBackend(result));
  }

  @override
  Future<Directory?> flattenDirectory(Directory? dir) async {
    String path = dir?.relativeApiPath ?? ".";
    BackendDirectory? result = (await _api.search(DirectorySearchQuery(text: path)))?.toDirectory();
    result?.directories.clear();
    return result?.let((it) => Directory.fromBackend(result));
  }
}
