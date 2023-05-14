import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:pigallery2_android/core/models/media.dart';
import 'package:pigallery2_android/ui/widgets/thumbnail_image.dart';

class MediaItem extends StatelessWidget {
  final Media item;
  final String thumbnailUrl;
  final int borderRadius;
  final VoidCallback onTap;

  const MediaItem({required this.item, required this.thumbnailUrl, required this.borderRadius, required this.onTap, super.key});

  bool isVideo(Media item) {
    return lookupMimeType(item.name)!.contains("video");
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: item.id.toString(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius.toDouble()),
          child: ThumbnailImage(
            key: ObjectKey(item),
            thumbnailUrl,
            imageBuilder: (context, imageProvider) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                  if (isVideo(item))
                    Icon(
                      Icons.play_arrow,
                      size: 70,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(175),
                    )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
