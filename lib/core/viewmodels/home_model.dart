import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/api.dart';

extension StringExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}

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

  /// Name of the base directory.
  String baseDirectoryName;

  List<File> _files = List.unmodifiable([]);

  /// [File]s received from the [ApiService].
  List<File> get files => _files;

  set files(List<File> val) {
    _files = List.unmodifiable(_sort(val));
  }

  /// All [files] of type [Media].
  List<Media> get media => files.whereType<Media>().toList();

  HomeModelState(this.baseDirectoryName, {this.sortOption = SortOption.name, this.sortAscending = true});

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
      if (a.runtimeType == Directory && b.runtimeType == Directory) {
        return directorySortFunction(a as Directory, b as Directory);
      } else if (a.runtimeType == Directory) {
        return -1;
      } else if (b.runtimeType == Directory) {
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
          (Directory a, Directory b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
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

  String _relativeApiPath(DirectoryPath directoryPath) => "${directoryPath.path}${directoryPath.name}";

  /// Relative API path to [item].
  String getRelativeMediaApiPath(Media item) {
    return "${_relativeApiPath(baseDirectory!)}/${item.name}";
  }

  /// Relative API path to the thumbnail of [item].
  String getRelativeThumbnailApiPath(File item) {
    DirectoryPath parentDirectory = baseDirectory!;
    if (item.runtimeType == Directory) {
      item = (item as Directory).preview!;
      parentDirectory = (item as DirectoryPreview).directory;
    }
    return "${_relativeApiPath(parentDirectory)}/${item.name}/thumbnail";
  }
}

class HomeModel extends ChangeNotifier {
  final List<HomeModelState> _state = [HomeModelState("")];

  /// [HomeModelState] of the given position in the [Navigator] stack.
  HomeModelState stateOf(int stackPosition) => _state[stackPosition];

  /// [HomeModelState] of the top-most [HomeView] in the [Navigator] stack.
  HomeModelState get currentState => _state.last;

  /// Chosen [SortOption] applied to all [HomeView] instances.
  SortOption get sortOption => currentState.sortOption;

  set sortOption(SortOption option) {
    for (HomeModelState state in _state) { state.updateSortOption(option); }
    notifyListeners();
  }

  /// Whether to sort using [sortOption] in ascending order.
  bool get sortAscending => currentState.sortAscending;

  set sortOrder(bool sortAscending) {
    for (HomeModelState state in _state) { state.updateSortOrder(sortAscending); }
    notifyListeners();
  }

  final ApiService _apiDelegate;

  /// Retrieve headers from [ApiService].
  Map<String, String> get headers => _apiDelegate.headers;

  /// Retrieve serverUrl from [ApiService].
  String? get serverUrl => _apiDelegate.serverUrl;

  /// Enter full screen. Disregards [appInFullScreen].
  void enableFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Leave full screen. Disregards [appInFullScreen].
  void disableFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
  }

  bool _appInFullScreen = false;

  /// Whether the application is in full screen mode.
  /// Fullscreen mode will always be entered when entering [FullScreenView] disregarding this setting.
  bool get appInFullScreen => _appInFullScreen;

  /// Toggle value of [appInFullScreen].
  void toggleAppInFullScreen() {
    _appInFullScreen = !_appInFullScreen;
    if (_appInFullScreen) {
      enableFullScreen();
    } else {
      disableFullScreen();
    }
    notifyListeners();
  }

  /// Whether an api request is ongoing.
  bool _requestAwaitingResponse = false;

  HomeModel(this._apiDelegate) {
    fetchItems();
  }

  /// API path to [item] of the [state].
  String getMediaApiPath(HomeModelState state, Media item) {
    return "${_apiDelegate.directoriesEndpoint}${state.getRelativeMediaApiPath(item)}";
  }

  /// API path to the thumbnail of [item] of the [state].
  String getThumbnailApiPath(HomeModelState state, File item) {
    return "${_apiDelegate.directoriesEndpoint}${state.getRelativeThumbnailApiPath(item)}";
  }

  /// Path to the current directory based on concatenating directory names.
  String get _currentBaseDirectoryPath {
    return _state.where((e) => e.baseDirectoryName.isNotEmpty).map((e) => e.baseDirectoryName).join("/");
  }

  /// Register a new [HomeView] instance.
  void addStack(String baseDirectory) {
    _state.add(HomeModelState(baseDirectory, sortOption: sortOption, sortAscending: sortAscending));
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
      return _fetchItems().then((value) => _requestAwaitingResponse = false);
    }
  }

  Future<void> _fetchItems() async {
    if (serverUrl == null) {
      currentState.error = 'Please add a Server';
      currentState.files = [];
      currentState.baseDirectory = null;
      notifyListeners();
      return Future.value();
    }

    currentState.isLoading = true;
    currentState.error = null;
    Directory? currentDirBefore = currentState.baseDirectory;
    notifyListeners();

    Directory? result = await _apiDelegate.getDirectories(path: _currentBaseDirectoryPath).catchError((e) {
      currentState.error = e.toString();
      return Future<Directory?>.value(null);
    });
    // Ensure that state has not been updated before this call completed.
    if (currentDirBefore == currentState.baseDirectory) {
      currentState.baseDirectory = result;
      currentState.files = [];
      if (result != null) {
        currentState.files = [...result.directories, ...result.media];
      }
    }
    currentState.isLoading = false;
    notifyListeners();
  }
}
