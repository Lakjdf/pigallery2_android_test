import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/two_finger_scale_gesture_recognizer.dart';
import 'package:provider/provider.dart';

/// Wraps the child with a detector for scale gestures.
/// Enables scaling videos to "fit-to-screen".
class VideoZoomDetector extends StatefulWidget {
  final Widget child;
  final VideoControllerItem videoControllerItem;

  const VideoZoomDetector({super.key, required this.videoControllerItem, required this.child});

  @override
  State<VideoZoomDetector> createState() => _VideoZoomDetectorState();
}

class _VideoZoomDetectorState extends State<VideoZoomDetector> {
  double initialScale = 1;
  late VideoModel model;

  @override
  void initState() {
    super.initState();
    model = context.read();
  }

  double getMaxScale(BuildContext context) {
    Rect? rect = widget.videoControllerItem.controller.rect.value;
    if (rect == null) return 1;
    double aspectRatio = rect.width / rect.height;
    double screenAspectRatio = MediaQuery.of(context).size.aspectRatio;

    if (aspectRatio > screenAspectRatio) {
      return aspectRatio / screenAspectRatio;
    } else {
      return screenAspectRatio / aspectRatio;
    }
  }

  void onUpdate(BuildContext context, ScaleUpdateDetails details) {
    if (widget.videoControllerItem.hasError) return;

    double maxScale = getMaxScale(context);
    model.videoScale = (initialScale * details.scale).clamp(1, maxScale);
  }

  void onEnd(BuildContext context, ScaleEndDetails details) {
    double scale = model.videoScale;
    double maxScale = getMaxScale(context);
    if (details.scaleVelocity < -1) {
      model.videoScale = 1;
    } else if (details.scaleVelocity > 1) {
      model.videoScale = maxScale;
    } else if ((maxScale - scale) > (scale - 1)) {
      model.videoScale = 1;
    } else {
      model.videoScale = maxScale;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        TwoFingerScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<TwoFingerScaleGestureRecognizer>(
          () => TwoFingerScaleGestureRecognizer(),
          (TwoFingerScaleGestureRecognizer instance) {
            instance
              ..onStart = (details) {
                initialScale = context.read<VideoModel>().videoScale;
              }
              ..onUpdate = (details) {
                if (details.pointerCount > 1) {
                  onUpdate(context, details);
                }
              }
              ..onEnd = (details) {
                if (details.pointerCount == 1) {
                  onEnd(context, details);
                }
              };
          },
        ),
      },
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
