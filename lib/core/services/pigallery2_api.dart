import 'dart:convert';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/models/api_response.dart';
import 'package:pigallery2_android/core/services/models/login_credentials.dart';
import 'package:pigallery2_android/core/services/models/search_query.dart';
import 'package:pigallery2_android/core/services/models/search_result.dart';
import 'package:pigallery2_android/core/services/models/session_data.dart';

import 'package:http/http.dart' as http;

class PiGallery2Api {
  String _getBaseEndpoint(String? serverUrl) => '$serverUrl/pgapi';

  String getDirectoriesEndpoint(String? serverUrl) => "${_getBaseEndpoint(serverUrl)}/gallery/content/";

  String _getLoginEndpoint(String? serverUrl) => "${_getBaseEndpoint(serverUrl)}/user/login";

  String _getSearchEndpoint(String? serverUrl) => "${_getBaseEndpoint(serverUrl)}/search/";

  final _client = http.Client();

  /// Removes all non-relevant cookies
  String _parseCookies(String cookie) {
    List<String> cookies = cookie.split(',').map((e) => e.split(';')).expand((element) => element).toList();
    List<String> cookiesFiltered = cookies.where((element) => element.contains('pigallery')).toList();
    return cookiesFiltered.join(';');
  }

  Map<String, String> getHeaders(SessionData? sessionData) {
    Map<String, String> headers = {};
    if (sessionData != null) {
      headers['Cookie'] = sessionData.sessionCookies;
      headers['CSRF-Token'] = sessionData.csrfToken;
    }
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
    final response = await _client.post(Uri.parse(_getLoginEndpoint(serverUrl)),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'loginCredential': credentials.toJson()}));
    Map<String, dynamic> result = json.decode(response.body);
    if (response.statusCode == 200 && result['error'] == null && response.headers.containsKey('set-cookie')) {
      return ApiResponse(
        code: 200,
        result: SessionData(
          sessionCookies: _parseCookies(response.headers['set-cookie']!),
          csrfToken: json.decode(response.body)['result']['csrfToken'],
        ),
      );
    } else {
      return ApiResponse(code: response.statusCode, error: result['error']?.toString() ?? "Unable to authenticate. \n${json.decode(response.body)}");
    }
  }

  Future<ApiResponse<SessionData>> login(String serverUrl, LoginCredentials credentials) => _runCatching(() => _login(serverUrl, credentials));

  Future<ApiResponse<Directory>> _getDirectories(String serverUrl, String path, SessionData? sessionData) async {
    Uri uri = Uri.parse(getDirectoriesEndpoint(serverUrl) + path);

    http.Response response = await _client.get(uri, headers: getHeaders(sessionData));
    Map<String, dynamic> result = json.decode(response.body);
    if (result["error"] == null) {
      Directory directory = Directory.fromJson(result['result']['directory'], path);
      return ApiResponse(code: response.statusCode, result: directory);
    } else {
      return ApiResponse(error: result["error"].toString(), code: response.statusCode);
    }
  }

  Future<ApiResponse<Directory>> getDirectories({
    required String serverUrl,
    String? path,
    SessionData? sessionData,
  }) async {
    return await _runCatching(() => _getDirectories(serverUrl, path ?? "", sessionData));
  }

  Future<ApiResponse<Directory>> _search(String serverUrl, String searchText, SessionData? sessionData) async {
    TextSearchQuery query = TextSearchQuery(text: searchText);
    Uri uri = Uri.parse(_getSearchEndpoint(serverUrl) + jsonEncode(query));

    http.Response response = await _client.get(uri, headers: getHeaders(sessionData));
    Map<String, dynamic> result = json.decode(response.body);
    if (result["error"] == null) {
      return ApiResponse(code: response.statusCode, result: SearchResult.fromJson(result['result']).toDirectory());
    } else {
      return ApiResponse(error: result["error"].toString(), code: response.statusCode);
    }
  }

  Future<ApiResponse<Directory>> search({
    required String serverUrl,
    String searchText = "",
    SessionData? sessionData,
  }) async {
    return await _runCatching(() => _search(serverUrl, searchText, sessionData));
  }
}
