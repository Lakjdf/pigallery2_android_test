import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/widgets/error_image.dart';
import 'package:pigallery2_android/ui/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';

class PhotoViewWidget extends StatelessWidget {
  final Directory directory;
  final Media item;

  const PhotoViewWidget(this.directory, this.item, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    return PhotoView(
      loadingBuilder: (context, event) => Hero(
        tag: item.id.toString(),
        child: ThumbnailImage(
          key: ObjectKey(item),
          item,
        ),
      ),
      backgroundDecoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      minScale: PhotoViewComputedScale.contained * 1.0,
      imageProvider: NetworkImage(
        model.getItemPath(item),
        headers: model.getHeaders(),
      ),
      heroAttributes: PhotoViewHeroAttributes(
        tag: item.id.toString(),
      ),
      errorBuilder: (context, url, error) {
        return Hero(
          tag: item.id.toString(),
          child: const ErrorImage(),
        );
      },
    );
  }
}
