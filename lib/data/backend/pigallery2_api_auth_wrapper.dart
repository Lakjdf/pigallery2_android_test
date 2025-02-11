import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/backend/models/api_response.dart';
import 'package:pigallery2_android/data/backend/models/search/search_query.dart';
import 'package:pigallery2_android/data/backend/models/search/search_result.dart';
import 'package:pigallery2_android/data/storage/credential_storage.dart';
import 'package:pigallery2_android/data/backend/models/auth/login_credentials.dart';
import 'package:pigallery2_android/data/storage/models/session_data.dart';
import 'package:pigallery2_android/data/backend/models/auth/connection_test_result.dart';
import 'package:pigallery2_android/data/backend/models/directory.dart';
import 'package:pigallery2_android/data/backend/pigallery2_api.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_helper.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:pigallery2_android/util/strings.dart';

class PiGallery2ApiAuthWrapper implements ApiService {
  final CredentialStorage _credentialStorage;
  final SharedPrefsStorage _storage;
  late final PiGallery2Api _api;
  late final StorageHelper _storageHelper;

  PiGallery2ApiAuthWrapper(this._storage, this._credentialStorage) {
    _api = PiGallery2Api();
    _storageHelper = StorageHelper(_storage);
  }

  @override
  Map<String, String> get headers => _api.getHeaders(_storageHelper.getSelectedServerSessionData());

  String _getServerUrlOrThrow() {
    String? url = _storageHelper.getSelectedServerUrl();
    if (url == null) {
      throw Exception(Strings.errorNoServerConfigured);
    } else {
      return url;
    }
  }

  /// Full API path to [item].
  @override
  String getMediaApiPath(Media item) {
    return PiGallery2Api.getMediaPath(_getServerUrlOrThrow(), item.relativeApiPath);
  }

  /// Full API path to the thumbnail of [item].
  @override
  String? getThumbnailApiPath(Item item) {
    return item.relativeThumbnailPath?.let((it) {
      return PiGallery2Api.getThumbnailPath(_getServerUrlOrThrow(), it);
    });
  }

  @override
  String getSpritesApiPath(Media item) {
    return PiGallery2Api.getSpritesPath(_getServerUrlOrThrow(), item.relativeApiPath);
  }

  Future<T?> _requestWithAuth<T>(Future<ApiResponse<T>> Function(String, SessionData?) request) async {
    String url = _getServerUrlOrThrow();
    ApiResponse<T> response = await request(url, _storageHelper.getSessionData(url));

    if (response.code == 401) {
      /// retry with stored credentials
      LoginCredentials? credentials = await _credentialStorage.getServerCredentials(url);
      if (credentials != null) {
        SessionData? sessionData = (await _api.login(url, credentials)).result;
        if (sessionData != null) {
          response = await request(url, sessionData);
          if (response.code == 200 && response.error == null) {
            await _storageHelper.storeSessionData(url, sessionData);
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
  Future<BackendDirectory?> getDirectories({String? path}) async {
    return _requestWithAuth((String url, SessionData? sessionData) => _api.getDirectories(serverUrl: url, path: path, sessionData: sessionData));
  }

  @override
  Future<SearchResult?> search(SearchQuery query) async {
    return _requestWithAuth((String url, SessionData? sessionData) => _api.search(serverUrl: url, query: query, sessionData: sessionData));
  }

  @override
  Future<ConnectionTestResult> testConnection(String url, String? username, String? password) async {
    if (username != null && password != null) {
      ApiResponse<SessionData> loginResponse = await _api.login(url, LoginCredentials(username, password));
      if (loginResponse.result == null) {
        if (loginResponse.code == 200) {
          return ConnectionTestResult(authFailed: true);
        } else {
          return ConnectionTestResult(serverUnreachable: true);
        }
      }
      return ConnectionTestResult(sessionData: loginResponse.result);
    }
    ApiResponse<BackendDirectory> response = await _api.getDirectories(serverUrl: url, path: null, sessionData: null);
    if (response.code == 200 && response.error == null) {
      return ConnectionTestResult();
    } else if (response.code == 401) {
      return ConnectionTestResult(authFailed: true);
    }
    return ConnectionTestResult(serverUnreachable: true);
  }
}
