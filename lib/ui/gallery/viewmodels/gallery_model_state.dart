import 'package:collection/collection.dart';
import 'package:pigallery2_android/data/backend/models/search/search.dart';
import 'package:pigallery2_android/data/backend/models/search/search_query_parser.dart';
import 'package:pigallery2_android/data/storage/models/sort_option.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/models/sort_option.dart';
import 'package:pigallery2_android/domain/repositories/sort_options_repository.dart';
import 'package:pigallery2_android/util/extensions.dart';

sealed class GalleryModelStateType {}

class DirectoryGalleryModelStateType extends GalleryModelStateType {}

class SearchGalleryModelStateType extends GalleryModelStateType {
  final SearchQueryDTO query;

  SearchGalleryModelStateType({required this.query});
}

class FlattenGalleryModelStateType extends GalleryModelStateType {
  final Directory? target;

  FlattenGalleryModelStateType({required this.target});
}

class TimelineGalleryModelStateType extends GalleryModelStateType {}

class TopPicksGalleryModelStateType extends GalleryModelStateType {}

class AlbumGalleryModelStateType extends GalleryModelStateType {}

/// Represents the data to be displayed for the current [HomeView].
class GalleryModelState {
  /// [Directory] received from the backend.
  Directory? baseDirectory;

  String? _title;

  String get title => _title ?? baseDirectory?.name ?? "";

  /// Whether this state represents a search result.
  bool isSearching = false;

  /// Whether to show a loading indicator.
  bool isLoading = false;

  /// Error received from the backend.
  String? error;

  late SortOption _sortOption;

  /// Selected [SortOption] to be applied to [items].
  SortOption get sortOption => _sortOption;

  List<Media> _media = List.unmodifiable([]);

  List<Directory> _directories = List.unmodifiable([]);

  /// Cached [items]
  List<Item>? _itemsCache;

  /// [Item]s received from the backend.
  List<Item> get items => _itemsCache ??= List<Item>.unmodifiable([..._directories, ..._media]);

  set items(List<Item> val) {
    final mediaList = <Media>[];
    final dirList = <Directory>[];
    for (final item in val) {
      if (item is Media) {
        mediaList.add(item);
      } else if (item is Directory) {
        dirList.add(item);
      }
    }
    _media = List.unmodifiable(_sort(mediaList));
    _directories = List.unmodifiable(_sort(dirList));
    _itemsCache = null;
  }

  /// All [items] of type [Media].
  List<Media> get media => _media;

  /// All [items] of type [Directory].
  List<Directory> get directories => _directories;

  /// Key for fetching the sort options stored for this [GalleryModelState].
  /// [Null] if nothing fetched yet or no server configured.
  SortingKey? sortingKey;

  GalleryModelStateType type;

  GalleryModelState(this.type, this.baseDirectory, SortOptionsRepository repo) {
    switch (type) {
      case DirectoryGalleryModelStateType():
        sortingKey = baseDirectory?.let((it) => DirectorySortingKey(it.relativeApiPath));
      case AlbumGalleryModelStateType():
        _title = baseDirectory?.name;
        sortingKey = baseDirectory?.let((it) => AlbumSortingKey((it as Album).id));
      case SearchGalleryModelStateType(:final query):
        _title = SearchQueryParser().stringify(query);
        isSearching = true;
        sortingKey = SearchSortingKey();
      case FlattenGalleryModelStateType(:final target):
        _title = target?.name;
        isSearching = true;
        sortingKey = FlattenSortingKey();
      case TimelineGalleryModelStateType():
        _title = "Timeline";
        isSearching = true;
        sortingKey = TimelineSortingKey();
        _sortOption = SortOption(order: SortOrder.desc, type: SortType.date, onlyThisFolder: false);
        return;
      case TopPicksGalleryModelStateType():
        isSearching = true;
        sortingKey = TopPicksSortingKey();
    }
    _sortOption = repo.getSortOption(sortingKey);
  }

  //region sorting
  set sortOption(SortOption newSortOption) {
    sortType = newSortOption.type;
    sortOrder = newSortOption.order;
    sortOnlyThisFolder = newSortOption.onlyThisFolder;
  }

  set sortType(SortType type) {
    if (type != sortOption.type || type == SortType.random) {
      _sortOption = sortOption.copyWith(type: type);
      _media = List.unmodifiable(_sort(_media.toList()));
      _directories = List.unmodifiable(_sort(_directories.toList()));
      _itemsCache = null;
    }
  }

  set sortOnlyThisFolder(bool onlyThisFolder) {
    if (sortOption.onlyThisFolder != onlyThisFolder) {
      _sortOption = _sortOption.copyWith(onlyThisFolder: onlyThisFolder);
    }
  }

  set sortOrder(SortOrder order) {
    if (sortOption.order != order) {
      _sortOption = sortOption.copyWith(order: order);
      _media = List.unmodifiable(_media.reversed);
      _directories = List.unmodifiable(_directories.reversed);
      _itemsCache = null;
    }
  }

  List<Item> _sort(List<Item> toSort) {
    if (sortOption.type == SortType.random) toSort.shuffle();
    toSort.sort(_compare(sortOption.type, sortOption.order));
    return toSort;
  }

  int _compareItems(Item a, Item b, SortType? sortType) {
    return switch (sortType) {
      SortType.date => a.metadata.date.compareTo(b.metadata.date),
      SortType.name => compareNatural(a.name.toLowerCase(), b.name.toLowerCase()),
      SortType.size => a.metadata.size.compareTo(b.metadata.size),
      SortType.random => 1,
      null => a.id.compareTo(b.id),
    };
  }


  /// Builds the primary + tiebreaker comparator for one sort run. Folds the
  /// [order] into the comparator directly rather than sorting asc and then
  /// reversing a list of thousands of items. Falls back to name (then id)
  /// whenever the primary comparison ties — keeps burst-shot photos with
  /// identical timestamps in a stable, human-readable order.
  int Function(Item, Item) _compare(SortType? sortType, SortOrder order) {
    final sign = order == SortOrder.asc ? 1 : -1;
    return (Item a, Item b) {
      int result = _compareItems(a, b, sortType);
      if (result != 0) return sign * result;
      if (sortType != SortType.name) {
        result = _compareItems(a, b, SortType.name);
        if (result != 0) return sign * result;
      }
      return sign * a.id.compareTo(b.id);
    };
  }
  
  //endregion
}
