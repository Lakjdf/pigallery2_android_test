import 'package:pigallery2_android/data/backend/models/search/search.dart';
import 'package:pigallery2_android/data/storage/models/sort_option.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:async/async.dart';
import 'package:pigallery2_android/domain/models/sort_option.dart';
import 'package:pigallery2_android/domain/repositories/album_repository.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'package:pigallery2_android/domain/repositories/sort_options_repository.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:pigallery2_android/util/strings.dart';

import 'gallery_model_state.dart';

class GalleryModel extends SafeChangeNotifier {
  final AlbumRepository _albumRepository;
  final ItemRepository _itemRepository;
  final SortOptionsRepository _sortOptionsRepository;
  final List<GalleryModelState> _state;
  final bool isAlbumView;
  final Set<int> _selectedMediaIds = <int>{};

  bool _initialFetchDone = false;

  GalleryModel(
    this._albumRepository,
    this._itemRepository,
    this._sortOptionsRepository,
    this.isAlbumView, {
    GalleryModelStateType? initialStateType,
  }) : _state = [
         GalleryModelState(
           initialStateType ?? DirectoryGalleryModelStateType(),
           null,
           _sortOptionsRepository,
         ),
       ];

  /// Trigger the first fetch. No-op once the initial load has already
  /// happened. Tabs call this when they actually become visible so that
  /// background tabs don't pay for a fetch the user may never look at.
  void ensureInitialFetch() {
    if (_initialFetchDone) return;
    _initialFetchDone = true;
    fetch();
  }

  /// [GalleryModelState] of the given position in the [Navigator] stack.
  GalleryModelState stateOf(int stackPosition) => _state[stackPosition];

  bool get isSelectionActive => _selectedMediaIds.isNotEmpty;

  int get selectedMediaCount => _selectedMediaIds.length;

  List<Media> get selectedMedia => currentState.media.where((media) => _selectedMediaIds.contains(media.id)).toList();

  bool isMediaSelected(Media media) => _selectedMediaIds.contains(media.id);

  void enterSelectionMode(Media media) {
    if (!_selectedMediaIds.contains(media.id)) {
      _selectedMediaIds.add(media.id);
      notifyListeners();
    }
  }

  void toggleSelection(Media media) {
    if (_selectedMediaIds.contains(media.id)) {
      _selectedMediaIds.remove(media.id);
    } else {
      _selectedMediaIds.add(media.id);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedMediaIds.isNotEmpty) {
      _selectedMediaIds.clear();
      notifyListeners();
    }
  }

  /// How many pages are on the [Navigator] stack.
  int get stackPosition => _state.length - 1;

  /// [GalleryModelState] of the top-most [HomeView] in the [Navigator] stack.
  GalleryModelState get currentState => _state.last;

  CancelableOperation<Directory?>? _currentRequest;

  SortOption get sortOption => currentState.sortOption;

  void setSortType(SortType type) {
    if (sortOption.onlyThisFolder) {
      currentState.sortType = type;
    } else {
      for (GalleryModelState state in _state) {
        if (!state.sortOption.onlyThisFolder) {
          state.sortType = type;
        }
      }
    }

    _sortOptionsRepository.storeSortOption(
      sortOption.onlyThisFolder ? currentState.sortingKey : null,
      SortOption(order: currentState.sortOption.order, type: type, onlyThisFolder: sortOption.onlyThisFolder),
    );
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    if (sortOption.onlyThisFolder) {
      currentState.sortOrder = order;
    } else {
      for (GalleryModelState state in _state) {
        if (!state.sortOption.onlyThisFolder) {
          state.sortOrder = order;
        }
      }
    }

    _sortOptionsRepository.storeSortOption(
      sortOption.onlyThisFolder ? currentState.sortingKey : null,
      SortOption(order: order, type: currentState.sortOption.type, onlyThisFolder: sortOption.onlyThisFolder),
    );
    notifyListeners();
  }

  void setSortOnlyThisFolder(bool onlyThisFolder) {
    SortingKey? sortingKey = currentState.sortingKey;
    if (!onlyThisFolder) {
      if (sortingKey != null) {
        _sortOptionsRepository.deleteSortOption(sortingKey);
      }
      SortOption sortOption = _sortOptionsRepository.getSortOption(sortingKey);
      currentState.sortOrder = sortOption.order;
      currentState.sortType = sortOption.type;
    } else {
      _sortOptionsRepository.storeSortOption(sortingKey, currentState.sortOption);
    }
    currentState.sortOnlyThisFolder = onlyThisFolder;
    notifyListeners();
  }

