import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pigallery2_android/data/backend/logging_client.dart';
import 'package:pigallery2_android/data/backend/models/album.dart';
import 'package:pigallery2_android/data/backend/models/api_response.dart';
import 'package:pigallery2_android/data/backend/models/auth/login_credentials.dart';
import 'package:pigallery2_android/data/backend/models/create_album.dart';
import 'package:pigallery2_android/data/backend/models/search/auto_complete.dart';
import 'package:pigallery2_android/data/backend/models/search/search.dart';
import 'package:pigallery2_android/data/storage/models/session_data.dart';
import 'package:pigallery2_android/data/backend/models/directory.dart';
import 'package:pigallery2_android/data/backend/models/search/search_result.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/util/extensions.dart';

class PiGallery2Api {
  String _getBaseEndpoint(String serverUrl) => '$serverUrl/pgapi';

  String getDirectoriesEndpoint(String serverUrl) => "${_getBaseEndpoint(serverUrl)}/gallery/content/";

  String getImagePath(String serverUrl, String relativePath) =>
      "${getDirectoriesEndpoint(serverUrl)}$relativePath${_serverRepository.apiSettings.imagePath}";

  String getVideoPath(String serverUrl, String relativePath) =>
      "${getDirectoriesEndpoint(serverUrl)}$relativePath${_serverRepository.apiSettings.videoPath}";

  String getThumbnailPath(String serverUrl, String relativePath) =>
      "${getDirectoriesEndpoint(serverUrl)}$relativePath${_serverRepository.apiSettings.thumbnailPath}";

  String getSpritesPath(String serverUrl, String relativePath) =>
      "${_getBaseEndpoint(serverUrl)}/extension/sprites/$relativePath";

  String _getLoginEndpoint(String serverUrl) => "${_getBaseEndpoint(serverUrl)}/user/login";

  String _getSearchEndpoint(String serverUrl) => "${_getBaseEndpoint(serverUrl)}/search/";

  String _getStartJobEndpoint(String serverUrl, String jobId) =>
      "${_getBaseEndpoint(serverUrl)}/admin/jobs/scheduled/$jobId/start";

  String _getAlbumsEndpoint(String serverUrl) => "${_getBaseEndpoint(serverUrl)}/albums";

  String _deleteAlbumsEndpoint(String serverUrl, int albumId) => "${_getBaseEndpoint(serverUrl)}/albums/$albumId";

  String _getCreateAlbumsEndpoint(String serverUrl) => "${_getBaseEndpoint(serverUrl)}/albums/saved-searches";

  String _getAutoCompleteEndpoint(String serverUrl) => "${_getBaseEndpoint(serverUrl)}/autocomplete/";

  final _client = kDebugMode ? LoggingClient(http.Client()) : http.Client();
  final ServerRepository _serverRepository;

  PiGallery2Api(this._serverRepository);

  /// Removes all non-relevant cookies
  String _parseCookies(String cookie) {
    List<String> cookies = cookie.split(',').map((e) => e.split(';')).expand((element) => element).toList();
    List<String> cookiesFiltered = cookies.where((element) => element.contains('pigallery')).toList();
    return cookiesFiltered.join(';');
  }

  Map<String, String> getHeaders(SessionData? sessionData) {
    Map<String, String> headers = {};
    if (sessionData != null) {
      headers['Cookie'] = sessionData.cookies;
      sessionData.csrfToken?.let((it) => headers['CSRF-Token'] = it);
    }
    headers["Content-Type"] = "application/json";
    return headers;
  }

  Future<ApiResponse<T>> _runCatching<T>(Future<ApiResponse<T>> Function() request) async {
    try {
      return await request();
    } on Exception catch (e) {
      return ApiResponse(error: e.toString(), result: null, code: null);
    }
  }

