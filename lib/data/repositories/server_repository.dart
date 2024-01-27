import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/backend/models/auth/connection_test_result.dart';
import 'package:pigallery2_android/data/storage/credential_storage.dart';
import 'package:pigallery2_android/data/storage/models/session_data.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_helper.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/util/extensions.dart';

class ServerRepositoryImpl implements ServerRepository {
  final ApiService _api;
  final CredentialStorage _credentialStorage;
  final SharedPrefsStorage _storage;
  late StorageHelper _storageHelper;

  ServerRepositoryImpl(this._api, this._storage, this._credentialStorage) {
    _storageHelper = StorageHelper(_storage);
  }

  @override
  String? get serverUrl => _storageHelper.getSelectedServerUrl();

  @override
  List<String> get serverUrls => _storage.get(StorageKey.serverUrls);

  @override
  Future<bool> addServer(String url, String? username, String? password, SessionData? sessionData) async {
    List<String> currentServerUrls = serverUrls;
    if (currentServerUrls.addDistinct(url)) {
      await _storage.set(StorageKey.serverUrls, currentServerUrls);
      if (username != null && password != null) {
        await _credentialStorage.storeCredentials(url, username, password);
      }
      if (sessionData != null) {
        await _storageHelper.storeSessionData(url, sessionData);
        sessionData = null;
      }
      if (currentServerUrls.length == 1) {
        await selectServer(url);
      }
      return true;
    }
    return false;
  }

  @override
  Future<void> deleteServer(String url) async {
    List<String> currentServerUrls = serverUrls;
    int selectedServerIndex = _storage.get(StorageKey.selectedServer);
    currentServerUrls.remove(url);
    await _storage.set(StorageKey.serverUrls, currentServerUrls);
    await _credentialStorage.deleteCredentials(url);
    await _storage.set(StorageKey.selectedServer, selectedServerIndex < 2 ? 0 : selectedServerIndex - 1);
  }

  @override
  Future<void> selectServer(String url) async {
    await _storage.set(StorageKey.selectedServer, serverUrls.indexOfOrNull(url) ?? 0);
  }

  @override
  Future<ConnectionTestResult> testConnection(String url, String? username, String? password) {
    return _api.testConnection(url, username, password);
  }
}
