import 'package:pigallery2_android/data/backend/models/models.dart';

import 'media_dimension.dart';
import 'metadata.dart';

sealed class Item {
  final String name;
  final int id;
  final String relativeApiPath;
  final String? relativeThumbnailPath;
  final Metadata metadata;

  Item({required this.name, required this.id, required this.relativeApiPath, required this.relativeThumbnailPath, required this.metadata});
}

class Media extends Item {
  final MediaDimension dimension;

  Media({required super.name, required super.id, required super.relativeApiPath, required super.relativeThumbnailPath, required this.dimension, required MediaMetadata super.metadata});

  Media.fromBackend(BackendMedia backendMedia)
      : dimension = MediaDimension.fromBackend(backendMedia.metadata.size),
        super(
          name: backendMedia.name,
          id: backendMedia.id,
          relativeApiPath: backendMedia.apiPath,
          relativeThumbnailPath: backendMedia.apiPath,
          metadata: MediaMetadata.fromBackend(backendMedia.metadata),
        );
}

class Directory extends Item {
  final List<Directory> directories;
  final List<Media> media;

  Directory({required super.name, required super.id, required super.relativeApiPath, required super.relativeThumbnailPath, required this.directories, required this.media, required DirectoryMetadata super.metadata});

  Directory.fromBackend(BackendDirectory backendDirectory)
      : directories = backendDirectory.directories.map((it) => Directory.fromBackend(it)).toList(),
        media = backendDirectory.media.map((it) => Media.fromBackend(it)).toList(),
        super(
          name: backendDirectory.name,
          id: backendDirectory.id,
          relativeApiPath: backendDirectory.apiPath,
          relativeThumbnailPath: backendDirectory.cover?.apiPath,
          metadata: DirectoryMetadata.fromBackend(backendDirectory),
        );
}
