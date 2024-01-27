import 'package:pigallery2_android/data/storage/models/session_data.dart';

class ConnectionTestResult {
  bool serverUnreachable;
  bool authFailed;
  SessionData? sessionData;

  ConnectionTestResult({
    this.serverUnreachable = false,
    this.authFailed = false,
    this.sessionData,
  });
}
