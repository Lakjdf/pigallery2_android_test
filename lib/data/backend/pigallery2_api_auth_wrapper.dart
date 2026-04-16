import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/backend/models/album.dart';
import 'package:pigallery2_android/data/backend/models/api_response.dart';
import 'package:pigallery2_android/data/backend/models/create_album.dart';
import 'package:pigallery2_android/data/backend/models/search/auto_complete.dart';
import 'package:pigallery2_android/data/backend/models/search/search.dart';
import 'package:pigallery2_android/data/backend/models/search/search_result.dart';
import 'package:pigallery2_android/data/storage/credential_storage.dart';
import 'package:pigallery2_android/data/backend/models/auth/login_credentials.dart';
import 'package:pigallery2_android/data/storage/models/session_data.dart';
import 'package:pigallery2_android/data/backend/models/auth/connection_test_result.dart';
import 'package:pigallery2_android/data/backend/models/directory.dart';
import 'package:pigallery2_android/data/backend/pigallery2_api.dart';
import 'package:pigallery2_android/data/storage/session_storage.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:pigallery2_android/util/strings.dart';

class PiGallery2ApiAuthWrapper implements ApiService {
  final CredentialStorage _credentialStorage;
  final SessionStorage _sessionStorage;
  final ServerRepository _serverRepository;
  late final PiGallery2Api _api;

  PiGallery2ApiAuthWrapper(this._credentialStorage, this._sessionStorage, this._serverRepository) {
    _api = PiGallery2Api(_serverRepository);
  }

  @override
  Map<String, String> get headers {
    SessionData? sessionData = _serverRepository.serverId?.let((it) => _sessionStorage.getSessionData(it));
    return _api.getHeaders(sessionData);
  }

  String _getServerUrlOrThrow() {
    String? url = _serverRepository.serverUrl;
    if (url == null) {
      throw Exception(Strings.errorNoServerConfigured);
    } else {
      return url;
    }
  }

  String _getServerIdOrThrow() {
    String? id = _serverRepository.serverId;
    if (id == null) {
      throw Exception(Strings.errorNoServerConfigured);
    } else {
      return id;
    }
  }

  /// Full API path to [item].
  @override
  String getMediaApiPath(Media item) {
    if (item.isVideo) {
      return _api.getVideoPath(_getServerUrlOrThrow(), item.relativeApiPath.encodeUri());
    }
    return _api.getImagePath(_getServerUrlOrThrow(), item.relativeApiPath.encodeUri());
  }

  /// Full API path to the thumbnail of [item].
  @override
  String? getThumbnailApiPath(Item item) {
    return item.relativeThumbnailPath?.let((it) {
      return _api.getThumbnailPath(_getServerUrlOrThrow(), it.encodeUri());
    });
  }

  @override
  String getSpritesApiPath(Media item) {
    return _api.getSpritesPath(_getServerUrlOrThrow(), item.relativeApiPath);
  }

  Future<T?> _requestWithAuth<T>(Future<ApiResponse<T>> Function(String, SessionData?) request) async {
    String url = _getServerUrlOrThrow();
    String id = _getServerIdOrThrow();
    ApiResponse<T> response = await request(url, _sessionStorage.getSessionData(id));

    if (response.code == 401) {
      /// retry with stored credentials
      LoginCredentials? credentials = await _credentialStorage.getServerCredentials(id);
      if (credentials != null) {
        SessionData? sessionData = (await _api.login(url, credentials)).result;
        if (sessionData != null) {
          response = await request(url, sessionData);
          if (response.code == 200 && response.error == null) {
            await _sessionStorage.storeSessionData(sessionData.copyWith(id: id));
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
  Future<BackendDirectory?> getDirectories({String? path}) {
    return _requestWithAuth(
      (String url, SessionData? sessionData) =>
          _api.getDirectories(serverUrl: url, path: path, sessionData: sessionData),
    );
  }

  @override
  Future<SearchResult?> search(SearchQueryDTO query) {
    return _requestWithAuth(
      (String url, SessionData? sessionData) => _api.search(serverUrl: url, query: query, sessionData: sessionData),
    );
  }

  @override
  Future<List<AlbumBaseDto>> getAlbums() async {
    List<AlbumBaseDto>? albums = await _requestWithAuth(
      (String url, SessionData? sessionData) => _api.getAlbums(serverUrl: url, sessionData: sessionData),
    );
    return albums ?? [];
  }

  @override
  Future<List<AutoCompleteItem>> autoComplete(AutoCompleteItem request) async {
    var result = await _requestWithAuth(
      (String url, SessionData? sessionData) =>
          _api.autoComplete(serverUrl: url, request: request, sessionData: sessionData),
    );
    return result ?? [];
  }

  @override
  Future<void> createAlbum(CreateAlbumDto album) async {
    await _requestWithAuth(
      (String url, SessionData? sessionData) =>
          _api.createAlbum(serverUrl: url, album: album, sessionData: sessionData),
    );
  }

  @override
  Future<void> deleteAlbum(int id) async {
    await _requestWithAuth(
      (String url, SessionData? sessionData) =>
          _api.deleteAlbum(serverUrl: url, id: id, sessionData: sessionData),
    );
  }

  @override
  Future<void> startIndexingJob() {
    String url = _getServerUrlOrThrow();
    String id = _getServerIdOrThrow();
    return _api.startIndexingJob(url, _sessionStorage.getSessionData(id));
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
