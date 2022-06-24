import 'package:pigallery2_android/core/services/models/session_data.dart';

class TestConnectionResult {
  bool serverUnreachable;
  bool authFailed;
  SessionData? sessionData;

  TestConnectionResult({
    this.serverUnreachable = false,
    this.authFailed = false,
    this.sessionData,
  });
}
