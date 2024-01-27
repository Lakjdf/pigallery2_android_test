import 'dart:async';
import 'dart:io';

import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/util/path.dart';
import 'package:http/http.dart' as http;

class MediaRepositoryImpl implements MediaRepository {
  final ApiService _api;

  MediaRepositoryImpl(this._api);

  Future<File> _getFile(Media item) async {
    String path = _api.getMediaApiPath(item);
    String filename = path.split('/').last;
    return File('${await Downloads.getPath()}/${filename.split('.').first}-${item.id}.${filename.split('.').last}');
  }

  Future<File?> _getExistingFile(Media item) async {
    final file = await _getFile(item);
    return file.existsSync() ? file : null;
  }

  Future<http.StreamedResponse> _request(Media item) {
    String path = _api.getMediaApiPath(item);
    http.Request request = http.Request('GET', Uri.parse(path));
    request.headers.addAll(_api.headers);
    return http.Client().send(request);
  }

  Stream<double> _download(Media item) async* {
    final file = await _getFile(item);
    http.StreamedResponse response = await _request(item);
    int received = 0;
    int total = response.contentLength ?? 0;
    IOSink sink = file.openWrite();
    await for (final buffer in response.stream) {
      sink.add(buffer);
      received += buffer.length;
      yield received/total;
    }
    await sink.close();
  }

  @override
  StreamSubscription<double> download(Media item) {
    return _download(item).listen(null, cancelOnError: true);
  }

  @override
  Future<String?> getFilePath(Media item) async {
    File? localFile = await _getExistingFile(item);
    if (localFile != null) {
      http.StreamedResponse remoteResponse = await _request(item);
      if (localFile.lengthSync() == remoteResponse.contentLength) {
        return localFile.path;
      }
    }
    return null;
  }

  @override
  String getMediaApiPath(Media item) => _api.getMediaApiPath(item);

  @override
  String? getThumbnailApiPath(Item item) => _api.getThumbnailApiPath(item);

  @override
  Map<String, String> get headers => _api.headers;

}