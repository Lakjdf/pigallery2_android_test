import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/shared/widgets/error_image.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';

class PhotoViewWidget extends StatelessWidget {
  final Media item;

  const PhotoViewWidget(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    MediaRepository repository = context.read<MediaRepository>();
    return PhotoView(
      loadingBuilder: (context, event) => ThumbnailImage(
        key: ObjectKey(item),
        item,
      ),
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      minScale: PhotoViewComputedScale.contained * 1.0,
      imageProvider: NetworkImage(
        repository.getMediaApiPath(item),
        headers: repository.headers,
      ),
      errorBuilder: (context, url, error) => const ErrorImage(),
    );
  }
}
