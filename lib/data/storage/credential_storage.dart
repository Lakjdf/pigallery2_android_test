import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pigallery2_android/data/backend/models/auth/login_credentials.dart';

class CredentialStorage {
  final FlutterSecureStorage _storage;
  CredentialStorage(this._storage);

  String _getUsernameKey(String id) => "$id-username";

  String _getPasswordKey(String id) => "$id-password";

  Future<LoginCredentials?> getServerCredentials(String id) async {
    String? username = await _storage.read(key: _getUsernameKey(id));
    String? password = await _storage.read(key: _getPasswordKey(id));
    if (username != null && password != null) {
      return LoginCredentials(username, password);
    }
    return null;
  }

  Future<void> storeCredentials(String id, String username, String password) async {
    await _storage.write(key: _getUsernameKey(id), value: username);
    await _storage.write(key: _getPasswordKey(id), value: password);
  }

  Future<void> deleteCredentials(String id) async {
    await _storage.delete(key: _getUsernameKey(id));
    await _storage.delete(key: _getPasswordKey(id));
  }
}
