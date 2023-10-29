import 'package:flutter_inappwebview/flutter_inappwebview.dart' as web_view;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pigallery2_android/core/services/models/models.dart';
import 'package:pigallery2_android/core/util/extensions.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  final _storage = const FlutterSecureStorage();

  late SharedPreferences _prefs;

  AndroidOptions _getAndroidOptions() => const AndroidOptions(encryptedSharedPreferences: true);

  Future<void> _storeSecureString(String key, String value) => _storage.write(key: key, value: value, aOptions: _getAndroidOptions());

  Future<String?> _readSecureString(String key) => _storage.read(key: key, aOptions: _getAndroidOptions());

  Future<void> _deleteSecureString(String key) => _storage.delete(key: key, aOptions: _getAndroidOptions());

  String _getUsernameKey(String url) => "$url-username";

  String _getPasswordKey(String url) => "$url-password";

  String _getSessionCookiesKey(String url) => "$url-cookies";

  String _getCsrfTokenKey(String url) => "$url-token";

  /// Loads [SharedPreferences] and returns stored server configuration.
  Future<InitialServerData> init() async {
    _prefs = await SharedPreferences.getInstance();
    // set initial values on first startup
    if (!_prefs.containsKey(StorageConstants.selectedServerKey)) {
      await _prefs.setInt(StorageConstants.selectedServerKey, 0);
    }
    if (!_prefs.containsKey(StorageConstants.serverUrlsKey)) {
      await _prefs.setStringList(StorageConstants.serverUrlsKey, []);
    }
    return getSelectedServerData();
  }

  InitialServerData getSelectedServerData() {
    return _getSelectedServer()?.let((it) => getServerData(it)) ?? InitialServerData();
  }

  InitialServerData getServerData(String url) {
    return InitialServerData(
      serverUrl: url,
      sessionData: _getSessionData(url),
    );
  }

  String? _getSelectedServer() {
    List<String> serverUrls = getServerUrls();
    if (serverUrls.isEmpty) return null;
    int selectedServerIndex = _getSelectedServerIndex();
    return serverUrls[selectedServerIndex];
  }

  List<String> getServerUrls() {
    return _prefs.getStringList(StorageConstants.serverUrlsKey) ?? [];
  }

  Future<void> storeServerUrls(List<String> serverUrls) async {
    await _prefs.setStringList(StorageConstants.serverUrlsKey, serverUrls);
  }

  int _getSelectedServerIndex() {
    return _prefs.getInt(StorageConstants.selectedServerKey) ?? 0;
  }

  Future<void> storeSelectedServerIndex(int value) async {
    await _prefs.setInt(StorageConstants.selectedServerKey, value);
  }

  Future<LoginCredentials?> getServerCredentials(String url) async {
    String? username = await _readSecureString(_getUsernameKey(url));
    String? password = await _readSecureString(_getPasswordKey(url));
    if (username != null && password != null) {
      return LoginCredentials(username, password);
    }
    return null;
  }

  Future<void> storeCredentials(String url, String username, String password) async {
    await _storeSecureString(_getUsernameKey(url), username);
    await _storeSecureString(_getPasswordKey(url), password);
  }

  Future<void> deleteCredentials(String url) async {
    await _deleteSecureString(_getUsernameKey(url));
    await _deleteSecureString(_getPasswordKey(url));
  }

  /// Set cookies to be used with the in app web view.
  Future<void> _storeCookies(String url, String cookieString) async {
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

  Future<void> storeSessionData(String url, SessionData data) async {
    await _prefs.setString(_getSessionCookiesKey(url), data.sessionCookies);
    await _prefs.setString(_getCsrfTokenKey(url), data.csrfToken);
    await _storeCookies(url, data.sessionCookies);
  }

  SessionData? _getSessionData(String url) {
    String? cookies = _prefs.getString(_getSessionCookiesKey(url));
    String? token = _prefs.getString(_getCsrfTokenKey(url));
    if (cookies != null && token != null) {
      return SessionData(sessionCookies: cookies, csrfToken: token);
    }
    return null;
  }

  bool getBool(String key, bool defaultValue) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  Future<void> storeBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  int getInt(String key, int defaultValue) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  Future<void> storeInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  double getDouble(String key, double defaultValue) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  Future<void> storeDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  SortOption getSortOption(String key, SortOption defaultValue) {
    return _prefs.getInt(StorageConstants.sortOptionKey)?.let((it) => SortOption.values[it]) ?? defaultValue;
  }

  Future<void> storeSortOption(String key, SortOption value) async {
    await _prefs.setInt(StorageConstants.sortOptionKey, value.index);
  }
}

class StorageConstants {
  static const serverUrlsKey = "serverUrls";
  static const selectedServerKey = "selectedServer";
  static const useMaterial3Key = "useMaterial3";
  static const showTopPicksKey = "showTopPicks";
  static const topPicksDaysLengthKey = "topPicksDaysLength";
  static const appInFullScreenKey = "appInFullScreen";
  static const sortOptionKey = "sortOption";
  static const sortAscendingKey = "sortAscending";
  static const showDirectoryItemCount = "showDirectoryItemCount";
  static const gridRoundedCorners = "gridRoundedCorners";
  static const gridAspectRatio = "gridAspectRatio";
  static const gridSpacing = "gridSpacing";
  static const gridCrossAxisCountLandscape = "gridCrossAxisCountLandscape";
  static const gridCrossAxisCountPortrait = "gridCrossAxisCountPortrait";
}
