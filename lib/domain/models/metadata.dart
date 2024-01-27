import 'package:pigallery2_android/data/backend/models/models.dart';

abstract interface class Metadata {
  int get size;

  double get date;
}

class MediaMetadata implements Metadata {
  final int _fileSize;
  final double _creationDate;

  MediaMetadata({required int fileSize, required double creationDate})
      : _fileSize = fileSize,
        _creationDate = creationDate;

  @override
  int get size => _fileSize;

  @override
  double get date => _creationDate;

  MediaMetadata.fromBackend(BackendMediaMetadata backendMediaMetadata)
      : _fileSize = backendMediaMetadata.fileSize,
        _creationDate = backendMediaMetadata.creationDate;
}

class DirectoryMetadata implements Metadata {
  final int _mediaCount;
  final double _lastModified;

  DirectoryMetadata({required int mediaCount, required double lastModified})
      : _mediaCount = mediaCount,
        _lastModified = lastModified;

  @override
  int get size => _mediaCount;

  @override
  double get date => _lastModified;

  DirectoryMetadata.fromBackend(BackendDirectory backendDirectory)
      : _mediaCount = backendDirectory.mediaCount,
        _lastModified = backendDirectory.lastModified.toDouble();
}
