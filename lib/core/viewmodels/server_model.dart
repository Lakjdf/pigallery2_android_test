import 'package:flutter/foundation.dart';
import 'package:pigallery2_android/core/services/api.dart';
import 'package:pigallery2_android/core/services/models/models.dart';
import 'package:pigallery2_android/core/services/storage_helper.dart';
import 'package:pigallery2_android/core/util/extensions.dart';

class ServerModel extends ChangeNotifier {
  final ApiService api;
  final StorageHelper storageHelper;

  ServerModel(this.api, this.storageHelper) : _serverUrls = storageHelper.getServerUrls();

  bool testSuccessUrl = false;
  bool testSuccessAuth = false;
  bool testFailedUrl = false;
  bool testFailedAuth = false;
  final List<String> _serverUrls;
  SessionData? _lastSessionData;

  String? get serverUrl => api.serverUrl;

  Future<void> addServer(String url, String? username, String? password) async {
    if (_serverUrls.addDistinct(url)) {
      await storageHelper.storeServerUrls(_serverUrls);
      if (username != null && password != null) {
        await storageHelper.storeCredentials(url, username, password);
      }
      if (_lastSessionData != null) {
        await storageHelper.storeSessionData(url, _lastSessionData!);
        _lastSessionData = null;
      }
      if (_serverUrls.length == 1) {
        await selectServer(url);
      }
      notifyListeners();
    }
  }

  Future<void> deleteServer(String url) async {
    int selectedServerIndex = api.serverUrl?.let((it) => _serverUrls.indexOfOrNull(it)) ?? 0;
    _serverUrls.remove(url);
    await storageHelper.storeServerUrls(_serverUrls);
    await storageHelper.deleteCredentials(url);
    await storageHelper.storeSelectedServerIndex(selectedServerIndex < 2 ? 0 : selectedServerIndex - 1);
    api.updateServer(storageHelper.getSelectedServerData());
    notifyListeners();
  }

  List<String> get serverUrls => _serverUrls;

  Future<void> selectServer(String url) async {
    await storageHelper.storeSelectedServerIndex(_serverUrls.indexOfOrNull(url) ?? 0);
    api.updateServer(storageHelper.getServerData(url));
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
