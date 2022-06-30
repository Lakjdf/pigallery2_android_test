import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pigallery2_android/core/services/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  final _storage = const FlutterSecureStorage();
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  Future<void> _storeSecureString(String key, String value) => _storage.write(key: key, value: value, aOptions: _getAndroidOptions());

  Future<String?> _readSecureString(String key) => _storage.read(key: key, aOptions: _getAndroidOptions());

  Future<void> _deleteSecureString(String key) => _storage.delete(key: key, aOptions: _getAndroidOptions());

  String _getUsernameKey(String url) => "$url-username";
  String _getPasswordKey(String url) => "$url-password";

  Future<InitialServerData> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // set initial values on first startup
    if (!prefs.containsKey("selectedServer")) {
      prefs.setInt("selectedServer", 0);
    }
    if (!prefs.containsKey("serverUrls")) {
      prefs.setStringList("serverUrls", []);
    }
    // Return currently selected server
    String? url = await getSelectedServer();
    if (url != null) {
      return InitialServerData(
        serverUrl: url,
        sessionData: await getSessionData(url),
      );
    }
    return InitialServerData();
  }

  Future<List<String>> getServerUrls() {
    return SharedPreferences.getInstance().then(
      (prefs) {
        return prefs.getStringList('serverUrls') ?? [];
      },
    );
  }

  Future<String?> getSelectedServer() {
    return SharedPreferences.getInstance().then((prefs) {
      List<String> serverUrls = prefs.getStringList('serverUrls') ?? [];
      if (serverUrls.isEmpty) return null;
      return serverUrls[prefs.getInt('selectedServer') ?? 0];
    });
  }

  Future<void> selectServer(String url) {
    return SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt('selectedServer', prefs.getStringList('serverUrls')?.indexOf(url) ?? 0),
    );
  }

  Future<void> storeServer(String url, String? username, String? password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> serverUrls = prefs.getStringList('serverUrls') ?? [];
    if (!serverUrls.contains(url)) {
      serverUrls.add(url);
    }
    prefs.setStringList('serverUrls', serverUrls);

    if (username != null && password != null) {
      await _storeSecureString(_getUsernameKey(url), username);
      await _storeSecureString(_getPasswordKey(url), password);
    }
  }

  Future<LoginCredentials?> getServerCredentials(String url) async {
    String? username = await _readSecureString(_getUsernameKey(url));
    String? password = await _readSecureString(_getPasswordKey(url));
    if (username != null && password != null) {
      return LoginCredentials(username, password);
    }
    return null;
  }

  Future<void> deleteServer(String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> serverUrls = prefs.getStringList('serverUrls') ?? [];
    if (serverUrls.contains(url)) {
      serverUrls.remove(url);
    }
    prefs.setStringList('serverUrls', serverUrls);

    int selectedServer = prefs.getInt('selectedServer')!;
    prefs.setInt('selectedServer', selectedServer < 2 ? 0 : selectedServer - 1);

    await _deleteSecureString(_getUsernameKey(url));
    await _deleteSecureString(_getPasswordKey(url));
  }

  Future<void> storeSessionData(String url, SessionData data) {
    return SharedPreferences.getInstance().then((prefs) {
      prefs.setString("$url-cookies", data.sessionCookies);
      prefs.setString("$url-token", data.csrfToken);
    });
  }

  Future<SessionData?> getSessionData(String url) {
    return SharedPreferences.getInstance().then((prefs) {
      String? cookies = prefs.getString("$url-cookies");
      String? token = prefs.getString("$url-token");
      if (cookies != null && token != null) {
        return SessionData(sessionCookies: cookies, csrfToken: token);
      }
      return null;
    });
  }
}
