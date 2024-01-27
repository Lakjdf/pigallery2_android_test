import 'package:pigallery2_android/data/storage/models/session_data.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as web_view;

class StorageHelper {
  final SharedPrefsStorage _storage;

  StorageHelper(this._storage);

  String _getSessionCookiesKey(String url) => "$url-cookies";

  String _getCsrfTokenKey(String url) => "$url-token";

  String? getSelectedServerUrl() {
    List<String> serverUrls = _storage.get(StorageKey.serverUrls);
    if (serverUrls.isEmpty) return null;
    int selectedServerIndex = _storage.get(StorageKey.selectedServer);
    return serverUrls[selectedServerIndex];
  }

  SessionData? getSelectedServerSessionData() {
    return getSelectedServerUrl()?.let((it) => getSessionData(it));
  }

  Future<void> storeSessionData(String url, SessionData data) async {
    await _storage.setWithKey(_getSessionCookiesKey(url), data.sessionCookies);
    await _storage.setWithKey(_getCsrfTokenKey(url), data.csrfToken);
    await _setCookies(url, data.sessionCookies);
  }

  SessionData? getSessionData(String url) {
    String? cookies = _storage.getWithKey(_getSessionCookiesKey(url));
    String? token = _storage.getWithKey(_getCsrfTokenKey(url));
    if (cookies != null && token != null) {
      return SessionData(sessionCookies: cookies, csrfToken: token);
    }
    return null;
  }

  /// Set cookies to be used with the in app web view.
  Future<void> _setCookies(String url, String cookieString) async {
    var cookieManager = web_view.CookieManager.instance();
    for (var cookie in cookieString.split(';')) {
      var splitIndex = cookie.indexOf('=');
      await cookieManager.setCookie(
        url: web_view.WebUri(url),
        name: cookie.substring(0, splitIndex),
        value: cookie.substring(splitIndex + 1),
      );
    }
  }
}
