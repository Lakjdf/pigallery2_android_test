import 'package:flutter/foundation.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/api.dart';

extension LastEmptyCheckExtension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
  T? tryGet(int index) => index >= 0 && index < length ? this[index] : null;
}

class HomeModelState {
  final List<File> files = [];
  Directory? currentDir;
}

class HomeModel extends ChangeNotifier {
  final List<HomeModelState> state = [HomeModelState()];

  List<File> get files => state.lastOrNull?.files ?? [];
  List<Directory> get directories => files.whereType<Directory>().toList();
  List<Media> get media => files.whereType<Media>().toList();
  Directory? get currentDir => state.lastOrNull?.currentDir;

  bool get isHomeView => state.length == 1;

  String? get serverUrl => api.serverUrl;

  String? error;

  final ApiService api;

  HomeModel(this.api);

  void addStack() {
    error = null;
    state.add(HomeModelState());
  }

  void popStack() {
    error = null;
    state.removeLast();
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

  Future<void> addDirectories({String baseDirectory = ""}) async {
    if (serverUrl == null) {
      error = 'Please add a Server';
      state.last.files.clear();
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
      state.last.files.clear();
      if (result != null) {
        state.last.files.addAll(result.directories);
        state.last.files.addAll(result.media);
      }
    }
  }

  Future<void> reset() async {
    await addDirectories();
    notifyListeners();
  }
}
