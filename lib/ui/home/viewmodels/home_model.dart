import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:async/async.dart';
import 'package:pigallery2_android/domain/models/sort_option.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

import 'home_model_state.dart';

class HomeModel extends SafeChangeNotifier {
  final ItemRepository _itemRepository;
  final SharedPrefsStorage _storage;
  final List<HomeModelState> _state;

  HomeModel(this._itemRepository, this._storage)
      : _state = [
          HomeModelState(
            null,
            _storage.get(StorageKey.sortOption),
            _storage.get(StorageKey.sortAscending)
          )
        ] {
    fetchItems();
  }

  /// [HomeModelState] of the given position in the [Navigator] stack.
  HomeModelState stateOf(int stackPosition) => _state[stackPosition];

  /// How many pages are on the [Navigator] stack.
  int get stackPosition => _state.length - 1;

  /// [HomeModelState] of the top-most [HomeView] in the [Navigator] stack.
  HomeModelState get currentState => _state.last;

  /// Whether a server has been added.
  bool get isServerConfigured => _storage.get(StorageKey.serverUrls).isNotEmpty;

  bool _isSearchPending = false;

  /// Whether a search view has been entered, but no search has been submitted yet.
  bool get isSearchPending => _isSearchPending;

  CancelableOperation<Directory?>? _currentRequest;

  /// Chosen [SortOption] applied to all [HomeView] instances.
  SortOption get sortOption => currentState.sortOption;

  set sortOption(SortOption option) {
    for (HomeModelState state in _state) {
      state.updateSortOption(option);
    }
    _storage.set(StorageKey.sortOption, option);
    notifyListeners();
  }

  /// Whether to sort using [sortOption] in ascending order.
  bool get sortAscending => currentState.sortAscending;

  set sortOrder(bool sortAscending) {
    for (HomeModelState state in _state) {
      state.updateSortOrder(sortAscending);
    }
    _storage.set(StorageKey.sortAscending, sortAscending);
    notifyListeners();
  }

  void _addStack(HomeModelState state) {
    _isSearchPending = false;
    _state.add(state);
  }

  /// Register a new [HomeView] instance.
  void addStack(Directory baseDirectory) {
    _addStack(HomeModelState(baseDirectory, sortOption, sortAscending));
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
    _isSearchPending = false;
  }

  void startSearch() {
    if (!_isSearchPending) {
      _isSearchPending = true;
    }
  }

  void stopSearch() {
    if (!_isSearchPending) {
      popStack();
    } else {
      _isSearchPending = false;
    }
  }

  void topPicksSearch(Directory directory) {
    _addStack(HomeModelState.searching(sortOption, sortAscending, baseDirectory: directory));
    currentState.items = directory.media;
    notifyListeners();
  }

  /// Update [currentState] to represent the given [Directory].
  void _updateCurrentState(Directory? result) {
    currentState.isLoading = false;
    if (result != null) {
      currentState.baseDirectory = result;
      currentState.items = [...result.directories, ...result.media];
    } else {
      currentState.items = [];
    }
  }

  /// Set [isLoading] if the request takes more than 200ms.
  /// Leads to a smoother transition if the loading screen would only be shown for a short time.
  void _setIsLoadingDelayed(CancelableOperation? request) {
    Future.delayed(const Duration(milliseconds: 200), () {
      return request == null || request.isCanceled || request.isCompleted;
    }).then((isRequestFinished) {
      if (!isRequestFinished) {
        currentState.isLoading = true;
        notifyListeners();
      }
    });
  }

  /// Perform the given api request & update the state according to the progress/result.
  Future<void> _apiRequest(CancelableOperation<Directory?> request) async {
    currentState.error = null;
    _setIsLoadingDelayed(_currentRequest);

    return request.then((result) {
      _updateCurrentState(result);
      notifyListeners();
    }).value;
  }

  /// Cancels the previous request when invoking the given [request].
  void _cancelableApiRequest(Future<Directory?> Function() request) async {
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

  /// Request [Item]s from the [ApiService] for the current [HomeView] screen.
  /// Result will be available via [currentState].
  void fetchItems() {
    _cancelableApiRequest(() {
      return _itemRepository.getDirectories(path: currentState.baseDirectory?.relativeApiPath);
    });
  }

  /// Start a search for the given text [searchText].
  /// Result will be available via [currentState].
  void textSearch(String searchText) {
    if (currentState.isSearching && currentState.title == searchText) return;
    if (!currentState.isSearching) {
      _addStack(HomeModelState.searching(sortOption, sortAscending, title: searchText));
    }
    Directory? baseDir = _state.reversed.skip(1).first.baseDirectory;
    _cancelableApiRequest(() {
      return _itemRepository.search(baseDir, searchText);
    });
  }

  /// Flatten the current directory.
  /// Result will be available via [currentState].
  void flattenDir() {
    Directory? dirToFlatten = currentState.baseDirectory;
    _addStack(HomeModelState.searching(sortOption, sortAscending, title: dirToFlatten?.name));
    _cancelableApiRequest(() {
      return _itemRepository.flattenDirectory(dirToFlatten);
    });
  }
}
