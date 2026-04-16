import 'package:collection/collection.dart';
import 'package:pigallery2_android/data/storage/credential_storage.dart';
import 'package:pigallery2_android/data/storage/models/server_settings.dart';
import 'package:pigallery2_android/data/storage/models/session_data.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/session_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';

class ServerRepositoryImpl implements ServerRepository {
  final CredentialStorage _credentialStorage;
  final SharedPrefsStorage _storage;
  final SessionStorage _sessionStorage;

  ServerSettings _serverSettings;

  ServerRepositoryImpl(this._storage, this._credentialStorage, this._sessionStorage)
    : _serverSettings = _storage.get(StorageKey.serverSettings);

  Future<void> _persist(ServerSettings settings) async {
    _serverSettings = settings;
    await _storage.set(StorageKey.serverSettings, settings);
  }

  @override
  Iterable<Server> get servers => _serverSettings.servers;

  @override
  String? get serverUrl {
    return _serverSettings.servers.firstWhereOrNull((it) => it.id == _serverSettings.selectedServer)?.url;
  }

  @override
  String? get serverId {
    return _serverSettings.servers.firstWhereOrNull((it) => it.id == _serverSettings.selectedServer)?.id;
  }

  @override
  ApiSettings get apiSettings {
    if (_serverSettings.servers.isEmpty) {
      return _serverSettings.defaultApiSettings;
    }
    return _serverSettings.servers.firstWhere((it) => it.id == _serverSettings.selectedServer).apiSettings;
  }

  @override
  Future<void> addServer(String url, String? username, String? password, SessionData? sessionData) async {
    final String id = Server.idFor(url, username);
    List<Server> servers = _serverSettings.servers.toList();
    if (servers.any((it) => it.id == id)) return;
    servers.add(Server(id: id, url: url, username: username, apiSettings: _serverSettings.defaultApiSettings));
    await _persist(_serverSettings.copyWith(
      servers: servers,
      selectedServer: servers.length == 1 ? id : _serverSettings.selectedServer,
    ));

    if (username != null && password != null) {
      await _credentialStorage.storeCredentials(id, username, password);
    }
    if (sessionData != null) {
      await _sessionStorage.storeSessionData(sessionData.copyWith(id: id));
    }
  }

  @override
  Future<void> deleteServer(String id) async {
    List<Server> updatedServers = _serverSettings.servers.whereNot((it) => it.id == id).toList();
    String? selectedServer = _serverSettings.selectedServer;
    if (selectedServer == id && updatedServers.isNotEmpty) {
      selectedServer = updatedServers.first.id;
    }
    await _persist(_serverSettings.copyWith(
      servers: updatedServers,
      selectedServer: selectedServer,
    ));
    await _credentialStorage.deleteCredentials(id);
    await _sessionStorage.deleteSessionData(id);
  }

  @override
  Future<void> selectServer(String id) async {
    await _persist(_serverSettings.copyWith(selectedServer: id));
  }

  @override
  Future<void> updateApiSettings(String serverId, ApiSettings apiSettings) async {
    ApiSettings? defaultApiSettings;
    if (_serverSettings.servers.length <= 1) {
      defaultApiSettings = apiSettings;
    }
    await _persist(_serverSettings.copyWith(
      defaultApiSettings: defaultApiSettings,
      servers: _serverSettings.servers.map((it) {
        if (it.id == serverId) {
          return it.copyWith(apiSettings: apiSettings);
        }
        return it;
      }).toList(),
    ));
  }
}
