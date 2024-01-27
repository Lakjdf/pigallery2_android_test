import 'package:pigallery2_android/data/backend/models/auth/connection_test_result.dart';
import 'package:pigallery2_android/data/backend/models/directory.dart';
import 'package:pigallery2_android/domain/models/item.dart';

abstract interface class ApiService {
  Future<BackendDirectory?> getDirectories({String? path});

  Future<BackendDirectory?> search({String searchText});

  Future<ConnectionTestResult> testConnection(String url, String? username, String? password);

  Future<BackendDirectory?> getTopPicks(int daysLength);

  Map<String, String> get headers;

  String getMediaApiPath(Media item);

  String? getThumbnailApiPath(Item item);
}
