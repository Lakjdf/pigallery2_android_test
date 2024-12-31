import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/storage/pigallery2_cache_manager.dart';
import 'package:pigallery2_android/data/storage/web_vtt_parser.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/models/sprite_thumbnail_data.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/util/path.dart';
import 'package:http/http.dart' as http;

class MediaRepositoryImpl implements MediaRepository {
  final Logger _logger = Logger((MediaRepository).toString());
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
    // todo download directly using cache manager as well
    localFile ??= (await PiGallery2CacheManager.fullRes.getFileFromCache(_api.getMediaApiPath(item)))?.file;
    if (localFile != null) {
      http.StreamedResponse remoteResponse = await _request(item);
      if (localFile.lengthSync() == remoteResponse.contentLength) {
        return localFile.path;
      }
    }
    return null;
  }

  @override
  Future<SplayTreeMap<Duration, SpriteRegion>?> getSpriteThumbnails(Media item) async {
    String path = '${_api.getSpritesApiPath(item)}.vtt';
    try {
      assert(item.isVideo);
      File vttFile = await PiGallery2CacheManager.spriteThumbnails.getSingleFile(path, headers: _api.headers);
      return WebVttParser.parse(vttFile, path.substring(0, path.lastIndexOf("/")));
    } catch (error, stackTrace) {
      _logger.warning('Failed to get sprite thumbnails for ${item.id}', error, stackTrace);
      return Future.value(null);
    }
  }

  @override
  String getMediaApiPath(Media item) => _api.getMediaApiPath(item);

  @override
  String? getThumbnailApiPath(Item item) => _api.getThumbnailApiPath(item);

  @override
  Map<String, String> get headers => _api.headers;

}