  void _addStack(GalleryModelState state) {
    _state.add(state);
  }

  /// Register a new [HomeView] instance.
  void addStack(Directory baseDirectory) {
    clearSelection();
    final type = baseDirectory is Album ? AlbumGalleryModelStateType() : DirectoryGalleryModelStateType();
    _addStack(GalleryModelState(type, baseDirectory, _sortOptionsRepository));
    fetch();
  }

  /// Unregister a closed [HomeView] instance.
  void popStack() {
    if (_state.length == 1) {
      // never remove last screen; should be unreachable
      return;
    }
    clearSelection();
    _currentRequest?.cancel();
    _currentRequest = null;
    _state.removeLast();
  }

  /// Update [currentState] to represent the given [Directory].
  void _updateCurrentState(Directory? result) {
    currentState.isLoading = false;
    if (result != null) {
      if (currentState.type is AlbumGalleryModelStateType) {
        if (currentState.baseDirectory is Album) {
          currentState.sortingKey ??= AlbumSortingKey((currentState.baseDirectory as Album).id);
        }
      } else {
        currentState.baseDirectory = result;
        currentState.sortingKey ??= DirectorySortingKey(result.relativeApiPath);
      }
      currentState.sortOption = _sortOptionsRepository.getSortOption(currentState.sortingKey);
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
  Future<void> _apiRequest(CancelableOperation<Directory?> request, bool isRefresh) async {
    currentState.error = null;
    if (!isRefresh) _setIsLoadingDelayed(_currentRequest);

    return request.then((result) {
      _updateCurrentState(result);
      notifyListeners();
    }).value;
  }

  /// Cancels the previous request when invoking the given [request].
  Future<void> _cancelableApiRequest(Future<Directory?> Function() request, bool isRefresh) async {
    _currentRequest?.cancel();
    try {
      CancelableOperation<Directory?> cancelableRequest = CancelableOperation.fromFuture(request());
      _currentRequest = cancelableRequest;
      await _apiRequest(cancelableRequest, isRefresh);
    } on Exception catch (e) {
      _updateCurrentState(null);
      currentState.error = e.toString().replaceAll(Strings.exceptionPrefix, "");
      notifyListeners();
      return Future.value();
    }
  }

  Future<void> fetch({bool isRefresh = false}) => switch (currentState.type) {
    SearchGalleryModelStateType(:final query) => _cancelableApiRequest(() {
      return _itemRepository.search(query);
    }, isRefresh),
    FlattenGalleryModelStateType(:final target) => _cancelableApiRequest(() {
      return _itemRepository.flattenDirectory(target);
    }, isRefresh),
    TimelineGalleryModelStateType() => _cancelableApiRequest(() {
      return _itemRepository.flattenDirectory(null);
    }, isRefresh),
    AlbumGalleryModelStateType() => _cancelableApiRequest(() {
      return _albumRepository.getAlbumContent(currentState.baseDirectory as Album);
    }, isRefresh),
    DirectoryGalleryModelStateType() => _cancelableApiRequest(() {
      if (stackPosition == 0 && isAlbumView) {
        return _albumRepository.getAlbums();
      }
      return _itemRepository.getDirectories(path: currentState.baseDirectory?.relativeApiPath);
    }, isRefresh),
    _ => Future.value(),
  };

  /// Result will be available via [currentState].
  void search(SearchQueryDTO query) {
    clearSelection();
    if (!currentState.isSearching) {
      var type = SearchGalleryModelStateType(query: query);
      _addStack(GalleryModelState(type, null, _sortOptionsRepository));
    } else {
      currentState.type = SearchGalleryModelStateType(query: query);
    }
    fetch();
  }

  /// Flatten the current directory.
  /// Result will be available via [currentState].
  void flattenDir() {
    clearSelection();
    var type = FlattenGalleryModelStateType(target: currentState.baseDirectory);
    _addStack(GalleryModelState(type, null, _sortOptionsRepository));
    fetch();
  }

  /// Add a new stack displaying the content of the given [directory]. No api requests done here.
  void topPicksSearch(Directory directory) {
    clearSelection();
    _addStack(GalleryModelState(TopPicksGalleryModelStateType(), directory, _sortOptionsRepository));
    currentState.items = directory.media;
    notifyListeners();
  }
}
