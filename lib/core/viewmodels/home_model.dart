import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/api.dart';
import 'package:pigallery2_android/core/services/storage_helper.dart';
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

  set files(List<File> val) {
    _files = List.unmodifiable(_sort(val));
  }

  /// All [files] of type [Media].
  List<Media> get media => files.whereType<Media>().toList();

  HomeModelState(this.baseDirectory, this.sortOption, this.sortAscending);

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
      if (result != 0) return result;

      if (sortOption != SortOption.name) {
        result = _compare(SortOption.name)(a, b);
        if (result != 0) return result;
      }

      return _compare(null)(a, b);
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

  bool _isSearching = false;

  bool get isSearching => _isSearching;

  CancelableOperation<Directory?>? _currentRequest;

  HomeModel(this._apiDelegate, this._storageHelper)
      : _state = [
          HomeModelState(
            null,
            _storageHelper.getSortOption(StorageConstants.sortOptionKey, SortOption.name),
            _storageHelper.getBool(StorageConstants.sortAscendingKey, true)
          )
        ] {
    fetchItems();
  }

  /// Register a new [HomeView] instance.
  void addStack(Directory baseDirectory) {
    _state.add(HomeModelState(baseDirectory, sortOption, sortAscending));
    fetchItems();
  }

  /// Unregister a closed [HomeView] instance.
  void popStack() {
    if (_state.length == 1) {
      // never remove last screen; should be unreachable
      return;
    }
    _currentRequest?.cancel();
    _currentRequest = null;
    _state.removeLast();
  }

  void startSearch() {
    if (!_isSearching) {
      _state.add(HomeModelState(null, sortOption, sortAscending));
      _isSearching = true;
    }
  }

  void stopSearch() {
    if (_isSearching) {
      _isSearching = false;
      popStack();
    }
  }

  void topPicksSearch(Directory directory) {
    _state.add(HomeModelState(directory, sortOption, sortAscending));
    _isSearching = true;
    currentState.files = directory.media;
    notifyListeners();
  }

  /// Update [currentState] to represent the given [Directory].
  void _updateCurrentState(Directory? result) {
    currentState.isLoading = false;
    if (result != null) {
      currentState.baseDirectory = result;
      currentState.files = [...result.directories, ...result.media];
    } else {
      currentState.files = [];
    }
  }

  /// Perform the given api request & update the state according to the progress/result.
  Future<void> _apiRequest(CancelableOperation<Directory?> request) async {
    currentState.isLoading = true;
    currentState.error = null;

    return request.then((result) {
      _updateCurrentState(result);
      notifyListeners();
    }).value;
  }

  /// Cancels the previous request when invoking the given [request].
  Future<void> _cancelableApiRequest(Future<Directory?> Function() request) async {
    _currentRequest?.cancel();
    try {
      CancelableOperation<Directory?> cancelableRequest = CancelableOperation.fromFuture(request());
      _currentRequest = cancelableRequest;
      await _apiRequest(cancelableRequest);
    } on Exception catch (e) {
      _updateCurrentState(null);
      currentState.error = e.toString();
      notifyListeners();
      return Future.value();
    }
  }

  /// Request [File]s from the [ApiService] for the current [HomeView] screen.
  /// Result will be available via [currentState].
  void fetchItems() {
    _cancelableApiRequest(() {
      return _apiDelegate.getDirectories(path: currentState.baseDirectory?.apiPath);
    });
  }

  /// Start a search for the given text [searchText].
  /// Result will be available via [currentState].
  void textSearch(String searchText) {
    _cancelableApiRequest(() {
      return _apiDelegate.search(searchText: searchText);
    });
  }
}
