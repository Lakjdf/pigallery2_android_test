import 'package:flutter/foundation.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/api.dart';

extension LastEmptyCheckExtension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
  T? tryGet(int index) => index >= 0 && index < length ? this[index] : null;
}

enum SortOption { name, date, size, random }

extension StringExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}

extension ParseToString on SortOption {
  String getName() {
    return toString().split('.').last.toCapitalized();
  }
}

class HomeModelState {
  List<File> _files = List.unmodifiable([]);
  Directory? currentDir;
  SortOption sortOption;
  bool sortAscending;

  HomeModelState({this.sortOption = SortOption.name, this.sortAscending = true});

  bool updateSortOption(SortOption option) {
    if (option != sortOption || option == SortOption.random) {
      sortOption = option;
      _files = List.unmodifiable(sort(_files.toList()));
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

  set files(List<File> val) {
    _files = List.unmodifiable(sort(val));
  }

  List<File> get files => _files;

  List<File> sort(List<File> toSort) {
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
          (Media a, Media b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
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
}

class HomeModel extends ChangeNotifier {
  final List<HomeModelState> state = [HomeModelState()];

  List<File> get files => state.lastOrNull?.files ?? [];
  List<Directory> get directories => files.whereType<Directory>().toList();
  List<Media> get media => files.whereType<Media>().toList();
  Directory? get currentDir => state.lastOrNull?.currentDir;

  bool get isHomeView => state.length == 1;

  String? get serverUrl => api.serverUrl;
  SortOption get sortOption => state.lastOrNull?.sortOption ?? SortOption.name;
  bool get sortAscending => state.lastOrNull?.sortAscending ?? true;

  set sortOption(SortOption option) {
    if (state.lastOrNull?.updateSortOption(option) == true) {
      notifyListeners();
    }
  }

  set sortOrder(bool sortAscending) {
    if (state.lastOrNull?.updateSortOrder(sortAscending) == true) {
      notifyListeners();
    }
  }

  String? error;

  final ApiService api;

  HomeModel(this.api);

  void addStack() {
    error = null;
    state.add(HomeModelState(sortOption: sortOption, sortAscending: sortAscending));
    notifyListeners();
  }

  void popStack() {
    error = null;
    state.removeLast();
    notifyListeners();
  }

  Map<String, String> getHeaders() => api.getHeaders();

  String getItemPath(File item) {
    DirectoryPath parentDirectory = currentDir!;
    if (item.runtimeType == Directory) {
      item = (item as Directory).preview!;
      parentDirectory = (item as DirectoryPreview).directory;
    }
    return "$serverUrl/api/gallery/content/${parentDirectory.path}${parentDirectory.name}/${item.name}";
  }

  String getThumbnailPath(File item) {
    return "${getItemPath(item)}/thumbnail";
  }

  Future<void> fetchItems({String baseDirectory = ""}) async {
    if (serverUrl == null) {
      error = 'Please add a Server';
      state.last.files = [];
      state.last.currentDir = null;
      return Future.value();
    }

    Directory? currentDirBefore = currentDir;
    error = null;

    Directory? result = await api.getDirectories(path: baseDirectory).catchError((e) {
      error = e.toString();
      return Future<Directory?>.value(null);
    });
    // Ensure that state has not been updated before this call completed.
    if (currentDirBefore == currentDir) {
      state.last.currentDir = result;
      state.last.files = [];
      if (result != null) {
        state.last.files = [...result.directories, ...result.media];
      }
    }
  }

  Future<void> reset() async {
    await fetchItems();
    notifyListeners();
  }
}
