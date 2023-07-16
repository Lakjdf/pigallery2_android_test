import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/api.dart';
import 'package:pigallery2_android/ui/widgets/error_image.dart';
import 'package:pigallery2_android/ui/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';

class PhotoViewWidget extends StatelessWidget {
  final Media item;

  const PhotoViewWidget(this.item, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ApiService api = Provider.of<ApiService>(context, listen: false);
    return PhotoView(
      loadingBuilder: (context, event) => ThumbnailImage(
        key: ObjectKey(item),
        api.getThumbnailApiPath(item),
      ),
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      minScale: PhotoViewComputedScale.contained * 1.0,
      imageProvider: NetworkImage(
        api.getMediaApiPath(item),
        headers: api.headers,
      ),
      errorBuilder: (context, url, error) => const ErrorImage(),
    );
  }
}
