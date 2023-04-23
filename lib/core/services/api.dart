import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/models/models.dart';
import 'package:pigallery2_android/core/services/pigallery2_api.dart';
import 'package:pigallery2_android/core/services/storage_helper.dart';

class ApiService {
  late PiGallery2API _api;
  SessionData? _sessionData;
  String? serverUrl;
  final StorageHelper _storageHelper;

  String get _serverUrl {
    if (serverUrl == null) {
      throw Exception("Please add a server");
    }
    return serverUrl!;
  }

  Map<String, String> get headers => _api.getHeaders(_sessionData);
  String get directoriesEndpoint => _api.getDirectoriesEndpoint(serverUrl);

  ApiService({
    required InitialServerData initialServerData,
    required StorageHelper storageHelper,
  }) : _storageHelper = storageHelper {
    serverUrl = initialServerData.serverUrl;
    _sessionData = initialServerData.sessionData;

    _api = PiGallery2API();
  }

  void updateServer(InitialServerData initialServerData) {
    serverUrl = initialServerData.serverUrl;
    _sessionData = initialServerData.sessionData;
  }

  Future<Directory?> getDirectories({String path = ""}) async {
    ApiResponse<Directory> response = await _api.getDirectories(serverUrl: _serverUrl, path: path, sessionData: _sessionData);

    if (response.code == 401) {
      /// retry with stored credentials
      LoginCredentials? credentials = await _storageHelper.getServerCredentials(_serverUrl);
      if (credentials != null) {
        _sessionData ??= (await _api.login(_serverUrl, credentials)).result;
        if (_sessionData != null) {
          response = await _api.getDirectories(serverUrl: _serverUrl, path: path, sessionData: _sessionData);
          if (response.code == 200 && response.error == null) {
            await _storageHelper.storeSessionData(_serverUrl, _sessionData!);
          }
        }
      }
    }
    if (response.error != null) {
      throw Exception(response.error);
    }
    return response.result;
  }

  Future<TestConnectionResult> testConnection(String url, String? username, String? password) async {
    if (username != null && password != null) {
      ApiResponse<SessionData> loginResponse = await _api.login(url, LoginCredentials(username, password));
      if (loginResponse.result == null) {
        if (loginResponse.code == 200) {
          return TestConnectionResult(authFailed: true);
        } else {
          return TestConnectionResult(serverUnreachable: true);
        }
      }
      return TestConnectionResult(sessionData: loginResponse.result);
    }
    ApiResponse<Directory> response = await _api.getDirectories(serverUrl: url, path: "", sessionData: null);
    if (response.code == 200 && response.error == null) {
      return TestConnectionResult();
    } else if (response.code == 401) {
      return TestConnectionResult(authFailed: true);
    }
    return TestConnectionResult(serverUnreachable: true);
  }
}
