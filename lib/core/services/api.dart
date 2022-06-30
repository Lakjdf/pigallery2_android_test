import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/models/models.dart';
import 'package:pigallery2_android/core/services/pigallery2_api.dart';
import 'package:pigallery2_android/core/services/storage_helper.dart';

class ApiService {
  late PiGallery2API api;
  SessionData? sessionData;
  String? serverUrl;
  StorageHelper storageHelper;

  String get _serverUrl {
    if (serverUrl == null) {
      throw Exception("Please add a server");
    }
    return serverUrl!;
  }

  Map<String, String> getHeaders() => api.getHeaders(sessionData);

  ApiService({
    required InitialServerData initialServerData,
    required this.storageHelper,
  }) {
    serverUrl = initialServerData.serverUrl;
    sessionData = initialServerData.sessionData;

    api = PiGallery2API();
  }

  void updateServer(InitialServerData initialServerData) {
    serverUrl = initialServerData.serverUrl;
    sessionData = initialServerData.sessionData;
  }

  Future<Directory?> getDirectories({String path = ""}) async {
    ApiResponse<Directory> response = await api.getDirectories(serverUrl: _serverUrl, path: path, sessionData: sessionData);

    if (response.code == 401) {
      /// retry with stored credentials
      LoginCredentials? credentials = await storageHelper.getServerCredentials(_serverUrl);
      if (credentials != null) {
        sessionData ??= (await api.login(_serverUrl, credentials)).result;
        if (sessionData != null) {
          response = await api.getDirectories(serverUrl: _serverUrl, path: path, sessionData: sessionData);
          if (response.code == 200 && response.error == null) {
            await storageHelper.storeSessionData(_serverUrl, sessionData!);
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
      ApiResponse<SessionData> loginResponse = await api.login(url, LoginCredentials(username, password));
      if (loginResponse.result == null) {
        if (loginResponse.code == 200) {
          return TestConnectionResult(authFailed: true);
        } else {
          return TestConnectionResult(serverUnreachable: true);
        }
      }
      return TestConnectionResult(sessionData: loginResponse.result);
    }
    ApiResponse<Directory> response = await api.getDirectories(serverUrl: url, path: "", sessionData: null);
    if (response.code == 200 && response.error == null) {
      return TestConnectionResult();
    } else if (response.code == 401) {
      return TestConnectionResult(authFailed: true);
    }
    return TestConnectionResult(serverUnreachable: true);
  }
}
