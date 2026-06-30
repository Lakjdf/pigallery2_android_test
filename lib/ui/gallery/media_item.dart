import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';

class MediaItem extends StatefulWidget {
  final Media item;
  final int borderRadius;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool selectionActive;

  const MediaItem({required this.item, required this.borderRadius, required this.onTap, this.onLongPress, this.isSelected = false, this.selectionActive = false, super.key});

  @override
  State<MediaItem> createState() => _MediaItemState();
}

class _MediaItemState extends State<MediaItem> {
  bool _suppressNextTap = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_suppressNextTap) {
          _suppressNextTap = false;
          return;
        }
        widget.onTap();
      },
      onLongPress: () {
        _suppressNextTap = true;
        widget.onLongPress?.call();
      },
      child: Hero(
        tag: widget.item.id.toString(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius.toDouble()),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ThumbnailImage(
                key: ObjectKey(widget.item),
                widget.item,
                fit: BoxFit.cover,
                imageBuilder: (context, image) => Stack(
                  fit: StackFit.expand,
                  children: [
                    ThumbnailImage(key: ObjectKey(widget.item), widget.item, fit: BoxFit.cover),
                    if (widget.item.isVideo) Icon(Icons.play_arrow, size: 70, color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(175)),
                  ],
                ),
              ),
              if (widget.selectionActive)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withAlpha(220),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      widget.isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: widget.isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
