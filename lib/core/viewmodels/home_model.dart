import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/api.dart';
import 'package:pigallery2_android/core/services/storage_helper.dart';
import 'package:pigallery2_android/core/util/strings.dart';
import 'package:pigallery2_android/core/util/extensions.dart';
import 'package:async/async.dart';

extension ParseToString on SortOption {
  String getName() {
    return toString().split('.').last.toCapitalized();
  }
}

enum SortOption { name, date, size, random }

/// Represents the data to be displayed for the current [HomeView].
class HomeModelState {
  /// [Directory] received from the [ApiService].
  Directory? baseDirectory;

  /// Whether to show a loading indicator.
  bool isLoading = false;

  /// Error received when requesting the [ApiService].
  String? error;

  /// Selected [SortOption] to be applied to [files].
  SortOption sortOption;

  /// Whether to sort with [sortOption] in ascending order.
  bool sortAscending;

  List<File> _files = List.unmodifiable([]);

  /// [File]s received from the [ApiService].
  List<File> get files => _files;

  final bool _isSearch;

  set files(List<File> val) {
    _files = List.unmodifiable(_sort(val));
  }

  /// All [files] of type [Media].
  List<Media> get media => files.whereType<Media>().toList();

  HomeModelState(this.baseDirectory, this.sortOption, this.sortAscending, this._isSearch);

  //region sorting
  bool updateSortOption(SortOption option) {
    if (option != sortOption || option == SortOption.random) {
      sortOption = option;
      _files = List.unmodifiable(_sort(_files.toList()));
      return true;
    }
    return false;
  }

  bool updateSortOrder(bool ascending) {
    if (sortAscending != ascending) {
      sortAscending = ascending;
      _files = List.unmodifiable(_files.toList().reversed);
      return true;
    }
    return false;
  }

  List<File> _sort(List<File> toSort) {
    if (_isSearch) return toSort;
    if (sortOption == SortOption.random) toSort.shuffle();
    toSort.sort(_compare(sortOption));
    return sortAscending ? toSort : toSort.reversed.toList();
  }

  int Function(File, File) _comparePreferDictionaries(int Function(Directory, Directory) directorySortFunction, int Function(Media, Media) mediaSortFunction) {
    /// Always list directories first.
    return (a, b) {
      if (a is Directory && b is Directory) {
        return directorySortFunction(a, b);
      } else if (a is Directory) {
        return -1;
      } else if (b is Directory) {
        return 1;
      }
      return mediaSortFunction(a as Media, b as Media);
    };
  }

  int Function(File, File) _compare(SortOption? sortOption) {
    int Function(File, File) compareFunction;
    switch (sortOption) {
      case SortOption.date:
        compareFunction = _comparePreferDictionaries(
          (Directory a, Directory b) => a.lastModified.compareTo(b.lastModified),
          (Media a, Media b) => a.metadata.creationDate.compareTo(b.metadata.creationDate),
        );
        break;
      case SortOption.name:
        compareFunction = _comparePreferDictionaries(
          (Directory a, Directory b) => compareNatural(a.name.toLowerCase(), b.name.toLowerCase()),
          (Media a, Media b) => compareNatural(a.name.toLowerCase(), b.name.toLowerCase()),
        );
        break;
      case SortOption.size:
        compareFunction = _comparePreferDictionaries(
          (Directory a, Directory b) => a.mediaCount.compareTo(b.mediaCount),
          (Media a, Media b) => a.metadata.fileSize.compareTo(b.metadata.fileSize),
        );
        break;
      case SortOption.random:
        compareFunction = _comparePreferDictionaries(
          (Directory a, Directory b) => 1,
          (Media a, Media b) => 1,
        );
        break;
      default:
        compareFunction = _comparePreferDictionaries(
          (Directory a, Directory b) => a.id.compareTo(b.id),
          (Media a, Media b) => a.id.compareTo(b.id),
        );
    }
    // Create consistent results by sorting by name or id if files are equal according to the current sort option.
    return (File a, File b) {
      int result = compareFunction(a, b);
      if (result == 0) {
        result = _compare(SortOption.name)(a, b);
        if (result == 0) {
          result = _compare(null)(a, b);
        }
      }
      return result;
    };
  }
  //endregion
}

class HomeModel extends ChangeNotifier {
  final List<HomeModelState> _state;

  /// [HomeModelState] of the given position in the [Navigator] stack.
  HomeModelState stateOf(int stackPosition) => _state[stackPosition];

