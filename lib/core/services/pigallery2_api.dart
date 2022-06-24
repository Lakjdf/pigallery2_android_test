import 'dart:convert';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/models/api_response.dart';
import 'package:pigallery2_android/core/services/models/login_credentials.dart';
import 'package:pigallery2_android/core/services/models/session_data.dart';

import 'package:http/http.dart' as http;

class PiGallery2API {
  String getBaseEndpoint(String? serverUrl) => '$serverUrl/api';
  String getDirectoriesEndpoint(String? serverUrl) =>
      "${getBaseEndpoint(serverUrl)}/gallery/content/";
  String getLoginEndpoint(String? serverUrl) =>
      "${getBaseEndpoint(serverUrl)}/user/login";

  final client = http.Client();

  /// Removes all non-relevant cookies
  String parseCookies(String cookie) {
    List<String> cookies = cookie
        .split(',')
        .map((e) => e.split(';'))
        .expand((element) => element)
        .toList();
    List<String> cookiesFiltered =
        cookies.where((element) => element.contains('pigallery')).toList();
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

  Future<ApiResponse<SessionData>> login(
      String serverUrl, LoginCredentials credentials) async {
    final response = await client.post(Uri.parse(getLoginEndpoint(serverUrl)),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'loginCredential': credentials.toJson()}));
    Map<String, dynamic> result = json.decode(response.body);
    if (response.statusCode == 200 &&
        result['error'] == null &&
        response.headers.containsKey('set-cookie')) {
      return ApiResponse(
        code: 200,
        result: SessionData(
          sessionCookies: parseCookies(response.headers['set-cookie']!),
          csrfToken: json.decode(response.body)['result']['csrfToken'],
        ),
      );
    } else {
      return ApiResponse(
          code: response.statusCode,
          error: result['error']?.toString() ??
              "Unable to authenticate. \n${json.decode(response.body)}");
    }
  }

  Future<ApiResponse<Directory>> getDirectories({
    required String serverUrl,
    String path = "",
    SessionData? sessionData,
  }) async {
    Uri uri = Uri.parse(getDirectoriesEndpoint(serverUrl) + path);

    try {
      http.Response response =
          await client.get(uri, headers: getHeaders(sessionData));
      Map<String, dynamic> result = json.decode(response.body);
      if (result["error"] == null) {
        return ApiResponse(
            code: response.statusCode,
            result: Directory.fromJson(result['result']['directory']));
      } else {
        return ApiResponse(
            error: result["error"].toString(), code: response.statusCode);
      }
    } catch (e) {
      return ApiResponse(error: e.toString());
    }
  }
}
