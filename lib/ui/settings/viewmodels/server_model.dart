import 'package:pigallery2_android/data/storage/models/server_settings.dart';
import 'package:pigallery2_android/data/storage/models/session_data.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

class ServerModel extends SafeChangeNotifier {
  final ServerRepository _serverRepository;

  ServerModel(this._serverRepository);

  String? get serverUrl => _serverRepository.serverUrl;

  String? get serverId => _serverRepository.serverId;

  Iterable<Server> get servers => _serverRepository.servers;

  Future<void> addServer(String url, String? username, String? password, SessionData? sessionData) async {
    await _serverRepository.addServer(url, username, password, sessionData);
    notifyListeners();
  }

  Future<void> deleteServer(String id) async {
    await _serverRepository.deleteServer(id);
    notifyListeners();
  }

  Future<void> selectServer(String id) async {
    await _serverRepository.selectServer(id);
    notifyListeners();
  }

  Future<void> updateApiSettings(String serverId, ApiSettings settings) async {
    await _serverRepository.updateApiSettings(serverId, settings);
    notifyListeners();
  }

}
