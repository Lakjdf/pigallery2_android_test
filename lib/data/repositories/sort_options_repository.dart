import 'package:collection/collection.dart';
import 'package:pigallery2_android/data/storage/models/server_settings.dart';
import 'package:pigallery2_android/data/storage/models/sort_option.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/domain/models/sort_option.dart';
import 'package:pigallery2_android/domain/repositories/sort_options_repository.dart';

class SortOptionsRepositoryImpl implements SortOptionsRepository {
  final SharedPrefsStorage _storage;

  SortOptionsRepositoryImpl(this._storage);

  ServerSettings get _serverSettings => _storage.get(StorageKey.serverSettings);

  Server? get _currentServer {
    return _serverSettings.servers.firstWhereOrNull((it) => it.id == _serverSettings.selectedServer);
  }

  Map<String, StoredSortOption>? get _sortOptions {
    return _currentServer?.sortOptions.options;
  }

  @override
  SortOption getSortOption(SortingKey? sortingKey) {
    Map<String, StoredSortOption>? options = _sortOptions;
    if (options == null) return SortOption.initial();
    StoredSortOption? storedOption = options.entries.firstWhereOrNull((it) => it.key == sortingKey?.key)?.value;
    if (storedOption != null) {
      return SortOption(order: storedOption.order, type: storedOption.type, onlyThisFolder: true);
    }
    storedOption = options[defaultSortingKey];
    if (storedOption != null) {
      return SortOption(order: storedOption.order, type: storedOption.type, onlyThisFolder: false);
    }
    return SortOption.initial();
  }

  Future<void> _storeSortOptions(Map<String, StoredSortOption> sortOptions) async {
    ServerSettings updatedSettings = _serverSettings.copyWith(
      servers: _serverSettings.servers.map((it) {
        if (it.id == _currentServer?.id) {
          return it.copyWith(sortOptions: StoredSortOptions(options: sortOptions));
        }
        return it;
      }).toList(),
    );
    await _storage.set(StorageKey.serverSettings, updatedSettings);
  }

  @override
  Future<void> storeSortOption(SortingKey? sortingKey, SortOption sortOption) async {
    Map<String, StoredSortOption>? options = _sortOptions;
    if (options == null) return;
    options[sortingKey?.key ?? defaultSortingKey] = StoredSortOption(order: sortOption.order, type: sortOption.type);
    await _storeSortOptions(options);
  }

  @override
  Future<void> deleteSortOption(SortingKey sortingKey) async {
    Map<String, StoredSortOption>? options = _sortOptions;
    if (options == null) return;
    options.remove(sortingKey.key);
    await _storeSortOptions(options);
  }
}
