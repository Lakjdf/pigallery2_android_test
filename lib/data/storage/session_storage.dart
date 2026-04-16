import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pigallery2_android/data/storage/models/session_data.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as web_view;

const String sessionDataKey = "session_data";

class SessionStorage {
  final FlutterSecureStorage _storage;

  SessionStorage(this._storage);

  List<SessionData> _cache = [];

  Future<void> init() async {
    String? storedData = await _storage.read(key: sessionDataKey);
    if (storedData == null) return;
    List<SessionData> storedSessionData = StoredSessionData.fromRawJson(storedData).sessionData;
    _cache = storedSessionData;
  }

  Future<void> storeSessionData(SessionData data) async {
    int index = _cache.indexWhere((it) => it.id == data.id);
    if (index == -1) {
      _cache.add(data);
    } else {
      _cache[index] = data;
    }

    await _storage.write(key: sessionDataKey, value: StoredSessionData(sessionData: _cache).toRawJson());
    await _setCookies(data.url, data.cookies);
  }

  SessionData? getSessionData(String id) {
    return _cache.firstWhereOrNull((it) => it.id == id);
  }

  Future<void> deleteSessionData(String id) async {
    _cache.removeWhere((it) => it.id == id);
    await _storage.write(key: sessionDataKey, value: StoredSessionData(sessionData: _cache).toRawJson());
  }

  /// Set cookies to be used with the in app web view.
  Future<void> _setCookies(String url, String cookieString) async {
    if (!Platform.isAndroid) return;
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
