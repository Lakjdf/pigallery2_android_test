import 'package:flutter/foundation.dart';
import 'package:pigallery2_android/core/services/api.dart';
import 'package:pigallery2_android/core/services/models/models.dart';
import 'package:pigallery2_android/core/services/storage_helper.dart';

class ServerModel extends ChangeNotifier {
  final ApiService api;
  final StorageHelper storageHelper;

  ServerModel(this.api, this.storageHelper);

  bool testSuccessUrl = false;
  bool testSuccessAuth = false;
  bool testFailedUrl = false;
  bool testFailedAuth = false;
  List<String>? _serverUrls;
  SessionData? _lastSessionData;

  String? get serverUrl => api.serverUrl;

  void _loadServerUrls() {
    storageHelper.getServerUrls().then((value) {
      _serverUrls = value;
      notifyListeners();
    });
  }

  void addServer(String url, String? username, String? password) async {
    _serverUrls?.add(url);
    await storageHelper.storeServer(url, username, password);
    if (_lastSessionData != null) {
      await storageHelper.storeSessionData(url, _lastSessionData!);
      _lastSessionData = null;
    }
    if (_serverUrls!.length == 1) {
      await selectServer(url);
    }
    notifyListeners();
  }

  Future<void> deleteServer(String url) async {
    _serverUrls?.remove(url);
    await storageHelper.deleteServer(url);
    api.updateServer(await storageHelper.init());
    notifyListeners();
  }

  List<String> get serverUrls {
    if (_serverUrls == null) {
      _loadServerUrls();
    }
    return _serverUrls ?? [];
  }

  Future<void> selectServer(String url) async {
    api.updateServer(
      InitialServerData(
        serverUrl: url,
        sessionData: await storageHelper.getSessionData(url),
      ),
    );
    storageHelper.selectServer(url);
    notifyListeners();
  }

  void credentialsChanged() {
    testFailedAuth = false;
    testSuccessAuth = false;
    _lastSessionData = null;
    notifyListeners();
  }

  void urlChanged() {
    testFailedUrl = false;
    testSuccessUrl = false;
    testSuccessAuth = false;
    testFailedAuth = false;
    _lastSessionData = null;
    notifyListeners();
  }

  Future<void> testConnection(String url, String? username, String? password) async {
    TestConnectionResult result = await api.testConnection(url, username, password);
    if (result.serverUnreachable) {
      testFailedUrl = true;
      testFailedAuth = false;
      testSuccessAuth = false;
      testSuccessUrl = false;
      _lastSessionData = null;
    } else if (result.authFailed) {
      testFailedUrl = false;
      testFailedAuth = true;
      testSuccessUrl = true;
      testSuccessAuth = false;
      _lastSessionData = null;
    } else {
      testFailedUrl = false;
      testFailedAuth = false;
      testSuccessAuth = true;
      testSuccessUrl = true;
      _lastSessionData = result.sessionData;
    }
    notifyListeners();
  }

  reset() {
    testFailedAuth = false;
    testFailedUrl = false;
    testSuccessAuth = false;
    testSuccessUrl = false;
    _lastSessionData = null;
  }
}
