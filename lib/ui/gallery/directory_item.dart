import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';

class DirectoryItem extends StatelessWidget {
  final Directory dir;
  final int borderRadius;
  final bool showDirectoryItemCount;
  final VoidCallback onTap;

  const DirectoryItem({
    required this.dir,
    required this.borderRadius,
    required this.showDirectoryItemCount,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius.toDouble()),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Theme.of(context).colorScheme.surface],
                  stops: const [0.6, 1.0],
                ),
              ),
              child: ThumbnailImage(
                key: ObjectKey(dir),
                dir,
                fit: BoxFit.cover,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 3.0),
                  child: Text(dir.name),
                ),
                if (showDirectoryItemCount)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 6.0),
                    child: Text(dir.metadata.size.toString()),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
