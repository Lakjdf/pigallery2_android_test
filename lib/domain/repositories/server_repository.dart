import 'package:pigallery2_android/data/storage/models/server_settings.dart';
import 'package:pigallery2_android/data/storage/models/session_data.dart';

abstract interface class ServerRepository {
  Iterable<Server> get servers;

  String? get serverUrl;

  String? get serverId;

  ApiSettings get apiSettings;

  Future<void> addServer(String url, String? username, String? password, SessionData? sessionData);

  Future<void> deleteServer(String id);

  Future<void> selectServer(String id);

  Future<void> updateApiSettings(String serverId, ApiSettings apiSettings);
}
