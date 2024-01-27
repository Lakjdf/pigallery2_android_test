import 'package:pigallery2_android/data/backend/models/auth/connection_test_result.dart';
import 'package:pigallery2_android/data/storage/models/session_data.dart';

abstract interface class ServerRepository {
  String? get serverUrl;
  List<String> get serverUrls;

  Future<bool> addServer(String url, String? username, String? password, SessionData? sessionData);

  Future<void> deleteServer(String url);

  Future<void> selectServer(String url);

  Future<ConnectionTestResult> testConnection(String url, String? username, String? password);
}
