import 'package:pigallery2_android/data/storage/models/session_data.dart';
import 'package:pigallery2_android/data/backend/models/auth/connection_test_result.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

class ServerModel extends SafeChangeNotifier {
  final ServerRepository _serverRepository;

  ServerModel(ServerRepository serverRepository) : _serverRepository = serverRepository;

  SessionData? _lastSessionData;

  bool testSuccessUrl = false;
  bool testSuccessAuth = false;
  bool testFailedUrl = false;
  bool testFailedAuth = false;

  String? get serverUrl => _serverRepository.serverUrl;

  List<String> get serverUrls => _serverRepository.serverUrls;

  Future<void> addServer(String url, String? username, String? password) async {
    bool added = await _serverRepository.addServer(url, username, password, _lastSessionData);
    if (added) {
      notifyListeners();
    }
  }

  Future<void> deleteServer(String url) async {
    await _serverRepository.deleteServer(url);
    notifyListeners();
  }

  Future<void> selectServer(String url) async {
    await _serverRepository.selectServer(url);
    notifyListeners();
  }

  void credentialsChanged() {
    testFailedAuth = false;
    testSuccessAuth = false;
    _lastSessionData = null;
    notifyListeners();
  }

  void urlChanged() {
    testFailedUrl = false;
    testSuccessUrl = false;
    testSuccessAuth = false;
    testFailedAuth = false;
    _lastSessionData = null;
    notifyListeners();
  }

  Future<void> testConnection(String url, String? username, String? password) async {
    ConnectionTestResult result = await _serverRepository.testConnection(url, username, password);
    if (result.serverUnreachable) {
      testFailedUrl = true;
      testFailedAuth = false;
      testSuccessAuth = false;
      testSuccessUrl = false;
      _lastSessionData = null;
    } else if (result.authFailed) {
      testFailedUrl = false;
      testFailedAuth = true;
      testSuccessUrl = true;
      testSuccessAuth = false;
      _lastSessionData = null;
    } else {
      testFailedUrl = false;
      testFailedAuth = false;
      testSuccessAuth = true;
      testSuccessUrl = true;
      _lastSessionData = result.sessionData;
    }
    notifyListeners();
  }

  reset() {
    testFailedAuth = false;
    testFailedUrl = false;
    testSuccessAuth = false;
    testSuccessUrl = false;
    _lastSessionData = null;
  }
}
