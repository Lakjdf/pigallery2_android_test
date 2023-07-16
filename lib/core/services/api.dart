import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/models/models.dart';
import 'package:pigallery2_android/core/services/pigallery2_api.dart';
import 'package:pigallery2_android/core/services/storage_helper.dart';
import 'package:pigallery2_android/core/util/extensions.dart';
import 'package:pigallery2_android/core/util/strings.dart';

abstract interface class ApiService {
  void updateServerConfig(InitialServerData initialServerData);

  Future<Directory?> getDirectories({String? path});

  Future<Directory?> search({String searchText});

  Future<TestConnectionResult> testConnection(String url, String? username, String? password);

  String? get serverUrl;

  Map<String, String> get headers;

  String get directoriesEndpoint;

  String getMediaApiPath(Media item);

  String? getThumbnailApiPath(File item);
}

class PiGallery2ApiAuthWrapper implements ApiService {
  late final PiGallery2Api _api;
  final StorageHelper _storageHelper;
  SessionData? _sessionData;
  String? _serverUrl;

  PiGallery2ApiAuthWrapper({
    required InitialServerData initialServerData,
    required StorageHelper storageHelper,
  }) : _storageHelper = storageHelper {
    _serverUrl = initialServerData.serverUrl;
    _sessionData = initialServerData.sessionData;

    _api = PiGallery2Api();
  }

  @override
  String? get serverUrl => _serverUrl;

  @override
  Map<String, String> get headers => _api.getHeaders(_sessionData);

  @override
  String get directoriesEndpoint => _api.getDirectoriesEndpoint(_serverUrl);

  @override
  void updateServerConfig(InitialServerData initialServerData) {
    _serverUrl = initialServerData.serverUrl;
    _sessionData = initialServerData.sessionData;
  }

  String _getServerUrlOrThrow() {
    if (_serverUrl == null) {
      throw Exception(Strings.errorNoServerConfigured);
    }
    return _serverUrl!;
  }

  /// Full API path to [item].
  @override
  String getMediaApiPath(Media item) {
    return "${_api.getDirectoriesEndpoint(_serverUrl)}${item.apiPath}";
  }

  /// Full API path to the thumbnail of [item].
  @override
  String? getThumbnailApiPath(File item) {
    String? thumbnailPath = item is Directory ? item.preview?.apiPath : item.apiPath;
    return thumbnailPath?.let((it) => "${_api.getDirectoriesEndpoint(_serverUrl)}$it/thumbnail");
  }

  Future<T?> _requestWithAuth<T>(Future<ApiResponse<T>> Function(SessionData?) request) async {
    ApiResponse<T> response = await request(_sessionData);

    if (response.code == 401) {
      /// retry with stored credentials
      LoginCredentials? credentials = await _storageHelper.getServerCredentials(_getServerUrlOrThrow());
      if (credentials != null) {
        _sessionData ??= (await _api.login(_getServerUrlOrThrow(), credentials)).result;
        if (_sessionData != null) {
          response = await request(_sessionData);
          if (response.code == 200 && response.error == null) {
            await _storageHelper.storeSessionData(_getServerUrlOrThrow(), _sessionData!);
          }
        }
      }
    }
    if (response.error != null) {
      throw Exception(response.error);
    }
    return response.result;
  }

  @override
  Future<Directory?> getDirectories({String? path}) {
    return _requestWithAuth((SessionData? sessionData) => _api.getDirectories(serverUrl: _getServerUrlOrThrow(), path: path, sessionData: sessionData));
  }

  @override
  Future<Directory?> search({String searchText = ""}) {
    return _requestWithAuth((SessionData? sessionData) => _api.search(serverUrl: _getServerUrlOrThrow(), searchText: searchText, sessionData: sessionData));
  }

  @override
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
    ApiResponse<Directory> response = await _api.getDirectories(serverUrl: url, path: null, sessionData: null);
    if (response.code == 200 && response.error == null) {
      return TestConnectionResult();
    } else if (response.code == 401) {
      return TestConnectionResult(authFailed: true);
    }
    return TestConnectionResult(serverUnreachable: true);
  }
}
