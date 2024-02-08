import 'package:collection/collection.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/models/sort_option.dart';

/// Represents the data to be displayed for the current [HomeView].
class HomeModelState {
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

  /// Selected [SortOption] to be applied to [items].
  SortOption sortOption;

  /// Whether to sort with [sortOption] in ascending order.
  bool sortAscending;

  List<Media> _media = List.unmodifiable([]);

  List<Directory> _directories = List.unmodifiable([]);

  /// [Item]s received from the backend.
  List<Item> get items => List<Item>.unmodifiable([..._directories, ..._media]);

  set items(List<Item> val) {
    _media = List.unmodifiable(_sort(val.whereType<Media>().toList()));
    _directories = List.unmodifiable(_sort(val.whereType<Directory>().toList()));
  }

  /// All [items] of type [Media].
  List<Media> get media => _media;

  /// All [items] of type [Directory].
  List<Directory> get directories => _directories;

  HomeModelState(this.baseDirectory, this.sortOption, this.sortAscending);

  HomeModelState.searching(this.sortOption, this.sortAscending, {String? title, this.baseDirectory})
      : _title = title,
        isSearching = true;

  //region sorting
  void updateSortOption(SortOption option) {
    if (option != sortOption || option == SortOption.random) {
      sortOption = option;
      _media = List.unmodifiable(_sort(_media.toList()));
      _directories = List.unmodifiable(_sort(_directories.toList()));
    }
  }

  bool updateSortOrder(bool ascending) {
    if (sortAscending != ascending) {
      sortAscending = ascending;
      _media = List.unmodifiable(_media.reversed);
      _directories = List.unmodifiable(_directories.reversed);
      return true;
    }
    return false;
  }

  List<Item> _sort(List<Item> toSort) {
    if (sortOption == SortOption.random) toSort.shuffle();
    toSort.sort(_compare(sortOption));
    return sortAscending ? toSort : toSort.reversed.toList();
  }

  int _compareItems(Item a, Item b, SortOption? sortOption) {
    return switch (sortOption) {
      SortOption.date => a.metadata.date.compareTo(b.metadata.date),
      SortOption.name => compareNatural(a.name.toLowerCase(), b.name.toLowerCase()),
      SortOption.size => a.metadata.size.compareTo(b.metadata.size),
      SortOption.random => 1,
      null => a.id.compareTo(b.id),
    };
  }

  int Function(Item, Item) _compare(SortOption? sortOption) {
    // Create consistent results by sorting by name or id if items are equal according to the current sort option.
    return (Item a, Item b) {
      int result = _compareItems(a, b, sortOption);
      if (result != 0) return result;

      if (sortOption != SortOption.name) {
        result = _compareItems(a, b, SortOption.name);
        if (result != 0) return result;
      }
      return _compareItems(a, b, null);
    };
  }
//endregion
}
