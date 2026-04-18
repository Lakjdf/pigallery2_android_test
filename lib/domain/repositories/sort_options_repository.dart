import 'package:pigallery2_android/domain/models/sort_option.dart';

abstract interface class SortOptionsRepository {
  /// Get the [SortOption] to be used for the given [sortingKey].
  /// Returns default sort options if nothing is stored for the key.
  SortOption getSortOption(SortingKey? sortingKey);

  /// Store a sort option specific to the [sortingKey].
  Future<void> storeSortOption(SortingKey? sortingKey, SortOption sortOption);

  /// Delete stored options for [sortingKey].
  /// [getSortOption] will return the default values for it again.
  Future<void> deleteSortOption(SortingKey sortingKey);
}

/// For global [SortOption]s applying whenever "Only this Folder" is not checked.
const String defaultSortingKey = ".default";

/// Represents a key for which [SortOption]s can be stored.
abstract interface class SortingKey {
  final String key;

  SortingKey(this.key);
}

class TopPicksSortingKey implements SortingKey {
  @override
  String get key => ".TopPicks";
}

class FlattenSortingKey implements SortingKey {
  @override
  String get key => ".Flatten";
}

class TimelineSortingKey implements SortingKey {
  @override
  String get key => ".Timeline";
}

class SearchSortingKey implements SortingKey {
  @override
  String get key => ".Search";
}

class DirectorySortingKey implements SortingKey {
  final String _key;

  DirectorySortingKey(this._key);

  @override
  String get key => _key;
}

class AlbumSortingKey implements SortingKey {
  final int id;

  AlbumSortingKey(this.id);

  @override
  String get key => ".Album.$id";
}
