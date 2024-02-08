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
            _storage.get(StorageKey.sortAscending),
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

  bool _isSearching = false;

  bool get isSearching => _isSearching;

  /// Whether the current state represents a flattened directory.
  bool isFlattened(int stackPosition) {
    if (stackPosition == 0) return false;
    if (stateOf(stackPosition).baseDirectory == null) return true;
    return _state.length > 1 && stateOf(stackPosition).baseDirectory?.name == stateOf(stackPosition - 1).baseDirectory?.relativeApiPath;
  }

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
    if (currentState.baseDirectory?.name == searchText) return;
    _cancelableApiRequest(() {
      return _itemRepository.search(searchText: searchText);
    });
  }

  /// Flatten the current directory.
  /// Result will be available via [currentState].
  void flattenDir() {
    _state.add(HomeModelState(null, sortOption, sortAscending));
    _cancelableApiRequest(() {
      return _itemRepository.flattenDirectory(currentState.baseDirectory);
    });
  }
}
