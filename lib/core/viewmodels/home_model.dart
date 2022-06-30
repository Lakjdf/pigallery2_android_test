import 'package:flutter/foundation.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/api.dart';

extension LastEmptyCheckExtension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}

class HomeModelState {
  final List<File> files = [];
  bool loading = false;
  bool returnedEmpty = false;
  Directory? currentDir;
}

class HomeModel extends ChangeNotifier {
  final List<HomeModelState> state = [HomeModelState()];

  bool get loading => state.lastOrNull?.loading ?? false;
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
    notifyListeners();
  }

  void popStack() {
    error = null;
    state.removeLast();
    notifyListeners();
  }

  Map<String, String> getHeaders() => api.getHeaders();

  Future<void> addDirectories({String baseDirectory = ""}) async {
    if (serverUrl == null) {
      error = 'Please add a Server';
      state.last.files.clear();
      state.last.currentDir = null;
      return Future.value(null);
    }

    Directory? currentDirBefore = currentDir;
    state.last.loading = true;
    error = null;
    Directory? result = await api.getDirectories(path: baseDirectory).catchError((e) {
      error = e.toString();
      return Future<Directory?>.value(null);
    });
    state.last.loading = false;
    // Ensure that state has not been updated before this call completed.
    if (currentDirBefore == currentDir) {
      state.last.currentDir = result;
      state.last.files.clear();
      if (result != null) {
        state.last.files.addAll(result.directories);
        state.last.files.addAll(result.media);
      }
      notifyListeners();
    }
  }

  Future<void> reset() async {
    await addDirectories();
    notifyListeners();
  }
}