  /// [HomeModelState] of the top-most [HomeView] in the [Navigator] stack.
  HomeModelState get currentState => _state.last;

  final StorageHelper _storageHelper;

  /// Chosen [SortOption] applied to all [HomeView] instances.
  SortOption get sortOption => currentState.sortOption;

  set sortOption(SortOption option) {
    for (HomeModelState state in _state) {
      state.updateSortOption(option);
    }
    _storageHelper.storeSortOption(StorageConstants.sortOptionKey, option);
    notifyListeners();
  }

  /// Whether to sort using [sortOption] in ascending order.
  bool get sortAscending => currentState.sortAscending;

  set sortOrder(bool sortAscending) {
    for (HomeModelState state in _state) {
      state.updateSortOrder(sortAscending);
    }
    _storageHelper.storeBool(StorageConstants.sortAscendingKey, sortAscending);
    notifyListeners();
  }

  final ApiService _apiDelegate;

  /// Retrieve headers from [ApiService].
  Map<String, String> get headers => _apiDelegate.headers;

  /// Retrieve serverUrl from [ApiService].
  String? get serverUrl => _apiDelegate.serverUrl;

  /// Whether an api request is ongoing.
  bool _requestAwaitingResponse = false;

  bool _isSearching = false;

  bool get isSearching => _isSearching;

  CancelableOperation? _currentSearch;

  HomeModel(this._apiDelegate, this._storageHelper)
      : _state = [
          HomeModelState(
            null,
            _storageHelper.getSortOption(StorageConstants.sortOptionKey, SortOption.name),
            _storageHelper.getBool(StorageConstants.sortAscendingKey, true),
            false,
          )
        ] {
    fetchItems();
  }

  /// Register a new [HomeView] instance.
  void addStack(Directory baseDirectory) {
    _state.add(HomeModelState(baseDirectory, sortOption, sortAscending, false));
    fetchItems();
  }

  /// Unregister a closed [HomeView] instance.
  void popStack() {
    if (_state.length == 1) {
      // never remove last screen; should be unreachable
      return;
    }
    _state.removeLast();
  }

  /// Request [File]s from the [ApiService] for the current [HomeView] screen.
  /// Ensures that only one request is executed at a time.
  Future<void> fetchItems() async {
    if (!_requestAwaitingResponse) {
      _requestAwaitingResponse = true;
      return _fetchItems().whenComplete(() => _requestAwaitingResponse = false);
    }
  }

  Future<void> _fetchItems() async {
    if (serverUrl == null) {
      currentState.error = Strings.errorNoServerConfigured;
      currentState.files = [];
      currentState.baseDirectory = null;
      notifyListeners();
      return;
    }

    currentState.isLoading = true;
    currentState.error = null;
    Directory? currentDirBefore = currentState.baseDirectory;
    notifyListeners();

    Directory? result = await _apiDelegate.getDirectories(path: currentState.baseDirectory?.apiPath).catchError((e) {
      currentState.error = e.toString();
      return Future<Directory?>.value(null);
    });
    // Ensure that state has not been updated before this call completed.
    if (currentDirBefore == currentState.baseDirectory) {
      currentState.baseDirectory = result;
      currentState.files = [];
      currentState.isLoading = false;
      if (result != null) {
        currentState.files = [...result.directories, ...result.media];
      }
      notifyListeners();
    }
  }

  void startSearch() {
    if (!_isSearching) {
      _state.add(HomeModelState(null, sortOption, sortAscending, true));
    }
    _isSearching = true;
  }

  void search(String searchText) {
    _currentSearch?.cancel();
    _currentSearch = CancelableOperation.fromFuture(_search(searchText)).then((result) {
      currentState.baseDirectory = result;
      currentState.files = [];
      currentState.isLoading = false;
      if (result != null) {
        currentState.files = [...result.directories, ...result.media];
      }
      notifyListeners();
    });
  }

  void stopSearch() {
    _currentSearch?.cancel();
    _currentSearch = null;
    _isSearching = false;
    popStack();
  }

  Future<Directory?> _search(String searchText) {
    if (serverUrl == null) {
      currentState.error = Strings.errorNoServerConfigured;
      currentState.files = [];
      currentState.baseDirectory = null;
      return Future<Directory?>.value(null);
    }
    currentState.isLoading = true;
    currentState.error = null;

    return _apiDelegate.search(searchText: searchText).catchError((e) {
      currentState.error = e.toString();
      return Future<Directory?>.value(null);
    });
  }
}
