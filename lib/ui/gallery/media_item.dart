import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';

class MediaItem extends StatelessWidget {
  final Media item;
  final int borderRadius;
  final VoidCallback onTap;

  const MediaItem({required this.item, required this.borderRadius, required this.onTap, super.key});

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
            item,
            fit: BoxFit.cover,
            imageBuilder: (context, image) => Stack(
              fit: StackFit.expand,
              children: [
                ThumbnailImage(key: ObjectKey(item), item, fit: BoxFit.cover),
                if (item.isVideo) Icon(Icons.play_arrow, size: 70, color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(175)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
