import 'package:pigallery2_android/data/backend/models/media_metadata.dart';

class MediaDimension {
  int width;
  int height;

  MediaDimension({required this.width, required this.height});

  MediaDimension.fromBackend(BackendMediaDimension backendMediaDimension)
      : width = backendMediaDimension.width,
        height = backendMediaDimension.height;
}
