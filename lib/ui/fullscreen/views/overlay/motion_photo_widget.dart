import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model.dart';
import 'package:provider/provider.dart';

class MotionPhotoWidget extends StatelessWidget {
  final Media item;
  final double opacity;

  const MotionPhotoWidget(this.item, this.opacity, {super.key});

  @override
  Widget build(BuildContext context) {
    bool isMotionPhoto = context.select<PhotoModel, bool>((it) => it.stateOf(item).isMotionPhoto);
    if (!isMotionPhoto) return Container();
    return SizedBox(
      height: 24,
      width: 24,
      child: Tooltip(
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 3),
        message: "Long press the image to see the motion photo",
        child: IconButton(
          padding: const EdgeInsets.all(0),
          constraints: const BoxConstraints(),
          onPressed: null,
          icon: Icon(
            Icons.motion_photos_paused,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(opacity),
          ),
        ),
      ),
    );
  }
}