  Future<ApiResponse<SessionData>> _login(String serverUrl, LoginCredentials credentials) async {
    final response = await _client.post(
      Uri.parse(_getLoginEndpoint(serverUrl)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'loginCredential': credentials.toJson()}),
    );
    Map<String, dynamic> result = json.decode(response.body);
    if (response.statusCode == 200 && result['error'] == null && response.headers.containsKey('set-cookie')) {
      Map<String, dynamic> bodyResult = json.decode(response.body)['result'];
      return ApiResponse(
        code: 200,
        result: SessionData(
          id: serverUrl,
          url: serverUrl,
          cookies: _parseCookies(response.headers['set-cookie']!),
          csrfToken: bodyResult.containsKey('csrfToken') ? bodyResult['csrfToken'] : null,
        ),
      );
    } else {
      return ApiResponse(
        code: response.statusCode,
        error: result['error']?.toString() ?? "Unable to authenticate. \n${json.decode(response.body)}",
      );
    }
  }

  Future<ApiResponse<SessionData>> login(String serverUrl, LoginCredentials credentials) =>
      _runCatching(() => _login(serverUrl, credentials));

  Future<ApiResponse<BackendDirectory>> _getDirectories(String serverUrl, String path, SessionData? sessionData) async {
    Uri uri = Uri.parse(getDirectoriesEndpoint(serverUrl) + Uri.encodeComponent(path));

    http.Response response = await _client.get(uri, headers: getHeaders(sessionData));
    Map<String, dynamic> result = json.decode(response.body);
    if (result["error"] == null) {
      BackendDirectory directory = BackendDirectory.fromJson(result['result']['directory'], path);
      return ApiResponse(code: response.statusCode, result: directory);
    } else {
      return ApiResponse(error: result["error"].toString(), code: response.statusCode);
    }
  }

  Future<ApiResponse<BackendDirectory>> getDirectories({
    required String serverUrl,
    String? path,
    SessionData? sessionData,
  }) async {
    return await _runCatching(() => _getDirectories(serverUrl, path ?? "", sessionData));
  }

  Future<ApiResponse<SearchResult>> _search(String serverUrl, SearchQueryDTO query, SessionData? sessionData) async {
    Uri uri = Uri.parse(_getSearchEndpoint(serverUrl) + Uri.encodeComponent(jsonEncode(query)));

    http.Response response = await _client.get(uri, headers: getHeaders(sessionData));
    Map<String, dynamic> result = json.decode(response.body);
    if (result["error"] == null) {
      return ApiResponse(code: response.statusCode, result: SearchResult.fromJson(result['result']));
    } else {
      return ApiResponse(error: result["error"].toString(), code: response.statusCode);
    }
  }

  Future<ApiResponse<SearchResult>> search({
    required String serverUrl,
    required SearchQueryDTO query,
    SessionData? sessionData,
  }) async {
    return await _runCatching(() => _search(serverUrl, query, sessionData));
  }

  Future<void> startIndexingJob(String serverUrl, SessionData? sessionData) async {
    Uri uri = Uri.parse(_getStartJobEndpoint(serverUrl, "Indexing"));
    await _client.post(uri, headers: getHeaders(sessionData));
  }

  Future<ApiResponse<List<AlbumBaseDto>>> _getAlbums(String serverUrl, SessionData? sessionData) async {
    Uri uri = Uri.parse(_getAlbumsEndpoint(serverUrl));

    http.Response response = await _client.get(uri, headers: getHeaders(sessionData));
    Map<String, dynamic> result = json.decode(response.body);
    if (result["error"] == null) {
      List<AlbumBaseDto> albums = (result['result'] as List<dynamic>).map((it) => AlbumBaseDto.fromJson(it)).toList();
      return ApiResponse(code: response.statusCode, result: albums);
    } else {
      return ApiResponse(error: result["error"].toString(), code: response.statusCode);
    }
  }

  Future<ApiResponse<List<AlbumBaseDto>>> getAlbums({
    required String serverUrl,
    SessionData? sessionData,
  }) async {
    return await _runCatching(() => _getAlbums(serverUrl, sessionData));
  }

  Future<ApiResponse<void>> _createAlbum(
    String serverUrl,
    CreateAlbumDto album, {
    SessionData? sessionData,
  }) async {
    Uri uri = Uri.parse(_getCreateAlbumsEndpoint(serverUrl));

    http.Response response = await _client.put(uri, headers: getHeaders(sessionData), body: jsonEncode(album));
    Map<String, dynamic> result = json.decode(response.body);
    if (result["error"] == null) {
      return ApiResponse(code: response.statusCode);
    } else {
      return ApiResponse(error: result["error"].toString(), code: response.statusCode);
    }
  }

  Future<ApiResponse<void>> createAlbum({
    required String serverUrl,
    required CreateAlbumDto album,
    SessionData? sessionData,
  }) async {
    return await _runCatching(() => _createAlbum(serverUrl, album, sessionData: sessionData));
  }

  Future<ApiResponse<void>> _deleteAlbum(
    String serverUrl,
    int id, {
    SessionData? sessionData,
  }) async {
    Uri uri = Uri.parse(_deleteAlbumsEndpoint(serverUrl, id));

    http.Response response = await _client.delete(uri, headers: getHeaders(sessionData));
    Map<String, dynamic> result = json.decode(response.body);
    if (result["error"] == null) {
      return ApiResponse(code: response.statusCode);
    } else {
      return ApiResponse(error: result["error"].toString(), code: response.statusCode);
    }
  }

  Future<ApiResponse<void>> deleteAlbum({
    required String serverUrl,
    required int id,
    SessionData? sessionData,
  }) async {
    return await _runCatching(() => _deleteAlbum(serverUrl, id, sessionData: sessionData));
  }

  Future<ApiResponse<List<AutoCompleteItem>>> _autoComplete(
    String serverUrl,
    AutoCompleteItem request, {
    SessionData? sessionData,
  }) async {
    final base = _getAutoCompleteEndpoint(serverUrl);
    final path = base + Uri.encodeComponent(request.text);
    final uri = Uri.parse('$path?type=${request.type.value}');

    http.Response response = await _client.get(uri, headers: getHeaders(sessionData));
    Map<String, dynamic> result = json.decode(response.body);
    if (result["error"] == null) {
      List<AutoCompleteItem> items = (result['result'] as List<dynamic>)
          .map((it) => AutoCompleteItem.fromJson(it))
          .toList();
      return ApiResponse(code: response.statusCode, result: items);
    } else {
      return ApiResponse(error: result["error"].toString(), code: response.statusCode);
    }
  }

  Future<ApiResponse<List<AutoCompleteItem>>> autoComplete({
    required String serverUrl,
    required AutoCompleteItem request,
    SessionData? sessionData,
  }) async {
    return await _runCatching(() => _autoComplete(serverUrl, request, sessionData: sessionData));
  }
}
