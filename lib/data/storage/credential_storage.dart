import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pigallery2_android/data/backend/models/auth/login_credentials.dart';

class CredentialStorage {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String _getUsernameKey(String url) => "$url-username";

  String _getPasswordKey(String url) => "$url-password";

  Future<LoginCredentials?> getServerCredentials(String url) async {
    String? username = await _storage.read(key: _getUsernameKey(url));
    String? password = await _storage.read(key: _getPasswordKey(url));
    if (username != null && password != null) {
      return LoginCredentials(username, password);
    }
    return null;
  }

  Future<void> storeCredentials(String url, String username, String password) async {
    await _storage.write(key: _getUsernameKey(url), value: username);
    await _storage.write(key: _getPasswordKey(url), value: password);
  }

  Future<void> deleteCredentials(String url) async {
    await _storage.delete(key: _getUsernameKey(url));
    await _storage.delete(key: _getPasswordKey(url));
  }
}
